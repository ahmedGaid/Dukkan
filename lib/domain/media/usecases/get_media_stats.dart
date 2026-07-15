import '../entities/media_stats.dart';
import '../repositories/media_repository.dart';

/// Thin pass-through.
class GetMediaStats {
  const GetMediaStats(this._repository);

  final MediaRepository _repository;

  Future<MediaStats> call() => _repository.stats();
}
