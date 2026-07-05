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

  /// The shop owned by [ownerUid], or null if they haven't onboarded one yet.
  /// One-shot (not a stream) — used at the S1b onboarding gate, not for a
  /// live-updating screen.
  Future<Shop?> getShopByOwner(String ownerUid);

  /// Creates a new shop for [ownerUid] (S1b onboarding). Requires connectivity
  /// — no offline queue for this write.
  Future<Shop> createShop({
    required String ownerUid,
    required String name,
    required String nameAr,
    required String address,
    String? logoUrl,
    bool isOpen = true,
    List<String> categories = const [],
  });
}
