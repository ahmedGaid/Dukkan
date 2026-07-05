import 'dart:async';

import 'package:dukkan/domain/product/entities/product.dart';
import 'package:dukkan/domain/product/entities/stock_status.dart';
import 'package:dukkan/domain/product/repositories/product_repository.dart';
import 'package:dukkan/domain/product/usecases/watch_all_products.dart';
import 'package:dukkan/domain/shop/entities/shop.dart';
import 'package:dukkan/domain/shop/repositories/shop_repository.dart';
import 'package:dukkan/domain/shop/usecases/watch_shops.dart';
import 'package:dukkan/presentation/home/bloc/shops_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// Drives the shops stream by hand so the bloc can be tested without Firebase.
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

/// Drives the all-products stream by hand — feeds the promo carousel.
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
  }) =>
      throw UnimplementedError();

  @override
  Future<void> updateProduct(Product product) => throw UnimplementedError();

  @override
  Future<void> deleteProduct(String productId) => throw UnimplementedError();
}

Shop _shop(String id, List<String> categories) => Shop(
      id: id,
      ownerUid: 'owner-$id',
      name: 'Shop $id',
      nameAr: 'دكان $id',
      address: 'Cairo',
      isOpen: true,
      categories: categories,
    );

void main() {
  late _FakeShopRepository shopRepo;
  late _FakeProductRepository productRepo;
  late ShopsBloc bloc;

  setUp(() {
    shopRepo = _FakeShopRepository();
    productRepo = _FakeProductRepository();
    bloc = ShopsBloc(
      watchShops: WatchShops(shopRepo),
      watchAllProducts: WatchAllProducts(productRepo),
    );
  });

  tearDown(() async {
    await bloc.close();
    await shopRepo.controller.close();
    await productRepo.controller.close();
  });

  test('loads shops and derives the category union in first-seen order',
      () async {
    bloc.add(const ShopsStarted());
    await Future<void>.delayed(Duration.zero);

    shopRepo.controller.add([
      _shop('a', ['خضروات', 'ألبان']),
      _shop('b', ['ألبان', 'مشروبات']),
    ]);
    productRepo.controller.add(const []);
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.status, ShopsStatus.loaded);
    expect(bloc.state.categories, ['خضروات', 'ألبان', 'مشروبات']);
    expect(bloc.state.visibleShops.length, 2);
  });

  test('category filter narrows visibleShops, re-tap clears it', () async {
    bloc.add(const ShopsStarted());
    await Future<void>.delayed(Duration.zero);
    shopRepo.controller.add([
      _shop('a', ['خضروات']),
      _shop('b', ['ألبان']),
    ]);
    productRepo.controller.add(const []);
    await Future<void>.delayed(Duration.zero);

    bloc.add(const ShopsCategorySelected('خضروات'));
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.selectedCategory, 'خضروات');
    expect(bloc.state.visibleShops.map((s) => s.id), ['a']);

    bloc.add(const ShopsCategorySelected('خضروات'));
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.selectedCategory, isNull);
    expect(bloc.state.visibleShops.length, 2);
  });

  test('drops a selected category that disappears from the feed', () async {
    bloc.add(const ShopsStarted());
    await Future<void>.delayed(Duration.zero);
    shopRepo.controller.add([
      _shop('a', ['خضروات']),
    ]);
    productRepo.controller.add(const []);
    await Future<void>.delayed(Duration.zero);
    bloc.add(const ShopsCategorySelected('خضروات'));
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.selectedCategory, 'خضروات');

    // Feed updates and that category is gone.
    shopRepo.controller.add([
      _shop('b', ['ألبان']),
    ]);
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.selectedCategory, isNull);
    expect(bloc.state.visibleShops.map((s) => s.id), ['b']);
  });

  test('stream error surfaces as error status', () async {
    bloc.add(const ShopsStarted());
    await Future<void>.delayed(Duration.zero);

    shopRepo.controller.addError(Exception('boom'));
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.status, ShopsStatus.error);
  });

  test('filters promo products and caps the carousel at 8', () async {
    bloc.add(const ShopsStarted());
    await Future<void>.delayed(Duration.zero);

    shopRepo.controller.add(const []);
    productRepo.controller.add([
      for (var i = 0; i < 10; i++)
        Product(
          id: 'p$i',
          shopId: 'a',
          name: 'Product $i',
          nameAr: 'منتج $i',
          priceMinor: 100,
          category: 'General',
          stockStatus: StockStatus.inStock,
          isPromo: true,
        ),
      Product(
        id: 'not-promo',
        shopId: 'a',
        name: 'Regular',
        nameAr: 'عادي',
        priceMinor: 100,
        category: 'General',
        stockStatus: StockStatus.inStock,
        isPromo: false,
      ),
    ]);
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.status, ShopsStatus.loaded);
    expect(bloc.state.promoProducts.length, 8);
    expect(bloc.state.promoProducts.every((p) => p.isPromo), isTrue);
  });
}
