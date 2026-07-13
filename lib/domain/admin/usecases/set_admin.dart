import '../repositories/admin_user_actions.dart';

/// Creates/updates a staff member's `/admins` doc. Thin pass-through.
class SetAdmin {
  const SetAdmin(this._actions);

  final AdminUserActions _actions;

  Future<void> call({
    required String uid,
    required String role,
    List<String> extraPermissions = const [],
  }) =>
      _actions.setAdmin(uid: uid, role: role, extraPermissions: extraPermissions);
}
