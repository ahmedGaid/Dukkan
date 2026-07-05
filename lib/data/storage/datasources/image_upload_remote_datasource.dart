import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../core/config/app_config.dart';
import '../../../core/errors/failures.dart';

/// Uploads image bytes to the Cloudflare Worker that fronts R2. Kept behind an
/// interface so the repository (and its tests) never touch `dart:io` or Firebase
/// — this concrete impl is only ever built at app runtime.
abstract class ImageUploadRemoteDataSource {
  /// POSTs [bytes] to the Worker and returns the stored file's public URL.
  Future<String> upload({
    required Uint8List bytes,
    required String contentType,
    required String folder,
  });
}

class HttpImageUploadRemoteDataSource implements ImageUploadRemoteDataSource {
  HttpImageUploadRemoteDataSource({required FirebaseAuth auth}) : _auth = auth;

  final FirebaseAuth _auth;

  @override
  Future<String> upload({
    required Uint8List bytes,
    required String contentType,
    required String folder,
  }) async {
    if (!AppConfig.workerConfigured) {
      throw const ServerFailure('Upload Worker URL not configured');
    }
    final user = _auth.currentUser;
    if (user == null) throw const ServerFailure('Not signed in');
    final token = await user.getIdToken();
    if (token == null) throw const ServerFailure('No auth token');

    final uri = Uri.parse('${AppConfig.workerBaseUrl}/upload')
        .replace(queryParameters: {'folder': folder});

    // dart:io HttpClient (matches `NetworkInfoImpl`; no new dependency). This
    // path is Android/iOS-only — the owner app runs on device, not web.
    final client = HttpClient();
    try {
      final request = await client.postUrl(uri);
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      request.headers.contentType = ContentType.parse(contentType);
      request.add(bytes);

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode != HttpStatus.ok) {
        debugPrint('[Upload] worker ${response.statusCode}: $body');
        throw ServerFailure('Upload failed (${response.statusCode})');
      }
      final url = (jsonDecode(body) as Map<String, dynamic>)['url'] as String?;
      if (url == null || url.isEmpty) {
        throw const ServerFailure('Upload returned no URL');
      }
      return url;
    } on SocketException catch (e) {
      throw NetworkFailure(e.message);
    } finally {
      client.close(force: true);
    }
  }
}
