import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dukkan/data/shop/models/shop_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ShopModel.fromFirestore', () {
    test('parses a pre-FC7 doc (no new fields) as active/not-featured', () {
      final model = ShopModel.fromFirestore('s1', {
        'ownerUid': 'o1',
        'name': 'Grocery',
        'nameAr': 'بقالة',
        'address': '123 St',
        'isOpen': true,
        'categories': ['food'],
      });

      expect(model.status, 'active');
      expect(model.isFeatured, isFalse);
      expect(model.isVerified, isFalse);
      expect(model.deleted, isFalse);
      expect(model.deletedAt, isNull);
      expect(model.hoursNote, isNull);
    });

    test('round-trips every FC7 field', () {
      final deletedAt = DateTime.utc(2026, 7, 1);
      final model = ShopModel.fromFirestore('s2', {
        'ownerUid': 'o2',
        'name': 'Bakery',
        'nameAr': 'مخبز',
        'address': '456 St',
        'isOpen': false,
        'categories': ['bakery'],
        'status': 'suspended',
        'isFeatured': true,
        'isVerified': true,
        'deleted': true,
        'deletedAt': Timestamp.fromDate(deletedAt),
        'deletedBy': 'staff1',
        'hoursNote': '9-5 daily',
      });

      expect(model.status, 'suspended');
      expect(model.isFeatured, isTrue);
      expect(model.isVerified, isTrue);
      expect(model.deleted, isTrue);
      expect(model.deletedAt?.toUtc(), deletedAt);
      expect(model.deletedBy, 'staff1');
      expect(model.hoursNote, '9-5 daily');

      final fs = model.toFirestore();
      expect(fs['status'], 'suspended');
      expect(fs['deletedAt'], isA<Timestamp>());

      final roundTripped = ShopModel.fromFirestore('s2', fs);
      expect(roundTripped, model);
    });
  });

  group('ShopModel json cache round-trip', () {
    test('preserves FC7 fields through toJson/fromJson', () {
      const model = ShopModel(
        id: 's3',
        ownerUid: 'o3',
        name: 'Pharmacy',
        nameAr: 'صيدلية',
        address: '789 St',
        isOpen: true,
        categories: ['pharmacy'],
        status: 'pending',
        isFeatured: false,
        isVerified: true,
      );

      final roundTripped = ShopModel.fromJson(model.toJson());
      expect(roundTripped, model);
    });
  });
}
