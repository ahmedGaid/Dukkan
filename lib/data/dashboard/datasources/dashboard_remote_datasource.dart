import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/errors/failures.dart';
import '../../../core/firestore/platform_stats.dart';
import '../../../domain/dashboard/entities/daily_order_count.dart';
import '../models/dashboard_summary_model.dart';
import 'day_window.dart';

/// Live platform figures for the console dashboard, read from the rolling
/// `/stats` counters (Phase 8 O1) instead of `count()`/`sum()` aggregates —
/// those can NEVER be served from Firestore's local cache (a hard SDK
/// restriction), so the dashboard was unusable offline no matter what
/// caching the rest of the app had. A plain doc read *can* be served
/// offline once fetched, so this datasource now costs 8 doc reads (1 global
/// + 7 daily buckets) instead of 16 aggregate reads, and stays populated
/// without a connection. See `core/firestore/platform_stats.dart` for who
/// bumps these fields and why each one is safe to trust.
class DashboardRemoteDataSource {
  DashboardRemoteDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  Future<DashboardSummaryModel> getSummary({required bool includeUsers}) async {
    try {
      final now = DateTime.now();
      final days = last7DayStarts(now);

      final results = await Future.wait([
        globalStatsRef(_firestore).get(),
        for (final day in days) dailyStatsRef(_firestore, day).get(),
      ]);

      final global = results.first.data() ?? const <String, dynamic>{};
      final dailySnaps = results.skip(1).toList(growable: false);
      final todayData = dailySnaps.last.data() ?? const <String, dynamic>{};

      var failedNotifications7d = 0;
      final last7Days = <DailyOrderCount>[];
      for (var i = 0; i < days.length; i++) {
        final data = dailySnaps[i].data() ?? const <String, dynamic>{};
        failedNotifications7d +=
            (data['failedNotifications'] as num?)?.toInt() ?? 0;
        last7Days.add(DailyOrderCount(
          day: days[i],
          count: (data['ordersCount'] as num?)?.toInt() ?? 0,
        ));
      }

      int field(Map<String, dynamic> data, String key) =>
          (data[key] as num?)?.toInt() ?? 0;

      return DashboardSummaryModel(
        ordersToday: field(todayData, 'ordersCount'),
        revenueTodayMinor: field(todayData, 'revenueMinor'),
        commissionTodayMinor: field(todayData, 'commissionMinor'),
        ordersWaiting: field(global, 'ordersWaiting'),
        totalShops: field(global, 'totalShops'),
        totalProducts: field(global, 'totalProducts'),
        driversOnline: field(global, 'driversOnline'),
        pendingShops: field(global, 'pendingShops'),
        last7Days: last7Days,
        failedNotifications7d: failedNotifications7d,
        totalUsers: includeUsers ? field(global, 'totalUsers') : null,
      );
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }
}
