import '../../order/entities/order_note.dart';
import '../repositories/admin_orders_repository.dart';

class WatchOrderNotes {
  const WatchOrderNotes(this._repository);

  final AdminOrdersRepository _repository;

  Stream<List<OrderNote>> call(String orderId) => _repository.watchNotes(orderId);
}
