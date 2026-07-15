import 'package:dukkan/domain/media/entities/media_object.dart';
import 'package:dukkan/domain/media/entities/media_reference.dart';
import 'package:dukkan/domain/media/media_diff.dart';
import 'package:flutter_test/flutter_test.dart';

MediaObject _obj(String key) =>
    MediaObject(key: key, size: 100, uploaded: DateTime(2026), url: 'https://cdn/$key');

MediaReference _ref(String? key, {String docType = 'shop', String docId = 'd1'}) =>
    MediaReference(url: 'https://cdn/$key', key: key, docType: docType, docId: docId);

void main() {
  group('findOrphanMedia (FC14)', () {
    test('an object with no matching reference is orphaned', () {
      final objects = [_obj('shop-logos/u1/a.jpg'), _obj('shop-logos/u1/b.jpg')];
      final refs = [_ref('shop-logos/u1/a.jpg')];

      final orphans = findOrphanMedia(objects, refs);

      expect(orphans.map((o) => o.key), ['shop-logos/u1/b.jpg']);
    });

    test('every object referenced yields no orphans', () {
      final objects = [_obj('a'), _obj('b')];
      final refs = [_ref('a'), _ref('b')];

      expect(findOrphanMedia(objects, refs), isEmpty);
    });
  });

  group('findBrokenReferences (FC14)', () {
    test('a reference whose key is missing from R2 is broken', () {
      final objects = [_obj('a')];
      final refs = [_ref('a'), _ref('missing')];

      final broken = findBrokenReferences(refs, objects);

      expect(broken.map((r) => r.key), ['missing']);
    });

    test('a reference with no derivable key (bundled asset) is never flagged', () {
      final objects = <MediaObject>[];
      final refs = [_ref(null)];

      expect(findBrokenReferences(refs, objects), isEmpty);
    });
  });
}
