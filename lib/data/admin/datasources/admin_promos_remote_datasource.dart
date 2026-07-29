import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/errors/failures.dart';
import '../../promos/models/coupon_model.dart';
import '../../promos/models/promo_banner_model.dart';

/// Firestore-direct reads/writes of `/coupons` + `/banners` for the console
/// (FC16). Both collections are small — no pagination, mirrors
/// `AdminTaxonomyRemoteDataSource`.
class AdminPromosRemoteDataSource {
  AdminPromosRemoteDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _coupons =>
      _firestore.collection('coupons');

  CollectionReference<Map<String, dynamic>> get _banners =>
      _firestore.collection('banners');

  // --- Coupons ---

  Future<List<CouponModel>> getAllCoupons() async {
    try {
      final snap = await _coupons.orderBy(FieldPath.documentId).get();
      return snap.docs
          .map((d) => CouponModel.fromFirestore(d.id, d.data()))
          .toList(growable: false);
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }

  /// The doc id IS the code — a create on an already-used code is rejected
  /// rather than silently overwritten.
  Future<void> createCoupon(String code, Map<String, dynamic> fields) async {
    try {
      final ref = _coupons.doc(code);
      if ((await ref.get()).exists) {
        throw const ServerFailure('coupon_code_taken');
      }
      await ref.set(fields);
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }

  Future<void> setCouponFields(String code, Map<String, dynamic> fields) async {
    try {
      await _coupons.doc(code).update(fields);
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }

  Future<void> deleteCoupon(String code) async {
    try {
      await _coupons.doc(code).delete();
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }

  // --- Banners ---

  Future<List<PromoBannerModel>> getAllBanners() async {
    try {
      final snap = await _banners.orderBy('sort').get();
      return snap.docs
          .map((d) => PromoBannerModel.fromFirestore(d.id, d.data()))
          .toList(growable: false);
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }

  Future<void> createBanner(Map<String, dynamic> fields) async {
    try {
      await _banners.add(fields);
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }

  Future<void> setBannerFields(String id, Map<String, dynamic> fields) async {
    try {
      await _banners.doc(id).update(fields);
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }

  Future<void> swapBannerSort({
    required String aId,
    required int aSort,
    required String bId,
    required int bSort,
  }) async {
    try {
      final batch = _firestore.batch();
      batch.update(_banners.doc(aId), {'sort': aSort});
      batch.update(_banners.doc(bId), {'sort': bSort});
      await batch.commit();
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }

  Future<void> deleteBanner(String id) async {
    try {
      await _banners.doc(id).delete();
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }
}
