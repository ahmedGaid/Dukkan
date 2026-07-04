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
    this.form = FormStatus.idle,
    this.errorCode,
  });

  final SessionStatus session;
  final AppUser? user;
  final FormStatus form;
  final AuthFailureCode? errorCode;

  bool get isSubmitting => form == FormStatus.submitting;

  AuthState copyWith({
    SessionStatus? session,
    AppUser? user,
    bool clearUser = false,
    FormStatus? form,
    AuthFailureCode? errorCode,
    bool clearError = false,
  }) {
    return AuthState(
      session: session ?? this.session,
      user: clearUser ? null : (user ?? this.user),
      form: form ?? this.form,
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
    );
  }

  @override
  List<Object?> get props => [session, user, form, errorCode];
}
