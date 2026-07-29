import '../entities/promo_banner.dart';

/// Customer-facing banner feed (home carousel). Realtime so deactivating a
/// banner from the console hides it without an app update (FC16 Task B smoke
/// test) — mirrors the promo-products stream's live-update contract.
abstract class BannerRepository {
  /// Active banners only, date-window-filtered, sorted by `sort`.
  Stream<List<PromoBanner>> watchActiveBanners();
}
