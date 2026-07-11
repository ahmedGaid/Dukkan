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
  });

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
      );

  Map<String, dynamic> toJson() => {'id': id, ...toFirestore()};
}
