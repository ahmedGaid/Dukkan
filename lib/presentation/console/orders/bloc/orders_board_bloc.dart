import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/admin/usecases/get_all_areas.dart';
import '../../../../domain/admin/usecases/get_all_shops.dart';
import '../../../../domain/admin/usecases/get_console_order_by_id.dart';
import '../../../../domain/admin/usecases/get_orders_by_customer.dart';
import '../../../../domain/admin/usecases/get_orders_page.dart';
import '../../../../domain/admin/usecases/get_user_by_phone.dart';
import '../../../../domain/areas/entities/area.dart';
import '../../../../domain/order/entities/order.dart';
import '../../../../domain/shop/entities/shop.dart';

part 'orders_board_event.dart';
part 'orders_board_state.dart';

/// Drives the console order board (`/console/orders`, FC10). [statusFilter]
/// is the one server-side equality facet (paginated, newest first — see
/// `AdminOrdersRepository` doc); shop/area/date-range narrow the
/// already-loaded pages client-side, the same "small marketplace, filter
/// what's loaded" contract `ShopsBoardBloc` uses, just with real server
/// pagination underneath since order history keeps growing. The search field
/// is a separate exact lookup (order id direct-get, or phone -> customer's
/// orders) that replaces the visible list, mirroring `UsersBloc`.
class OrdersBoardBloc extends Bloc<OrdersBoardEvent, OrdersBoardState> {
  OrdersBoardBloc({
    required GetOrdersPage getOrdersPage,
    required GetConsoleOrderById getOrderById,
    required GetOrdersByCustomer getOrdersByCustomer,
    required GetUserByPhone getUserByPhone,
    required GetAllShops getAllShops,
    required GetAllAreas getAllAreas,
  })  : _getOrdersPage = getOrdersPage,
        _getOrderById = getOrderById,
        _getOrdersByCustomer = getOrdersByCustomer,
        _getUserByPhone = getUserByPhone,
        _getAllShops = getAllShops,
        _getAllAreas = getAllAreas,
        super(const OrdersBoardState()) {
    on<OrdersBoardStarted>(_onStarted);
    on<OrdersBoardRetryRequested>(_onRetry);
    on<OrdersBoardStatusFilterChanged>(_onStatusFilterChanged);
    on<OrdersBoardShopFilterChanged>(
      (e, emit) => emit(state.copyWith(shopFilter: e.shopId)),
    );
    on<OrdersBoardAreaFilterChanged>(
      (e, emit) => emit(state.copyWith(areaFilter: e.areaId)),
    );
    on<OrdersBoardDateRangeChanged>(
      (e, emit) => emit(state.copyWith(dateFrom: e.from, dateTo: e.to)),
    );
    on<OrdersBoardLoadMoreRequested>(_onLoadMore);
    on<OrdersBoardSearchSubmitted>(_onSearchSubmitted);
    on<OrdersBoardSearchCleared>(
      (e, emit) => emit(state.copyWith(searchResults: null)),
    );
  }

  final GetOrdersPage _getOrdersPage;
  final GetConsoleOrderById _getOrderById;
  final GetOrdersByCustomer _getOrdersByCustomer;
  final GetUserByPhone _getUserByPhone;
  final GetAllShops _getAllShops;
  final GetAllAreas _getAllAreas;

  Future<void> _onStarted(OrdersBoardStarted event, Emitter<OrdersBoardState> emit) async {
    final status = event.initialStatus ?? state.statusFilter;
    emit(state.copyWith(status: OrdersBoardStatus.loading, statusFilter: status));
    try {
      final results = await Future.wait([_getAllShops(), _getAllAreas()]);
      final page = await _getOrdersPage(status: status);
      emit(state.copyWith(
        status: OrdersBoardStatus.loaded,
        shops: results[0] as List<Shop>,
        areas: results[1] as List<Area>,
        orders: page.orders,
        hasMore: page.hasMore,
      ));
    } catch (_) {
      emit(state.copyWith(status: OrdersBoardStatus.error));
    }
  }

  Future<void> _onRetry(
    OrdersBoardRetryRequested event,
    Emitter<OrdersBoardState> emit,
  ) =>
      _onStarted(OrdersBoardStarted(initialStatus: state.statusFilter), emit);

  Future<void> _onStatusFilterChanged(
    OrdersBoardStatusFilterChanged event,
    Emitter<OrdersBoardState> emit,
  ) async {
    emit(state.copyWith(
      status: OrdersBoardStatus.loading,
      statusFilter: event.status,
      orders: const [],
    ));
    try {
      final page = await _getOrdersPage(status: event.status);
      emit(state.copyWith(status: OrdersBoardStatus.loaded, orders: page.orders, hasMore: page.hasMore));
    } catch (_) {
      emit(state.copyWith(status: OrdersBoardStatus.error));
    }
  }

  Future<void> _onLoadMore(
    OrdersBoardLoadMoreRequested event,
    Emitter<OrdersBoardState> emit,
  ) async {
    if (state.status != OrdersBoardStatus.loaded ||
        state.loadingMore ||
        !state.hasMore ||
        state.orders.isEmpty) {
      return;
    }
    emit(state.copyWith(loadingMore: true));
    try {
      final page = await _getOrdersPage(
        status: state.statusFilter,
        cursor: state.orders.last.createdAt,
      );
      emit(state.copyWith(
        orders: [...state.orders, ...page.orders],
        hasMore: page.hasMore,
        loadingMore: false,
      ));
    } catch (_) {
      emit(state.copyWith(loadingMore: false, hasMore: false));
    }
  }

  static final _phonePattern = RegExp(r'^[0-9+ ]{4,}$');

  Future<void> _onSearchSubmitted(
    OrdersBoardSearchSubmitted event,
    Emitter<OrdersBoardState> emit,
  ) async {
    final query = event.query.trim();
    if (query.isEmpty) {
      emit(state.copyWith(searchResults: null));
      return;
    }
    emit(state.copyWith(searching: true));
    try {
      if (_phonePattern.hasMatch(query)) {
        final user = await _getUserByPhone(query);
        final orders = user == null ? const <Order>[] : await _getOrdersByCustomer(user.uid);
        emit(state.copyWith(searching: false, searchResults: orders));
      } else {
        final order = await _getOrderById(query);
        emit(state.copyWith(searching: false, searchResults: order == null ? const [] : [order]));
      }
    } catch (_) {
      emit(state.copyWith(searching: false, searchResults: const []));
    }
  }
}
