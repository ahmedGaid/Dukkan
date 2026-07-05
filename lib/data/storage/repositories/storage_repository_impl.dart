import 'dart:typed_data';

import '../../../core/errors/failures.dart';
import '../../../core/network/network_info.dart';
import '../../../domain/storage/repositories/storage_repository.dart';
import '../datasources/image_upload_remote_datasource.dart';

/// Gates uploads on connectivity and normalizes errors to [Failure]s. The remote
/// datasource does the actual HTTP work; this layer owns the "am I online?"
/// check and the error contract the UI relies on.
class StorageRepositoryImpl implements StorageRepository {
  StorageRepositoryImpl(this._remote, this._network);

  final ImageUploadRemoteDataSource _remote;
  final NetworkInfo _network;

  @override
  Future<String> uploadImage({
    required Uint8List bytes,
    required String contentType,
    required String folder,
  }) async {
    if (!await _network.isConnected) {
      throw const NetworkFailure('No connection');
    }
    try {
      return await _remote.upload(
        bytes: bytes,
        contentType: contentType,
        folder: folder,
      );
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
