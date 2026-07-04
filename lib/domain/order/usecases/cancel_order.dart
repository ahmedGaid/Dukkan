import '../repositories/order_repository.dart';

class CancelOrder {
  const CancelOrder(this._repository);

  final OrderRepository _repository;

  Future<void> call(String orderId) => _repository.cancelOrder(orderId);
}
