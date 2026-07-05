import '../entities/product.dart';
import '../repositories/product_repository.dart';

/// Overwrites an existing product's fields (S2 edit). Thin pass-through.
class UpdateProduct {
  const UpdateProduct(this._repository);

  final ProductRepository _repository;

  Future<void> call(Product product) => _repository.updateProduct(product);
}
