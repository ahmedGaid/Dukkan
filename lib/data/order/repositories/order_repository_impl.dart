import '../../../domain/order/entities/address.dart';
import '../../../domain/order/entities/order.dart';
import '../../../domain/order/entities/order_item.dart';
import '../../../domain/order/repositories/order_repository.dart';
import '../datasources/order_remote_datasource.dart';

/// No offline branch — orders always need a live write, and status realtime
/// only matters while connected (see `OrderRepository` doc).
class OrderRepositoryImpl implements OrderRepository {
  OrderRepositoryImpl(this._remote);

  final OrderRemoteDataSource _remote;

  @override
  Future<Order> placeOrder({
    required String shopId,
    required String customerUid,
    required List<OrderItem> items,
    required int totalMinor,
    required Address deliveryAddress,
    String? notes,
  }) {
    return _remote.placeOrder(
      shopId: shopId,
      customerUid: customerUid,
      items: items,
      totalMinor: totalMinor,
      deliveryAddress: deliveryAddress,
      notes: notes,
    );
  }

  @override
  Stream<List<Order>> watchCustomerOrders(String customerUid) =>
      _remote.watchCustomerOrders(customerUid);

  @override
  Stream<Order> watchOrder(String orderId) => _remote.watchOrder(orderId);

  @override
  Future<void> cancelOrder(String orderId) => _remote.cancelOrder(orderId);
}
