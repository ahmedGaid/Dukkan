import '../../promos/entities/promo_banner.dart';
import '../repositories/admin_promos_repository.dart';

class UpdateBanner {
  const UpdateBanner(this._repository);

  final AdminPromosRepository _repository;

  Future<void> call(PromoBanner banner) => _repository.updateBanner(banner);
}
