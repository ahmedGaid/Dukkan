part of 'orders_board_bloc.dart';

enum OrdersBoardStatus { loading, loaded, error }

class OrdersBoardState extends Equatable {
  const OrdersBoardState({
    this.status = OrdersBoardStatus.loading,
    this.orders = const [],
    this.shops = const [],
    this.areas = const [],
    this.statusFilter,
    this.shopFilter,
    this.areaFilter,
    this.dateFrom,
    this.dateTo,
    this.hasMore = false,
    this.loadingMore = false,
    this.searching = false,
    this.searchResults,
  });

  final OrdersBoardStatus status;

  /// Every order loaded so far for [statusFilter] — server-paginated,
  /// newest first (see `OrdersBoardBloc` doc).
  final List<Order> orders;

  /// Loaded once on open — dropdown labels for [shopFilter]/[areaFilter].
  final List<Shop> shops;
  final List<Area> areas;

  /// null | one of the 7 wire statuses. The one server-side facet.
  final String? statusFilter;

  /// null | a shop id — client-side refine over [orders].
  final String? shopFilter;

  /// null | an area id — client-side refine over [orders].
  final String? areaFilter;

  final DateTime? dateFrom;
  final DateTime? dateTo;

  final bool hasMore;
  final bool loadingMore;
  final bool searching;

  /// Null = showing the normal paginated+filtered [orders]; non-null = an
  /// exact search result (order id / phone) replacing it entirely.
  final List<Order>? searchResults;

  /// [orders] narrowed by the shop/area/date-range facets — the search
  /// results (when present) are shown as-is, unfiltered by these.
  List<Order> get filtered {
    if (searchResults != null) return searchResults!;
    Iterable<Order> result = orders;
    if (shopFilter != null) {
      result = result.where((o) => o.shopId == shopFilter);
    }
    if (areaFilter != null) {
      result = result.where((o) => o.deliveryAddress.areaId == areaFilter);
    }
    if (dateFrom != null) {
      result = result.where((o) => !o.createdAt.isBefore(dateFrom!));
    }
    if (dateTo != null) {
      result = result.where((o) => !o.createdAt.isAfter(dateTo!));
    }
    return result.toList(growable: false);
  }

  static const _unset = Object();

  OrdersBoardState copyWith({
    OrdersBoardStatus? status,
    List<Order>? orders,
    List<Shop>? shops,
    List<Area>? areas,
    Object? statusFilter = _unset,
    Object? shopFilter = _unset,
    Object? areaFilter = _unset,
    Object? dateFrom = _unset,
    Object? dateTo = _unset,
    bool? hasMore,
    bool? loadingMore,
    bool? searching,
    Object? searchResults = _unset,
  }) {
    return OrdersBoardState(
      status: status ?? this.status,
      orders: orders ?? this.orders,
      shops: shops ?? this.shops,
      areas: areas ?? this.areas,
      statusFilter: statusFilter == _unset ? this.statusFilter : statusFilter as String?,
      shopFilter: shopFilter == _unset ? this.shopFilter : shopFilter as String?,
      areaFilter: areaFilter == _unset ? this.areaFilter : areaFilter as String?,
      dateFrom: dateFrom == _unset ? this.dateFrom : dateFrom as DateTime?,
      dateTo: dateTo == _unset ? this.dateTo : dateTo as DateTime?,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
      searching: searching ?? this.searching,
      searchResults: searchResults == _unset ? this.searchResults : searchResults as List<Order>?,
    );
  }

  @override
  List<Object?> get props => [
        status,
        orders,
        shops,
        areas,
        statusFilter,
        shopFilter,
        areaFilter,
        dateFrom,
        dateTo,
        hasMore,
        loadingMore,
        searching,
        searchResults,
      ];
}
