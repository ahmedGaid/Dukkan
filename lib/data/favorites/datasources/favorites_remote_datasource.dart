import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/favorites/entities/favorites.dart';

class FavoritesRemoteDataSource {
  FavoritesRemoteDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection('users').doc(uid);

  Stream<Favorites> watchFavorites(String uid) {
    return _userDoc(uid).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return const Favorites.empty();
      return Favorites(
        shopIds: Set<String>.from(data['favoriteShopIds'] as List? ?? const []),
        productIds:
            Set<String>.from(data['favoriteProductIds'] as List? ?? const []),
      );
    });
  }

  Future<void> toggleFavoriteShop(String uid, String shopId) =>
      _toggle(uid, 'favoriteShopIds', shopId);

  Future<void> toggleFavoriteProduct(String uid, String productId) =>
      _toggle(uid, 'favoriteProductIds', productId);

  /// Reads-then-flips inside a transaction so two rapid taps (or a stale
  /// client) can't desync from `arrayUnion`/`arrayRemove` racing each other.
  Future<void> _toggle(String uid, String field, String id) async {
    final doc = _userDoc(uid);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(doc);
      final current = Set<String>.from(
        (snap.data()?[field] as List?) ?? const [],
      );
      tx.update(doc, {
        field: current.contains(id)
            ? FieldValue.arrayRemove([id])
            : FieldValue.arrayUnion([id]),
      });
    });
  }
}
