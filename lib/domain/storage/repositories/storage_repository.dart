import 'dart:typed_data';

/// Uploads binary assets (images) to remote storage and returns their public
/// URL. Backed by the Cloudflare Worker + R2 — the app never holds storage
/// credentials. Throws a [Failure] on any error.
abstract class StorageRepository {
  /// Uploads [bytes] of the given [contentType] (e.g. `image/jpeg`) into
  /// [folder] (a [StorageFolder] value). Returns the stored file's public URL.
  Future<String> uploadImage({
    required Uint8List bytes,
    required String contentType,
    required String folder,
  });
}
