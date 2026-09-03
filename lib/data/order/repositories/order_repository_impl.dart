import '../../../core/offline/offline_mutation_queue.dart';
import '../../../core/offline/pending_mutation.dart';
import '../../../core/errors/failures.dart';
import '../../../domain/order/entities/address.dart';
import '../../../domain/order/entities/order.dart';
import '../../../domain/order/entities/order_item.dart';
import '../../../domain/order/entities/order_status.dart';
import '../../../domain/order/repositories/order_repository.dart';
import '../datasources/order_remote_datasource.dart';

/// No offline branch on any method except [updateOrderStatus] (O2 slice 1) —
/// every other order write still needs a live round trip (placing an order,
/// cancelling, rating are all out of this slice's locked scope, see
/// `Docs/plan/offline-order-status-queue-design.md`); realtime status only
/// matters while connected too.
class OrderRepositoryImpl implements OrderRepository {
  OrderRepositoryImpl(
    OrderRemoteDataSource remote, {
    required OfflineMutationQueue queue,
    required String? Function() currentUidProvider,
  })  : _updateOrderStatusRemote = remote.updateOrderStatus,
        _remote = remote,
        _queue = queue,
        _currentUidProvider = currentUidProvider;

  /// Test seam — lets `order_repository_impl_test.dart` fake just the one
  /// remote call this offline branch touches, without a real `FirebaseAuth`/
  /// `FirebaseFirestore`. Production always goes through the real
  /// [OrderRemoteDataSource.updateOrderStatus].
  OrderRepositoryImpl.forTest({
    required Future<void> Function(String orderId, OrderStatus status) updateOrderStatusRemote,
    required OfflineMutationQueue queue,
    required String? Function() currentUidProvider,
  })  : _updateOrderStatusRemote = updateOrderStatusRemote,
        _remote = null,
        _queue = queue,
        _currentUidProvider = currentUidProvider;

  final OrderRemoteDataSource? _remote;
  final Future<void> Function(String orderId, OrderStatus status) _updateOrderStatusRemote;
  final OfflineMutationQueue _queue;
  final String? Function() _currentUidProvider;

  @override
  Future<Order> placeOrder({
    required String shopId,
    required String customerUid,
    required List<OrderItem> items,
    required Address deliveryAddress,
    required int subtotalMinor,
    required int deliveryFeeMinor,
    required int commissionBps,
    required int commissionMinor,
    required int driverDeliveryShareMinor,
    required int platformDeliveryShareMinor,
    required int totalMinor,
    String? notes,
    String? couponCode,
    int discountMinor = 0,
  }) {
    return _remote!.placeOrder(
      shopId: shopId,
      customerUid: customerUid,
      items: items,
      deliveryAddress: deliveryAddress,
      subtotalMinor: subtotalMinor,
      deliveryFeeMinor: deliveryFeeMinor,
      commissionBps: commissionBps,
      commissionMinor: commissionMinor,
      driverDeliveryShareMinor: driverDeliveryShareMinor,
      platformDeliveryShareMinor: platformDeliveryShareMinor,
      totalMinor: totalMinor,
      notes: notes,
      couponCode: couponCode,
      discountMinor: discountMinor,
    );
  }

  @override
  Stream<List<Order>> watchCustomerOrders(String customerUid) =>
      _remote!.watchCustomerOrders(customerUid);

  @override
  Stream<List<Order>> watchShopOrders(String shopId) => _remote!.watchShopOrders(shopId);

  @override
  Stream<Order> watchOrder(String orderId) => _remote!.watchOrder(orderId);

  @override
  Stream<List<Order>> watchDriverActiveOrders(String driverUid) =>
      _remote!.watchDriverActiveOrders(driverUid);

  @override
  Stream<List<Order>> watchDriverHistory(String driverUid) =>
      _remote!.watchDriverHistory(driverUid);

  @override
  Future<void> cancelOrder(String orderId) => _remote!.cancelOrder(orderId);

  /// Try-then-queue, not check-then-branch (final-review I3): attempts the
  /// real write first and only falls back to the offline queue when it
  /// throws a [ServerFailure] that [isOfflineShapedFailure] recognizes as
  /// "couldn't reach the server", rather than paying a `NetworkInfo` probe
  /// (2 real HTTP requests) ahead of every single call. This also closes
  /// the old check-then-branch's gap where connectivity could drop (or the
  /// probe could succeed through something that can't actually reach
  /// Firestore) between the check and the write — that write used to throw
  /// straight to the caller instead of being queued; now the same write
  /// attempt IS the check.
  @override
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      await _updateOrderStatusRemote(orderId, status);
    } on ServerFailure catch (e) {
      if (!isOfflineShapedFailure(e)) rethrow;
      await _queue.enqueue(PendingMutation(
        id: '${DateTime.now().microsecondsSinceEpoch}-$orderId',
        orderId: orderId,
        targetStatus: status,
        actorUid: _currentUidProvider() ?? '',
        enqueuedAt: DateTime.now(),
      ));
    }
  }

  @override
  Future<void> rateOrder({
    required String orderId,
    required String shopId,
    required int rating,
  }) =>
      _remote!.rateOrder(orderId: orderId, shopId: shopId, rating: rating);
}
