import '../repositories/admin_drivers_repository.dart';

/// Console edit of everything except status/verification/activeOrdersCount:
/// areas, capacity, vehicle, contact. Thin pass-through.
class UpdateDriver {
  const UpdateDriver(this._repository);

  final AdminDriversRepository _repository;

  Future<void> call({
    required String uid,
    required String name,
    String? phone,
    required List<String> areaIds,
    required int maxActiveOrders,
    String? vehicleType,
    String? vehiclePlate,
    String? idDocUrl,
  }) =>
      _repository.updateDetails(
        uid: uid,
        name: name,
        phone: phone,
        areaIds: areaIds,
        maxActiveOrders: maxActiveOrders,
        vehicleType: vehicleType,
        vehiclePlate: vehiclePlate,
        idDocUrl: idDocUrl,
      );
}
