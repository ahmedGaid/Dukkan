import 'entities/media_object.dart';
import 'entities/media_reference.dart';

/// Pure set-difference helpers behind the media library's two finder tabs
/// (FC14). Kept free of Firestore/Worker so they're unit-testable without
/// mocking either.

/// R2 objects no live doc points to.
List<MediaObject> findOrphanMedia(
  List<MediaObject> objects,
  List<MediaReference> references,
) {
  final referencedKeys = references.map((r) => r.key).whereType<String>().toSet();
  return objects.where((o) => !referencedKeys.contains(o.key)).toList(growable: false);
}

/// Doc references whose key doesn't exist in R2 (excludes references with no
/// derivable key, e.g. bundled `assets/…` paths — those were never R2 objects).
List<MediaReference> findBrokenReferences(
  List<MediaReference> references,
  List<MediaObject> objects,
) {
  final existingKeys = objects.map((o) => o.key).toSet();
  return references
      .where((r) => r.key != null && !existingKeys.contains(r.key))
      .toList(growable: false);
}
