import '../repositories/admin_user_actions.dart';

/// Changes a user's app persona (customer/owner/courier). Thin pass-through.
class SetUserPersonaRole {
  const SetUserPersonaRole(this._actions);

  final AdminUserActions _actions;

  Future<void> call({required String uid, required String role}) =>
      _actions.setPersonaRole(uid: uid, role: role);
}
