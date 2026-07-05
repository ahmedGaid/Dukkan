import '../entities/shop.dart';
import '../repositories/shop_repository.dart';

class GetShopByOwner {
  const GetShopByOwner(this._repository);

  final ShopRepository _repository;

  Future<Shop?> call(String ownerUid) => _repository.getShopByOwner(ownerUid);
}
