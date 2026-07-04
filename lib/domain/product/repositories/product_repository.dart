import '../entities/product.dart';

/// Product catalog boundary, scoped per shop. Same online/offline contract as
/// `ShopRepository`.
abstract class ProductRepository {
  Stream<List<Product>> watchProductsByShop(String shopId);

  /// Every product across all shops — backs global search (C2c). Realtime when
  /// online (cached after each snapshot), a single cached snapshot when offline.
  Stream<List<Product>> watchAllProducts();

  /// Single product (product detail, C2) — throws [CacheFailure] if offline
  /// and not present in any cached shop's product list.
  Future<Product> getProduct(String productId);
}
