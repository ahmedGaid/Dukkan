part of 'shops_bloc.dart';

enum ShopsStatus { loading, loaded, error }

class ShopsState extends Equatable {
  const ShopsState({
    this.status = ShopsStatus.loading,
    this.shops = const [],
    this.categories = const [],
    this.selectedCategory,
  });

  final ShopsStatus status;

  /// Every shop from the feed (unfiltered) — [visibleShops] applies the filter.
  final List<Shop> shops;

  /// Union of shop categories, drives the category grid.
  final List<String> categories;

  /// Active category filter, or null for "all".
  final String? selectedCategory;

  /// Shops shown in the nearby list: all, or only those carrying the selected
  /// category.
  List<Shop> get visibleShops {
    final selected = selectedCategory;
    if (selected == null) return shops;
    return shops.where((s) => s.categories.contains(selected)).toList();
  }

  ShopsState copyWith({
    ShopsStatus? status,
    List<Shop>? shops,
    List<String>? categories,
    String? selectedCategory,
    bool clearCategory = false,
  }) {
    return ShopsState(
      status: status ?? this.status,
      shops: shops ?? this.shops,
      categories: categories ?? this.categories,
      selectedCategory:
          clearCategory ? null : (selectedCategory ?? this.selectedCategory),
    );
  }

  @override
  List<Object?> get props => [status, shops, categories, selectedCategory];
}
