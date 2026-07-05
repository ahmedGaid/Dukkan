import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/errors/failures.dart';
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
    final doc = await _shops.add(shop.toFirestore());
    return ShopModel(
      id: doc.id,
      ownerUid: shop.ownerUid,
      name: shop.name,
      nameAr: shop.nameAr,
      logoUrl: shop.logoUrl,
      address: shop.address,
      isOpen: shop.isOpen,
      categories: shop.categories,
    );
  }
}
