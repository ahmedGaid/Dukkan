import '../entities/migration_status.dart';
import '../repositories/devtools_repository.dart';

class GetMigrations {
  const GetMigrations(this._repository);

  final DevToolsRepository _repository;

  Future<List<MigrationStatus>> call() => _repository.getMigrations();
}
