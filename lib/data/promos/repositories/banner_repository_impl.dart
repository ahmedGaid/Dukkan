import '../../../domain/promos/entities/promo_banner.dart';
import '../../../domain/promos/repositories/banner_repository.dart';
import '../datasources/banner_remote_datasource.dart';

class BannerRepositoryImpl implements BannerRepository {
  BannerRepositoryImpl(this._remote);

  final BannerRemoteDataSource _remote;

  @override
  Stream<List<PromoBanner>> watchActiveBanners() {
    return _remote.watchActiveBanners().map((banners) {
      final now = DateTime.now();
      final live = banners.where((b) => b.isLiveAt(now)).toList()
        ..sort((a, b) => a.sort.compareTo(b.sort));
      return live;
    });
  }
}
