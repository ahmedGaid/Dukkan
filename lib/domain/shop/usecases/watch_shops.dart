import '../entities/shop.dart';
import '../repositories/shop_repository.dart';

class WatchShops {
  const WatchShops(this._repository);

  final ShopRepository _repository;

  Stream<List<Shop>> call() => _repository.watchShops();
}
