import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/errors/failures.dart';
import '../../shop/models/shop_model.dart';

/// Firestore-direct reads/writes of `/shops` for the console. Unlike
/// `AdminUsersRemoteDataSource`, no permission-gated read is needed — `/shops`
/// read is public (`allow read: if true`); writes here rely on the
/// `shops.update` rules branch (see `firestore.rules`), never a Worker route,
/// except ownership transfer (Worker-only — see `AdminApiDataSource`).
class AdminShopsRemoteDataSource {
  AdminShopsRemoteDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _shops =>
      _firestore.collection('shops');

  Future<List<ShopModel>> getAllShops() async {
    try {
      final snap = await _shops.orderBy('name').get();
      return snap.docs
          .map((d) => ShopModel.fromFirestore(d.id, d.data()))
          .toList(growable: false);
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }

  Future<ShopModel?> getShopById(String shopId) async {
    try {
      final doc = await _shops.doc(shopId).get();
      final data = doc.data();
      if (data == null) return null;
      return ShopModel.fromFirestore(doc.id, data);
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }

  Future<void> patchFields(String shopId, Map<String, dynamic> fields) async {
    try {
      await _shops.doc(shopId).update(fields);
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }

  Future<void> softDelete(String shopId, String actorUid) async {
    try {
      await _shops.doc(shopId).update({
        'deleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': actorUid,
      });
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }

  Future<void> restore(String shopId) async {
    try {
      await _shops.doc(shopId).update({
        'deleted': false,
        'deletedAt': null,
        'deletedBy': null,
      });
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }

  Future<ShopModel> createShop(ShopModel shop) async {
    try {
      final doc = await _shops.add(shop.toFirestore());
      return ShopModel.fromFirestore(doc.id, shop.toFirestore());
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }
}
