part of 'products_bloc.dart';

enum ProductsStatus { loading, loaded, error }

class ProductsState extends Equatable {
  const ProductsState({
    this.status = ProductsStatus.loading,
    this.shop,
    this.products = const [],
    this.categories = const [],
    this.selectedCategory,
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

  /// Products shown in the grid: all, or only those in the selected category.
  List<Product> get visibleProducts {
    final selected = selectedCategory;
    if (selected == null) return products;
    return products.where((p) => p.category == selected).toList();
  }

  ProductsState copyWith({
    ProductsStatus? status,
    Shop? shop,
    List<Product>? products,
    List<String>? categories,
    String? selectedCategory,
    bool clearCategory = false,
  }) {
    return ProductsState(
      status: status ?? this.status,
      shop: shop ?? this.shop,
      products: products ?? this.products,
      categories: categories ?? this.categories,
      selectedCategory:
          clearCategory ? null : (selectedCategory ?? this.selectedCategory),
    );
  }

  @override
  List<Object?> get props =>
      [status, shop, products, categories, selectedCategory];
}
