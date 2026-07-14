import '../repositories/admin_taxonomy_repository.dart';

/// The board's eye-toggle. Thin pass-through.
class SetCategoryVisible {
  const SetCategoryVisible(this._repository);

  final AdminTaxonomyRepository _repository;

  Future<void> call({required String categoryId, required bool value}) =>
      _repository.setCategoryVisible(categoryId: categoryId, value: value);
}
