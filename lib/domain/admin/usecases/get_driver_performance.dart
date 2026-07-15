import '../entities/driver_performance.dart';
import '../repositories/admin_drivers_repository.dart';

/// Delivered-order counts for the console detail page's performance card.
/// Thin pass-through.
class GetDriverPerformance {
  const GetDriverPerformance(this._repository);

  final AdminDriversRepository _repository;

  Future<DriverPerformance> call(String uid) => _repository.getPerformance(uid);
}
