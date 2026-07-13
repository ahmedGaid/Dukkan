import '../repositories/admin_shops_repository.dart';

/// Console status transition: `pending` → `active` (approve), `pending` →
/// `suspended` (reject, [reason] required by the UI), or `active` ↔
/// `suspended` (suspend/unsuspend). Thin pass-through.
class SetShopStatus {
  const SetShopStatus(this._repository);

  final AdminShopsRepository _repository;

  Future<void> call({required String shopId, required String status, String? reason}) =>
      _repository.setStatus(shopId: shopId, status: status, reason: reason);
}
