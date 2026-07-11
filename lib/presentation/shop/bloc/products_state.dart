part of 'products_bloc.dart';

enum ProductsStatus { loading, loaded, error }

class ProductsState extends Equatable {
  const ProductsState({
    this.status = ProductsStatus.loading,
    this.shop,
    this.products = const [],
    this.categories = const [],
    this.selectedCategory,
    this.collections = const [],
    this.selectedCollectionId,
  });

  final ProductsStatus status;

  /// The shop for the page header — null until the shop stream's first value.
  final Shop? shop;

  /// Every product in the catalog (unfiltered) — [visibleProducts] applies the
  /// category filter.
  final List<Product> products;

  /// The catalog's categories, drives the in-shop filter row.
  final List<String> categories;

  /// Active category filter, or null for "all".
  final String? selectedCategory;

  /// This shop's collections (M7) — drives the second, optional filter row.
  /// Empty means either no collections yet or the load failed; either way
  /// the row simply doesn't render.
  final List<ShopCollection> collections;

  /// Active collection filter, or null for "all".
  final String? selectedCollectionId;

  /// Products shown in the grid: category and collection filters both apply
  /// (AND) when set.
  List<Product> get visibleProducts {
    final category = selectedCategory;
    final collectionId = selectedCollectionId;
    return products.where((p) {
      if (category != null && p.category != category) return false;
      if (collectionId != null && !p.collectionIds.contains(collectionId)) {
        return false;
      }
      return true;
    }).toList();
  }

  ProductsState copyWith({
    ProductsStatus? status,
    Shop? shop,
    List<Product>? products,
    List<String>? categories,
    String? selectedCategory,
    bool clearCategory = false,
    List<ShopCollection>? collections,
    String? selectedCollectionId,
    bool clearCollection = false,
  }) {
    return ProductsState(
      status: status ?? this.status,
      shop: shop ?? this.shop,
      products: products ?? this.products,
      categories: categories ?? this.categories,
      selectedCategory:
          clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      collections: collections ?? this.collections,
      selectedCollectionId: clearCollection
          ? null
          : (selectedCollectionId ?? this.selectedCollectionId),
    );
  }

  @override
  List<Object?> get props => [
        status,
        shop,
        products,
        categories,
        selectedCategory,
        collections,
        selectedCollectionId,
      ];
}
