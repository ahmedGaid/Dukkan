import '../entities/shop_collection.dart';

/// Owner-scoped collections boundary. Reads go straight through (no local
/// cache — owner-only management screen plus a customer filter row, low
/// value offline, matches `FavoritesRepository`'s reasoning). Writes require
/// connectivity, same contract as `createProduct`.
abstract class CollectionsRepository {
  /// Realtime feed, sort order — backs the owner manager and the customer
  /// shop-page filter row.
  Stream<List<ShopCollection>> watchCollections(String shopId);

  /// One-shot read, sort order — backs the product form's picker (matches
  /// `GetTaxonomy`'s one-shot-per-form-open style).
  Future<List<ShopCollection>> getCollections(String shopId);

  Future<ShopCollection> createCollection(
    String shopId, {
    required String nameAr,
    required String nameEn,
    required int sort,
  });

  Future<void> renameCollection(
    String shopId,
    String collectionId, {
    required String nameAr,
    required String nameEn,
  });

  Future<void> deleteCollection(String shopId, String collectionId);
}
