import 'dart:async';

import 'package:dukkan/domain/product/entities/product.dart';
import 'package:dukkan/domain/product/entities/stock_status.dart';
import 'package:dukkan/domain/product/repositories/product_repository.dart';
import 'package:dukkan/domain/product/usecases/watch_all_products.dart';
import 'package:dukkan/domain/promos/entities/promo_banner.dart';
import 'package:dukkan/domain/promos/repositories/banner_repository.dart';
import 'package:dukkan/domain/promos/usecases/watch_active_banners.dart';
import 'package:dukkan/domain/shop/entities/shop.dart';
import 'package:dukkan/domain/shop/repositories/shop_repository.dart';
import 'package:dukkan/domain/shop/usecases/watch_shops.dart';
import 'package:dukkan/domain/taxonomy/entities/category.dart';
import 'package:dukkan/domain/taxonomy/repositories/taxonomy_repository.dart';
import 'package:dukkan/domain/taxonomy/usecases/watch_taxonomy.dart';
import 'package:dukkan/presentation/home/bloc/shops_bloc.dart';
import 'package:dukkan/presentation/home/widgets/promo_carousel.dart';
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
    String? subcategoryId,
    List<String> collectionIds = const [],
  }) =>
      throw UnimplementedError();

  @override
  Future<void> updateProduct(Product product) => throw UnimplementedError();

  @override
  Future<void> deleteProduct(String productId) => throw UnimplementedError();
}

/// Drives the active-banners stream by hand (FC16 Task B).
class _FakeBannerRepository implements BannerRepository {
  final controller = StreamController<List<PromoBanner>>();

  @override
  Stream<List<PromoBanner>> watchActiveBanners() => controller.stream;
}

/// Drives the taxonomy stream by hand — feeds the category grid directly,
/// independent of shop coverage (see `ShopsBloc` doc).
class _FakeTaxonomyRepository implements TaxonomyRepository {
  final controller = StreamController<List<Category>>();

  @override
  Stream<List<Category>> watchTaxonomy() => controller.stream;

  @override
  Future<List<Category>> getTaxonomy() => throw UnimplementedError();
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

Category _category(String id) => Category(
      id: id,
      nameAr: id,
      nameEn: id,
      sort: 0,
      subcategories: const [],
    );

void main() {
  late _FakeShopRepository shopRepo;
  late _FakeProductRepository productRepo;
  late _FakeBannerRepository bannerRepo;
  late _FakeTaxonomyRepository taxonomyRepo;
  late ShopsBloc bloc;

  setUp(() {
    shopRepo = _FakeShopRepository();
    productRepo = _FakeProductRepository();
    bannerRepo = _FakeBannerRepository();
    taxonomyRepo = _FakeTaxonomyRepository();
    bloc = ShopsBloc(
      watchShops: WatchShops(shopRepo),
      watchAllProducts: WatchAllProducts(productRepo),
      watchActiveBanners: WatchActiveBanners(bannerRepo),
      watchTaxonomy: WatchTaxonomy(taxonomyRepo),
    );
  });

  tearDown(() async {
    await bloc.close();
    await shopRepo.controller.close();
    await productRepo.controller.close();
    await bannerRepo.controller.close();
    await taxonomyRepo.controller.close();
  });

  test('category grid follows the taxonomy stream, not shop coverage',
      () async {
    bloc.add(const ShopsStarted());
    await Future<void>.delayed(Duration.zero);

    shopRepo.controller.add([_shop('a', const [])]);
    productRepo.controller.add(const []);
    taxonomyRepo.controller
        .add([_category('خضروات'), _category('ألبان'), _category('مشروبات')]);
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.status, ShopsStatus.loaded);
    expect(bloc.state.categories.map((c) => c.id),
        ['خضروات', 'ألبان', 'مشروبات']);
    // Shop 'a' carries none of these — the grid still shows all three.
    expect(bloc.state.visibleShops.length, 1);
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

  test('drops a selected category that is hidden/deleted from taxonomy',
      () async {
    bloc.add(const ShopsStarted());
    await Future<void>.delayed(Duration.zero);
    shopRepo.controller.add([
      _shop('a', ['خضروات']),
      _shop('b', ['ألبان']),
    ]);
    productRepo.controller.add(const []);
    taxonomyRepo.controller.add([_category('خضروات'), _category('ألبان')]);
    await Future<void>.delayed(Duration.zero);
    bloc.add(const ShopsCategorySelected('خضروات'));
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.selectedCategory, 'خضروات');

    // Taxonomy updates and that category is gone (hidden or deleted).
    taxonomyRepo.controller.add([_category('ألبان')]);
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.selectedCategory, isNull);
    expect(bloc.state.visibleShops.map((s) => s.id), ['a', 'b']);
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

  test('carousel prepends banners, then promo, then deduped featured (FC16)',
      () async {
    bloc.add(const ShopsStarted());
    await Future<void>.delayed(Duration.zero);

    shopRepo.controller.add(const []);
    productRepo.controller.add([
      Product(
        id: 'promo-and-featured',
        shopId: 'a',
        name: 'Both',
        nameAr: 'كلاهما',
        priceMinor: 100,
        category: 'General',
        stockStatus: StockStatus.inStock,
        isPromo: true,
        isFeatured: true,
      ),
      Product(
        id: 'featured-only',
        shopId: 'a',
        name: 'Featured',
        nameAr: 'مميز',
        priceMinor: 100,
        category: 'General',
        stockStatus: StockStatus.inStock,
        isPromo: false,
        isFeatured: true,
      ),
    ]);
    bannerRepo.controller.add(const [
      PromoBanner(
        id: 'b1',
        imageUrl: 'https://example.com/b1.png',
        targetType: BannerTargetType.none,
        sort: 0,
      ),
    ]);
    await Future<void>.delayed(Duration.zero);

    final items = bloc.state.carouselItems;
    expect(items.length, 3); // 1 banner + 1 promo(+featured, deduped) + 1 featured-only
    expect(items[0], isA<BannerCarouselItem>());
    expect((items[1] as ProductCarouselItem).product.id, 'promo-and-featured');
    expect((items[2] as ProductCarouselItem).product.id, 'featured-only');
  });

  test('featuredShops filters isFeatured and caps at 5 (FC16)', () async {
    bloc.add(const ShopsStarted());
    await Future<void>.delayed(Duration.zero);

    shopRepo.controller.add([
      for (var i = 0; i < 7; i++)
        Shop(
          id: 'f$i',
          ownerUid: 'owner-f$i',
          name: 'Shop $i',
          nameAr: 'دكان $i',
          address: 'Cairo',
          isOpen: true,
          categories: const [],
          isFeatured: true,
        ),
      _shop('not-featured', const []),
    ]);
    productRepo.controller.add(const []);
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.featuredShops.length, 5);
    expect(bloc.state.featuredShops.every((s) => s.isFeatured), isTrue);
  });
}
