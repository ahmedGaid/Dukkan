/// Which side of the marketplace a signed-in user is on. Chosen once at
/// signup and stored on the `/users` doc; drives the auth-guarded routing.
enum UserRole {
  customer,
  owner,
  courier;

  /// Wire form stored in Firestore. Kept explicit (not `.name`) so a future
  /// rename of the Dart enum can't silently break existing docs.
  String get wire => switch (this) {
        UserRole.customer => 'customer',
        UserRole.owner => 'owner',
        UserRole.courier => 'courier',
      };

  static UserRole fromWire(String value) => switch (value) {
        'owner' => UserRole.owner,
        'courier' => UserRole.courier,
        _ => UserRole.customer,
      };
}
