import '../entities/shop.dart';
import '../repositories/shop_repository.dart';

/// Creates the owner's shop (S1b onboarding). Thin pass-through — the
/// onboarding page calls this directly (no bloc, matches checkout's usecase
/// call pattern).
class CreateShop {
  const CreateShop(this._repository);

  final ShopRepository _repository;

  Future<Shop> call({
    required String ownerUid,
    required String name,
    required String nameAr,
    required String address,
    String? logoUrl,
    bool isOpen = true,
  }) {
    return _repository.createShop(
      ownerUid: ownerUid,
      name: name,
      nameAr: nameAr,
      address: address,
      logoUrl: logoUrl,
      isOpen: isOpen,
    );
  }
}
