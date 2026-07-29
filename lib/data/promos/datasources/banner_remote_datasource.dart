import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/promo_banner_model.dart';

/// Realtime feed for the home carousel. Queries `isActive == true` only —
/// the `startsAt`/`endsAt` date window is filtered client-side (a two-field
/// range query needs a composite index Firestore can't express here; the
/// collection is small, so filtering post-fetch is cheap). Sort happens in
/// the same pass.
class BannerRemoteDataSource {
  BannerRemoteDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _banners =>
      _firestore.collection('banners');

  Stream<List<PromoBannerModel>> watchActiveBanners() {
    return _banners.where('isActive', isEqualTo: true).snapshots().map(
          (snap) => snap.docs
              .map((d) => PromoBannerModel.fromFirestore(d.id, d.data()))
              .toList(),
        );
  }
}
