import '../../areas/entities/area.dart';
import '../repositories/admin_geo_repository.dart';

/// Loads every area for the console board, unfiltered (deactivated
/// included). Thin pass-through — matches `GetAllCategories`.
class GetAllAreas {
  const GetAllAreas(this._repository);

  final AdminGeoRepository _repository;

  Future<List<Area>> call() => _repository.getAllAreas();
}
