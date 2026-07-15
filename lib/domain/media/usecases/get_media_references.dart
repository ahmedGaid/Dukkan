import '../entities/media_reference.dart';
import '../repositories/media_repository.dart';

/// Thin pass-through.
class GetMediaReferences {
  const GetMediaReferences(this._repository);

  final MediaRepository _repository;

  Future<List<MediaReference>> call() => _repository.getReferences();
}
