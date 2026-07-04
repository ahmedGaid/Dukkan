import '../entities/app_user.dart';
import '../entities/user_role.dart';

/// Auth boundary the presentation layer talks to (via use cases). Methods that
/// can fail throw a [Failure] (`AuthFailure` with a code) — callers catch and
/// map to a localized message. No `Either`/`dartz` — throwing keeps the stack
/// dependency-free (see core/errors/failures.dart).
abstract class AuthRepository {
  /// Current signed-in user (null when signed out), fired on start and on every
  /// sign-in/out. The app-wide AuthBloc subscribes to this.
  Stream<AppUser?> authStateChanges();

  /// Synchronous best-effort snapshot; null until the first stream event or
  /// when signed out.
  AppUser? get currentUser;

  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? phone,
  });

  Future<AppUser> logIn({required String email, required String password});

  Future<void> sendPasswordReset(String email);

  Future<void> logOut();
}
