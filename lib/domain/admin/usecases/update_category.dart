import '../repositories/admin_taxonomy_repository.dart';

/// The edit sheet's name/icon save. Thin pass-through.
class UpdateCategory {
  const UpdateCategory(this._repository);

  final AdminTaxonomyRepository _repository;

  Future<void> call({
    required String categoryId,
    required String nameAr,
    required String nameEn,
    String? iconName,
  }) =>
      _repository.updateCategory(
        categoryId: categoryId,
        nameAr: nameAr,
        nameEn: nameEn,
        iconName: iconName,
      );
}
