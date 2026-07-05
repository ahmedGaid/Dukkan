import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../core/errors/failures.dart';
import '../../../domain/auth/entities/user_role.dart';
import '../models/app_user_model.dart';

/// Pure Firebase operations for auth. Every failure is translated into an
/// [AuthFailure] with a code — the raw FirebaseAuthException never escapes this
/// layer, so the UI only ever deals with domain failures.
class AuthRemoteDataSource {
  AuthRemoteDataSource({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  })  : _auth = auth,
        _firestore = firestore;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  /// Raw Auth-state stream (Firebase [User], profile not yet loaded).
  Stream<User?> rawAuthChanges() => _auth.authStateChanges();

  /// Loads the `/users/{uid}` profile for a signed-in Firebase user. Falls back
  /// to a customer profile from the Auth record if the doc is missing (broken
  /// state — shouldn't happen once signUp always writes it).
  Future<AppUserModel> loadProfile(User fbUser) async {
    try {
      final snap = await _users.doc(fbUser.uid).get();
      final data = snap.data();
      if (data == null) {
        return AppUserModel(
          uid: fbUser.uid,
          email: fbUser.email ?? '',
          name: fbUser.displayName ?? '',
          role: UserRole.customer,
        );
      }
      return AppUserModel.fromFirestore(fbUser.uid, data,
          authEmail: fbUser.email);
    } on FirebaseException catch (e) {
      debugPrint('[Auth] loadProfile FirebaseException: ${e.code} — ${e.message}');
      throw ServerFailure(e.message ?? e.code);
    }
  }

  Future<AppUserModel> signUp({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? phone,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final fbUser = cred.user!;
      await fbUser.updateDisplayName(name);
      final model = AppUserModel(
        uid: fbUser.uid,
        email: email.trim(),
        name: name,
        role: role,
        phone: phone,
      );
      await _users.doc(fbUser.uid).set({
        ...model.toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      return model;
    } on FirebaseAuthException catch (e) {
      throw _mapAuthError(e);
    } on FirebaseException catch (e) {
      // Firestore write failed (e.g. rules) after the Auth account was created.
      throw ServerFailure(e.message ?? e.code);
    }
  }

  Future<AppUserModel> logIn({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return loadProfile(cred.user!);
    } on FirebaseAuthException catch (e) {
      throw _mapAuthError(e);
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _mapAuthError(e);
    }
  }

  Future<void> logOut() => _auth.signOut();

  /// Best-effort — a push token write must never surface an error to the UI.
  Future<void> saveFcmToken(String uid, String token) async {
    try {
      await _users.doc(uid).update({'fcmToken': token});
    } on FirebaseException catch (e) {
      debugPrint('[Auth] saveFcmToken FirebaseException: ${e.code} — ${e.message}');
    }
  }

  AuthFailure _mapAuthError(FirebaseAuthException e) {
    final code = switch (e.code) {
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' =>
        AuthFailureCode.invalidCredentials,
      'email-already-in-use' => AuthFailureCode.emailInUse,
      'weak-password' => AuthFailureCode.weakPassword,
      'invalid-email' => AuthFailureCode.invalidEmail,
      'user-disabled' => AuthFailureCode.userDisabled,
      'network-request-failed' => AuthFailureCode.network,
      _ => AuthFailureCode.unknown,
    };
    if (code == AuthFailureCode.unknown) {
      debugPrint('[Auth] unmapped FirebaseAuthException: ${e.code} — ${e.message}');
    }
    return AuthFailure(code, e.message ?? e.code);
  }
}
