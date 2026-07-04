import '../entities/app_user.dart';
import '../entities/user_role.dart';
import '../repositories/auth_repository.dart';

/// Creates the Auth account, writes the `/users/{uid}` profile with the chosen
/// role, and returns the signed-in user. Throws `AuthFailure` on failure.
class SignUp {
  const SignUp(this._repository);

  final AuthRepository _repository;

  Future<AppUser> call({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? phone,
  }) {
    return _repository.signUp(
      name: name,
      email: email,
      password: password,
      role: role,
      phone: phone,
    );
  }
}
