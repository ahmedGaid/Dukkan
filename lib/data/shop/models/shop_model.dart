import '../../../domain/shop/entities/shop.dart';

class ShopModel extends Shop {
  const ShopModel({
    required super.id,
    required super.ownerUid,
    required super.name,
    required super.nameAr,
    required super.address,
    required super.isOpen,
    required super.categories,
    super.logoUrl,
  });

  factory ShopModel.fromFirestore(String id, Map<String, dynamic> data) {
    return ShopModel(
      id: id,
      ownerUid: data['ownerUid'] as String? ?? '',
      name: data['name'] as String? ?? '',
      nameAr: data['nameAr'] as String? ?? '',
      logoUrl: data['logoUrl'] as String?,
      address: data['address'] as String? ?? '',
      isOpen: data['isOpen'] as bool? ?? false,
      categories: List<String>.from(data['categories'] as List? ?? const []),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'ownerUid': ownerUid,
        'name': name,
        'nameAr': nameAr,
        if (logoUrl != null) 'logoUrl': logoUrl,
        'address': address,
        'isOpen': isOpen,
        'categories': categories,
      };

  factory ShopModel.fromJson(Map<String, dynamic> json) => ShopModel(
        id: json['id'] as String,
        ownerUid: json['ownerUid'] as String,
        name: json['name'] as String,
        nameAr: json['nameAr'] as String,
        logoUrl: json['logoUrl'] as String?,
        address: json['address'] as String,
        isOpen: json['isOpen'] as bool,
        categories: List<String>.from(json['categories'] as List),
      );

  Map<String, dynamic> toJson() => {'id': id, ...toFirestore()};
}
