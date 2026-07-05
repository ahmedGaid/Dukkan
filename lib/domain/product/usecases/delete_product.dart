import '../repositories/product_repository.dart';

/// Removes a product from the catalog (S2 delete). Thin pass-through.
class DeleteProduct {
  const DeleteProduct(this._repository);

  final ProductRepository _repository;

  Future<void> call(String productId) => _repository.deleteProduct(productId);
}
