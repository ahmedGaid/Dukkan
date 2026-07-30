import '../entities/managed_user.dart';
import '../repositories/admin_users_repository.dart';

/// The console global search's "users" name-prefix lookup (FC17). Thin
/// pass-through.
class SearchUsersByName {
  const SearchUsersByName(this._repository);

  final AdminUsersRepository _repository;

  Future<List<ManagedUser>> call(String prefix, {int limit = 5}) =>
      _repository.searchByNamePrefix(prefix, limit: limit);
}
