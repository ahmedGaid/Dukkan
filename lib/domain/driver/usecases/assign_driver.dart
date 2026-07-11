import '../repositories/driver_repository.dart';

/// Owner assigns a driver to an order (Session 9's assignment sheet).
class AssignDriver {
  const AssignDriver(this._repository);

  final DriverRepository _repository;

  Future<void> call({required String orderId, required String driverUid}) =>
      _repository.assignDriver(orderId: orderId, driverUid: driverUid);
}
