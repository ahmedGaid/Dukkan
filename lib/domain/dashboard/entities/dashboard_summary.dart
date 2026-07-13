import 'package:equatable/equatable.dart';

import 'daily_order_count.dart';

/// Live platform snapshot for the Founder Console dashboard (FC5). Every figure
/// is an aggregate query (`count()`/`sum()`) — never a document download, the
/// M13 finance lesson — so a busy platform stays cheap to summarise.
///
/// [totalUsers] is null when the viewer lacks `users.read`: the dashboard is
/// open to any active staff member, but a moderator can't count `/users`, so
/// that one query is skipped and the tile renders a neutral dash instead of
/// failing the whole load. Order/shop/product/driver figures ride read rules
/// every staff role already satisfies.
class DashboardSummary extends Equatable {
  const DashboardSummary({
    required this.ordersToday,
    required this.revenueTodayMinor,
    required this.commissionTodayMinor,
    required this.ordersWaiting,
    required this.totalUsers,
    required this.totalShops,
    required this.totalProducts,
    required this.driversOnline,
    required this.pendingShops,
    required this.last7Days,
  });

  final int ordersToday;
  final int revenueTodayMinor;
  final int commissionTodayMinor;
  final int ordersWaiting;

  /// Null when the viewer cannot read `/users` (see class doc).
  final int? totalUsers;
  final int totalShops;
  final int totalProducts;
  final int driversOnline;

  /// Shops awaiting founder approval (`status == 'pending'`). 0 until Session 7
  /// introduces the field — an equality query on a missing field matches
  /// nothing, which reads correctly as "none pending".
  final int pendingShops;

  /// Seven daily order counts, oldest-first, the last bucket being today.
  final List<DailyOrderCount> last7Days;

  @override
  List<Object?> get props => [
        ordersToday,
        revenueTodayMinor,
        commissionTodayMinor,
        ordersWaiting,
        totalUsers,
        totalShops,
        totalProducts,
        driversOnline,
        pendingShops,
        last7Days,
      ];
}
