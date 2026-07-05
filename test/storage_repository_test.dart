import 'dart:typed_data';

import 'package:dukkan/core/errors/failures.dart';
import 'package:dukkan/core/network/network_info.dart';
import 'package:dukkan/data/storage/datasources/image_upload_remote_datasource.dart';
import 'package:dukkan/data/storage/repositories/storage_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

/// Forces the connectivity answer so the offline branch is reachable without a
/// real probe.
class _FakeNetwork implements NetworkInfo {
  _FakeNetwork(this._connected);
  final bool _connected;
  @override
  Future<bool> get isConnected async => _connected;
}

/// Stands in for the HTTP uploader — records calls and can be made to throw.
class _FakeUploader implements ImageUploadRemoteDataSource {
  Object? throwThis;
  String returnUrl = 'https://cdn.example/x.jpg';
  int calls = 0;

  @override
  Future<String> upload({
    required Uint8List bytes,
    required String contentType,
    required String folder,
  }) async {
    calls++;
    if (throwThis != null) throw throwThis!;
    return returnUrl;
  }
}

void main() {
  final bytes = Uint8List.fromList([1, 2, 3]);

  Future<String> run(StorageRepositoryImpl repo) => repo.uploadImage(
        bytes: bytes,
        contentType: 'image/jpeg',
        folder: 'shop-logos',
      );

  test('offline throws NetworkFailure without hitting the uploader', () async {
    final uploader = _FakeUploader();
    final repo = StorageRepositoryImpl(uploader, _FakeNetwork(false));

    await expectLater(run(repo), throwsA(isA<NetworkFailure>()));
    expect(uploader.calls, 0);
  });

  test('online returns the uploaded URL', () async {
    final uploader = _FakeUploader()..returnUrl = 'https://cdn/y.png';
    final repo = StorageRepositoryImpl(uploader, _FakeNetwork(true));

    expect(await run(repo), 'https://cdn/y.png');
    expect(uploader.calls, 1);
  });

  test('a Failure from the uploader is rethrown unchanged', () async {
    final uploader = _FakeUploader()..throwThis = const ServerFailure('boom');
    final repo = StorageRepositoryImpl(uploader, _FakeNetwork(true));

    await expectLater(run(repo), throwsA(isA<ServerFailure>()));
  });

  test('a non-Failure error is wrapped as ServerFailure', () async {
    final uploader = _FakeUploader()..throwThis = Exception('io');
    final repo = StorageRepositoryImpl(uploader, _FakeNetwork(true));

    await expectLater(run(repo), throwsA(isA<ServerFailure>()));
  });
}
