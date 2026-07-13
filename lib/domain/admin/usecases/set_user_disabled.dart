import '../repositories/admin_user_actions.dart';

/// Suspends/bans/reactivates a user. Thin pass-through — matches `GetAreas`.
class SetUserDisabled {
  const SetUserDisabled(this._actions);

  final AdminUserActions _actions;

  Future<void> call({required String uid, required String status}) =>
      _actions.setDisabled(uid: uid, status: status);
}
