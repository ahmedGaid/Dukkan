import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/errors/failures.dart';
import '../../../domain/dashboard/entities/daily_order_count.dart';
import '../models/dashboard_summary_model.dart';
import 'day_window.dart';

/// Live platform figures for the console dashboard, all via `count()`/`sum()`
/// aggregates — no document downloads (M13 lesson). One `Future.wait` fires
/// every query in parallel; the read rules each aggregate rides are auth-only
/// (never `resource.data`), so aggregation stays legal.
///
/// Index note: the `delivered && createdAt >= today` money sums need the
/// composite `status + createdAt`; every other query is a single-field range or
/// equality (or two equalities, which Firestore serves from single-field
/// indexes) — see `firestore.indexes.json`.
class DashboardRemoteDataSource {
  DashboardRemoteDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  Future<DashboardSummaryModel> getSummary({required bool includeUsers}) async {
    try {
      final now = DateTime.now();
      final todayStart = Timestamp.fromDate(startOfDay(now));
      final days = last7DayStarts(now);

      final orders = _firestore.collection('orders');
      final shops = _firestore.collection('shops');

      final ordersToday =
          orders.where('createdAt', isGreaterThanOrEqualTo: todayStart);
      final deliveredToday = orders
          .where('status', isEqualTo: 'delivered')
          .where('createdAt', isGreaterThanOrEqualTo: todayStart);
      final waiting = orders.where('status', isEqualTo: 'pending');
      final driversOnline = _firestore
          .collection('drivers')
          .where('isOnline', isEqualTo: true)
          .where('isSuspended', isEqualTo: false);
      final pendingShops = shops.where('status', isEqualTo: 'pending');
      final failedNotifications = _firestore
          .collection('notifications')
          .where('status', isEqualTo: 'failed')
          .where('sentAt', isGreaterThanOrEqualTo: Timestamp.fromDate(days.first));

      // Order matters: results are read back by index below. The 7 per-day
      // counts occupy indices 7..13; failed notifications is 14; the
      // optional users count is last.
      final futures = <Future<AggregateQuerySnapshot>>[
        ordersToday.count().get(), // 0
        deliveredToday
            .aggregate(count(), sum('totalMinor'), sum('commissionMinor'))
            .get(), // 1
        waiting.count().get(), // 2
        shops.count().get(), // 3
        _firestore.collection('products').count().get(), // 4
        driversOnline.count().get(), // 5
        pendingShops.count().get(), // 6
        for (final d in days) // 7 .. 13
          orders
              .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(d))
              .where('createdAt',
                  isLessThan: Timestamp.fromDate(nextDay(d)))
              .count()
              .get(),
        failedNotifications.count().get(), // 14
        if (includeUsers) _firestore.collection('users').count().get(), // 15
      ];

      final r = await Future.wait(futures);

      return DashboardSummaryModel(
        ordersToday: r[0].count ?? 0,
        revenueTodayMinor: (r[1].getSum('totalMinor') ?? 0).round(),
        commissionTodayMinor: (r[1].getSum('commissionMinor') ?? 0).round(),
        ordersWaiting: r[2].count ?? 0,
        totalShops: r[3].count ?? 0,
        totalProducts: r[4].count ?? 0,
        driversOnline: r[5].count ?? 0,
        pendingShops: r[6].count ?? 0,
        last7Days: [
          for (var i = 0; i < days.length; i++)
            DailyOrderCount(day: days[i], count: r[7 + i].count ?? 0),
        ],
        failedNotifications7d: r[7 + days.length].count ?? 0,
        totalUsers: includeUsers ? (r[8 + days.length].count ?? 0) : null,
      );
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }
}
