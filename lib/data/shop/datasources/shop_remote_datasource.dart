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
}
