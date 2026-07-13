import 'package:dukkan/domain/admin/entities/auth_lookup.dart';
import 'package:dukkan/domain/admin/entities/managed_user.dart';
import 'package:dukkan/domain/admin/entities/users_page.dart';
import 'package:dukkan/domain/admin/repositories/admin_user_actions.dart';
import 'package:dukkan/domain/admin/repositories/admin_users_repository.dart';
import 'package:dukkan/domain/admin/usecases/get_user_by_email.dart';
import 'package:dukkan/domain/admin/usecases/get_user_by_phone.dart';
import 'package:dukkan/domain/admin/usecases/get_users.dart';
import 'package:dukkan/domain/admin/usecases/set_user_disabled.dart';
import 'package:dukkan/domain/auth/entities/user_role.dart';
import 'package:dukkan/presentation/console/users/bloc/users_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeUsersRepository implements AdminUsersRepository {
  String? lastRole;
  String? lastStatus;
  String? lastCursor;
  int calls = 0;
  bool shouldFail = false;

  UsersPage firstPage = const UsersPage(users: [], hasMore: false);
  UsersPage secondPage = const UsersPage(users: [], hasMore: false);
  ManagedUser? byEmailResult;
  ManagedUser? byPhoneResult;

  @override
  Future<UsersPage> getUsers({String? role, String? status, String? cursor}) async {
    calls++;
    lastRole = role;
    lastStatus = status;
    lastCursor = cursor;
    if (shouldFail) throw Exception('boom');
    return cursor == null ? firstPage : secondPage;
  }

  @override
  Future<ManagedUser?> getByEmail(String email) async => byEmailResult;

  @override
  Future<ManagedUser?> getByPhone(String phone) async => byPhoneResult;
}

class _FakeUserActions implements AdminUserActions {
  final calledUids = <String>[];
  bool shouldFailOnUid(String uid) => failingUids.contains(uid);
  final failingUids = <String>{};

  @override
  Future<void> setDisabled({required String uid, required String status}) async {
    calledUids.add(uid);
    if (failingUids.contains(uid)) throw Exception('boom');
  }

  @override
  Future<void> setPersonaRole({required String uid, required String role}) async {}

  @override
  Future<void> changeEmail({required String uid, required String email}) async {}

  @override
  Future<void> softDelete(String uid) async {}

  @override
  Future<void> restore(String uid) async {}

  @override
  Future<String> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async =>
      'new-uid';

  @override
  Future<AuthLookup> lookupAuth(String uid) async =>
      const AuthLookup(email: null, emailVerified: false, disabled: false);

  @override
  Future<void> setAdmin({
    required String uid,
    required String role,
    List<String> extraPermissions = const [],
  }) async {}

  @override
  Future<void> removeAdmin(String uid) async {}
}

ManagedUser _user(String uid, {String name = 'Sara', String status = 'active'}) => ManagedUser(
      uid: uid,
      name: name,
      email: '$uid@example.com',
      role: UserRole.customer,
      status: status,
    );

void main() {
  late _FakeUsersRepository repo;
  late _FakeUserActions actions;
  late UsersBloc bloc;

  setUp(() {
    repo = _FakeUsersRepository()
      ..firstPage = UsersPage(users: [_user('u1'), _user('u2')], hasMore: true)
      ..secondPage = UsersPage(users: [_user('u3')], hasMore: false);
    actions = _FakeUserActions();
    bloc = UsersBloc(
      getUsers: GetUsers(repo),
      getUserByEmail: GetUserByEmail(repo),
      getUserByPhone: GetUserByPhone(repo),
      setUserDisabled: SetUserDisabled(actions),
    );
  });

  tearDown(() => bloc.close());

  Future<void> settle() async {
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  test('start loads the first page and reaches loaded', () async {
    bloc.add(const UsersStarted());
    await settle();

    expect(bloc.state.status, UsersStatus.loaded);
    expect(bloc.state.users.map((u) => u.uid), ['u1', 'u2']);
    expect(bloc.state.hasMore, isTrue);
    expect(repo.lastCursor, isNull);
  });

  test('a filter change reloads with the new role/status', () async {
    bloc.add(const UsersStarted());
    await settle();

    bloc.add(const UsersFilterChanged(role: 'owner', status: 'suspended'));
    await settle();

    expect(repo.lastRole, 'owner');
    expect(repo.lastStatus, 'suspended');
    expect(repo.lastCursor, isNull); // fresh load, not paginated
  });

  test('load more appends the next page using the last row uid as cursor', () async {
    bloc.add(const UsersStarted());
    await settle();

    bloc.add(const UsersLoadMoreRequested());
    await settle();

    expect(bloc.state.users.map((u) => u.uid), ['u1', 'u2', 'u3']);
    expect(bloc.state.hasMore, isFalse);
    expect(repo.lastCursor, 'u2');
  });

  test('a failed load surfaces as error status', () async {
    repo.shouldFail = true;
    bloc.add(const UsersStarted());
    await settle();

    expect(bloc.state.status, UsersStatus.error);
  });

  test('search with an email queries getByEmail and shows a single result', () async {
    bloc.add(const UsersStarted());
    await settle();
    repo.byEmailResult = _user('u9', name: 'Found');

    bloc.add(const UsersSearchSubmitted('found@dukkan.dev'));
    await settle();

    expect(bloc.state.searchResults?.map((u) => u.uid), ['u9']);
    expect(bloc.state.visibleUsers.map((u) => u.uid), ['u9']);
  });

  test('search with a plain name filters the already-loaded page locally', () async {
    bloc.add(const UsersStarted());
    await settle();

    bloc.add(const UsersSearchSubmitted('sara'));
    await settle();

    // Both u1 and u2 are named 'Sara' by the _user() helper default.
    expect(bloc.state.searchResults?.length, 2);
    expect(repo.calls, 1); // no extra Firestore query for a name filter
  });

  test('clearing the search returns to the normal paginated list', () async {
    bloc.add(const UsersStarted());
    await settle();
    bloc.add(const UsersSearchSubmitted('sara'));
    await settle();

    bloc.add(const UsersSearchCleared());
    await settle();

    expect(bloc.state.searchResults, isNull);
    expect(bloc.state.visibleUsers.map((u) => u.uid), ['u1', 'u2']);
  });

  test('bulk suspend runs setDisabled for every selected uid and reports the summary',
      () async {
    bloc.add(const UsersStarted());
    await settle();
    bloc.add(const UserSelectionToggled('u1'));
    bloc.add(const UserSelectionToggled('u2'));
    await settle();

    bloc.add(const UsersBulkSetDisabledRequested('suspended'));
    await settle();

    expect(actions.calledUids, containsAll(['u1', 'u2']));
    expect(bloc.state.bulkBusy, isFalse);
    expect(bloc.state.bulkSucceeded, 2);
    expect(bloc.state.selected, isEmpty);
  });

  test('a bulk failure on one uid still completes the rest of the batch', () async {
    bloc.add(const UsersStarted());
    await settle();
    actions.failingUids.add('u1');
    bloc.add(const UserSelectionToggled('u1'));
    bloc.add(const UserSelectionToggled('u2'));
    await settle();

    bloc.add(const UsersBulkSetDisabledRequested('suspended'));
    await settle();

    expect(actions.calledUids, containsAll(['u1', 'u2']));
    expect(bloc.state.bulkTotal, 2);
    expect(bloc.state.bulkSucceeded, 1);
  });
}
