import '../repositories/admin_user_actions.dart';

/// Reversibly deactivates a user account. Thin pass-through.
class SoftDeleteUser {
  const SoftDeleteUser(this._actions);

  final AdminUserActions _actions;

  Future<void> call(String uid) => _actions.softDelete(uid);
}
