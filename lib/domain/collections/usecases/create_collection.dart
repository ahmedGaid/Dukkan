import '../entities/shop_collection.dart';
import '../repositories/collections_repository.dart';

/// Creates a new collection under the owner's shop. Thin pass-through.
class CreateCollection {
  const CreateCollection(this._repository);

  final CollectionsRepository _repository;

  Future<ShopCollection> call(
    String shopId, {
    required String nameAr,
    required String nameEn,
    required int sort,
  }) {
    return _repository.createCollection(
      shopId,
      nameAr: nameAr,
      nameEn: nameEn,
      sort: sort,
    );
  }
}
