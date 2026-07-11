import '../../../domain/finance/entities/finance_summary.dart';

class FinanceSummaryModel extends FinanceSummary {
  const FinanceSummaryModel({
    required super.totalOrders,
    required super.deliveredOrders,
    required super.cancelledOrders,
    required super.commissionMinor,
    required super.deliveryRevenueMinor,
  });
}
