import '../repositories/devtools_repository.dart';

class ClearDevToolsCaches {
  const ClearDevToolsCaches(this._repository);

  final DevToolsRepository _repository;

  Future<void> call() => _repository.clearCaches();
}
