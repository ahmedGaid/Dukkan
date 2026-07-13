import '../repositories/admin_user_actions.dart';

/// Staff-initiated account creation. Thin pass-through; returns the new uid.
class CreateUser {
  const CreateUser(this._actions);

  final AdminUserActions _actions;

  Future<String> call({
    required String name,
    required String email,
    required String password,
    required String role,
  }) =>
      _actions.createUser(name: name, email: email, password: password, role: role);
}
