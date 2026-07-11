import 'package:dukkan/core/di/injector.dart';
import 'package:dukkan/domain/auth/entities/app_user.dart';
import 'package:dukkan/domain/auth/entities/user_role.dart';
import 'package:dukkan/domain/auth/repositories/auth_repository.dart';
import 'package:dukkan/main.dart';
import 'package:dukkan/presentation/auth/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Signed-out fake so the widget tree never touches Firebase. The real
/// repository (which subscribes to Firebase on construction) is swapped out
/// before the app is built.
class _SignedOutAuthRepository implements AuthRepository {
  @override
  Stream<AppUser?> authStateChanges() => Stream<AppUser?>.value(null);

  @override
  AppUser? get currentUser => null;

  @override
  Future<AppUser> logIn({required String email, required String password}) =>
      throw UnimplementedError();

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
  Future<void> sendPasswordReset(String email) => throw UnimplementedError();

  @override
  Future<void> logOut() async {}

  @override
  Future<void> saveFcmToken(String uid, String token) async {}

  @override
  Future<AppUser?> getUserById(String uid) async => null;
}

void main() {
  setUp(() async {
    // initDependencies now loads SharedPreferences (locale/theme controllers);
    // give it an empty in-memory store so the tree builds signed-out.
    SharedPreferences.setMockInitialValues({});
    await initDependencies();
    // Override the Firebase-backed repository with a signed-out fake.
    await sl.unregister<AuthRepository>();
    sl.registerLazySingleton<AuthRepository>(_SignedOutAuthRepository.new);
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('Signed-out app routes to the login page',
      (WidgetTester tester) async {
    await tester.pumpWidget(const DukkanApp());
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(LoginPage), findsOneWidget);
  });
}
