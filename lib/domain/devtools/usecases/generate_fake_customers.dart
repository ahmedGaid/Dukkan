import '../repositories/devtools_repository.dart';

class GenerateFakeCustomers {
  const GenerateFakeCustomers(this._repository);

  final DevToolsRepository _repository;

  Future<List<String>> call(int count) => _repository.generateFakeCustomers(count);
}
