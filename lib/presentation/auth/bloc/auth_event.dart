part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Emitted internally when the Auth-state stream fires (sign-in/out, start-up).
class AuthUserChanged extends AuthEvent {
  const AuthUserChanged(this.user);

  final AppUser? user;

  @override
  List<Object?> get props => [user];
}

class AuthLoginRequested extends AuthEvent {
  const AuthLoginRequested({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

class AuthSignUpRequested extends AuthEvent {
  const AuthSignUpRequested({
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.phone,
  });

  final String name;
  final String email;
  final String password;
  final UserRole role;
  final String? phone;

  @override
  List<Object?> get props => [name, email, password, role, phone];
}

class AuthPasswordResetRequested extends AuthEvent {
  const AuthPasswordResetRequested(this.email);

  final String email;

  @override
  List<Object?> get props => [email];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

/// Clears a consumed form result (error/success) so re-entering a page starts
/// from a clean [FormStatus.idle].
class AuthFormReset extends AuthEvent {
  const AuthFormReset();
}
