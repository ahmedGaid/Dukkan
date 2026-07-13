import '../../shop/entities/shop.dart';

/// Founder Console shop management (FC7). Reads are Firestore-direct and
/// unfiltered — `/shops` read is public (`allow read: if true`), so there is
/// no permission gate to route through, unlike [AdminUsersRepository]. Every
/// mutation except [transferOwnership] is also Firestore-direct, gated by the
/// `shops.update` rules branch; only an ownerUid change is Worker-routed (the
/// rules forbid a client from ever touching that field).
abstract class AdminShopsRepository {
  /// Every shop doc, unfiltered (including pending/suspended/deleted) — the
  /// customer-facing filter lives only in `ShopRepositoryImpl`.
  Future<List<Shop>> getAllShops();

  /// Single shop by id, unfiltered; null if it doesn't exist.
  Future<Shop?> getShopById(String shopId);

  /// `pending` | `active` | `suspended`. [reason] is required by the console
  /// UI when rejecting a pending shop, optional otherwise.
  Future<void> setStatus({required String shopId, required String status, String? reason});

  Future<void> setFeatured({required String shopId, required bool value});

  Future<void> setVerified({required String shopId, required bool value});

  /// Everything else editable on the detail page: name/nameAr/address/isOpen/
  /// logo/hoursNote. ownerUid is never touched here.
  Future<void> updateDetails({
    required String shopId,
    required String name,
    required String nameAr,
    required String address,
    required bool isOpen,
    String? logoUrl,
    String? hoursNote,
  });

  /// [actorUid] is self-reported by the client (this write isn't Worker-
  /// verified) — acceptable for FC7, matching the trust level of every other
  /// Firestore-direct console mutation here.
  Future<void> softDelete({required String shopId, required String actorUid});

  Future<void> restore(String shopId);

  /// Console-created shop for a named owner (perm `shops.update`, no
  /// self-ownerUid rule requirement). Defaults to `active` — staff has
  /// already vetted the owner, unlike self-serve onboarding which always
  /// lands `pending`.
  Future<Shop> createShop({
    required String ownerUid,
    required String name,
    required String nameAr,
    required String address,
    String? logoUrl,
    bool isOpen = true,
    List<String> categories = const [],
    String status = 'active',
  });

  /// Worker-routed (`/admin/shops/transfer`, perm `shops.transfer`) — the only
  /// path that can change `ownerUid`. Returns the old owner's uid and whether
  /// they still carry `role: owner` with no shop left (a hint the console
  /// shows; persona role cleanup stays a manual Session-6 action).
  Future<Map<String, dynamic>> transferOwnership({
    required String shopId,
    required String newOwnerUid,
  });
}
