import '../entities/address.dart';
import '../entities/order.dart';
import '../entities/order_item.dart';
import '../repositories/order_repository.dart';

class PlaceOrder {
  const PlaceOrder(this._repository);

  final OrderRepository _repository;

  Future<Order> call({
    required String shopId,
    required String customerUid,
    required List<OrderItem> items,
    required int totalMinor,
    required Address deliveryAddress,
    String? notes,
  }) {
    return _repository.placeOrder(
      shopId: shopId,
      customerUid: customerUid,
      items: items,
      totalMinor: totalMinor,
      deliveryAddress: deliveryAddress,
      notes: notes,
    );
  }
}
