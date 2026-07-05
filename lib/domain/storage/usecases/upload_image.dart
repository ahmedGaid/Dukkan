import 'dart:typed_data';

import '../repositories/storage_repository.dart';

/// Uploads an image and returns its public URL. Thin pass-through — a BLoC calls
/// this, never the repository directly (Clean Architecture rule).
class UploadImage {
  const UploadImage(this._repo);

  final StorageRepository _repo;

  Future<String> call({
    required Uint8List bytes,
    required String contentType,
    required String folder,
  }) =>
      _repo.uploadImage(bytes: bytes, contentType: contentType, folder: folder);
}
