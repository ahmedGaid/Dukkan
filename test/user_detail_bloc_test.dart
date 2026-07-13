import 'package:dukkan/domain/admin/entities/admin_profile.dart';
import 'package:dukkan/domain/admin/entities/auth_lookup.dart';
import 'package:dukkan/domain/admin/entities/managed_user.dart';
import 'package:dukkan/domain/admin/entities/staff_role.dart';
import 'package:dukkan/domain/admin/repositories/admin_repository.dart';
import 'package:dukkan/domain/admin/repositories/admin_user_actions.dart';
import 'package:dukkan/domain/admin/repositories/admin_users_repository.dart';
import 'package:dukkan/domain/admin/usecases/change_user_email.dart';
import 'package:dukkan/domain/admin/usecases/get_staff_profile_for_uid.dart';
import 'package:dukkan/domain/admin/usecases/get_user_by_email.dart';
import 'package:dukkan/domain/admin/usecases/lookup_user_auth.dart';
import 'package:dukkan/domain/admin/usecases/remove_admin.dart';
import 'package:dukkan/domain/admin/usecases/restore_user.dart';
import 'package:dukkan/domain/admin/usecases/set_admin.dart';
import 'package:dukkan/domain/admin/usecases/set_user_disabled.dart';
import 'package:dukkan/domain/admin/usecases/set_user_persona_role.dart';
import 'package:dukkan/domain/admin/usecases/soft_delete_user.dart';
import 'package:dukkan/domain/auth/entities/app_user.dart';
import 'package:dukkan/domain/auth/entities/user_role.dart';
import 'package:dukkan/domain/auth/repositories/auth_repository.dart';
import 'package:dukkan/domain/admin/entities/users_page.dart';
import 'package:dukkan/domain/auth/usecases/send_password_reset.dart';
import 'package:dukkan/presentation/console/users/bloc/user_detail_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeUserActions implements AdminUserActions {
  bool shouldFail = false;
  String? lastAction;

  @override
  Future<void> setDisabled({required String uid, required String status}) async {
    lastAction = 'setDisabled:$status';
    if (shouldFail) throw Exception('boom');
  }

  @override
  Future<void> setPersonaRole({required String uid, required String role}) async {
    lastAction = 'setPersonaRole:$role';
    if (shouldFail) throw Exception('boom');
  }

  @override
  Future<void> changeEmail({required String uid, required String email}) async {
    lastAction = 'changeEmail:$email';
    if (shouldFail) throw Exception('boom');
  }

  @override
  Future<void> softDelete(String uid) async {
    lastAction = 'softDelete';
    if (shouldFail) throw Exception('boom');
  }

  @override
  Future<void> restore(String uid) async {
    lastAction = 'restore';
    if (shouldFail) throw Exception('boom');
  }

  @override
  Future<String> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async =>
      'new-uid';

  @override
  Future<AuthLookup> lookupAuth(String uid) async => const AuthLookup(
        email: 'u1@example.com',
        emailVerified: true,
        disabled: false,
      );

  @override
  Future<void> setAdmin({
    required String uid,
    required String role,
    List<String> extraPermissions = const [],
  }) async {
    lastAction = 'setAdmin:$role';
  }

  @override
  Future<void> removeAdmin(String uid) async {
    lastAction = 'removeAdmin';
  }
}

class _FakeAdminRepository implements AdminRepository {
  AdminProfile? profileForUid;

  @override
  Future<AdminProfile?> getAdminProfile(String uid) async => null;

  @override
  Future<AdminProfile?> getAdminProfileForUid(String uid) async => profileForUid;

  @override
  void reset() {}
}

class _FakeUsersRepository implements AdminUsersRepository {
  ManagedUser? refreshed;

  @override
  Future<UsersPage> getUsers({String? role, String? status, String? cursor}) async =>
      const UsersPage(users: [], hasMore: false);

  @override
  Future<ManagedUser?> getByEmail(String email) async => refreshed;

  @override
  Future<ManagedUser?> getByPhone(String phone) async => null;
}

class _FakeAuthRepository implements AuthRepository {
  bool resetSent = false;

  @override
  Stream<AppUser?> authStateChanges() => const Stream.empty();

  @override
  AppUser? get currentUser => null;

