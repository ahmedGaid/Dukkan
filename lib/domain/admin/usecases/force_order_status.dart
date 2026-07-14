import '../repositories/admin_orders_repository.dart';

class ForceOrderStatus {
  const ForceOrderStatus(this._repository);

  final AdminOrdersRepository _repository;

  Future<void> call({
    required String orderId,
    required String toStatus,
    required String reason,
  }) =>
      _repository.forceStatus(orderId: orderId, toStatus: toStatus, reason: reason);
}
