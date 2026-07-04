import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

/// Signs in with email + password. Throws `AuthFailure` on failure.
class LogIn {
  const LogIn(this._repository);

  final AuthRepository _repository;

  Future<AppUser> call({required String email, required String password}) {
    return _repository.logIn(email: email, password: password);
  }
}
