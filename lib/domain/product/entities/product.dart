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

  /// Links to a `/categories/{categoryId}` subcategory (M3). Nullable — the
  /// 53 products seeded before this session don't have one yet; `category`
  /// stays the source of truth for filtering until every product is edited.
  final String? subcategoryId;

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
      ];
}
