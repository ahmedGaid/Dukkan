import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/category_model.dart';

class TaxonomyRemoteDataSource {
  TaxonomyRemoteDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  /// One read of the whole (small, fixed) tree, sorted by `sort`. No
  /// pagination, no join queries — subcategories are embedded per category.
  Future<List<CategoryModel>> getTaxonomy() async {
    final snap =
        await _firestore.collection('categories').orderBy('sort').get();
    return snap.docs
        .map((doc) => CategoryModel.fromFirestore(doc.id, doc.data()))
        .toList();
  }
}
