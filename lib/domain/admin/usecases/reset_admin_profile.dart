import '../repositories/admin_repository.dart';

/// Clears the cached staff profile on sign-out (keeps the BLoC off the
/// repository directly, per the project's layering rule).
class ResetAdminProfile {
  const ResetAdminProfile(this._repository);

  final AdminRepository _repository;

  void call() => _repository.reset();
}
