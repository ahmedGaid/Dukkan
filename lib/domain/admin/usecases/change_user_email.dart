import '../repositories/admin_user_actions.dart';

/// Updates a user's email (Auth + `/users` doc). Thin pass-through.
class ChangeUserEmail {
  const ChangeUserEmail(this._actions);

  final AdminUserActions _actions;

  Future<void> call({required String uid, required String email}) =>
      _actions.changeEmail(uid: uid, email: email);
}
