import '../../../domain/admin/entities/managed_user.dart';
import '../../../domain/admin/entities/users_page.dart';
import '../../../domain/admin/repositories/admin_users_repository.dart';
import '../datasources/admin_users_remote_datasource.dart';

/// No cache — the user list must always reflect the latest moderation state
/// (same contract as `AuditRepositoryImpl`).
class AdminUsersRepositoryImpl implements AdminUsersRepository {
  AdminUsersRepositoryImpl(this._remote);

  final AdminUsersRemoteDataSource _remote;

  @override
  Future<UsersPage> getUsers({String? role, String? status, String? cursor}) =>
      _remote.getUsers(role: role, status: status, cursor: cursor);

  @override
  Future<ManagedUser?> getByEmail(String email) => _remote.getByEmail(email);

  @override
  Future<ManagedUser?> getByPhone(String phone) => _remote.getByPhone(phone);
}
