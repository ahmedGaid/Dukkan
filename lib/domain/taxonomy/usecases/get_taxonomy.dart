import '../entities/category.dart';
import '../repositories/taxonomy_repository.dart';

/// Loads the fixed category/subcategory tree (product form dropdowns, home
/// chips). Thin pass-through — matches `WatchShops`'s single-method usecase.
class GetTaxonomy {
  const GetTaxonomy(this._repository);

  final TaxonomyRepository _repository;

  Future<List<Category>> call() => _repository.getTaxonomy();
}
