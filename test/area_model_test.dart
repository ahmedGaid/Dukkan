import 'package:dukkan/data/areas/models/area_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromFirestore parses an area', () {
    final area = AreaModel.fromFirestore('abu-atwa', {
      'nameAr': 'أبو عطوة',
      'nameEn': 'Abu Atwa',
      'sort': 1,
      'governorate': 'الإسماعيلية',
      'city': 'أبو عطوة',
      'isActive': false,
      'deliveryFeeMinorOverride': 5000,
    });

    expect(area.id, 'abu-atwa');
    expect(area.nameAr, 'أبو عطوة');
    expect(area.nameEn, 'Abu Atwa');
    expect(area.sort, 1);
    expect(area.governorate, 'الإسماعيلية');
    expect(area.city, 'أبو عطوة');
    expect(area.isActive, false);
    expect(area.deliveryFeeMinorOverride, 5000);
  });

  test('fromFirestore defaults missing fields safely (pre-FC9 docs)', () {
    final area = AreaModel.fromFirestore('abu-atwa', const {});

    expect(area.nameAr, '');
    expect(area.nameEn, '');
    expect(area.sort, 0);
    expect(area.governorate, 'الإسماعيلية');
    expect(area.city, 'الإسماعيلية');
    expect(area.isActive, true);
    expect(area.deliveryFeeMinorOverride, isNull);
  });

  test('toJson/fromJson round-trips (the local cache path)', () {
    final area = AreaModel.fromFirestore('abu-atwa', {
      'nameAr': 'أبو عطوة',
      'nameEn': 'Abu Atwa',
      'sort': 1,
      'governorate': 'الإسماعيلية',
      'city': 'أبو عطوة',
      'isActive': false,
      'deliveryFeeMinorOverride': 5000,
    });

    final roundTripped = AreaModel.fromJson(area.toJson());

    expect(roundTripped.id, area.id);
    expect(roundTripped.nameAr, area.nameAr);
    expect(roundTripped.nameEn, area.nameEn);
    expect(roundTripped.sort, area.sort);
    expect(roundTripped.governorate, area.governorate);
    expect(roundTripped.city, area.city);
    expect(roundTripped.isActive, area.isActive);
    expect(roundTripped.deliveryFeeMinorOverride, area.deliveryFeeMinorOverride);
  });
}
