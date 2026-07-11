import '../entities/driver.dart';
import '../repositories/driver_repository.dart';

/// Owner's assignment-list source (Session 9).
class AvailableDrivers {
  const AvailableDrivers(this._repository);

  final DriverRepository _repository;

  Future<List<Driver>> call(String areaId) =>
      _repository.availableDrivers(areaId);
}
