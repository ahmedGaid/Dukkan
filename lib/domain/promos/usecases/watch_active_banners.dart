import '../entities/promo_banner.dart';
import '../repositories/banner_repository.dart';

class WatchActiveBanners {
  const WatchActiveBanners(this._repository);

  final BannerRepository _repository;

  Stream<List<PromoBanner>> call() => _repository.watchActiveBanners();
}
