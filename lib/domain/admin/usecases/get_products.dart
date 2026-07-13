import '../entities/products_page.dart';
import '../repositories/admin_products_repository.dart';

/// Loads one page of the console product board. Thin pass-through — matches `GetUsers`.
class GetProducts {
  const GetProducts(this._repository);

  final AdminProductsRepository _repository;

  Future<ProductsPage> call({
    String? shopId,
    String? category,
    String? subcategoryId,
    String? stockStatus,
    bool? isPromo,
    bool deletedOnly = false,
    String? cursor,
  }) =>
      _repository.getProducts(
        shopId: shopId,
        category: category,
        subcategoryId: subcategoryId,
        stockStatus: stockStatus,
        isPromo: isPromo,
        deletedOnly: deletedOnly,
        cursor: cursor,
      );
}
