import '../entities/admin_profile.dart';
import '../repositories/admin_repository.dart';

/// Loads an arbitrary uid's staff profile (console user detail "staff card").
/// Thin pass-through — matches `GetAdminProfile`, but never memoized.
class GetStaffProfileForUid {
  const GetStaffProfileForUid(this._repository);

  final AdminRepository _repository;

  Future<AdminProfile?> call(String uid) => _repository.getAdminProfileForUid(uid);
}
