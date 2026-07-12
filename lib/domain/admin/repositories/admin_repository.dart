import '../entities/admin_profile.dart';

/// Back-office identity boundary (Founder Console RBAC). One-shot read of the
/// `/admins/{uid}` doc, memoized per uid for the app session (staff status
/// rarely changes mid-session). [getAdminProfile] returns null when the uid
/// has no admin doc — i.e. the account is not staff.
abstract class AdminRepository {
  Future<AdminProfile?> getAdminProfile(String uid);

  /// Drops the memoized profile (called on sign-out, so a later sign-in — even
  /// as the same uid whose permissions changed server-side — re-reads fresh).
  void reset();
}
