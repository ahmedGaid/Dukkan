import '../entities/users_page.dart';
import '../repositories/admin_users_repository.dart';

/// Loads one page of the console user list. Thin pass-through — matches `GetAuditEntries`.
class GetUsers {
  const GetUsers(this._repository);

  final AdminUsersRepository _repository;

  Future<UsersPage> call({String? role, String? status, String? cursor}) =>
      _repository.getUsers(role: role, status: status, cursor: cursor);
}
