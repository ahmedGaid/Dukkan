import '../repositories/admin_taxonomy_repository.dart';

/// The pre-delete warning count. Thin pass-through.
class CountProductsInCategory {
  const CountProductsInCategory(this._repository);

  final AdminTaxonomyRepository _repository;

  Future<int> call(String categoryId) =>
      _repository.countProductsInCategory(categoryId);
}
