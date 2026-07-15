import '../../driver/entities/driver.dart';
import '../repositories/admin_drivers_repository.dart';

/// Loads every driver for the console board, unfiltered. Thin pass-through —
/// matches `GetAllShops`.
class GetAllDrivers {
  const GetAllDrivers(this._repository);

  final AdminDriversRepository _repository;

  Future<List<Driver>> call() => _repository.getAllDrivers();
}
