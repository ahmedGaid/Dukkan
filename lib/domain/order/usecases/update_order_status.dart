import '../entities/order_status.dart';
import '../repositories/order_repository.dart';

class UpdateOrderStatus {
  const UpdateOrderStatus(this._repository);

  final OrderRepository _repository;

  Future<void> call(String orderId, OrderStatus status) =>
      _repository.updateOrderStatus(orderId, status);
}
