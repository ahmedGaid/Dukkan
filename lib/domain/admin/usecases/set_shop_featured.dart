import '../repositories/admin_shops_repository.dart';

/// Toggles the console "featured" curation flag. Thin pass-through.
class SetShopFeatured {
  const SetShopFeatured(this._repository);

  final AdminShopsRepository _repository;

  Future<void> call({required String shopId, required bool value}) =>
      _repository.setFeatured(shopId: shopId, value: value);
}
