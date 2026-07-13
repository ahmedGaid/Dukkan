import '../entities/auth_lookup.dart';

/// Privileged user + staff management ops (Founder Console Session 6). Every
/// method is one Worker `/admin/*` endpoint — the Worker permission-checks
/// and audit-logs each call server-side, so this is the ONLY path the app
/// uses for these mutations (never a direct Firestore/Auth write).
abstract class AdminUserActions {
  /// `active` | `suspended` | `banned`.
  Future<void> setDisabled({required String uid, required String status});

  /// `customer` | `owner` | `courier` — the app persona ONLY, never a staff tier.
  Future<void> setPersonaRole({required String uid, required String role});

  Future<void> changeEmail({required String uid, required String email});

  Future<void> softDelete(String uid);

  Future<void> restore(String uid);

  /// Returns the new account's uid.
  Future<String> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
  });

  Future<AuthLookup> lookupAuth(String uid);

  /// Creates/updates `/admins/{uid}`. [role] is a staff tier
  /// (support/moderator/admin/founder); [extraPermissions] are added on top
  /// of the role's own set. Rank-guarded server-side.
  Future<void> setAdmin({
    required String uid,
    required String role,
    List<String> extraPermissions = const [],
  });

  Future<void> removeAdmin(String uid);
}
