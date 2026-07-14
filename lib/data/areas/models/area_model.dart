import '../../../domain/areas/entities/area.dart';

class AreaModel extends Area {
  const AreaModel({
    required super.id,
    required super.nameAr,
    required super.nameEn,
    required super.sort,
    super.governorate,
    super.city,
    super.isActive,
    super.deliveryFeeMinorOverride,
  });

  factory AreaModel.fromFirestore(String id, Map<String, dynamic> data) {
    return AreaModel(
      id: id,
      nameAr: data['nameAr'] as String? ?? '',
      nameEn: data['nameEn'] as String? ?? '',
      sort: (data['sort'] as num?)?.toInt() ?? 0,
      governorate: data['governorate'] as String? ?? 'الإسماعيلية',
      city: data['city'] as String? ?? 'الإسماعيلية',
      isActive: data['isActive'] as bool? ?? true,
      deliveryFeeMinorOverride: (data['deliveryFeeMinorOverride'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'nameAr': nameAr,
        'nameEn': nameEn,
        'sort': sort,
        'governorate': governorate,
        'city': city,
        'isActive': isActive,
        'deliveryFeeMinorOverride': deliveryFeeMinorOverride,
      };

  factory AreaModel.fromJson(Map<String, dynamic> json) => AreaModel(
        id: json['id'] as String,
        nameAr: json['nameAr'] as String,
        nameEn: json['nameEn'] as String,
        sort: json['sort'] as int,
        governorate: json['governorate'] as String? ?? 'الإسماعيلية',
        city: json['city'] as String? ?? 'الإسماعيلية',
        isActive: json['isActive'] as bool? ?? true,
        deliveryFeeMinorOverride: (json['deliveryFeeMinorOverride'] as num?)?.toInt(),
      );

  Map<String, dynamic> toJson() => {'id': id, ...toFirestore()};
}
