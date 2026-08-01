import '../entities/category.dart';
import '../repositories/taxonomy_repository.dart';

class WatchTaxonomy {
  const WatchTaxonomy(this._repository);

  final TaxonomyRepository _repository;

  Stream<List<Category>> call() => _repository.watchTaxonomy();
}
