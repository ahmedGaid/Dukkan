import '../repositories/admin_promos_repository.dart';

class SetBannerActive {
  const SetBannerActive(this._repository);

  final AdminPromosRepository _repository;

  Future<void> call({required String id, required bool value}) =>
      _repository.setBannerActive(id: id, value: value);
}
