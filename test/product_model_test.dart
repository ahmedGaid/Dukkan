import 'package:dukkan/data/product/models/product_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final baseFirestoreData = {
    'shopId': 'shop1',
    'name': 'Milk 1L',
    'nameAr': 'لبن 1 لتر',
    'priceMinor': 3500,
    'category': 'ألبان',
    'stockStatus': 'inStock',
    'isPromo': false,
  };

  test('fromFirestore parses a product WITH a subcategoryId', () {
    final product = ProductModel.fromFirestore('p1', {
      ...baseFirestoreData,
      'subcategoryId': 'milk',
    });

    expect(product.subcategoryId, 'milk');
  });

  test('fromFirestore parses a pre-M3 product with no subcategoryId', () {
    final product = ProductModel.fromFirestore('p1', baseFirestoreData);

    expect(product.subcategoryId, isNull);
    expect(product.category, 'ألبان');
  });

  test('toJson/fromJson round-trips with a subcategoryId', () {
    final product = ProductModel.fromFirestore('p1', {
      ...baseFirestoreData,
      'subcategoryId': 'milk',
    });

    final roundTripped = ProductModel.fromJson(product.toJson());

    expect(roundTripped.subcategoryId, 'milk');
    expect(roundTripped.category, product.category);
  });

  test('toJson/fromJson round-trips with no subcategoryId', () {
    final product = ProductModel.fromFirestore('p1', baseFirestoreData);

    final roundTripped = ProductModel.fromJson(product.toJson());

    expect(roundTripped.subcategoryId, isNull);
  });
}
