import '../entities/media_object.dart';
import '../entities/media_page.dart';
import '../entities/media_reference.dart';
import '../entities/media_stats.dart';

/// Founder Console media library (FC14). Browse/stats/delete are
/// Worker-routed (`/admin/media/*` — R2 isn't reachable from Firestore rules
/// at all, so there is no client-direct path here, unlike most other
/// sections); the unused/broken finders additionally read the four
/// Firestore collections that hold image URLs.
abstract class MediaRepository {
  Future<MediaPage> list({String? folder, String? cursor});

  /// Every object in the bucket, looping `list()` past its 100-per-page
  /// cursor internally — the finder tabs need the full key set, not one page.
  Future<List<MediaObject>> listAll();

  Future<MediaStats> stats();

  /// Permanent, unrecoverable — the Worker deletes straight from R2.
  Future<void> delete(List<String> keys);

  /// Every image URL currently referenced by a live doc (shops, products —
  /// including soft-deleted, drivers, banners). Powers both finders: a key
  /// with no matching reference is unused; a reference whose key isn't in R2
  /// is broken.
  Future<List<MediaReference>> getReferences();
}
