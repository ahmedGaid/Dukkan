import 'package:dukkan/core/errors/failures.dart';
import 'package:dukkan/core/offline/offline_mutation_queue.dart';
import 'package:dukkan/data/order/repositories/order_repository_impl.dart';
import 'package:dukkan/domain/order/entities/order_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('online: updateOrderStatus calls the remote directly, never the queue', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    var remoteCalls = 0;
    final queue = OfflineMutationQueue(
      prefs: prefs,
      currentUidProvider: () => 'u1',
      remoteUpdate: (_, _) async {},
    );
    final repo = OrderRepositoryImpl.forTest(
      updateOrderStatusRemote: (_, _) async => remoteCalls++,
      queue: queue,
      currentUidProvider: () => 'u1',
    );

    await repo.updateOrderStatus('o1', OrderStatus.accepted);

    expect(remoteCalls, 1);
    expect(queue.pendingForOrder('o1'), isEmpty);
    addTearDown(queue.dispose);
  });

  test(
      'offline: updateOrderStatus enqueues instead of propagating the failure, '
      'reached via try-then-catch (final-review I3) — the remote write is '
      'always attempted first; only a failure that looks like "couldn\'t '
      'reach the server" falls back to the queue', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    var remoteCalls = 0;
    final queue = OfflineMutationQueue(
      prefs: prefs,
      currentUidProvider: () => 'u1',
      remoteUpdate: (_, _) async {},
    );
    final repo = OrderRepositoryImpl.forTest(
      updateOrderStatusRemote: (_, _) async {
        remoteCalls++;
        throw const ServerFailure('offline', 'unavailable');
      },
      queue: queue,
      currentUidProvider: () => 'u1',
    );

    await repo.updateOrderStatus('o1', OrderStatus.rejected);

    expect(remoteCalls, 1); // the write WAS attempted — this is the "try"
    expect(queue.pendingForOrder('o1').single.targetStatus, OrderStatus.rejected);
    expect(queue.pendingForOrder('o1').single.actorUid, 'u1');
    addTearDown(queue.dispose);
  });

  test(
      'a real (non-offline-shaped) rejection propagates straight to the '
      'caller instead of being queued', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final queue = OfflineMutationQueue(
      prefs: prefs,
      currentUidProvider: () => 'u1',
      remoteUpdate: (_, _) async {},
    );
    final repo = OrderRepositoryImpl.forTest(
      updateOrderStatusRemote: (_, _) async =>
          throw const ServerFailure('denied', 'permission-denied'),
      queue: queue,
      currentUidProvider: () => 'u1',
    );

    await expectLater(
      () => repo.updateOrderStatus('o1', OrderStatus.rejected),
      throwsA(isA<ServerFailure>()),
    );

    expect(queue.pendingForOrder('o1'), isEmpty);
    addTearDown(queue.dispose);
  });

  test(
      'a code-less ServerFailure (e.g. auth not ready yet right after cold '
      'start) is also queued, not propagated (final-review C2)', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final queue = OfflineMutationQueue(
      prefs: prefs,
      currentUidProvider: () => 'u1',
      remoteUpdate: (_, _) async {},
    );
    final repo = OrderRepositoryImpl.forTest(
      updateOrderStatusRemote: (_, _) async => throw const ServerFailure('Not signed in'),
      queue: queue,
      currentUidProvider: () => 'u1',
    );

    await repo.updateOrderStatus('o1', OrderStatus.rejected);

    expect(queue.pendingForOrder('o1').single.targetStatus, OrderStatus.rejected);
    addTearDown(queue.dispose);
  });
}
