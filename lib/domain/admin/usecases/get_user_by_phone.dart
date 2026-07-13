import '../entities/managed_user.dart';
import '../repositories/admin_users_repository.dart';

/// Exact-phone search field on the user list. Thin pass-through.
class GetUserByPhone {
  const GetUserByPhone(this._repository);

  final AdminUsersRepository _repository;

  Future<ManagedUser?> call(String phone) => _repository.getByPhone(phone);
}
