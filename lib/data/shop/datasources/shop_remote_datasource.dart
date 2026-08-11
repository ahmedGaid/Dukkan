import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/errors/failures.dart';
import '../../../core/firestore/platform_stats.dart';
import '../models/shop_model.dart';

class ShopRemoteDataSource {
  ShopRemoteDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _shops =>
      _firestore.collection('shops');

  Stream<List<ShopModel>> watchShops() {
    return _shops.snapshots().map(
          (snap) => snap.docs
              .map((doc) => ShopModel.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<ShopModel> watchShop(String shopId) {
    return _shops.doc(shopId).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) {
        throw ServerFailure('Shop $shopId not found');
      }
      return ShopModel.fromFirestore(doc.id, data);
    });
  }

  Future<ShopModel?> getShopByOwner(String ownerUid) async {
    final snap =
        await _shops.where('ownerUid', isEqualTo: ownerUid).limit(1).get();
    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    return ShopModel.fromFirestore(doc.id, doc.data());
  }

  Future<ShopModel> createShop(ShopModel shop) async {
    // `createdAt` (FC17, additive) — only written going forward; the
    // returned in-memory model doesn't resolve the server sentinel, matching
    // every other admin repo's "no local cache, re-fetch if you need truth"
    // contract. Reports queries read it straight from Firestore.
    final doc = await _shops.add({
      ...shop.toFirestore(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    bumpGlobalStats(_firestore, {
      'totalShops': 1,
      if (shop.status == 'pending') 'pendingShops': 1,
    });
    return ShopModel.fromFirestore(doc.id, shop.toFirestore());
  }
}
