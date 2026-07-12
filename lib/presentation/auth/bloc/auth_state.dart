part of 'auth_bloc.dart';

/// Session status — drives routing (the router's redirect reads this).
enum SessionStatus { unknown, authenticated, unauthenticated }

/// Status of the in-flight form action (login/signup/reset) — drives the
/// button spinner and success/error feedback on the auth pages.
enum FormStatus { idle, submitting, success, failure }

class AuthState extends Equatable {
  const AuthState({
    this.session = SessionStatus.unknown,
    this.user,
    this.adminProfile,
    this.form = FormStatus.idle,
    this.errorCode,
  });

  final SessionStatus session;
  final AppUser? user;

  /// Back-office identity (Founder Console RBAC). Null for a non-staff account;
  /// loaded right after the user lands in state, never blocks routing.
  final AdminProfile? adminProfile;
  final FormStatus form;
  final AuthFailureCode? errorCode;

  bool get isSubmitting => form == FormStatus.submitting;

  /// Whether the signed-in account's staff profile grants [permission]. False
  /// for non-staff or an inactive admin — the one place the UI and router ask
  /// "can this account do X".
  bool can(String permission) => adminProfile?.can(permission) ?? false;

  AuthState copyWith({
    SessionStatus? session,
    AppUser? user,
    bool clearUser = false,
    AdminProfile? adminProfile,
    bool clearAdminProfile = false,
    FormStatus? form,
    AuthFailureCode? errorCode,
    bool clearError = false,
  }) {
    return AuthState(
      session: session ?? this.session,
      user: clearUser ? null : (user ?? this.user),
      adminProfile:
          clearAdminProfile ? null : (adminProfile ?? this.adminProfile),
      form: form ?? this.form,
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
    );
  }

  @override
  List<Object?> get props => [session, user, adminProfile, form, errorCode];
}
