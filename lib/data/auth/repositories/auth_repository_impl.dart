import 'dart:async';

import '../../../domain/auth/entities/app_user.dart';
import '../../../domain/auth/entities/user_role.dart';
import '../../../domain/auth/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

/// Bridges the raw Firebase Auth stream to resolved [AppUser]s. Subscribes once
/// on construction, resolves the `/users` profile for each Auth change, and
/// fans the result out through a broadcast stream while caching the latest for
/// the synchronous [currentUser] getter.
///
/// The subscription touches Firebase, so this class is only ever built at app
/// runtime (after `Firebase.initializeApp`) — tests use a fake repository, so
/// this constructor never runs under `flutter test`.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote) {
    _sub = _remote.rawAuthChanges().asyncMap((fbUser) async {
      if (fbUser == null) return null;
      return _remote.loadProfile(fbUser);
    }).listen(
      (user) {
        _currentUser = user;
        _controller.add(user);
      },
      onError: _controller.addError,
    );
  }

  final AuthRemoteDataSource _remote;
  final _controller = StreamController<AppUser?>.broadcast();
  StreamSubscription<AppUser?>? _sub;
  AppUser? _currentUser;

  @override
  Stream<AppUser?> authStateChanges() => _controller.stream;

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? phone,
  }) {
    return _remote.signUp(
      name: name,
      email: email,
      password: password,
      role: role,
      phone: phone,
    );
  }

  @override
  Future<AppUser> logIn({required String email, required String password}) {
    return _remote.logIn(email: email, password: password);
  }

  @override
  Future<void> sendPasswordReset(String email) =>
      _remote.sendPasswordReset(email);

  @override
  Future<void> logOut() => _remote.logOut();

  @override
  Future<void> saveFcmToken(String uid, String token) =>
      _remote.saveFcmToken(uid, token);

  /// Not wired to any lifecycle yet (the repo is an app-lifetime singleton);
  /// here for completeness if the container is ever torn down in tests.
  void dispose() {
    _sub?.cancel();
    _controller.close();
  }
}
