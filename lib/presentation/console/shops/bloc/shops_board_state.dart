part of 'shops_board_bloc.dart';

enum ShopsBoardStatus { loading, loaded, error }

class ShopsBoardState extends Equatable {
  const ShopsBoardState({
    this.status = ShopsBoardStatus.loading,
    this.allShops = const [],
    this.statusFilter,
    this.query = '',
    this.visibleCount = _pageSize,
  });

  static const _pageSize = 20;

  final ShopsBoardStatus status;
  final List<Shop> allShops;

  /// null | 'pending' | 'active' | 'suspended' | 'deleted'.
  final String? statusFilter;
  final String query;
  final int visibleCount;

  /// [allShops] narrowed by the status chip and the search query. `deleted`
  /// shows soft-deleted shops regardless of `status`; every other chip
  /// (including "all") excludes deleted shops — a deleted shop is only ever
  /// reachable through its own chip.
  List<Shop> get filtered {
    Iterable<Shop> shops = allShops;
    if (statusFilter == 'deleted') {
      shops = shops.where((s) => s.deleted);
    } else {
      shops = shops.where((s) => !s.deleted);
      if (statusFilter != null) {
        shops = shops.where((s) => s.status == statusFilter);
      }
    }
    final q = normalizeSearch(query);
    if (q.isNotEmpty) {
      shops = shops.where(
        (s) => normalizeSearch(s.name).contains(q) || normalizeSearch(s.nameAr).contains(q),
      );
    }
    return shops.toList(growable: false);
  }

  List<Shop> get visible => filtered.take(visibleCount).toList(growable: false);

  bool get hasMore => filtered.length > visibleCount;

  static const _unset = Object();

  ShopsBoardState copyWith({
    ShopsBoardStatus? status,
    List<Shop>? allShops,
    Object? statusFilter = _unset,
    String? query,
    int? visibleCount,
  }) {
    return ShopsBoardState(
      status: status ?? this.status,
      allShops: allShops ?? this.allShops,
      statusFilter: statusFilter == _unset ? this.statusFilter : statusFilter as String?,
      query: query ?? this.query,
      visibleCount: visibleCount ?? this.visibleCount,
    );
  }

  @override
  List<Object?> get props => [status, allShops, statusFilter, query, visibleCount];
}
