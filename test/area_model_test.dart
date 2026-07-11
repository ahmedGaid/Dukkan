import 'package:dukkan/data/areas/models/area_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromFirestore parses an area', () {
    final area = AreaModel.fromFirestore('abu-atwa', {
      'nameAr': 'أبو عطوة',
      'nameEn': 'Abu Atwa',
      'sort': 1,
    });

    expect(area.id, 'abu-atwa');
    expect(area.nameAr, 'أبو عطوة');
    expect(area.nameEn, 'Abu Atwa');
    expect(area.sort, 1);
  });

  test('fromFirestore defaults missing fields safely', () {
    final area = AreaModel.fromFirestore('abu-atwa', const {});

    expect(area.nameAr, '');
    expect(area.nameEn, '');
    expect(area.sort, 0);
  });

  test('toJson/fromJson round-trips (the local cache path)', () {
    final area = AreaModel.fromFirestore('abu-atwa', {
      'nameAr': 'أبو عطوة',
      'nameEn': 'Abu Atwa',
      'sort': 1,
    });

    final roundTripped = AreaModel.fromJson(area.toJson());

    expect(roundTripped.id, area.id);
    expect(roundTripped.nameAr, area.nameAr);
    expect(roundTripped.nameEn, area.nameEn);
    expect(roundTripped.sort, area.sort);
  });
}
