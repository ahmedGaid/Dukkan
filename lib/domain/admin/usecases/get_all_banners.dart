import '../../promos/entities/promo_banner.dart';
import '../repositories/admin_promos_repository.dart';

class GetAllBanners {
  const GetAllBanners(this._repository);

  final AdminPromosRepository _repository;

  Future<List<PromoBanner>> call() => _repository.getAllBanners();
}
