import '../repositories/admin_orders_repository.dart';

class AddOrderNote {
  const AddOrderNote(this._repository);

  final AdminOrdersRepository _repository;

  Future<void> call({required String orderId, required String text}) =>
      _repository.addNote(orderId: orderId, text: text);
}
