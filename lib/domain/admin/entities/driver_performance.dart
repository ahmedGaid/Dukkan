import 'package:equatable/equatable.dart';

/// Delivered-order counts for the console driver detail card (FC11). Current
/// active load reads straight off [Driver.activeOrdersCount] — no query
/// needed for that half.
class DriverPerformance extends Equatable {
  const DriverPerformance({
    required this.deliveredTotal,
    required this.deliveredThisMonth,
  });

  final int deliveredTotal;
  final int deliveredThisMonth;

  @override
  List<Object?> get props => [deliveredTotal, deliveredThisMonth];
}
