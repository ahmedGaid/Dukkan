import '../repositories/admin_geo_repository.dart';

/// The pre-delete/deactivate-instead count. Thin pass-through.
class CountOrdersInArea {
  const CountOrdersInArea(this._repository);

  final AdminGeoRepository _repository;

  Future<int> call(String areaId) => _repository.countOrdersInArea(areaId);
}
