import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/product/entities/product.dart';
import '../../../domain/product/entities/stock_status.dart';

class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.shopId,
    required super.name,
    required super.nameAr,
    required super.priceMinor,
    required super.category,
    required super.stockStatus,
    required super.isPromo,
    super.imageUrl,
    super.subcategoryId,
    super.collectionIds,
    super.isFeatured,
    super.deleted,
    super.deletedAt,
    super.deletedBy,
  });

  /// Every FC8 field is missing on any doc created before this session,
  /// defaulting to the pre-FC8 behavior (not featured, not deleted) — same
  /// convention as `ShopModel.fromFirestore`.
  factory ProductModel.fromFirestore(String id, Map<String, dynamic> data) {
    return ProductModel(
      id: id,
      shopId: data['shopId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      nameAr: data['nameAr'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      priceMinor: (data['priceMinor'] as num?)?.toInt() ?? 0,
      category: data['category'] as String? ?? '',
      stockStatus: StockStatus.fromWire(data['stockStatus'] as String? ?? ''),
      isPromo: data['isPromo'] as bool? ?? false,
      subcategoryId: data['subcategoryId'] as String?,
      collectionIds:
          List<String>.from(data['collectionIds'] as List? ?? const []),
      isFeatured: data['isFeatured'] as bool? ?? false,
      deleted: data['deleted'] as bool? ?? false,
      deletedAt: (data['deletedAt'] as Timestamp?)?.toDate(),
      deletedBy: data['deletedBy'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'shopId': shopId,
        'name': name,
        'nameAr': nameAr,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'priceMinor': priceMinor,
        'category': category,
        'stockStatus': stockStatus.wire,
        'isPromo': isPromo,
        if (subcategoryId != null) 'subcategoryId': subcategoryId,
        'collectionIds': collectionIds,
        'isFeatured': isFeatured,
        'deleted': deleted,
        if (deletedAt != null) 'deletedAt': Timestamp.fromDate(deletedAt!),
        if (deletedBy != null) 'deletedBy': deletedBy,
      };

  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
        id: json['id'] as String,
        shopId: json['shopId'] as String,
        name: json['name'] as String,
        nameAr: json['nameAr'] as String,
        imageUrl: json['imageUrl'] as String?,
        priceMinor: json['priceMinor'] as int,
        category: json['category'] as String,
        stockStatus: StockStatus.fromWire(json['stockStatus'] as String),
        isPromo: json['isPromo'] as bool,
        subcategoryId: json['subcategoryId'] as String?,
        collectionIds:
            List<String>.from(json['collectionIds'] as List? ?? const []),
        isFeatured: json['isFeatured'] as bool? ?? false,
        deleted: json['deleted'] as bool? ?? false,
        deletedAt: json['deletedAt'] == null
            ? null
            : DateTime.parse(json['deletedAt'] as String),
        deletedBy: json['deletedBy'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'shopId': shopId,
        'name': name,
        'nameAr': nameAr,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'priceMinor': priceMinor,
        'category': category,
        'stockStatus': stockStatus.wire,
        'isPromo': isPromo,
        if (subcategoryId != null) 'subcategoryId': subcategoryId,
        'collectionIds': collectionIds,
        'isFeatured': isFeatured,
        'deleted': deleted,
        if (deletedAt != null) 'deletedAt': deletedAt!.toIso8601String(),
        if (deletedBy != null) 'deletedBy': deletedBy,
      };
}
