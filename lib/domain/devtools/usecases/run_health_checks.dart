import '../entities/health_check_result.dart';
import '../repositories/devtools_repository.dart';

class RunHealthChecks {
  const RunHealthChecks(this._repository);

  final DevToolsRepository _repository;

  Future<List<HealthCheckResult>> call() => _repository.runHealthChecks();
}
