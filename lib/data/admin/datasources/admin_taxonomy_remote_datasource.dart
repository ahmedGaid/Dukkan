import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/errors/failures.dart';
import '../../taxonomy/models/category_model.dart';

/// Firestore-direct reads/writes of `/categories` for the console (FC9).
/// Unlike the read-only `TaxonomyRemoteDataSource`, this returns every
/// category (hidden included) and exposes the console's mutations; writes
/// rely on the `taxonomy.edit` rules branch, never a Worker route.
class AdminTaxonomyRemoteDataSource {
  AdminTaxonomyRemoteDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _categories =>
      _firestore.collection('categories');

  Future<List<CategoryModel>> getAllCategories() async {
    try {
      final snap = await _categories.orderBy('sort').get();
      return snap.docs
          .map((d) => CategoryModel.fromFirestore(d.id, d.data()))
          .toList(growable: false);
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }

  Future<void> createCategory(Map<String, dynamic> fields) async {
    try {
      await _categories.add(fields);
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }

  Future<void> patchFields(
    String categoryId,
    Map<String, dynamic> fields,
  ) async {
    try {
      await _categories.doc(categoryId).update(fields);
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }

  Future<void> swapSort({
    required String aId,
    required int aSort,
    required String bId,
    required int bSort,
  }) async {
    try {
      final batch = _firestore.batch();
      batch.update(_categories.doc(aId), {'sort': aSort});
      batch.update(_categories.doc(bId), {'sort': bSort});
      await batch.commit();
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      await _categories.doc(categoryId).delete();
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }

  Future<int> countProductsInCategory(String categoryId) async {
    try {
      final agg = await _firestore
          .collection('products')
          .where('category', isEqualTo: categoryId)
          .count()
          .get();
      return agg.count ?? 0;
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }
}
