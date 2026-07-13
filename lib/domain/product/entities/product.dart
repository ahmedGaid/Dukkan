import 'package:equatable/equatable.dart';

import 'stock_status.dart';

/// A product listed under one shop. `priceMinor` is integer piasters — never
/// format/parse it outside `core/money.dart`.
class Product extends Equatable {
  const Product({
    required this.id,
    required this.shopId,
    required this.name,
    required this.nameAr,
    required this.priceMinor,
    required this.category,
    required this.stockStatus,
    required this.isPromo,
    this.imageUrl,
    this.subcategoryId,
    this.collectionIds = const [],
    this.isFeatured = false,
    this.deleted = false,
    this.deletedAt,
    this.deletedBy,
  });

  final String id;
  final String shopId;
  final String name;
  final String nameAr;
  final String? imageUrl;
  final int priceMinor;
  final String category;
  final StockStatus stockStatus;
  final bool isPromo;

  /// Founder Console curation flag (FC8) — customer-facing badge only, no
  /// behavior gate.
  final bool isFeatured;

  /// Soft delete (FC8) — reversible, never a real Firestore delete. The
  /// spec's "archive" maps to this one hide mechanism instead of two.
  final bool deleted;
  final DateTime? deletedAt;
  final String? deletedBy;

  /// Links to a `/categories/{categoryId}` subcategory (M3). Nullable — the
  /// 53 products seeded before this session don't have one yet; `category`
  /// stays the source of truth for filtering until every product is edited.
  final String? subcategoryId;

  /// Owner-assigned collection ids (M7), e.g. shows under "Offers" on the
  /// shop page. Empty is valid — collections are optional tags, not
  /// required categorization. Stale ids (a deleted collection) are simply
  /// ignored at render time.
  final List<String> collectionIds;

  @override
  List<Object?> get props => [
        id,
        shopId,
        name,
        nameAr,
        imageUrl,
        priceMinor,
        category,
        stockStatus,
        isPromo,
        subcategoryId,
        collectionIds,
        isFeatured,
        deleted,
        deletedAt,
        deletedBy,
      ];
}
