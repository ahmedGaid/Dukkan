import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../core/config/app_config.dart';

/// Asks the Worker to push a notification about an order. Kept behind an
/// interface so the repository (and its tests) never touch `dart:io` or
/// Firebase — mirrors `ImageUploadRemoteDataSource`.
abstract class NotificationRemoteDataSource {
  Future<void> notify({
    required String orderId,
    required String type,
    required String title,
    required String body,
  });
}

/// Every failure here is swallowed and logged, never thrown — a push is a
/// nice-to-have side effect of placing/advancing an order, not part of that
/// order's own success/failure contract.
class HttpNotificationRemoteDataSource implements NotificationRemoteDataSource {
  HttpNotificationRemoteDataSource({required FirebaseAuth auth}) : _auth = auth;

  final FirebaseAuth _auth;

  @override
  Future<void> notify({
    required String orderId,
    required String type,
    required String title,
    required String body,
  }) async {
    if (!AppConfig.workerConfigured) return;
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final token = await user.getIdToken();
      if (token == null) return;

      final uri = Uri.parse('${AppConfig.workerBaseUrl}/notify');
      final client = HttpClient();
      try {
        final request = await client.postUrl(uri);
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
        request.headers.contentType = ContentType.json;
        request.add(utf8.encode(jsonEncode({
          'orderId': orderId,
          'type': type,
          'title': title,
          'body': body,
        })));
        final response = await request.close();
        await response.drain<void>();
        if (response.statusCode != HttpStatus.ok) {
          debugPrint('[Notify] worker returned ${response.statusCode}');
        }
      } finally {
        client.close(force: true);
      }
    } catch (e) {
      debugPrint('[Notify] failed: $e');
    }
  }
}
