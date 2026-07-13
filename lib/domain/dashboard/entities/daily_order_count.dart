import 'package:equatable/equatable.dart';

/// One day's order count for the dashboard's 7-day mini bar chart. [day] is the
/// local midnight that starts the bucket; [count] is the number of orders
/// created that day. The list on [DashboardSummary] is oldest-first.
class DailyOrderCount extends Equatable {
  const DailyOrderCount({required this.day, required this.count});

  final DateTime day;
  final int count;

  @override
  List<Object?> get props => [day, count];
}
