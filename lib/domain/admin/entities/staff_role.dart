/// A back-office staff tier (Founder Console RBAC). Distinct from
/// [UserRole] (customer/owner/courier), which stays the app-persona field on
/// `/users`; this lives on `/admins` and drives what console operations the
/// account may perform. `rank` orders tiers so a lower tier can never act on a
/// higher one (e.g. impersonation, role edits).
enum StaffRole {
  support,
  moderator,
  admin,
  founder;

  /// Wire form stored in Firestore. Kept explicit (not `.name`) so a future
  /// rename of the Dart enum can't silently break existing docs.
  String get wire => switch (this) {
        StaffRole.support => 'support',
        StaffRole.moderator => 'moderator',
        StaffRole.admin => 'admin',
        StaffRole.founder => 'founder',
      };

  /// Tier weight: founder 100 > admin 80 > moderator 60 > support 40.
  int get rank => switch (this) {
        StaffRole.support => 40,
        StaffRole.moderator => 60,
        StaffRole.admin => 80,
        StaffRole.founder => 100,
      };

  /// Unknown strings fall back to the least-privileged tier (fail-closed);
  /// callers that need to reject unknown roles entirely should check the raw
  /// wire against [values] first.
  static StaffRole fromWire(String value) => switch (value) {
        'founder' => StaffRole.founder,
        'admin' => StaffRole.admin,
        'moderator' => StaffRole.moderator,
        _ => StaffRole.support,
      };
}
