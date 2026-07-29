import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/errors/failures.dart';
import '../models/coupon_model.dart';

/// Checkout-side coupon lookup + redemption bump. Doc id IS the uppercase
/// code, so a lookup is a single `.doc(code).get()` — no query needed.
class CouponRemoteDataSource {
  CouponRemoteDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _coupons =>
      _firestore.collection('coupons');

  Future<CouponModel?> getByCode(String code) async {
    try {
      final snap = await _coupons.doc(code).get();
      if (!snap.exists) return null;
      return CouponModel.fromFirestore(snap.id, snap.data()!);
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }

  /// Rules only allow `usedCount` to move by exactly +1 — `increment(1)`
  /// satisfies that shape (mirrors the shop rating bump).
  Future<void> redeem(String code) async {
    try {
      await _coupons.doc(code).update({'usedCount': FieldValue.increment(1)});
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }
}
