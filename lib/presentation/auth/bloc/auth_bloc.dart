import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failures.dart';
import '../../../domain/admin/entities/admin_profile.dart';
import '../../../domain/admin/usecases/get_admin_profile.dart';
import '../../../domain/admin/usecases/reset_admin_profile.dart';
import '../../../domain/auth/entities/app_user.dart';
import '../../../domain/auth/entities/user_role.dart';
import '../../../domain/auth/usecases/log_in.dart';
import '../../../domain/auth/usecases/log_out.dart';
import '../../../domain/auth/usecases/send_password_reset.dart';
import '../../../domain/auth/usecases/sign_up.dart';
import '../../../domain/auth/usecases/watch_auth_state.dart';
import '../../../domain/driver/usecases/create_driver_profile.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// App-wide session bloc. Subscribes to the Auth-state stream on creation and
/// keeps [SessionStatus] in sync (routing), while [FormStatus] tracks the
/// current login/signup/reset action (button state + feedback).
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required WatchAuthState watchAuthState,
    required LogIn logIn,
    required SignUp signUp,
    required SendPasswordReset sendPasswordReset,
    required LogOut logOut,
    required CreateDriverProfile createDriverProfile,
    required GetAdminProfile getAdminProfile,
    required ResetAdminProfile resetAdminProfile,
  })  : _logIn = logIn,
        _signUp = signUp,
        _sendPasswordReset = sendPasswordReset,
        _logOut = logOut,
        _createDriverProfile = createDriverProfile,
        _getAdminProfile = getAdminProfile,
        _resetAdminProfile = resetAdminProfile,
        super(const AuthState()) {
    on<AuthUserChanged>(_onUserChanged);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthSignUpRequested>(_onSignUpRequested);
    on<AuthPasswordResetRequested>(_onPasswordResetRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthFormReset>(_onFormReset);

    _userSub = watchAuthState().listen(
      (user) => add(AuthUserChanged(user)),
    );
  }

  final LogIn _logIn;
  final SignUp _signUp;
  final SendPasswordReset _sendPasswordReset;
  final LogOut _logOut;
  final CreateDriverProfile _createDriverProfile;
  final GetAdminProfile _getAdminProfile;
  final ResetAdminProfile _resetAdminProfile;
  StreamSubscription<AppUser?>? _userSub;

  Future<void> _onUserChanged(
    AuthUserChanged event,
    Emitter<AuthState> emit,
  ) async {
    final user = event.user;
    if (user == null) {
      _resetAdminProfile();
      emit(state.copyWith(
        session: SessionStatus.unauthenticated,
        clearUser: true,
        clearAdminProfile: true,
      ));
      return;
    }

    // Route first: authenticated is emitted immediately so login never waits
    // on the admin lookup below.
    emit(state.copyWith(
      session: SessionStatus.authenticated,
      user: user,
    ));

    // Enrich the session with the staff/admin profile (Founder Console RBAC).
    // A failed load is treated as "not staff" (null), never an error that
    // blocks the app.
    AdminProfile? profile;
    try {
      profile = await _getAdminProfile(user.uid);
    } on Failure {
      profile = null;
    }

    // Skip if a sign-out or account switch landed while the profile loaded.
    if (state.session == SessionStatus.authenticated &&
        state.user?.uid == user.uid) {
      emit(state.copyWith(
        adminProfile: profile,
        clearAdminProfile: profile == null,
      ));
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(form: FormStatus.submitting, clearError: true));
    try {
      await _logIn(email: event.email, password: event.password);
      emit(state.copyWith(form: FormStatus.success));
    } on Failure catch (f) {
      emit(state.copyWith(form: FormStatus.failure, errorCode: _codeOf(f)));
    }
  }

  Future<void> _onSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(form: FormStatus.submitting, clearError: true));
    try {
      final user = await _signUp(
        name: event.name,
        email: event.email,
        password: event.password,
        role: event.role,
        phone: event.phone,
      );
      if (event.role == UserRole.courier) {
        await _createDriverProfile(
          uid: user.uid,
          name: event.name,
          phone: event.phone,
        );
      }
      emit(state.copyWith(form: FormStatus.success));
    } on Failure catch (f) {
      emit(state.copyWith(form: FormStatus.failure, errorCode: _codeOf(f)));
    }
  }

  Future<void> _onPasswordResetRequested(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(form: FormStatus.submitting, clearError: true));
    try {
      await _sendPasswordReset(event.email);
      emit(state.copyWith(form: FormStatus.success));
    } on Failure catch (f) {
      emit(state.copyWith(form: FormStatus.failure, errorCode: _codeOf(f)));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _logOut();
  }

  void _onFormReset(AuthFormReset event, Emitter<AuthState> emit) {
    emit(state.copyWith(form: FormStatus.idle, clearError: true));
  }

  AuthFailureCode _codeOf(Failure f) =>
      f is AuthFailure ? f.code : AuthFailureCode.unknown;

  @override
  Future<void> close() {
    _userSub?.cancel();
    return super.close();
  }
}
