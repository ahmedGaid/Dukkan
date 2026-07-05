import '../entities/order.dart';
import '../repositories/order_repository.dart';

class WatchShopOrders {
  const WatchShopOrders(this._repository);

  final OrderRepository _repository;

  Stream<List<Order>> call(String shopId) =>
      _repository.watchShopOrders(shopId);
}
