import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/errors/failures.dart';
import '../../../domain/reports/entities/report_period_point.dart';
import '../../../domain/reports/entities/report_period_totals.dart';
import '../../dashboard/datasources/day_window.dart';

/// Live per-day aggregates for the console reports page (FC17) — the same
/// `count()`/`sum()` shape as `DashboardRemoteDataSource`, generalized from a
/// fixed 7 days to the period picker's 7/30/90. No document downloads.
///
/// Index note: the delivered-per-day sum (`status == 'delivered' &&
/// createdAt` range) rides the exact composite index the dashboard's
/// `deliveredToday` query already uses (`status ASC, createdAt ASC`) — no new
/// `firestore.indexes.json` entry needed. `users`/`shops` `createdAt` range
/// counts and the per-shop `orders.shopId` counts are single-field
/// equalities/ranges, auto-indexed by Firestore.
class ReportsRemoteDataSource {
  ReportsRemoteDataSource({required FirebaseFirestore firestore}) : _firestore = firestore;

  final FirebaseFirestore _firestore;

  Future<ReportPeriodTotals> getPeriodTotals({required int periodDays}) async {
    try {
      final now = DateTime.now();
      final days = lastNDayStarts(now, periodDays);
      final periodStart = Timestamp.fromDate(days.first);
      final n = days.length;

      final orders = _firestore.collection('orders');

      final futures = <Future<AggregateQuerySnapshot>>[
        for (final d in days) // 0 .. n-1: per-day order count
          orders
              .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(d))
              .where('createdAt', isLessThan: Timestamp.fromDate(nextDay(d)))
              .count()
              .get(),
        for (final d in days) // n .. 2n-1: per-day delivered revenue+commission
          orders
              .where('status', isEqualTo: 'delivered')
              .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(d))
              .where('createdAt', isLessThan: Timestamp.fromDate(nextDay(d)))
              .aggregate(count(), sum('totalMinor'), sum('commissionMinor'))
              .get(),
        _firestore.collection('users').where('createdAt', isGreaterThanOrEqualTo: periodStart).count().get(), // 2n
        _firestore.collection('shops').where('createdAt', isGreaterThanOrEqualTo: periodStart).count().get(), // 2n+1
      ];

      final r = await Future.wait(futures);

      final daily = [
        for (var i = 0; i < n; i++)
          ReportPeriodPoint(
            day: days[i],
            ordersCount: r[i].count ?? 0,
            revenueMinor: (r[n + i].getSum('totalMinor') ?? 0).round(),
            commissionMinor: (r[n + i].getSum('commissionMinor') ?? 0).round(),
          ),
      ];

      var totalOrders = 0;
      var totalRevenueMinor = 0;
      var totalCommissionMinor = 0;
      for (final point in daily) {
        totalOrders += point.ordersCount;
        totalRevenueMinor += point.revenueMinor;
        totalCommissionMinor += point.commissionMinor;
      }

      return ReportPeriodTotals(
        periodDays: periodDays,
        daily: daily,
        totalOrders: totalOrders,
        totalRevenueMinor: totalRevenueMinor,
        totalCommissionMinor: totalCommissionMinor,
        newUsers: r[2 * n].count ?? 0,
        newShops: r[2 * n + 1].count ?? 0,
      );
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }

  Future<Map<String, int>> getOrderCountsByShop(List<String> shopIds) async {
    if (shopIds.isEmpty) return const {};
    try {
      final orders = _firestore.collection('orders');
      final futures = [
        for (final id in shopIds) orders.where('shopId', isEqualTo: id).count().get(),
      ];
      final results = await Future.wait(futures);
      return {
        for (var i = 0; i < shopIds.length; i++) shopIds[i]: results[i].count ?? 0,
      };
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }
}
