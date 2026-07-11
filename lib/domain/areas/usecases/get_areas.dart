import '../entities/area.dart';
import '../repositories/areas_repository.dart';

/// Loads the fixed area list (checkout's area picker, driver assignment).
/// Thin pass-through — matches `GetTaxonomy`.
class GetAreas {
  const GetAreas(this._repository);

  final AreasRepository _repository;

  Future<List<Area>> call() => _repository.getAreas();
}
