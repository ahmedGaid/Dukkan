import '../repositories/media_repository.dart';

/// Thin pass-through. Permanent — the caller must confirm before calling.
class DeleteMedia {
  const DeleteMedia(this._repository);

  final MediaRepository _repository;

  Future<void> call(List<String> keys) => _repository.delete(keys);
}
