import '../repositories/admin_geo_repository.dart';

/// The edit sheet's save. Thin pass-through.
class UpdateArea {
  const UpdateArea(this._repository);

  final AdminGeoRepository _repository;

  Future<void> call({
    required String areaId,
    required String nameAr,
    required String nameEn,
    required String governorate,
    required String city,
    int? deliveryFeeMinorOverride,
  }) =>
      _repository.updateArea(
        areaId: areaId,
        nameAr: nameAr,
        nameEn: nameEn,
        governorate: governorate,
        city: city,
        deliveryFeeMinorOverride: deliveryFeeMinorOverride,
      );
}
