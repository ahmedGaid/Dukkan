import 'package:equatable/equatable.dart';

/// One day's slice of the reports period aggregate (FC17) — generalizes the
/// dashboard's `DailyOrderCount` with the revenue/commission sums the
/// reports page's three mini bar charts need.
class ReportPeriodPoint extends Equatable {
  const ReportPeriodPoint({
    required this.day,
    required this.ordersCount,
    required this.revenueMinor,
    required this.commissionMinor,
  });

  final DateTime day;
  final int ordersCount;
  final int revenueMinor;
  final int commissionMinor;

  @override
  List<Object?> get props => [day, ordersCount, revenueMinor, commissionMinor];
}
