import '../repositories/devtools_repository.dart';

class RunDemoSeed {
  const RunDemoSeed(this._repository);

  final DevToolsRepository _repository;

  Future<void> call({
    required bool rbac,
    required bool catalog,
    required bool customers,
  }) =>
      _repository.runDemoSeed(rbac: rbac, catalog: catalog, customers: customers);
}
