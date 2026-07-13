import '../repositories/admin_products_repository.dart';

class RestoreProduct {
  const RestoreProduct(this._repository);

  final AdminProductsRepository _repository;

  Future<void> call(String productId) => _repository.restore(productId);
}
