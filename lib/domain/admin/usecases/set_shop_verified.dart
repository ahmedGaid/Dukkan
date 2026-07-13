import '../repositories/admin_shops_repository.dart';

/// Toggles the console "verified" curation flag. Thin pass-through.
class SetShopVerified {
  const SetShopVerified(this._repository);

  final AdminShopsRepository _repository;

  Future<void> call({required String shopId, required bool value}) =>
      _repository.setVerified(shopId: shopId, value: value);
}
