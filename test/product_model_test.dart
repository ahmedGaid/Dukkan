import 'package:cloud_firestore/cloud_firestore.dart';
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

  test('fromFirestore parses collectionIds', () {
    final product = ProductModel.fromFirestore('p1', {
      ...baseFirestoreData,
      'collectionIds': ['offers', 'new'],
    });

    expect(product.collectionIds, ['offers', 'new']);
  });

  test('fromFirestore defaults collectionIds for a pre-M7 product', () {
    final product = ProductModel.fromFirestore('p1', baseFirestoreData);

    expect(product.collectionIds, isEmpty);
  });

  test('toJson/fromJson round-trips collectionIds', () {
    final product = ProductModel.fromFirestore('p1', {
      ...baseFirestoreData,
      'collectionIds': ['offers'],
    });

    final roundTripped = ProductModel.fromJson(product.toJson());

    expect(roundTripped.collectionIds, ['offers']);
  });

  test('fromFirestore parses a pre-FC8 product as not-featured, not-deleted', () {
    final product = ProductModel.fromFirestore('p1', baseFirestoreData);

    expect(product.isFeatured, isFalse);
    expect(product.deleted, isFalse);
    expect(product.deletedAt, isNull);
    expect(product.deletedBy, isNull);
  });

  test('fromFirestore/toFirestore round-trips every FC8 field', () {
    final deletedAt = DateTime.utc(2026, 7, 14);
    final product = ProductModel.fromFirestore('p1', {
      ...baseFirestoreData,
      'isFeatured': true,
      'deleted': true,
      'deletedAt': Timestamp.fromDate(deletedAt),
      'deletedBy': 'staff1',
    });

    expect(product.isFeatured, isTrue);
    expect(product.deleted, isTrue);
    expect(product.deletedAt?.toUtc(), deletedAt);
    expect(product.deletedBy, 'staff1');

    final fs = product.toFirestore();
    expect(fs['isFeatured'], true);
    expect(fs['deleted'], true);
    expect(fs['deletedAt'], isA<Timestamp>());

    final roundTripped = ProductModel.fromFirestore('p1', fs);
    expect(roundTripped, product);
  });

  test('toJson/fromJson round-trips FC8 fields', () {
    final product = ProductModel.fromFirestore('p1', {
      ...baseFirestoreData,
      'isFeatured': true,
      'deleted': true,
      'deletedBy': 'staff1',
    });

    final roundTripped = ProductModel.fromJson(product.toJson());

    expect(roundTripped.isFeatured, isTrue);
    expect(roundTripped.deleted, isTrue);
    expect(roundTripped.deletedBy, 'staff1');
  });
}
