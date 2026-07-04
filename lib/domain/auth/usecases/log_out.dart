import '../repositories/auth_repository.dart';

/// Signs the current user out.
class LogOut {
  const LogOut(this._repository);

  final AuthRepository _repository;

  Future<void> call() => _repository.logOut();
}
