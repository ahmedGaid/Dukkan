import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import '../../data/admin/datasources/admin_api_datasource.dart';

/// Founder-Console impersonation (FC15). Holds the return-to-founder custom
/// token in memory ONLY — never persisted, never survives a process kill by
/// design (a lost token is a fail-safe, not a bug: [exit] falls back to a
/// hard sign-out so the app can never get stuck impersonating with no way
/// back). The banner that shows impersonation is ACTIVE never reads this —
/// it derives that independently from the signed-in user's ID-token claims
/// (`impersonatedBy`), which DO survive a relaunch (see
/// `ImpersonationOverlay`).
class ImpersonationSession {
  ImpersonationSession({required AdminApiDataSource api, required FirebaseAuth auth})
      : _api = api,
        _auth = auth;

  final AdminApiDataSource _api;
  final FirebaseAuth _auth;

  String? _returnToken;

  /// Calls `/admin/impersonate`, then signs the current (founder) session
  /// into [targetUid]'s account. `AuthBloc`'s existing auth-state listener
  /// picks up the switch and the router redirects to that persona's home —
  /// no navigation call needed here.
  Future<void> start(String targetUid) async {
    final result = await _api.post('impersonate', {'targetUid': targetUid});
    final token = result['token'] as String?;
    final returnToken = result['returnToken'] as String?;
    if (token == null || returnToken == null) {
      throw StateError('impersonate: missing token in response');
    }
    _returnToken = returnToken;
    await _auth.signInWithCustomToken(token);
  }

  /// Signs back to the founder's own session. Any failure (token expired
  /// past its 1h lifetime, revoked, or simply lost to a process kill) falls
  /// back to a hard sign-out — never leaves the device stuck signed in as
  /// the impersonated user with no way to exit.
  Future<void> exit() async {
    final impersonatedUid = _auth.currentUser?.uid;
    final token = _returnToken;
    _returnToken = null;
    try {
      if (token == null) throw StateError('no return token');
      await _auth.signInWithCustomToken(token);
    } catch (_) {
      await _auth.signOut();
    }
    if (impersonatedUid != null) {
      unawaited(_api.reportAudit(
        action: 'impersonation.end',
        targetType: 'user',
        targetId: impersonatedUid,
      ));
    }
  }
}
