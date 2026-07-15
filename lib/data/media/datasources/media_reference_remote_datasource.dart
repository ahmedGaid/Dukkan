import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/config/app_config.dart';
import '../../../core/errors/failures.dart';
import '../../../domain/media/entities/media_reference.dart';

/// Firestore-direct scan of every collection that holds an image URL —
/// `shops.logoUrl`, `products.imageUrl` (incl. soft-deleted — no `deleted`
/// filter, orphan/broken finders must see them too), `drivers.idDocUrl`,
/// `banners.imageUrl` (collection doesn't exist yet, Session 16 — an empty
/// snapshot is not an error). Read-only; gated by `images.delete` in
/// `firestore.rules` alongside every other admin read/write in this section.
class MediaReferenceRemoteDataSource {
  MediaReferenceRemoteDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  Future<List<MediaReference>> getReferences() async {
    try {
      final results = await Future.wait([
        _firestore.collection('shops').get(),
        _firestore.collection('products').get(),
        _firestore.collection('drivers').get(),
      ]);

      final refs = <MediaReference>[];
      _addRefs(refs, results[0], 'shop', 'logoUrl');
      _addRefs(refs, results[1], 'product', 'imageUrl');
      _addRefs(refs, results[2], 'driver', 'idDocUrl');
      refs.addAll(await _getBannerRefs());
      return refs;
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }

  /// `/banners` has no `firestore.rules` entry until Session 16 lands it — it
  /// falls to the catch-all `allow read: if false`, so a permission-denied
  /// here means "the collection doesn't exist yet", not a real failure.
  Future<List<MediaReference>> _getBannerRefs() async {
    try {
      final snap = await _firestore.collection('banners').get();
      final refs = <MediaReference>[];
      _addRefs(refs, snap, 'banner', 'imageUrl');
      return refs;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') return const [];
      rethrow;
    }
  }

  void _addRefs(
    List<MediaReference> out,
    QuerySnapshot<Map<String, dynamic>> snap,
    String docType,
    String field,
  ) {
    for (final doc in snap.docs) {
      final url = doc.data()[field] as String?;
      if (url == null || url.isEmpty) continue;
      out.add(MediaReference(url: url, key: _keyFor(url), docType: docType, docId: doc.id));
    }
  }

  /// Strips `AppConfig.mediaPublicBaseUrl` off [url] to get the R2 key, or
  /// null when [url] isn't an R2 object at all (e.g. a bundled `assets/…`
  /// demo-seed path) — the finders must not flag those as broken.
  String? _keyFor(String url) {
    final base = AppConfig.mediaPublicBaseUrl.replaceFirst(RegExp(r'/$'), '');
    if (!url.startsWith('$base/')) return null;
    return url.substring(base.length + 1);
  }
}
