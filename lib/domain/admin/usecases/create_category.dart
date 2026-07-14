import '../repositories/admin_taxonomy_repository.dart';

/// Console-created category (auto id, appended after the current max sort).
/// Thin pass-through.
class CreateCategory {
  const CreateCategory(this._repository);

  final AdminTaxonomyRepository _repository;

  Future<void> call({
    required String nameAr,
    required String nameEn,
    String? iconName,
  }) =>
      _repository.createCategory(nameAr: nameAr, nameEn: nameEn, iconName: iconName);
}
