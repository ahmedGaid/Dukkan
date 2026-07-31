import 'package:dukkan/core/di/injector.dart';
import 'package:dukkan/domain/admin/entities/admin_profile.dart';
import 'package:dukkan/domain/admin/repositories/admin_repository.dart';
import 'package:dukkan/domain/auth/entities/app_user.dart';
import 'package:dukkan/domain/auth/entities/user_role.dart';
import 'package:dukkan/domain/auth/repositories/auth_repository.dart';
import 'package:dukkan/domain/driver/entities/driver.dart';
import 'package:dukkan/domain/driver/repositories/driver_repository.dart';
import 'package:dukkan/main.dart';
import 'package:dukkan/presentation/auth/pages/login_page.dart';
import 'package:dukkan/presentation/widgets/common/app_button.dart';
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

/// `AuthBloc` now takes `CreateDriverProfile` as a constructor dependency
/// (M8), so building it — even signed-out — resolves a `DriverRepository`.
/// Swapped out for the same reason as `_SignedOutAuthRepository`: never let
/// a widget test touch real Firebase.
class _NoopDriverRepository implements DriverRepository {
  @override
  Future<void> createDriverProfile({
    required String uid,
    required String name,
    String? phone,
  }) =>
      throw UnimplementedError();

  @override
  Future<Driver?> getDriver(String uid) => throw UnimplementedError();

  @override
  Stream<Driver?> watchDriver(String uid) => throw UnimplementedError();

  @override
  Future<void> setOnline(String uid, bool isOnline) =>
      throw UnimplementedError();

  @override
  Future<List<Driver>> availableDrivers(String areaId) =>
      throw UnimplementedError();

  @override
  Future<void> assignDriver({required String orderId, required String driverUid}) =>
      throw UnimplementedError();
}

/// `AuthBloc` now resolves an `AdminRepository` (Founder Console RBAC) to load
/// the staff profile at login. That datasource is Firestore-backed, so — same
/// reason as the two fakes above — it's swapped for a signed-out no-op that
/// never reports staff.
class _NoopAdminRepository implements AdminRepository {
  @override
  Future<AdminProfile?> getAdminProfile(String uid) async => null;

  @override
  Future<AdminProfile?> getAdminProfileForUid(String uid) async => null;

  @override
  void reset() {}
}

void main() {
  setUp(() async {
    // initDependencies now loads SharedPreferences (locale/theme controllers);
    // give it an empty in-memory store so the tree builds signed-out.
    SharedPreferences.setMockInitialValues({});
    await initDependencies();
    // Override the Firebase-backed repositories with signed-out fakes.
    await sl.unregister<AuthRepository>();
    sl.registerLazySingleton<AuthRepository>(_SignedOutAuthRepository.new);
    await sl.unregister<DriverRepository>();
    sl.registerLazySingleton<DriverRepository>(_NoopDriverRepository.new);
    await sl.unregister<AdminRepository>();
    sl.registerLazySingleton<AdminRepository>(_NoopAdminRepository.new);
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

  // A live run on 2026-07-31 showed both login fields carrying «الحقل ده
  // مطلوب» and was first read as "validation fires on arrival". It is not:
  // the fields use the default (disabled) autovalidateMode, so errors appear
  // only after a submit — what was really seen was an empty-form login
  // attempt. These two pin that contract so a future autovalidateMode change
  // can't quietly regress it.
  testWidgets('login shows no validation errors before the first submit',
      (WidgetTester tester) async {
    await tester.pumpWidget(const DukkanApp());
    await tester.pumpAndSettle();

    final fields = tester.widgetList<TextField>(find.byType(TextField));
    expect(fields, hasLength(2));
    for (final f in fields) {
      expect(f.decoration?.errorText, isNull);
    }
  });

  testWidgets('login surfaces required errors once submitted empty',
      (WidgetTester tester) async {
    await tester.pumpWidget(const DukkanApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(AppButton));
    await tester.pumpAndSettle();

    final fields =
        tester.widgetList<TextField>(find.byType(TextField)).toList();
    expect(fields.every((f) => f.decoration?.errorText != null), isTrue,
        reason: 'an empty submit must mark both fields');
  });
}
