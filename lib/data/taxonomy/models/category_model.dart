import '../../../domain/taxonomy/entities/category.dart';
import '../../../domain/taxonomy/entities/subcategory.dart';

class CategoryModel extends Category {
  const CategoryModel({
    required super.id,
    required super.nameAr,
    required super.nameEn,
    required super.sort,
    required super.subcategories,
  });

  factory CategoryModel.fromFirestore(String id, Map<String, dynamic> data) {
    final rawSubcategories = (data['subcategories'] as List? ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map));
    return CategoryModel(
      id: id,
      nameAr: data['nameAr'] as String? ?? '',
      nameEn: data['nameEn'] as String? ?? '',
      sort: (data['sort'] as num?)?.toInt() ?? 0,
      subcategories: rawSubcategories.map(_subcategoryFromMap).toList(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'nameAr': nameAr,
        'nameEn': nameEn,
        'sort': sort,
        'subcategories': subcategories.map(_subcategoryToMap).toList(),
      };

  static Subcategory _subcategoryFromMap(Map<String, dynamic> map) =>
      Subcategory(
        id: map['id'] as String? ?? '',
        nameAr: map['nameAr'] as String? ?? '',
        nameEn: map['nameEn'] as String? ?? '',
      );

  static Map<String, dynamic> _subcategoryToMap(Subcategory subcategory) => {
        'id': subcategory.id,
        'nameAr': subcategory.nameAr,
        'nameEn': subcategory.nameEn,
      };

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final rawSubcategories = (json['subcategories'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map));
    return CategoryModel(
      id: json['id'] as String,
      nameAr: json['nameAr'] as String,
      nameEn: json['nameEn'] as String,
      sort: json['sort'] as int,
      subcategories: rawSubcategories.map(_subcategoryFromMap).toList(),
    );
  }

  Map<String, dynamic> toJson() => {'id': id, ...toFirestore()};
}
