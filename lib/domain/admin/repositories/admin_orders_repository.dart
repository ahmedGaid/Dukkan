import '../../order/entities/order.dart';
import '../../order/entities/order_note.dart';
import '../entities/orders_page.dart';

/// Founder Console order admin (FC10). Board reads are Firestore-direct
/// (gated by `orders.read`, same rule the order-owner/shop-owner/driver reads
/// already use); the three correction ops are Worker-routed so they can be
/// permission-checked server-side and written to the immutable audit trail —
/// the client-side transition whitelist in `firestore.rules` stays untouched,
/// corrections only ever happen through here.
abstract class AdminOrdersRepository {
  /// One page of the board, newest first. [status] is the one server-side
  /// equality facet (matches the dashboard's `?status=` deep link and the
  /// board's status chips); shop/area/date-range are refined client-side over
  /// the loaded page — the same "small marketplace, filter what's loaded"
  /// contract as `AdminShopsRepository.getAllShops`, just paginated because an
  /// order history keeps growing where a shop list doesn't.
  Future<OrdersPage> getOrders({String? status, DateTime? cursor});

  /// Direct doc lookup for the board's "order id" search field.
  Future<Order?> getOrderById(String orderId);

  /// Every order for one customer, newest first — the board's "exact phone"
  /// search resolves the phone to a uid first (`GetUserByPhone`), then calls
  /// this (reuses the existing `customerUid`+`createdAt` index).
  Future<List<Order>> getOrdersByCustomerUid(String customerUid);

  /// `/admin/orders/force-status` (perm `orders.forceStatus`) — moves the
  /// order to [toStatus] outside the normal transition whitelist, always with
  /// a [reason]. Also fixes the side effects a normal transition would have
  /// (commission payable flag, the driver's `activeOrdersCount`).
  Future<void> forceStatus({
    required String orderId,
    required String toStatus,
    required String reason,
  });

  /// `/admin/orders/reassign-driver` (perm `orders.assignDriver`) — moves the
  /// order to [newDriverUid], or unassigns it when [clear] is true. Always
  /// with a [reason].
  Future<void> reassignDriver({
    required String orderId,
    String? newDriverUid,
    bool clear = false,
    required String reason,
  });

  /// `/admin/orders/cancel` (perm `orders.cancel`) — cancels an order outside
  /// the customer's own pending/accepted-only window. [refundNoteMinor] is a
  /// COD ledger note only; no money actually moves.
  Future<void> cancelOrder({
    required String orderId,
    required String reason,
    int? refundNoteMinor,
  });

  /// Realtime notes on one order — Firestore-direct (`orders.update` rules
  /// branch), append-only.
  Stream<List<OrderNote>> watchNotes(String orderId);

  Future<void> addNote({required String orderId, required String text});
}
