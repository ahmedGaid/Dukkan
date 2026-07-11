import '../entities/shop_collection.dart';
import '../repositories/collections_repository.dart';

/// One-shot read of a shop's collections — the product form's picker (M7).
/// Thin pass-through.
class GetCollections {
  const GetCollections(this._repository);

  final CollectionsRepository _repository;

  Future<List<ShopCollection>> call(String shopId) =>
      _repository.getCollections(shopId);
}
