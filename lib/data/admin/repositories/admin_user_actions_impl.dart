import '../../../domain/admin/entities/auth_lookup.dart';
import '../../../domain/admin/repositories/admin_user_actions.dart';
import '../datasources/admin_api_datasource.dart';
import '../models/auth_lookup_model.dart';

/// Calls the Worker's `/admin/users/*` and `/admin/admins/*` endpoints. Every
/// method is a thin `post` — the Worker does the permission check, the actual
/// Auth/Firestore mutation, and the audit write; this layer never touches
/// Firebase Auth or Firestore directly for these ops.
class AdminUserActionsImpl implements AdminUserActions {
  AdminUserActionsImpl(this._api);

  final AdminApiDataSource _api;

  @override
  Future<void> setDisabled({required String uid, required String status}) =>
      _api.post('users/set-disabled', {'uid': uid, 'status': status});

  @override
  Future<void> setPersonaRole({required String uid, required String role}) =>
      _api.post('users/set-persona-role', {'uid': uid, 'role': role});

  @override
  Future<void> changeEmail({required String uid, required String email}) =>
      _api.post('users/change-email', {'uid': uid, 'email': email});

  @override
  Future<void> softDelete(String uid) => _api.post('users/soft-delete', {'uid': uid});

  @override
  Future<void> restore(String uid) => _api.post('users/restore', {'uid': uid});

  @override
  Future<String> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final res = await _api.post('users/create', {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
    });
    return res['uid'] as String;
  }

  @override
  Future<AuthLookup> lookupAuth(String uid) async {
    final res = await _api.post('users/lookup', {'uid': uid});
    return AuthLookupModel.fromJson(res);
  }

  @override
  Future<void> setAdmin({
    required String uid,
    required String role,
    List<String> extraPermissions = const [],
  }) =>
      _api.post('admins/set', {
        'uid': uid,
        'role': role,
        'extraPermissions': extraPermissions,
      });

  @override
  Future<void> removeAdmin(String uid) => _api.post('admins/remove', {'uid': uid});
}
