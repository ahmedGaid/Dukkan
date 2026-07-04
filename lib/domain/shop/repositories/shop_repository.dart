import '../entities/shop.dart';

/// Shop catalog boundary. Methods that can fail throw a [Failure] — see
/// `core/errors/failures.dart` (no `Either`/`dartz`, matches auth).
abstract class ShopRepository {
  /// All shops for the home listing. Realtime when online; a single cached
  /// snapshot when offline (Shoppy lesson: online -> remote, offline -> cache).
  Stream<List<Shop>> watchShops();

  /// One shop's live detail (isOpen toggle, S1 edits) — falls back to the
  /// cached list entry when offline.
  Stream<Shop> watchShop(String shopId);
}
