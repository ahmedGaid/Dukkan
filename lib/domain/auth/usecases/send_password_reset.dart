import '../repositories/auth_repository.dart';

/// Sends a password-reset email. Throws `AuthFailure` on failure.
class SendPasswordReset {
  const SendPasswordReset(this._repository);

  final AuthRepository _repository;

  Future<void> call(String email) => _repository.sendPasswordReset(email);
}
