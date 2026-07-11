import 'dart:async';

import 'package:dukkan/domain/auth/entities/app_user.dart';
import 'package:dukkan/domain/auth/entities/user_role.dart';
import 'package:dukkan/domain/auth/repositories/auth_repository.dart';
import 'package:dukkan/domain/auth/usecases/get_user_by_id.dart';
import 'package:dukkan/domain/order/entities/address.dart';
import 'package:dukkan/domain/order/entities/order.dart';
import 'package:dukkan/domain/order/entities/order_item.dart';
import 'package:dukkan/domain/order/entities/order_status.dart';
import 'package:dukkan/domain/order/repositories/order_repository.dart';
import 'package:dukkan/domain/order/usecases/cancel_order.dart';
import 'package:dukkan/domain/order/usecases/rate_order.dart';
import 'package:dukkan/domain/order/usecases/update_order_status.dart';
import 'package:dukkan/domain/order/usecases/watch_order.dart';
import 'package:dukkan/presentation/orders/bloc/order_detail_bloc.dart';
import 'package:dukkan/presentation/orders/order_viewer_role.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake so the owner-view customer fetch (M2) is testable without Firebase.
class _FakeAuthRepository implements AuthRepository {
  int getUserByIdCalls = 0;
  AppUser? userToReturn;

  @override
  Future<AppUser?> getUserById(String uid) async {
    getUserByIdCalls++;
    return userToReturn;
  }

  @override
  Stream<AppUser?> authStateChanges() => const Stream.empty();

  @override
  AppUser? get currentUser => null;

  @override
  Future<AppUser> logIn({required String email, required String password}) =>
      throw UnimplementedError();

  @override
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? phone,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> sendPasswordReset(String email) => throw UnimplementedError();

  @override
  Future<void> logOut() => throw UnimplementedError();

  @override
  Future<void> saveFcmToken(String uid, String token) async {}
}

/// Drives one order's stream by hand and lets a test force `cancelOrder` to
/// throw, so the failure path is reachable without Firebase.
class _FakeOrderRepository implements OrderRepository {
  final controller = StreamController<Order>();
  bool cancelShouldFail = false;
  int cancelCalls = 0;
  bool rateShouldFail = false;
  int rateCalls = 0;
  bool advanceShouldFail = false;
  int advanceCalls = 0;

  @override
  Stream<Order> watchOrder(String orderId) => controller.stream;

  @override
  Stream<List<Order>> watchCustomerOrders(String customerUid) =>
      const Stream.empty();

  @override
  Stream<List<Order>> watchShopOrders(String shopId) => const Stream.empty();

  @override
  Stream<List<Order>> watchDriverActiveOrders(String driverUid) =>
      const Stream.empty();

  @override
  Stream<List<Order>> watchDriverHistory(String driverUid) =>
      const Stream.empty();

  @override
  Future<void> cancelOrder(String orderId) async {
    cancelCalls++;
    if (cancelShouldFail) throw Exception('boom');
  }

  @override
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    advanceCalls++;
    if (advanceShouldFail) throw Exception('boom');
  }

  @override
  Future<void> rateOrder({
    required String orderId,
    required String shopId,
    required int rating,
  }) async {
    rateCalls++;
    if (rateShouldFail) throw Exception('boom');
  }

  @override
  Future<Order> placeOrder({
    required String shopId,
    required String customerUid,
    required List<OrderItem> items,
    required int totalMinor,
    required Address deliveryAddress,
    String? notes,
  }) async =>
      _order(OrderStatus.pending);
}

Order _order(OrderStatus status, {int? rating}) => Order(
      id: 'o1',
      shopId: 's1',
      customerUid: 'u1',
      items: const [
        OrderItem(
          productId: 'p1',
          name: 'Item',
          nameAr: 'منتج',
          priceMinor: 1000,
          quantity: 1,
        ),
      ],
      totalMinor: 1000,
      status: status,
      createdAt: DateTime(2026, 1, 1),
      deliveryAddress: const Address(line1: 'Street 1', city: 'Cairo'),
      rating: rating,
    );

