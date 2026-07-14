import '../repositories/admin_taxonomy_repository.dart';

/// Real delete (categories aren't soft-deleted) — the console warns with
/// `CountProductsInCategory` first. Thin pass-through.
class DeleteCategory {
  const DeleteCategory(this._repository);

  final AdminTaxonomyRepository _repository;

  Future<void> call(String categoryId) => _repository.deleteCategory(categoryId);
}
