import 'dart:async';

import 'package:dukkan/domain/product/entities/product.dart';
import 'package:dukkan/domain/product/entities/stock_status.dart';
import 'package:dukkan/domain/product/repositories/product_repository.dart';
import 'package:dukkan/domain/product/usecases/watch_products_by_shop.dart';
import 'package:dukkan/domain/shop/entities/shop.dart';
import 'package:dukkan/domain/shop/repositories/shop_repository.dart';
import 'package:dukkan/domain/shop/usecases/watch_shop.dart';
import 'package:dukkan/presentation/shop/bloc/products_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// Drives both streams the bloc listens to by hand, so it can be tested without
/// Firebase.
class _FakeShopRepository implements ShopRepository {
  final controller = StreamController<Shop>();

  @override
  Stream<Shop> watchShop(String shopId) => controller.stream;

  @override
  Stream<List<Shop>> watchShops() => const Stream.empty();

  @override
  Future<Shop?> getShopByOwner(String ownerUid) => throw UnimplementedError();

  @override
  Future<Shop> createShop({
    required String ownerUid,
    required String name,
    required String nameAr,
    required String address,
    String? logoUrl,
    bool isOpen = true,
    List<String> categories = const [],
  }) =>
      throw UnimplementedError();
}

class _FakeProductRepository implements ProductRepository {
  final controller = StreamController<List<Product>>();

  @override
  Stream<List<Product>> watchProductsByShop(String shopId) =>
      controller.stream;

  @override
  Stream<List<Product>> watchAllProducts() => const Stream.empty();

  @override
  Future<Product> getProduct(String productId) =>
      throw UnimplementedError();

  @override
  Future<Product> createProduct({
    required String shopId,
    required String name,
    required String nameAr,
    required int priceMinor,
    required String category,
    required StockStatus stockStatus,
    required bool isPromo,
    String? imageUrl,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> updateProduct(Product product) => throw UnimplementedError();

  @override
  Future<void> deleteProduct(String productId) => throw UnimplementedError();
}

Shop _shop(String id) => Shop(
      id: id,
      ownerUid: 'owner-$id',
      name: 'Shop $id',
      nameAr: 'دكان $id',
      address: 'Cairo',
      isOpen: true,
      categories: const [],
    );

Product _product(String id, String category) => Product(
      id: id,
      shopId: 's',
      name: 'Product $id',
      nameAr: 'منتج $id',
      priceMinor: 1000,
      category: category,
      stockStatus: StockStatus.inStock,
      isPromo: false,
    );

void main() {
  late _FakeShopRepository shopRepo;
  late _FakeProductRepository productRepo;
  late ProductsBloc bloc;

  setUp(() {
    shopRepo = _FakeShopRepository();
    productRepo = _FakeProductRepository();
    bloc = ProductsBloc(
      shopId: 's',
      watchShop: WatchShop(shopRepo),
      watchProductsByShop: WatchProductsByShop(productRepo),
    );
  });

  tearDown(() async {
    await bloc.close();
    await shopRepo.controller.close();
    await productRepo.controller.close();
  });

  test('stays loading until BOTH the shop and its products have arrived',
      () async {
    bloc.add(const ProductsStarted());
    await Future<void>.delayed(Duration.zero);

    productRepo.controller.add([_product('a', 'خضروات')]);
    await Future<void>.delayed(Duration.zero);
    // Products in, shop still missing — header can't render yet.
    expect(bloc.state.status, ProductsStatus.loading);

    shopRepo.controller.add(_shop('s'));
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.status, ProductsStatus.loaded);
    expect(bloc.state.shop, isNotNull);
  });

  test('derives the category union in first-seen order', () async {
    bloc.add(const ProductsStarted());
    await Future<void>.delayed(Duration.zero);

    shopRepo.controller.add(_shop('s'));
    productRepo.controller.add([
      _product('a', 'خضروات'),
      _product('b', 'ألبان'),
      _product('c', 'خضروات'),
    ]);
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.status, ProductsStatus.loaded);
    expect(bloc.state.categories, ['خضروات', 'ألبان']);
    expect(bloc.state.visibleProducts.length, 3);
  });

  test('category filter narrows visibleProducts, re-tap clears it', () async {
    bloc.add(const ProductsStarted());
    await Future<void>.delayed(Duration.zero);
    shopRepo.controller.add(_shop('s'));
    productRepo.controller.add([
      _product('a', 'خضروات'),
      _product('b', 'ألبان'),
    ]);
    await Future<void>.delayed(Duration.zero);

    bloc.add(const ProductsCategorySelected('خضروات'));
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.selectedCategory, 'خضروات');
    expect(bloc.state.visibleProducts.map((p) => p.id), ['a']);

    bloc.add(const ProductsCategorySelected('خضروات'));
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.selectedCategory, isNull);
    expect(bloc.state.visibleProducts.length, 2);
  });

  test('drops a selected category that disappears from the catalog', () async {
    bloc.add(const ProductsStarted());
    await Future<void>.delayed(Duration.zero);
    shopRepo.controller.add(_shop('s'));
    productRepo.controller.add([_product('a', 'خضروات')]);
    await Future<void>.delayed(Duration.zero);
    bloc.add(const ProductsCategorySelected('خضروات'));
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.selectedCategory, 'خضروات');

    // Catalog updates and that category is gone.
    productRepo.controller.add([_product('b', 'ألبان')]);
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.selectedCategory, isNull);
    expect(bloc.state.visibleProducts.map((p) => p.id), ['b']);
  });

  test('a stream error surfaces as error status', () async {
    bloc.add(const ProductsStarted());
    await Future<void>.delayed(Duration.zero);

    productRepo.controller.addError(Exception('boom'));
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.status, ProductsStatus.error);
  });
}
