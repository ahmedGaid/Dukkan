import 'package:equatable/equatable.dart';

/// One row of the reports page's «التوزيع» section (orders by area, products
/// by category, orders by shop) — a simple horizontal bar row (count + label),
/// no new chart widget (FC17).
class DistributionEntry extends Equatable {
  const DistributionEntry({required this.labelAr, required this.labelEn, required this.count});

  final String labelAr;
  final String labelEn;
  final int count;

  @override
  List<Object?> get props => [labelAr, labelEn, count];
}
