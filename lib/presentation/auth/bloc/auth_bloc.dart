import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failures.dart';
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
  })  : _logIn = logIn,
        _signUp = signUp,
        _sendPasswordReset = sendPasswordReset,
        _logOut = logOut,
        _createDriverProfile = createDriverProfile,
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
  StreamSubscription<AppUser?>? _userSub;

  void _onUserChanged(AuthUserChanged event, Emitter<AuthState> emit) {
    if (event.user != null) {
      emit(state.copyWith(
        session: SessionStatus.authenticated,
        user: event.user,
      ));
    } else {
      emit(state.copyWith(
        session: SessionStatus.unauthenticated,
        clearUser: true,
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
