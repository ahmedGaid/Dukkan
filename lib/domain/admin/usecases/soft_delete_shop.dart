import '../repositories/admin_shops_repository.dart';

/// Reversible soft delete — flags the doc, never a real Firestore delete.
/// Thin pass-through.
class SoftDeleteShop {
  const SoftDeleteShop(this._repository);

  final AdminShopsRepository _repository;

  Future<void> call({required String shopId, required String actorUid}) =>
      _repository.softDelete(shopId: shopId, actorUid: actorUid);
}
