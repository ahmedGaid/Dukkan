import '../repositories/admin_shops_repository.dart';

/// Saves the console detail page's editable fields (never ownerUid). Thin
/// pass-through.
class UpdateShopDetails {
  const UpdateShopDetails(this._repository);

  final AdminShopsRepository _repository;

  Future<void> call({
    required String shopId,
    required String name,
    required String nameAr,
    required String address,
    required bool isOpen,
    String? logoUrl,
    String? hoursNote,
  }) =>
      _repository.updateDetails(
        shopId: shopId,
        name: name,
        nameAr: nameAr,
        address: address,
        isOpen: isOpen,
        logoUrl: logoUrl,
        hoursNote: hoursNote,
      );
}
