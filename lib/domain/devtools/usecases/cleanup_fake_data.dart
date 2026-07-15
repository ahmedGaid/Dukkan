import '../repositories/devtools_repository.dart';

class CleanupFakeData {
  const CleanupFakeData(this._repository);

  final DevToolsRepository _repository;

  Future<int> call() => _repository.cleanupFakeData();
}
