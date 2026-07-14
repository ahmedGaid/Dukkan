import '../../../domain/admin/entities/orders_page.dart';
import '../../../domain/admin/repositories/admin_orders_repository.dart';
import '../../../domain/order/entities/order.dart';
import '../../../domain/order/entities/order_note.dart';
import '../datasources/admin_api_datasource.dart';
import '../datasources/admin_orders_remote_datasource.dart';

/// Board reads are Firestore-direct, no cache (same contract as
/// `AdminUsersRepositoryImpl` — the console must always reflect the latest
/// state); the three correction ops are Worker-routed and audited
/// server-side, never a Firestore-direct write (see `worker/src/admin.js`).
class AdminOrdersRepositoryImpl implements AdminOrdersRepository {
  AdminOrdersRepositoryImpl(this._remote, this._api);

  final AdminOrdersRemoteDataSource _remote;
  final AdminApiDataSource _api;

  @override
  Future<OrdersPage> getOrders({String? status, DateTime? cursor}) =>
      _remote.getOrders(status: status, cursor: cursor);

  @override
  Future<Order?> getOrderById(String orderId) => _remote.getOrderById(orderId);

  @override
  Future<List<Order>> getOrdersByCustomerUid(String customerUid) =>
      _remote.getOrdersByCustomerUid(customerUid);

  @override
  Future<void> forceStatus({
    required String orderId,
    required String toStatus,
    required String reason,
  }) =>
      _api.post('orders/force-status', {
        'orderId': orderId,
        'toStatus': toStatus,
        'reason': reason,
      });

  @override
  Future<void> reassignDriver({
    required String orderId,
    String? newDriverUid,
    bool clear = false,
    required String reason,
  }) =>
      _api.post('orders/reassign-driver', {
        'orderId': orderId,
        if (clear) 'clear': true else 'newDriverUid': newDriverUid,
        'reason': reason,
      });

  @override
  Future<void> cancelOrder({
    required String orderId,
    required String reason,
    int? refundNoteMinor,
  }) =>
      _api.post('orders/cancel', {
        'orderId': orderId,
        'reason': reason,
        'refundNoteMinor': ?refundNoteMinor,
      });

  @override
  Stream<List<OrderNote>> watchNotes(String orderId) => _remote.watchNotes(orderId);

  @override
  Future<void> addNote({required String orderId, required String text}) =>
      _remote.addNote(orderId: orderId, text: text);
}
