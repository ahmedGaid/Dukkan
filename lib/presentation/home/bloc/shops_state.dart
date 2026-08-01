part of 'shops_bloc.dart';

enum ShopsStatus { loading, loaded, error }

class ShopsState extends Equatable {
  const ShopsState({
    this.status = ShopsStatus.loading,
    this.shops = const [],
    this.categories = const [],
    this.selectedCategory,
    this.promoProducts = const [],
    this.featuredProducts = const [],
    this.banners = const [],
  });

  final ShopsStatus status;

  /// Every shop from the feed (unfiltered) — [visibleShops] applies the filter.
  final List<Shop> shops;

  /// Taxonomy categories (console-visible, `sort` order) — drives the
  /// category grid directly, independent of which shops carry them.
  final List<Category> categories;

  /// Up to 8 real `isPromo` products across every shop — feeds the promo
  /// carousel (P1). Empty hides the carousel entirely (no bare placeholder).
  final List<Product> promoProducts;

  /// Up to 6 `isFeatured` products (FC16 Task C), deduped against
  /// [promoProducts] before rendering — a product that is both promo and
  /// featured shows once, at its promo position.
  final List<Product> featuredProducts;

  /// Active banners (FC16 Task B), date-window-filtered + sorted, prepended
  /// before every product card in [carouselItems].
  final List<PromoBanner> banners;

  /// Active category filter, or null for "all".
  final String? selectedCategory;

  /// Shops shown in the nearby list: all, or only those carrying the selected
  /// category.
  List<Shop> get visibleShops {
    final selected = selectedCategory;
    if (selected == null) return shops;
    return shops.where((s) => s.categories.contains(selected)).toList();
  }

  /// «دكاكين مميزة» row (FC16 Task C) — independent of the category filter,
  /// a marketing rail, not a nearby-list refinement.
  List<Shop> get featuredShops =>
      shops.where((s) => s.isFeatured).take(5).toList();

  /// Banners, then promo products, then featured products (deduped against
  /// promo), capped at 10 total — the carousel's full ordered feed (FC16
  /// Task B/C). Empty hides the carousel entirely, same as before.
  List<PromoCarouselItem> get carouselItems {
    final promoIds = promoProducts.map((p) => p.id).toSet();
    final dedupedFeatured =
        featuredProducts.where((p) => !promoIds.contains(p.id));
    final items = <PromoCarouselItem>[
      ...banners.map(BannerCarouselItem.new),
      ...promoProducts.map(ProductCarouselItem.new),
      ...dedupedFeatured.map(ProductCarouselItem.new),
    ];
    return items.take(10).toList();
  }

  ShopsState copyWith({
    ShopsStatus? status,
    List<Shop>? shops,
    List<Category>? categories,
    String? selectedCategory,
    bool clearCategory = false,
    List<Product>? promoProducts,
    List<Product>? featuredProducts,
    List<PromoBanner>? banners,
  }) {
    return ShopsState(
      status: status ?? this.status,
      shops: shops ?? this.shops,
      categories: categories ?? this.categories,
      selectedCategory:
          clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      promoProducts: promoProducts ?? this.promoProducts,
      featuredProducts: featuredProducts ?? this.featuredProducts,
      banners: banners ?? this.banners,
    );
  }

  @override
  List<Object?> get props => [
        status,
        shops,
        categories,
        selectedCategory,
        promoProducts,
        featuredProducts,
        banners,
      ];
}
