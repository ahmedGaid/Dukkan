import '../entities/product.dart';
import '../repositories/product_repository.dart';

class WatchAllProducts {
  const WatchAllProducts(this._repository);

  final ProductRepository _repository;

  Stream<List<Product>> call() => _repository.watchAllProducts();
}
