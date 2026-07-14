import '../repositories/admin_orders_repository.dart';

/// Named distinctly from the customer's own `CancelOrder` (order vertical) —
/// `OrderDetailBloc` holds both, one per role.
class CancelOrderAsStaff {
  const CancelOrderAsStaff(this._repository);

  final AdminOrdersRepository _repository;

  Future<void> call({
    required String orderId,
    required String reason,
    int? refundNoteMinor,
  }) =>
      _repository.cancelOrder(orderId: orderId, reason: reason, refundNoteMinor: refundNoteMinor);
}
