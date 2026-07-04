import '../entities/address.dart';
import '../entities/order.dart';
import '../entities/order_item.dart';

/// Order boundary. Orders always go straight to Firestore — no offline cache
/// (COD ops need a live write anyway); realtime status comes from snapshots.
abstract class OrderRepository {
  Future<Order> placeOrder({
    required String shopId,
    required String customerUid,
    required List<OrderItem> items,
    required int totalMinor,
    required Address deliveryAddress,
    String? notes,
  });

  Stream<List<Order>> watchCustomerOrders(String customerUid);

  Stream<Order> watchOrder(String orderId);

  /// Throws [AuthFailure]-free domain error if the order is past
  /// `OrderStatus.isCancellable` — see `order_status.dart`.
  Future<void> cancelOrder(String orderId);
}
