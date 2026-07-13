import '../repositories/admin_products_repository.dart';

/// Irreversible — the console UI restricts this to an already soft-deleted
/// product and the founder wildcard permission (see `AdminProductsRepository.hardDelete`).
class HardDeleteProduct {
  const HardDeleteProduct(this._repository);

  final AdminProductsRepository _repository;

  Future<void> call(String productId) => _repository.hardDelete(productId);
}
