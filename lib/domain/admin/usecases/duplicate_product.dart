import '../repositories/admin_products_repository.dart';

class DuplicateProduct {
  const DuplicateProduct(this._repository);

  final AdminProductsRepository _repository;

  Future<String> call(String productId) => _repository.duplicate(productId);
}
