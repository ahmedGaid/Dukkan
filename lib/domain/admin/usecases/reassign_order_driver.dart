import '../repositories/admin_orders_repository.dart';

class ReassignOrderDriver {
  const ReassignOrderDriver(this._repository);

  final AdminOrdersRepository _repository;

  Future<void> call({
    required String orderId,
    String? newDriverUid,
    bool clear = false,
    required String reason,
  }) =>
      _repository.reassignDriver(
        orderId: orderId,
        newDriverUid: newDriverUid,
        clear: clear,
        reason: reason,
      );
}
