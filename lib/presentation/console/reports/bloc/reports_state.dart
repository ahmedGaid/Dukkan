part of 'reports_bloc.dart';

enum ReportsStatus { loading, loaded, error }

class ReportsState extends Equatable {
  const ReportsState({
    this.status = ReportsStatus.loading,
    this.periodDays = 7,
    this.totals,
    this.ordersByArea = const [],
    this.productsByCategory = const [],
    this.ordersByShop = const [],
  });

  final ReportsStatus status;
  final int periodDays;
  final ReportPeriodTotals? totals;
  final List<DistributionEntry> ordersByArea;
  final List<DistributionEntry> productsByCategory;

  /// Already sorted desc + capped to the top 10.
  final List<DistributionEntry> ordersByShop;

  ReportsState copyWith({
    ReportsStatus? status,
    int? periodDays,
    ReportPeriodTotals? totals,
    List<DistributionEntry>? ordersByArea,
    List<DistributionEntry>? productsByCategory,
    List<DistributionEntry>? ordersByShop,
  }) =>
      ReportsState(
        status: status ?? this.status,
        periodDays: periodDays ?? this.periodDays,
        totals: totals ?? this.totals,
        ordersByArea: ordersByArea ?? this.ordersByArea,
        productsByCategory: productsByCategory ?? this.productsByCategory,
        ordersByShop: ordersByShop ?? this.ordersByShop,
      );

  @override
  List<Object?> get props =>
      [status, periodDays, totals, ordersByArea, productsByCategory, ordersByShop];
}
