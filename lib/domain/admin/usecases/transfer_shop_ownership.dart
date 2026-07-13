import '../repositories/admin_shops_repository.dart';

/// Worker-routed ownership change. Thin pass-through.
class TransferShopOwnership {
  const TransferShopOwnership(this._repository);

  final AdminShopsRepository _repository;

  Future<Map<String, dynamic>> call({required String shopId, required String newOwnerUid}) =>
      _repository.transferOwnership(shopId: shopId, newOwnerUid: newOwnerUid);
}
