import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/errors/failures.dart';
import '../models/product_model.dart';

class ProductRemoteDataSource {
  ProductRemoteDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _products =>
      _firestore.collection('products');

  Stream<List<ProductModel>> watchProductsByShop(String shopId) {
    return _products.where('shopId', isEqualTo: shopId).snapshots().map(
          (snap) => snap.docs
              .map((doc) => ProductModel.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<List<ProductModel>> watchAllProducts() {
    return _products.snapshots().map(
          (snap) => snap.docs
              .map((doc) => ProductModel.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<ProductModel> getProduct(String productId) async {
    final doc = await _products.doc(productId).get();
    final data = doc.data();
    if (data == null) {
      throw ServerFailure('Product $productId not found');
    }
    return ProductModel.fromFirestore(doc.id, data);
  }
}
