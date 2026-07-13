import '../repositories/admin_products_repository.dart';

class SoftDeleteProduct {
  const SoftDeleteProduct(this._repository);

  final AdminProductsRepository _repository;

  Future<void> call({required String productId, required String actorUid}) =>
      _repository.softDelete(productId: productId, actorUid: actorUid);
}
