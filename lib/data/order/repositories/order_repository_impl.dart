import '../../../domain/order/entities/address.dart';
import '../../../domain/order/entities/order.dart';
import '../../../domain/order/entities/order_item.dart';
import '../../../domain/order/entities/order_status.dart';
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
  Stream<List<Order>> watchShopOrders(String shopId) =>
      _remote.watchShopOrders(shopId);

  @override
  Stream<Order> watchOrder(String orderId) => _remote.watchOrder(orderId);

  @override
  Stream<List<Order>> watchDriverActiveOrders(String driverUid) =>
      _remote.watchDriverActiveOrders(driverUid);

  @override
  Stream<List<Order>> watchDriverHistory(String driverUid) =>
      _remote.watchDriverHistory(driverUid);

  @override
  Future<void> cancelOrder(String orderId) => _remote.cancelOrder(orderId);

  @override
  Future<void> updateOrderStatus(String orderId, OrderStatus status) =>
      _remote.updateOrderStatus(orderId, status);

  @override
  Future<void> rateOrder({
    required String orderId,
    required String shopId,
    required int rating,
  }) =>
      _remote.rateOrder(orderId: orderId, shopId: shopId, rating: rating);
}
