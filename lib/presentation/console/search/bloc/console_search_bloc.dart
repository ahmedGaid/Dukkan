import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/search/arabic_fold.dart';
import '../../../../domain/admin/entities/admin_profile.dart';
import '../../../../domain/admin/entities/console_search_results.dart';
import '../../../../domain/admin/entities/managed_user.dart';
import '../../../../domain/admin/entities/permissions.dart';
import '../../../../domain/admin/usecases/get_all_areas.dart';
import '../../../../domain/admin/usecases/get_all_categories.dart';
import '../../../../domain/admin/usecases/get_all_drivers.dart';
import '../../../../domain/admin/usecases/get_all_shops.dart';
import '../../../../domain/admin/usecases/get_console_order_by_id.dart';
import '../../../../domain/admin/usecases/get_user_by_email.dart';
import '../../../../domain/admin/usecases/get_user_by_phone.dart';
import '../../../../domain/admin/usecases/search_products.dart';
import '../../../../domain/admin/usecases/search_users_by_name.dart';
import '../../../../domain/areas/entities/area.dart';
import '../../../../domain/driver/entities/driver.dart';
import '../../../../domain/order/entities/order.dart';
import '../../../../domain/product/entities/product.dart';
import '../../../../domain/shop/entities/shop.dart';
import '../../../../domain/taxonomy/entities/category.dart';

part 'console_search_event.dart';
part 'console_search_state.dart';

const _resultLimit = 5;

/// Drives the console's Ctrl+K global search (FC17). Debounce lives in the
/// dialog widget — this bloc runs the seven lookup groups in parallel on
/// every [ConsoleSearchQueryChanged], each independently try/caught so one
/// denied permission or one failed query never blanks the other groups
/// (`Future.wait` over closures that swallow their own errors, per the
/// FILE_17 spec, rather than `Future.wait`'s own error propagation which
/// would cancel siblings on the first rejection).
///
/// [admin] is fixed for the dialog's lifetime (a factory param, mirrors
/// `DevToolsBloc`'s `actorUid`) — only groups the caller's permissions allow
/// are ever queried, so a group they cannot read never appears, matching the
/// console menu's own `visibleConsoleSections` gating.
class ConsoleSearchBloc extends Bloc<ConsoleSearchEvent, ConsoleSearchState> {
  ConsoleSearchBloc({
    required this.admin,
    required GetConsoleOrderById getOrderById,
    required GetUserByEmail getUserByEmail,
    required GetUserByPhone getUserByPhone,
    required SearchUsersByName searchUsersByName,
    required GetAllShops getAllShops,
    required SearchProducts searchProducts,
    required GetAllDrivers getAllDrivers,
    required GetAllAreas getAllAreas,
    required GetAllCategories getAllCategories,
  })  : _getOrderById = getOrderById,
        _getUserByEmail = getUserByEmail,
        _getUserByPhone = getUserByPhone,
        _searchUsersByName = searchUsersByName,
        _getAllShops = getAllShops,
        _searchProducts = searchProducts,
        _getAllDrivers = getAllDrivers,
        _getAllAreas = getAllAreas,
        _getAllCategories = getAllCategories,
        super(const ConsoleSearchState()) {
    on<ConsoleSearchQueryChanged>(_onQueryChanged);
  }

  final AdminProfile admin;
  final GetConsoleOrderById _getOrderById;
  final GetUserByEmail _getUserByEmail;
  final GetUserByPhone _getUserByPhone;
  final SearchUsersByName _searchUsersByName;
  final GetAllShops _getAllShops;
  final SearchProducts _searchProducts;
  final GetAllDrivers _getAllDrivers;
  final GetAllAreas _getAllAreas;
  final GetAllCategories _getAllCategories;

