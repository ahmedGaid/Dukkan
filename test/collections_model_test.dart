import 'package:dukkan/data/collections/models/shop_collection_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromFirestore parses a collection', () {
    final collection = ShopCollectionModel.fromFirestore('c1', {
      'nameAr': 'عروض',
      'nameEn': 'Offers',
      'sort': 1,
      'createdAt': '2026-07-11T00:00:00.000',
    });

    expect(collection.id, 'c1');
    expect(collection.nameAr, 'عروض');
    expect(collection.nameEn, 'Offers');
    expect(collection.sort, 1);
  });

  test('fromFirestore defaults missing fields safely', () {
    final collection = ShopCollectionModel.fromFirestore('c1', const {});

    expect(collection.nameAr, '');
    expect(collection.nameEn, '');
    expect(collection.sort, 0);
  });

  test('toFirestore carries the writable fields', () {
    const collection = ShopCollectionModel(
      id: 'c1',
      nameAr: 'عروض',
      nameEn: 'Offers',
      sort: 2,
    );

    final data = collection.toFirestore();

    expect(data['nameAr'], 'عروض');
    expect(data['nameEn'], 'Offers');
    expect(data['sort'], 2);
    expect(data.containsKey('createdAt'), isTrue);
  });
}
