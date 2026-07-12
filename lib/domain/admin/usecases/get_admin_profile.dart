import '../entities/admin_profile.dart';
import '../repositories/admin_repository.dart';

/// Loads a signed-in account's staff profile (null = not staff). Thin
/// pass-through — matches `GetFinanceSummary`.
class GetAdminProfile {
  const GetAdminProfile(this._repository);

  final AdminRepository _repository;

  Future<AdminProfile?> call(String uid) => _repository.getAdminProfile(uid);
}