  @override
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? phone,
  }) =>
      throw UnimplementedError();

  @override
  Future<AppUser> logIn({required String email, required String password}) =>
      throw UnimplementedError();

  @override
  Future<void> sendPasswordReset(String email) async {
    resetSent = true;
  }

  @override
  Future<void> logOut() => throw UnimplementedError();

  @override
  Future<void> saveFcmToken(String uid, String token) => throw UnimplementedError();

  @override
  Future<AppUser?> getUserById(String uid) => throw UnimplementedError();
}

ManagedUser _seedUser() => const ManagedUser(
      uid: 'u1',
      name: 'Sara',
      email: 'u1@example.com',
      role: UserRole.customer,
      status: 'active',
    );

void main() {
  late _FakeUserActions actions;
  late _FakeAdminRepository adminRepo;
  late _FakeUsersRepository usersRepo;
  late _FakeAuthRepository authRepo;
  late UserDetailBloc bloc;

  setUp(() {
    actions = _FakeUserActions();
    adminRepo = _FakeAdminRepository();
    usersRepo = _FakeUsersRepository()..refreshed = _seedUser();
    authRepo = _FakeAuthRepository();
    bloc = UserDetailBloc(
      seed: _seedUser(),
      lookupUserAuth: LookupUserAuth(actions),
      getStaffProfileForUid: GetStaffProfileForUid(adminRepo),
      getUserByEmail: GetUserByEmail(usersRepo),
      setUserDisabled: SetUserDisabled(actions),
      setUserPersonaRole: SetUserPersonaRole(actions),
      changeUserEmail: ChangeUserEmail(actions),
      softDeleteUser: SoftDeleteUser(actions),
      restoreUser: RestoreUser(actions),
      sendPasswordReset: SendPasswordReset(authRepo),
      setAdmin: SetAdmin(actions),
      removeAdmin: RemoveAdmin(actions),
    );
  });

  tearDown(() => bloc.close());

  Future<void> settle() async {
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  test('start loads the auth lookup and staff profile', () async {
    adminRepo.profileForUid = const AdminProfile(
      uid: 'u1',
      role: StaffRole.support,
      permissions: {'users.read'},
      isActive: true,
      rank: 40,
    );

    bloc.add(const UserDetailStarted());
    await settle();

    expect(bloc.state.status, UserDetailStatus.loaded);
    expect(bloc.state.authLookup?.emailVerified, isTrue);
    expect(bloc.state.staffProfile?.role, StaffRole.support);
  });

  test('a non-staff target loads with a null staff profile', () async {
    bloc.add(const UserDetailStarted());
    await settle();

    expect(bloc.state.staffProfile, isNull);
  });

  test('setDisabled succeeds, refreshes the user, and clears actionBusy', () async {
    usersRepo.refreshed = _seedUser(); // status field isn't varied here — refresh path only
    bloc.add(const UserDetailStarted());
    await settle();

    bloc.add(const UserDetailSetDisabledRequested(uid: 'u1', status: 'suspended'));
    await settle();

    expect(actions.lastAction, 'setDisabled:suspended');
    expect(bloc.state.actionBusy, isFalse);
    expect(bloc.state.actionError, isNull);
  });

  test('a failed mutation surfaces actionError without touching the cached user', () async {
    bloc.add(const UserDetailStarted());
    await settle();
    actions.shouldFail = true;

    bloc.add(const UserDetailSoftDeleteRequested('u1'));
    await settle();

    expect(bloc.state.actionError, isNotNull);
    expect(bloc.state.actionBusy, isFalse);
    expect(bloc.state.user.uid, 'u1'); // unchanged
  });

  test('sendPasswordReset calls the Auth repository directly (not the Worker)', () async {
    bloc.add(const UserDetailStarted());
    await settle();

    bloc.add(const UserDetailSendPasswordResetRequested());
    await settle();

    expect(authRepo.resetSent, isTrue);
    expect(bloc.state.actionBusy, isFalse);
  });

  test('setAdmin refreshes the staff profile afterward', () async {
    bloc.add(const UserDetailStarted());
    await settle();
    adminRepo.profileForUid = const AdminProfile(
      uid: 'u1',
      role: StaffRole.moderator,
      permissions: {'users.read', 'orders.read'},
      isActive: true,
      rank: 60,
    );

    bloc.add(const UserDetailSetAdminRequested(uid: 'u1', role: 'moderator'));
    await settle();

    expect(actions.lastAction, 'setAdmin:moderator');
    expect(bloc.state.staffProfile?.role, StaffRole.moderator);
  });
}
