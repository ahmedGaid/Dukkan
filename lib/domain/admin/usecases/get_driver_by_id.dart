import '../../driver/entities/driver.dart';
import '../repositories/admin_drivers_repository.dart';

/// Single driver by id, unfiltered — used to reload the detail page's truth
/// after a mutation. Thin pass-through — matches `GetShopById`.
class GetDriverById {
  const GetDriverById(this._repository);

  final AdminDriversRepository _repository;

  Future<Driver?> call(String uid) => _repository.getDriverById(uid);
}
