import '../../taxonomy/entities/category.dart';
import '../repositories/admin_taxonomy_repository.dart';

/// Loads every category for the console board, unfiltered (hidden included).
/// Thin pass-through — matches `GetAllShops`.
class GetAllCategories {
  const GetAllCategories(this._repository);

  final AdminTaxonomyRepository _repository;

  Future<List<Category>> call() => _repository.getAllCategories();
}
