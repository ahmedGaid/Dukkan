import '../entities/auth_lookup.dart';
import '../repositories/admin_user_actions.dart';

/// Loads Auth-side facts for the user detail page. Thin pass-through.
class LookupUserAuth {
  const LookupUserAuth(this._actions);

  final AdminUserActions _actions;

  Future<AuthLookup> call(String uid) => _actions.lookupAuth(uid);
}
