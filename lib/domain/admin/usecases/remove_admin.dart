import '../repositories/admin_user_actions.dart';

/// Revokes staff status. Thin pass-through.
class RemoveAdmin {
  const RemoveAdmin(this._actions);

  final AdminUserActions _actions;

  Future<void> call(String uid) => _actions.removeAdmin(uid);
}
