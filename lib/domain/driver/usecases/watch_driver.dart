import '../entities/driver.dart';
import '../repositories/driver_repository.dart';

class WatchDriver {
  const WatchDriver(this._repository);

  final DriverRepository _repository;

  Stream<Driver?> call(String uid) => _repository.watchDriver(uid);
}
