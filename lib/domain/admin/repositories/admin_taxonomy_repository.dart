import '../../taxonomy/entities/category.dart';

/// Founder Console taxonomy management (FC9). Reads are Firestore-direct and
/// unfiltered (including hidden categories) — the customer/owner-facing
/// filter lives only in `TaxonomyRepositoryImpl`. Every write is
/// Firestore-direct, gated by the `taxonomy.edit` rules branch.
abstract class AdminTaxonomyRepository {
  /// Every category, sorted by `sort`, including hidden ones.
  Future<List<Category>> getAllCategories();

  /// Auto-id'd (a console-created category has no legacy `Shop.categories`/
  /// `Product.category` string to match, unlike the original seeded set).
  /// `sort` lands after the current highest.
  Future<void> createCategory({
    required String nameAr,
    required String nameEn,
    String? iconName,
  });

  /// Never touches `id` or `subcategories` — this is the name/icon edit sheet.
  Future<void> updateCategory({
    required String categoryId,
    required String nameAr,
    required String nameEn,
    String? iconName,
  });

  Future<void> setCategoryVisible({
    required String categoryId,
    required bool value,
  });

  /// Swaps the `sort` value of two adjacent categories (an up/down reorder
  /// tap) in one batch, so the list never observes a duplicate/missing sort.
  Future<void> swapSort({
    required String aId,
    required int aSort,
    required String bId,
    required int bSort,
  });

  /// Real delete — categories aren't soft-deleted. Safe even with products
  /// still referencing the id: `Product.category` is a plain string, not a
  /// foreign key, so those products keep rendering (the console warns with
  /// [countProductsInCategory] first).
  Future<void> deleteCategory(String categoryId);

  /// `products` where `category == categoryId` — the console's pre-delete
  /// warning count. An aggregate `.count()`, no document downloads.
  Future<int> countProductsInCategory(String categoryId);
}
