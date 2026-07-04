import '../entities/shop.dart';
import '../repositories/shop_repository.dart';

class WatchShop {
  const WatchShop(this._repository);

  final ShopRepository _repository;

  Stream<Shop> call(String shopId) => _repository.watchShop(shopId);
}
