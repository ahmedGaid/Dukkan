import 'dart:async';

import 'package:dukkan/domain/admin/entities/admin_profile.dart';
import 'package:dukkan/domain/admin/entities/permissions.dart';
import 'package:dukkan/domain/admin/entities/staff_role.dart';
import 'package:dukkan/domain/admin/repositories/admin_repository.dart';
import 'package:dukkan/domain/admin/usecases/get_admin_profile.dart';
import 'package:dukkan/domain/admin/usecases/reset_admin_profile.dart';
import 'package:dukkan/domain/auth/entities/app_user.dart';
import 'package:dukkan/domain/auth/entities/user_role.dart';
import 'package:dukkan/domain/auth/usecases/log_in.dart';
import 'package:dukkan/domain/auth/usecases/log_out.dart';
import 'package:dukkan/domain/auth/usecases/send_password_reset.dart';
import 'package:dukkan/domain/auth/usecases/sign_up.dart';
import 'package:dukkan/domain/auth/usecases/watch_auth_state.dart';
import 'package:dukkan/domain/driver/usecases/create_driver_profile.dart';
import 'package:dukkan/presentation/auth/bloc/auth_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// Drives the auth stream by hand so the tests can push sign-in / sign-out.
class _FakeWatchAuthState implements WatchAuthState {
  final controller = StreamController<AppUser?>();
  @override
  Stream<AppUser?> call() => controller.stream;
}

class _FakeAdminRepository implements AdminRepository {
  AdminProfile? profile;
  int resetCalls = 0;

  @override
  Future<AdminProfile?> getAdminProfile(String uid) async => profile;

  @override
  Future<AdminProfile?> getAdminProfileForUid(String uid) async => profile;

  @override
  void reset() => resetCalls++;
}

// The remaining ctor deps are never exercised by these tests — stubbed to the
// minimum the AuthBloc constructor needs.
class _FakeLogIn implements LogIn {
  @override
  Future<AppUser> call({required String email, required String password}) =>
      throw UnimplementedError();
}

class _FakeSignUp implements SignUp {
  @override
  Future<AppUser> call({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? phone,
  }) =>
      throw UnimplementedError();
}

class _FakeSendPasswordReset implements SendPasswordReset {
  @override
  Future<void> call(String email) => throw UnimplementedError();
}

class _FakeLogOut implements LogOut {
  @override
  Future<void> call() async {}
}

class _FakeCreateDriverProfile implements CreateDriverProfile {
  @override
  Future<void> call({
    required String uid,
    required String name,
    String? phone,
  }) =>
      throw UnimplementedError();
}

const _user = AppUser(
  uid: 'u1',
  email: 'a@b.com',
  name: 'Test',
  role: UserRole.customer,
);

const _staffProfile = AdminProfile(
  uid: 'u1',
  role: StaffRole.founder,
  permissions: {Permissions.all},
  isActive: true,
  rank: 100,
);

void main() {
  late _FakeWatchAuthState watch;
  late _FakeAdminRepository adminRepo;
  late AuthBloc bloc;

  setUp(() {
    watch = _FakeWatchAuthState();
    adminRepo = _FakeAdminRepository();
    bloc = AuthBloc(
      watchAuthState: watch,
      logIn: _FakeLogIn(),
      signUp: _FakeSignUp(),
      sendPasswordReset: _FakeSendPasswordReset(),
      logOut: _FakeLogOut(),
      createDriverProfile: _FakeCreateDriverProfile(),
      getAdminProfile: GetAdminProfile(adminRepo),
      resetAdminProfile: ResetAdminProfile(adminRepo),
    );
  });

  tearDown(() async {
    await bloc.close();
    await watch.controller.close();
  });

  // The user-changed handler emits authenticated, then awaits the admin
  // lookup and emits again — a couple of event-loop turns flush both.
  Future<void> settle() async {
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  test('a non-staff sign-in reaches authenticated with a null admin profile',
      () async {
    adminRepo.profile = null;
    watch.controller.add(_user);
    await settle();

    expect(bloc.state.session, SessionStatus.authenticated);
    expect(bloc.state.adminProfile, isNull);
    expect(bloc.state.can(Permissions.financeRead), isFalse);
  });

  test('a staff sign-in enriches the session with the admin profile', () async {
    adminRepo.profile = _staffProfile;
    watch.controller.add(_user);
    await settle();

    expect(bloc.state.session, SessionStatus.authenticated);
    expect(bloc.state.adminProfile, _staffProfile);
    expect(bloc.state.can(Permissions.financeRead), isTrue);
  });

  test('sign-out clears the profile and resets the cache', () async {
    adminRepo.profile = _staffProfile;
    watch.controller.add(_user);
    await settle();
    expect(bloc.state.adminProfile, _staffProfile);

    watch.controller.add(null);
    await settle();

    expect(bloc.state.session, SessionStatus.unauthenticated);
    expect(bloc.state.adminProfile, isNull);
    expect(adminRepo.resetCalls, greaterThanOrEqualTo(1));
  });
}
