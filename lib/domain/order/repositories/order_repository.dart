import '../entities/address.dart';
import '../entities/order.dart';
import '../entities/order_item.dart';
import '../entities/order_status.dart';

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

  /// The owner's order desk (S3) — newest first, same query shape as
  /// [watchCustomerOrders] but keyed by shop instead of customer.
  Stream<List<Order>> watchShopOrders(String shopId);

  Stream<Order> watchOrder(String orderId);

  /// The courier's own active deliveries (`preparing`/`outForDelivery`,
  /// Session 10) — unordered on the wire, sorted client-side by the bloc.
  Stream<List<Order>> watchDriverActiveOrders(String driverUid);

  /// The courier's delivered history, newest first, capped at 20.
  Stream<List<Order>> watchDriverHistory(String driverUid);

  /// Throws [AuthFailure]-free domain error if the order is past
  /// `OrderStatus.isCancellable` — see `order_status.dart`.
  Future<void> cancelOrder(String orderId);

  /// Owner-side status advance (accept/reject/preparing/outForDelivery/
  /// delivered) — the allowed transitions are enforced server-side by the
  /// Firestore rule, not re-validated here.
  Future<void> updateOrderStatus(String orderId, OrderStatus status);

  /// Customer rates the shop (1-5) after a delivered order (P3). Stamps the
  /// order's `rating` and bumps the shop's `ratingSum`/`ratingCount` in one
  /// transaction. Second call on an already-rated order is a Firestore-rule
  /// rejection, not re-validated here.
  Future<void> rateOrder({
    required String orderId,
    required String shopId,
    required int rating,
  });
}
