import 'package:dukkan/core/short_id.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shortId', () {
    test('keeps a short id whole', () {
      expect(shortId('abc'), 'abc');
      expect(shortId('123456'), '123456');
    });

    test('takes the tail, so prefixed ids stay distinguishable', () {
      // The bug this replaced: every seeded order id starts with `order_de`,
      // so a head-truncating short id rendered every board row identically.
      final ids = ['order_demo_0_1', 'order_demo_0_2', 'order_demo_1_1'];
      final shorts = ids.map(shortId).toList();
      expect(shorts.toSet().length, ids.length, reason: 'must stay unique');
      expect(shorts.every((s) => s.length == 6), isTrue);
    });

    test('a head-truncating short id would NOT have been unique', () {
      final heads = ['order_demo_0_1', 'order_demo_0_2', 'order_demo_1_1']
          .map((id) => id.substring(0, 8))
          .toSet();
      expect(heads.length, 1, reason: 'pins why the tail is used');
    });

    test('shortens a Firestore auto-id to the requested length', () {
      expect(shortId('AbCdEfGhIjKlMnOpQrSt'), 'OpQrSt');
      expect(shortId('AbCdEfGhIjKlMnOpQrSt', length: 4), 'QrSt');
    });

    test('a non-positive length yields an empty string', () {
      expect(shortId('anything', length: 0), '');
      expect(shortId('anything', length: -3), '');
    });
  });
}
