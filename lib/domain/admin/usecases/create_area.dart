import '../repositories/admin_geo_repository.dart';

/// Console-created area (auto id, appended after the current max sort).
/// Thin pass-through.
class CreateArea {
  const CreateArea(this._repository);

  final AdminGeoRepository _repository;

  Future<void> call({
    required String nameAr,
    required String nameEn,
    required String governorate,
    required String city,
    int? deliveryFeeMinorOverride,
  }) =>
      _repository.createArea(
        nameAr: nameAr,
        nameEn: nameEn,
        governorate: governorate,
        city: city,
        deliveryFeeMinorOverride: deliveryFeeMinorOverride,
      );
}
