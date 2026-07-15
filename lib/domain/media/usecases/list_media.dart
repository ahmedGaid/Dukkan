import '../entities/media_page.dart';
import '../repositories/media_repository.dart';

/// Thin pass-through.
class ListMedia {
  const ListMedia(this._repository);

  final MediaRepository _repository;

  Future<MediaPage> call({String? folder, String? cursor}) =>
      _repository.list(folder: folder, cursor: cursor);
}
