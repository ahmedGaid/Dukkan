import '../../../domain/areas/entities/area.dart';

class AreaModel extends Area {
  const AreaModel({
    required super.id,
    required super.nameAr,
    required super.nameEn,
    required super.sort,
  });

  factory AreaModel.fromFirestore(String id, Map<String, dynamic> data) {
    return AreaModel(
      id: id,
      nameAr: data['nameAr'] as String? ?? '',
      nameEn: data['nameEn'] as String? ?? '',
      sort: (data['sort'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() =>
      {'nameAr': nameAr, 'nameEn': nameEn, 'sort': sort};

  factory AreaModel.fromJson(Map<String, dynamic> json) => AreaModel(
        id: json['id'] as String,
        nameAr: json['nameAr'] as String,
        nameEn: json['nameEn'] as String,
        sort: json['sort'] as int,
      );

  Map<String, dynamic> toJson() => {'id': id, ...toFirestore()};
}
