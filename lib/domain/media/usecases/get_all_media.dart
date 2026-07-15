import '../entities/media_object.dart';
import '../repositories/media_repository.dart';

/// Thin pass-through.
class GetAllMedia {
  const GetAllMedia(this._repository);

  final MediaRepository _repository;

  Future<List<MediaObject>> call() => _repository.listAll();
}