void main() {
  late _FakeOrderRepository repo;
  late OrderDetailBloc bloc;

  setUp(() {
    repo = _FakeOrderRepository();
    bloc = OrderDetailBloc(
      orderId: 'o1',
      watchOrder: WatchOrder(repo),
      cancelOrder: CancelOrder(repo),
      rateOrder: RateOrder(repo),
      updateOrderStatus: UpdateOrderStatus(repo),
    );
  });

  tearDown(() async {
    await bloc.close();
    await repo.controller.close();
  });

  Future<void> tick() => Future<void>.delayed(Duration.zero);

  test('loads the order from the watch stream', () async {
    bloc.add(const OrderDetailStarted());
    await tick();

    repo.controller.add(_order(OrderStatus.pending));
    await tick();

    expect(bloc.state.status, OrderDetailStatus.loaded);
    expect(bloc.state.order!.status, OrderStatus.pending);
  });

  test('stream error surfaces as error status', () async {
    bloc.add(const OrderDetailStarted());
    await tick();

    repo.controller.addError(Exception('boom'));
    await tick();

    expect(bloc.state.status, OrderDetailStatus.error);
  });

  test('cancel calls the repository once and stays cancellable-driven, not '
      'self-patched', () async {
    bloc.add(const OrderDetailStarted());
    await tick();
    repo.controller.add(_order(OrderStatus.pending));
    await tick();

    bloc.add(const OrderDetailCancelRequested());
    await tick();

    expect(repo.cancelCalls, 1);
    // No local patch — status only changes when the stream delivers it.
    expect(bloc.state.order!.status, OrderStatus.pending);
  });

  test('cancel on a non-cancellable order is a no-op', () async {
    bloc.add(const OrderDetailStarted());
    await tick();
    repo.controller.add(_order(OrderStatus.delivered));
    await tick();

    bloc.add(const OrderDetailCancelRequested());
    await tick();

    expect(repo.cancelCalls, 0);
  });

  test('a failed cancel surfaces cancelStatus.failure', () async {
    repo.cancelShouldFail = true;
    bloc.add(const OrderDetailStarted());
    await tick();
    repo.controller.add(_order(OrderStatus.pending));
    await tick();

    bloc.add(const OrderDetailCancelRequested());
    await tick();

    expect(bloc.state.cancelStatus, OrderCancelStatus.failure);
  });

  test('a new stream snapshot resets cancelStatus back to idle', () async {
    repo.cancelShouldFail = true;
    bloc.add(const OrderDetailStarted());
    await tick();
    repo.controller.add(_order(OrderStatus.pending));
    await tick();
    bloc.add(const OrderDetailCancelRequested());
    await tick();
    expect(bloc.state.cancelStatus, OrderCancelStatus.failure);

    repo.controller.add(_order(OrderStatus.cancelled));
    await tick();

    expect(bloc.state.cancelStatus, OrderCancelStatus.idle);
  });

  test('rating a delivered order calls the repository once', () async {
    bloc.add(const OrderDetailStarted());
    await tick();
    repo.controller.add(_order(OrderStatus.delivered));
    await tick();

    bloc.add(const OrderDetailRateSubmitted(4));
    await tick();

    expect(repo.rateCalls, 1);
  });

  test('rating a non-delivered order is a no-op', () async {
    bloc.add(const OrderDetailStarted());
    await tick();
    repo.controller.add(_order(OrderStatus.preparing));
    await tick();

    bloc.add(const OrderDetailRateSubmitted(4));
    await tick();

    expect(repo.rateCalls, 0);
  });

  test('rating an already-rated order is a no-op', () async {
    bloc.add(const OrderDetailStarted());
    await tick();
    repo.controller.add(_order(OrderStatus.delivered, rating: 5));
    await tick();

    bloc.add(const OrderDetailRateSubmitted(3));
    await tick();

    expect(repo.rateCalls, 0);
  });

  test('a failed rate surfaces rateStatus.failure', () async {
    repo.rateShouldFail = true;
    bloc.add(const OrderDetailStarted());
    await tick();
    repo.controller.add(_order(OrderStatus.delivered));
    await tick();

    bloc.add(const OrderDetailRateSubmitted(2));
    await tick();

    expect(bloc.state.rateStatus, OrderRateStatus.failure);
  });

  test('a new stream snapshot resets rateStatus back to idle', () async {
    repo.rateShouldFail = true;
    bloc.add(const OrderDetailStarted());
    await tick();
    repo.controller.add(_order(OrderStatus.delivered));
    await tick();
    bloc.add(const OrderDetailRateSubmitted(2));
    await tick();
    expect(bloc.state.rateStatus, OrderRateStatus.failure);

    repo.controller.add(_order(OrderStatus.delivered, rating: 2));
    await tick();

    expect(bloc.state.rateStatus, OrderRateStatus.idle);
  });

  test('owner view fetches the customer profile once per order', () async {
    final authRepo = _FakeAuthRepository()
      ..userToReturn = const AppUser(
        uid: 'u1',
        email: 'c@x.com',
        name: 'Customer One',
        role: UserRole.customer,
        phone: '0100000000',
      );
    final ownerBloc = OrderDetailBloc(
      orderId: 'o1',
      watchOrder: WatchOrder(repo),
      cancelOrder: CancelOrder(repo),
      rateOrder: RateOrder(repo),
      updateOrderStatus: UpdateOrderStatus(repo),
      getUserById: GetUserById(authRepo),
      role: OrderViewerRole.owner,
    );
    addTearDown(ownerBloc.close);

    ownerBloc.add(const OrderDetailStarted());
    await tick();
    repo.controller.add(_order(OrderStatus.pending));
    await tick();
    await tick();

    expect(authRepo.getUserByIdCalls, 1);
    expect(ownerBloc.state.customer?.name, 'Customer One');

    // A later snapshot for the same order (same customerUid) must not
    // refetch — the profile is fetched once per order, not per snapshot.
    repo.controller.add(_order(OrderStatus.accepted));
    await tick();
    await tick();

    expect(authRepo.getUserByIdCalls, 1);
  });

  test('customer view never fetches a profile', () async {
    final authRepo = _FakeAuthRepository();
    final customerBloc = OrderDetailBloc(
      orderId: 'o1',
      watchOrder: WatchOrder(repo),
      cancelOrder: CancelOrder(repo),
      rateOrder: RateOrder(repo),
      updateOrderStatus: UpdateOrderStatus(repo),
      getUserById: GetUserById(authRepo),
    );
    addTearDown(customerBloc.close);

    customerBloc.add(const OrderDetailStarted());
    await tick();
    repo.controller.add(_order(OrderStatus.pending));
    await tick();

    expect(authRepo.getUserByIdCalls, 0);
    expect(customerBloc.state.customer, isNull);
  });

  test('courier advance calls the repository once', () async {
    bloc.add(const OrderDetailStarted());
    await tick();
    repo.controller.add(_order(OrderStatus.preparing));
    await tick();

    bloc.add(const OrderDetailAdvanceRequested(OrderStatus.outForDelivery));
    await tick();

    expect(repo.advanceCalls, 1);
    // No local patch — status only changes when the stream delivers it.
    expect(bloc.state.order!.status, OrderStatus.preparing);
  });

  test('a failed courier advance surfaces advanceStatus.failure', () async {
    repo.advanceShouldFail = true;
    bloc.add(const OrderDetailStarted());
    await tick();
    repo.controller.add(_order(OrderStatus.preparing));
    await tick();

    bloc.add(const OrderDetailAdvanceRequested(OrderStatus.outForDelivery));
    await tick();

    expect(bloc.state.advanceStatus, OrderAdvanceStatus.failure);
  });

  test('a new stream snapshot resets advanceStatus back to idle', () async {
    repo.advanceShouldFail = true;
    bloc.add(const OrderDetailStarted());
    await tick();
    repo.controller.add(_order(OrderStatus.preparing));
    await tick();
    bloc.add(const OrderDetailAdvanceRequested(OrderStatus.outForDelivery));
    await tick();
    expect(bloc.state.advanceStatus, OrderAdvanceStatus.failure);

    repo.controller.add(_order(OrderStatus.outForDelivery));
    await tick();

    expect(bloc.state.advanceStatus, OrderAdvanceStatus.idle);
  });
}
