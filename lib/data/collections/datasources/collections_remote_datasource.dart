import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/shop_collection_model.dart';

class CollectionsRemoteDataSource {
  CollectionsRemoteDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collections(String shopId) =>
      _firestore.collection('shops').doc(shopId).collection('collections');

  Stream<List<ShopCollectionModel>> watchCollections(String shopId) {
    return _collections(shopId).orderBy('sort').snapshots().map(
          (snap) => snap.docs
              .map((doc) =>
                  ShopCollectionModel.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<List<ShopCollectionModel>> getCollections(String shopId) async {
    final snap = await _collections(shopId).orderBy('sort').get();
    return snap.docs
        .map((doc) => ShopCollectionModel.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  Future<ShopCollectionModel> createCollection(
    String shopId, {
    required String nameAr,
    required String nameEn,
    required int sort,
  }) async {
    final model = ShopCollectionModel(
      id: '',
      nameAr: nameAr,
      nameEn: nameEn,
      sort: sort,
    );
    final doc = await _collections(shopId).add(model.toFirestore());
    return ShopCollectionModel(
      id: doc.id,
      nameAr: nameAr,
      nameEn: nameEn,
      sort: sort,
    );
  }

  Future<void> renameCollection(
    String shopId,
    String collectionId, {
    required String nameAr,
    required String nameEn,
  }) =>
      _collections(shopId)
          .doc(collectionId)
          .update({'nameAr': nameAr, 'nameEn': nameEn});

  Future<void> deleteCollection(String shopId, String collectionId) =>
      _collections(shopId).doc(collectionId).delete();
}
