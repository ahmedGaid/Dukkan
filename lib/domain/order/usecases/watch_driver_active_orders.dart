import '../entities/order.dart';
import '../repositories/order_repository.dart';

class WatchDriverActiveOrders {
  const WatchDriverActiveOrders(this._repository);

  final OrderRepository _repository;

  Stream<List<Order>> call(String driverUid) =>
      _repository.watchDriverActiveOrders(driverUid);
}
