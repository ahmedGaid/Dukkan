import '../../../domain/collections/entities/shop_collection.dart';

class ShopCollectionModel extends ShopCollection {
  const ShopCollectionModel({
    required super.id,
    required super.nameAr,
    required super.nameEn,
    required super.sort,
  });

  factory ShopCollectionModel.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return ShopCollectionModel(
      id: id,
      nameAr: data['nameAr'] as String? ?? '',
      nameEn: data['nameEn'] as String? ?? '',
      sort: (data['sort'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'nameAr': nameAr,
        'nameEn': nameEn,
        'sort': sort,
        'createdAt': DateTime.now().toIso8601String(),
      };
}
