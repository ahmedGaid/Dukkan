import '../../shop/entities/shop.dart';
import '../repositories/admin_shops_repository.dart';

/// Console "create shop for owner" form (perm `shops.update`). Named
/// distinctly from `domain/shop/usecases/create_shop.dart`'s `CreateShop` —
/// that one is the self-serve onboarding path (always lands `pending`) and
/// requires the caller to be the new shop's own owner; this one doesn't.
class CreateShopAsStaff {
  const CreateShopAsStaff(this._repository);

  final AdminShopsRepository _repository;

  Future<Shop> call({
    required String ownerUid,
    required String name,
    required String nameAr,
    required String address,
    String? logoUrl,
    bool isOpen = true,
    List<String> categories = const [],
    String status = 'active',
  }) =>
      _repository.createShop(
        ownerUid: ownerUid,
        name: name,
        nameAr: nameAr,
        address: address,
        logoUrl: logoUrl,
        isOpen: isOpen,
        categories: categories,
        status: status,
      );
}
