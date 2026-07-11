import 'package:dukkan/data/taxonomy/models/category_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final firestoreData = {
    'nameAr': 'خضروات وفواكه',
    'nameEn': 'Vegetables & Fruits',
    'sort': 1,
    'subcategories': [
      {'id': 'fruits', 'nameAr': 'فواكه', 'nameEn': 'Fruits'},
      {'id': 'vegetables', 'nameAr': 'خضروات', 'nameEn': 'Vegetables'},
    ],
  };

  test('fromFirestore parses the category and its embedded subcategories',
      () {
    final category = CategoryModel.fromFirestore('خضروات وفواكه', firestoreData);

    expect(category.id, 'خضروات وفواكه');
    expect(category.nameAr, 'خضروات وفواكه');
    expect(category.nameEn, 'Vegetables & Fruits');
    expect(category.sort, 1);
    expect(category.subcategories, hasLength(2));
    expect(category.subcategories.first.id, 'fruits');
    expect(category.subcategories.first.nameAr, 'فواكه');
    expect(category.subcategories.last.id, 'vegetables');
  });

  test('toJson/fromJson round-trips (the local cache path)', () {
    final category = CategoryModel.fromFirestore('خضروات وفواكه', firestoreData);

    final roundTripped = CategoryModel.fromJson(category.toJson());

    expect(roundTripped.id, category.id);
    expect(roundTripped.nameAr, category.nameAr);
    expect(roundTripped.nameEn, category.nameEn);
    expect(roundTripped.sort, category.sort);
    expect(roundTripped.subcategories, category.subcategories);
  });

  test('a category with no subcategories parses to an empty list', () {
    final category = CategoryModel.fromFirestore('id', {
      'nameAr': 'قسم',
      'nameEn': 'Section',
      'sort': 9,
    });

    expect(category.subcategories, isEmpty);
  });
}
