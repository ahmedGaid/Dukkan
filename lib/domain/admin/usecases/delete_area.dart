import '../repositories/admin_geo_repository.dart';

/// Real delete — the console falls back to `SetAreaActive`(false) when
/// `CountOrdersInArea` is non-zero. Thin pass-through.
class DeleteArea {
  const DeleteArea(this._repository);

  final AdminGeoRepository _repository;

  Future<void> call(String areaId) => _repository.deleteArea(areaId);
}
