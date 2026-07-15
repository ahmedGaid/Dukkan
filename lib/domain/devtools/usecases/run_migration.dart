import '../repositories/devtools_repository.dart';

class RunMigration {
  const RunMigration(this._repository);

  final DevToolsRepository _repository;

  Future<void> call(String id) => _repository.runMigration(id);
}