  Future<void> _onQueryChanged(
    ConsoleSearchQueryChanged event,
    Emitter<ConsoleSearchState> emit,
  ) async {
    final query = event.query.trim();
    if (query.isEmpty) {
      emit(const ConsoleSearchState());
      return;
    }
    emit(state.copyWith(status: ConsoleSearchStatus.loading, query: query));
    final folded = normalizeSearch(query);

    Order? order;
    var users = const <ManagedUser>[];
    var shops = const <Shop>[];
    var products = const <Product>[];
    var drivers = const <Driver>[];
    var areas = const <Area>[];
    var categories = const <Category>[];

    await Future.wait([
      if (admin.can(Permissions.ordersRead))
        _guarded(() async => order = await _getOrderById(query)),
      if (admin.can(Permissions.usersRead))
        _guarded(() async => users = await _searchUsers(query)),
      if (admin.can(Permissions.shopsUpdate))
        _guarded(() async => shops = await _searchShops(folded)),
      if (admin.can(Permissions.productsUpdate))
        _guarded(() async => products = await _searchProductsGroup(folded)),
      if (admin.can(Permissions.driversManage))
        _guarded(() async => drivers = await _searchDrivers(query, folded)),
      if (admin.can(Permissions.geoEdit))
        _guarded(() async => areas = await _searchAreas(folded)),
      if (admin.can(Permissions.taxonomyEdit))
        _guarded(() async => categories = await _searchCategories(folded)),
    ]);

    // Only the latest queued event should win — a fast typist can queue
    // several; `on<>` drains them in order, so a stale one finishing last
    // would otherwise clobber a fresher result already rendered.
    if (state.query != query) return;

    emit(state.copyWith(
      status: ConsoleSearchStatus.ready,
      results: ConsoleSearchResults(
        order: order,
        users: users,
        shops: shops,
        products: products,
        drivers: drivers,
        areas: areas,
        categories: categories,
      ),
    ));
  }

  Future<void> _guarded(Future<void> Function() run) async {
    try {
      await run();
    } catch (_) {
      // Collapse to whatever default the group's local var already holds.
    }
  }

  Future<List<ManagedUser>> _searchUsers(String query) async {
    final emailFuture = _getUserByEmail(query);
    final phoneFuture = _getUserByPhone(query);
    final nameFuture = _searchUsersByName(query, limit: _resultLimit);
    final byEmail = await emailFuture;
    final byPhone = await phoneFuture;
    final byName = await nameFuture;
    final seen = <String>{};
    final merged = <ManagedUser>[];
    for (final u in [?byEmail, ?byPhone, ...byName]) {
      if (seen.add(u.uid)) merged.add(u);
    }
    return merged.take(_resultLimit).toList(growable: false);
  }

  Future<List<Shop>> _searchShops(String folded) async {
    final shops = await _getAllShops();
    return shops
        .where((s) => normalizeSearch(s.name).contains(folded) || normalizeSearch(s.nameAr).contains(folded))
        .take(_resultLimit)
        .toList(growable: false);
  }

  Future<List<Product>> _searchProductsGroup(String folded) async {
    final products = await _searchProducts();
    return products
        .where((p) => normalizeSearch(p.name).contains(folded) || normalizeSearch(p.nameAr).contains(folded))
        .take(_resultLimit)
        .toList(growable: false);
  }

  Future<List<Driver>> _searchDrivers(String query, String folded) async {
    final drivers = await _getAllDrivers();
    return drivers
        .where((d) => d.phone == query || normalizeSearch(d.name).contains(folded))
        .take(_resultLimit)
        .toList(growable: false);
  }

  Future<List<Area>> _searchAreas(String folded) async {
    final areas = await _getAllAreas();
    return areas
        .where((a) => normalizeSearch(a.nameAr).contains(folded) || normalizeSearch(a.nameEn).contains(folded))
        .take(_resultLimit)
        .toList(growable: false);
  }

  Future<List<Category>> _searchCategories(String folded) async {
    final categories = await _getAllCategories();
    return categories
        .where((c) => normalizeSearch(c.nameAr).contains(folded) || normalizeSearch(c.nameEn).contains(folded))
        .take(_resultLimit)
        .toList(growable: false);
  }
}
