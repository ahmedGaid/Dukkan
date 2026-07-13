import '../../shop/entities/shop.dart';
import '../repositories/admin_shops_repository.dart';

/// Reloads one shop by id after a console mutation. Thin pass-through.
class GetShopById {
  const GetShopById(this._repository);

  final AdminShopsRepository _repository;

  Future<Shop?> call(String shopId) => _repository.getShopById(shopId);
}
