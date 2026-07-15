import '../../../domain/dashboard/entities/dashboard_summary.dart';

/// Thin over the entity — built straight from aggregate snapshots in the
/// datasource (there is no document JSON to parse), mirrors
/// `FinanceSummaryModel`.
class DashboardSummaryModel extends DashboardSummary {
  const DashboardSummaryModel({
    required super.ordersToday,
    required super.revenueTodayMinor,
    required super.commissionTodayMinor,
    required super.ordersWaiting,
    required super.totalUsers,
    required super.totalShops,
    required super.totalProducts,
    required super.driversOnline,
    required super.pendingShops,
    required super.last7Days,
    required super.failedNotifications7d,
  });
}
