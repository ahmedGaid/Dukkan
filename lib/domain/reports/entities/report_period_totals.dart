import 'package:equatable/equatable.dart';

import 'report_period_point.dart';

/// The reports page's period-picker aggregate (FC17, 7/30/90 days) — the
/// per-day series behind the three mini bar charts plus the totals row and
/// the «النمو» growth counts. [newUsers]/[newShops] exclude docs written
/// before their `createdAt` field existed (the UI captions this).
class ReportPeriodTotals extends Equatable {
  const ReportPeriodTotals({
    required this.periodDays,
    required this.daily,
    required this.totalOrders,
    required this.totalRevenueMinor,
    required this.totalCommissionMinor,
    required this.newUsers,
    required this.newShops,
  });

  final int periodDays;

  /// Oldest-first, one entry per day in the period.
  final List<ReportPeriodPoint> daily;

  final int totalOrders;
  final int totalRevenueMinor;
  final int totalCommissionMinor;
  final int newUsers;
  final int newShops;

  @override
  List<Object?> get props => [
        periodDays,
        daily,
        totalOrders,
        totalRevenueMinor,
        totalCommissionMinor,
        newUsers,
        newShops,
      ];
}
