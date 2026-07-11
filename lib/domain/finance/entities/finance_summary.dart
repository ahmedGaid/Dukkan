import 'package:equatable/equatable.dart';

/// Founder-only aggregate snapshot of the whole `/orders` collection (M13).
/// Financial sums (`commissionMinor`/`deliveryRevenueMinor`) filter to
/// `delivered` orders only — a cancelled/pending order never carried a
/// payable commission (see `PlatformConfig`/M12), and pre-M12 orders sum as
/// zero since they had no commission fields at all.
class FinanceSummary extends Equatable {
  const FinanceSummary({
    required this.totalOrders,
    required this.deliveredOrders,
    required this.cancelledOrders,
    required this.commissionMinor,
    required this.deliveryRevenueMinor,
  });

  final int totalOrders;
  final int deliveredOrders;
  final int cancelledOrders;
  final int commissionMinor;
  final int deliveryRevenueMinor;

  /// The platform's total cut — commission plus its share of the delivery
  /// fee. Derived here (client add), never stored anywhere.
  int get platformRevenueMinor => commissionMinor + deliveryRevenueMinor;

  @override
  List<Object?> get props => [
        totalOrders,
        deliveredOrders,
        cancelledOrders,
        commissionMinor,
        deliveryRevenueMinor,
      ];
}
