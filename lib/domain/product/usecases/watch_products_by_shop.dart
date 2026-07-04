import '../entities/product.dart';
import '../repositories/product_repository.dart';

class WatchProductsByShop {
  const WatchProductsByShop(this._repository);

  final ProductRepository _repository;

  Stream<List<Product>> call(String shopId) =>
      _repository.watchProductsByShop(shopId);
}
