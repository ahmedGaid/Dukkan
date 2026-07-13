import '../repositories/admin_user_actions.dart';

/// Undoes a soft-delete. Thin pass-through.
class RestoreUser {
  const RestoreUser(this._actions);

  final AdminUserActions _actions;

  Future<void> call(String uid) => _actions.restore(uid);
}
