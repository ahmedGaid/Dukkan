import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../core/config/app_config.dart';
import '../../../core/errors/failures.dart';

/// Talks to the Worker's privileged `/admin/*` endpoints (Founder Console
/// back-office ops). Mirrors the notify/upload datasources' HTTP style
/// (`dart:io` [HttpClient], Bearer Firebase ID token) so the repository layer
/// and its tests never touch `dart:io` or Firebase directly.
///
/// Two contracts live here:
///  * [post] — for operations that MUST succeed. Throws a typed [ServerFailure]
///    on any non-2xx (or misconfig / not-signed-in) so the BLoC can surface it.
///  * [reportAudit] — best-effort, fire-and-forget audit reporting for
///    client-direct (rules-guarded) mutations. Swallows every error, exactly
///    like the notify datasource — a failed audit report must never fail the
///    mutation it describes.
class AdminApiDataSource {
  AdminApiDataSource({required FirebaseAuth auth}) : _auth = auth;

  final FirebaseAuth _auth;

  /// POSTs [body] to `/admin/[path]` with the caller's Firebase ID token and
  /// returns the decoded JSON object. Throws [ServerFailure] when the Worker
  /// is not configured, no user is signed in, or the response is non-2xx.
  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    if (!AppConfig.workerConfigured) {
      throw const ServerFailure('worker_not_configured');
    }
    final user = _auth.currentUser;
    if (user == null) throw const ServerFailure('not_signed_in');

    final token = await user.getIdToken();
    if (token == null) throw const ServerFailure('no_id_token');

    final uri = Uri.parse('${AppConfig.workerBaseUrl}/admin/$path');
    final client = HttpClient();
    try {
      final request = await client.postUrl(uri);
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      request.headers.contentType = ContentType.json;
      request.add(utf8.encode(jsonEncode(body)));
      final response = await request.close();
      final text = await response.transform(utf8.decoder).join();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (text.isEmpty) return const <String, dynamic>{};
        final decoded = jsonDecode(text);
        return decoded is Map<String, dynamic> ? decoded : const <String, dynamic>{};
      }
      throw ServerFailure(_errorCode(response.statusCode, text));
    } on SocketException catch (e) {
      throw ServerFailure('network_error: ${e.message}');
    } finally {
      client.close(force: true);
    }
  }

  /// Fire-and-forget audit report for a client-direct (rules-guarded)
  /// mutation. The Worker stamps the actor from the verified token and marks
  /// the entry `reported: true`. Swallows all errors by design.
  Future<void> reportAudit({
    required String action,
    required String targetType,
    required String targetId,
    Object? before,
    Object? after,
    String? reason,
  }) async {
    try {
      await post('audit', {
        'action': action,
        'targetType': targetType,
        'targetId': targetId,
        'before': ?before,
        'after': ?after,
        'reason': ?reason,
      });
    } catch (e) {
      debugPrint('[AdminAudit] report failed: $e');
    }
  }

  /// Maps a non-2xx status to a stable technical code (logs only — the UI maps
  /// failure type to a localized string, never this raw value).
  String _errorCode(int status, String text) {
    switch (status) {
      case 401:
        return 'unauthorized';
      case 403:
        return 'forbidden';
      case 404:
        return 'not_found';
      default:
        return 'server_error_$status';
    }
  }
}
