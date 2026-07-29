import '../repositories/admin_promos_repository.dart';

class DeleteBanner {
  const DeleteBanner(this._repository);

  final AdminPromosRepository _repository;

  Future<void> call(String id) => _repository.deleteBanner(id);
}
