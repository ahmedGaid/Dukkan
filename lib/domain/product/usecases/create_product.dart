import '../entities/product.dart';
import '../entities/stock_status.dart';
import '../repositories/product_repository.dart';

/// Creates a product under the owner's shop (S2). Thin pass-through — the
/// product form calls this directly (no bloc, matches `CreateShop`'s
/// onboarding pattern).
class CreateProduct {
  const CreateProduct(this._repository);

  final ProductRepository _repository;

  Future<Product> call({
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
  }) {
    return _repository.createProduct(
      shopId: shopId,
      name: name,
      nameAr: nameAr,
      priceMinor: priceMinor,
      category: category,
      stockStatus: stockStatus,
      isPromo: isPromo,
      imageUrl: imageUrl,
      subcategoryId: subcategoryId,
      collectionIds: collectionIds,
    );
  }
}
