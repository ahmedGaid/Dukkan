import '../repositories/admin_geo_repository.dart';

/// The board's active toggle. Thin pass-through.
class SetAreaActive {
  const SetAreaActive(this._repository);

  final AdminGeoRepository _repository;

  Future<void> call({required String areaId, required bool value}) =>
      _repository.setAreaActive(areaId: areaId, value: value);
}
