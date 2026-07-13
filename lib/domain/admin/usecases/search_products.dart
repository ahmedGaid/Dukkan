import '../../product/entities/product.dart';
import '../repositories/admin_products_repository.dart';

/// Loads every product matching the current filters (unpaginated) so the
/// board can fold-search by name over the result — see `GetAllMatching` doc.
class SearchProducts {
  const SearchProducts(this._repository);

  final AdminProductsRepository _repository;

  Future<List<Product>> call({
    String? shopId,
    String? category,
    String? subcategoryId,
    String? stockStatus,
    bool? isPromo,
    bool deletedOnly = false,
  }) =>
      _repository.getAllMatching(
        shopId: shopId,
        category: category,
        subcategoryId: subcategoryId,
        stockStatus: stockStatus,
        isPromo: isPromo,
        deletedOnly: deletedOnly,
      );
}
