import '../entities/managed_user.dart';
import '../repositories/admin_users_repository.dart';

/// Exact-email search field on the user list. Thin pass-through.
class GetUserByEmail {
  const GetUserByEmail(this._repository);

  final AdminUsersRepository _repository;

  Future<ManagedUser?> call(String email) => _repository.getByEmail(email);
}
