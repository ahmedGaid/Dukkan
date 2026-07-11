import '../entities/order.dart';
import '../repositories/order_repository.dart';

class WatchDriverOrderHistory {
  const WatchDriverOrderHistory(this._repository);

  final OrderRepository _repository;

  Stream<List<Order>> call(String driverUid) =>
      _repository.watchDriverHistory(driverUid);
}
