import '../entities/order.dart';
import '../repositories/order_repository.dart';

class WatchCustomerOrders {
  const WatchCustomerOrders(this._repository);

  final OrderRepository _repository;

  Stream<List<Order>> call(String customerUid) =>
      _repository.watchCustomerOrders(customerUid);
}
