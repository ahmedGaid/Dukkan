import 'dart:async';

import 'package:dukkan/domain/product/entities/product.dart';
import 'package:dukkan/domain/product/entities/stock_status.dart';
import 'package:dukkan/domain/product/repositories/product_repository.dart';
import 'package:dukkan/domain/product/usecases/watch_all_products.dart';
import 'package:dukkan/domain/shop/entities/shop.dart';
import 'package:dukkan/domain/shop/repositories/shop_repository.dart';
import 'package:dukkan/domain/shop/usecases/watch_shops.dart';
import 'package:dukkan/presentation/search/bloc/search_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hand-drives the two streams the bloc listens to, no Firebase.
class _FakeProductRepository implements ProductRepository {
  final controller = StreamController<List<Product>>();

  @override
  Stream<List<Product>> watchAllProducts() => controller.stream;

  @override
  Stream<List<Product>> watchProductsByShop(String shopId) =>
      const Stream.empty();

  @override
  Future<Product> getProduct(String productId) => throw UnimplementedError();

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
    String? subcategoryId,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> updateProduct(Product product) => throw UnimplementedError();

  @override
  Future<void> deleteProduct(String productId) => throw UnimplementedError();
}

class _FakeShopRepository implements ShopRepository {
  final controller = StreamController<List<Shop>>();

  @override
  Stream<List<Shop>> watchShops() => controller.stream;

  @override
  Stream<Shop> watchShop(String shopId) => const Stream.empty();

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

Shop _shop(String id, {required String name, required String nameAr}) => Shop(
      id: id,
      ownerUid: 'owner-$id',
      name: name,
      nameAr: nameAr,
      address: 'Cairo',
      isOpen: true,
      categories: const [],
    );

Product _product(
  String id, {
  required String shopId,
  String name = 'Item',
  String nameAr = 'منتج',
  String category = 'عام',
}) =>
    Product(
      id: id,
      shopId: shopId,
      name: name,
      nameAr: nameAr,
      priceMinor: 1000,
      category: category,
      stockStatus: StockStatus.inStock,
      isPromo: false,
    );

void main() {
  late _FakeProductRepository productRepo;
  late _FakeShopRepository shopRepo;
  late SearchBloc bloc;

  setUp(() {
    productRepo = _FakeProductRepository();
    shopRepo = _FakeShopRepository();
    bloc = SearchBloc(
      watchAllProducts: WatchAllProducts(productRepo),
      watchShops: WatchShops(shopRepo),
    );
  });

  tearDown(() async {
    await bloc.close();
    await productRepo.controller.close();
    await shopRepo.controller.close();
  });

  Future<void> tick() => Future<void>.delayed(Duration.zero);

  test('stays loading until BOTH products and shops have arrived', () async {
    bloc.add(const SearchStarted());
    await tick();

    productRepo.controller.add([_product('a', shopId: 's')]);
    await tick();
    expect(bloc.state.status, SearchStatus.loading);

    shopRepo.controller.add([_shop('s', name: 'Shop', nameAr: 'دكان')]);
    await tick();
    expect(bloc.state.status, SearchStatus.ready);
  });

  test('a blank query yields no results (the prompt state)', () async {
    bloc.add(const SearchStarted());
    await tick();
    productRepo.controller.add([_product('a', shopId: 's', nameAr: 'موز')]);
    shopRepo.controller.add([_shop('s', name: 'Shop', nameAr: 'دكان')]);
    await tick();

    expect(bloc.state.status, SearchStatus.ready);
    expect(bloc.state.results, isEmpty);
  });

  test('matches a product by name, Arabic-folded', () async {
    bloc.add(const SearchStarted());
    await tick();
    productRepo.controller.add([
      _product('a', shopId: 's', nameAr: 'مياه'),
      _product('b', shopId: 's', nameAr: 'خبز'),
    ]);
    shopRepo.controller.add([_shop('s', name: 'Shop', nameAr: 'دكان')]);
    await tick();

    // Query ends in ة, the product name in ه — they must still match because
    // ة/ه fold to one form on both sides of the comparison.
    bloc.add(const SearchQueryChanged('مياة'));
    await tick();
    expect(bloc.state.results.map((p) => p.id), ['a']);
  });

  test('typing a shop name surfaces that shop\'s products', () async {
    bloc.add(const SearchStarted());
    await tick();
    productRepo.controller.add([
      _product('a', shopId: 's1', nameAr: 'خبز'),
      _product('b', shopId: 's2', nameAr: 'لبن'),
    ]);
    shopRepo.controller.add([
      _shop('s1', name: 'Baker', nameAr: 'الفرن'),
      _shop('s2', name: 'Dairy', nameAr: 'الألبان'),
    ]);
    await tick();

    bloc.add(const SearchQueryChanged('الفرن'));
    await tick();
    expect(bloc.state.results.map((p) => p.id), ['a']);
  });

  test('a genuine miss yields empty results while ready', () async {
    bloc.add(const SearchStarted());
    await tick();
    productRepo.controller.add([_product('a', shopId: 's', nameAr: 'خبز')]);
    shopRepo.controller.add([_shop('s', name: 'Shop', nameAr: 'دكان')]);
    await tick();

    bloc.add(const SearchQueryChanged('سمك'));
    await tick();
    expect(bloc.state.status, SearchStatus.ready);
    expect(bloc.state.results, isEmpty);
  });

  test('a stream error surfaces as error status', () async {
    bloc.add(const SearchStarted());
    await tick();
    productRepo.controller.addError(Exception('boom'));
    await tick();
    expect(bloc.state.status, SearchStatus.error);
  });
}
