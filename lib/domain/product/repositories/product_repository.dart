import '../entities/product.dart';
import '../entities/stock_status.dart';

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

  /// Creates a product under the owner's shop (S2 catalog manager). Requires
  /// connectivity — no offline queue for this write (matches `createShop`).
  Future<Product> createProduct({
    required String shopId,
    required String name,
    required String nameAr,
    required int priceMinor,
    required String category,
    required StockStatus stockStatus,
    required bool isPromo,
    String? imageUrl,
    String? subcategoryId,
    List<String> collectionIds = const [],
  });

  /// Overwrites an existing product's fields (S2 edit). Requires connectivity.
  Future<void> updateProduct(Product product);

  /// Removes a product from the catalog (S2 delete). Requires connectivity.
  Future<void> deleteProduct(String productId);
}
