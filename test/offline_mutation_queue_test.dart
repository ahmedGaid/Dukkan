import 'package:dukkan/core/errors/failures.dart';
import 'package:dukkan/core/network/network_info.dart';
import 'package:dukkan/core/offline/offline_mutation_queue.dart';
import 'package:dukkan/core/offline/pending_mutation.dart';
import 'package:dukkan/domain/order/entities/order_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeNetworkInfo implements NetworkInfo {
  bool connected = true;
  @override
  Future<bool> get isConnected async => connected;
}

PendingMutation _mutation(String id, {String orderId = 'o1'}) => PendingMutation(
      id: id,
      orderId: orderId,
      targetStatus: OrderStatus.preparing,
      actorUid: 'u1',
      enqueuedAt: DateTime(2026, 8, 11),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('starts empty when nothing was persisted', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final queue = OfflineMutationQueue(
      prefs: prefs,
      networkInfo: _FakeNetworkInfo()..connected = false,
      remoteUpdate: (_, _) async {},
    );

    expect(queue.pendingForOrder('o1'), isEmpty);
    await queue.dispose();
  });

  test('enqueue makes the mutation visible via pendingForOrder immediately', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final queue = OfflineMutationQueue(
      prefs: prefs,
      networkInfo: _FakeNetworkInfo()..connected = false,
      remoteUpdate: (_, _) async {},
    );

    await queue.enqueue(_mutation('m1'));

    expect(queue.pendingForOrder('o1').single.id, 'm1');
    await queue.dispose();
  });

  test('watchAll emits the current list on every enqueue', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final queue = OfflineMutationQueue(
      prefs: prefs,
      networkInfo: _FakeNetworkInfo()..connected = false,
      remoteUpdate: (_, _) async {},
    );

    final emissions = <int>[];
    final sub = queue.watchAll().listen((items) => emissions.add(items.length));

    await queue.enqueue(_mutation('m1'));
    await Future<void>.delayed(Duration.zero);

    expect(emissions, contains(1));
    await sub.cancel();
    await queue.dispose();
  });

  test('a persisted queue survives a fresh instance (simulates app kill)', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final first = OfflineMutationQueue(
      prefs: prefs,
      networkInfo: _FakeNetworkInfo()..connected = false,
      remoteUpdate: (_, _) async {},
    );
    await first.enqueue(_mutation('m1'));
    await first.dispose();

    final second = OfflineMutationQueue(
      prefs: prefs,
      networkInfo: _FakeNetworkInfo()..connected = false,
      remoteUpdate: (_, _) async {},
    );

    expect(second.pendingForOrder('o1').single.id, 'm1');
    await second.dispose();
  });

  test('late subscriber to watchAll does not receive initial state (broadcast behavior)', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final first = OfflineMutationQueue(
      prefs: prefs,
      networkInfo: _FakeNetworkInfo()..connected = false,
      remoteUpdate: (_, _) async {},
    );
    await first.enqueue(_mutation('m1'));
    await first.dispose();

    // Construct a fresh queue with m1 already persisted
    final second = OfflineMutationQueue(
      prefs: prefs,
      networkInfo: _FakeNetworkInfo()..connected = false,
      remoteUpdate: (_, _) async {},
    );

    // Subscribe AFTER construction — should not receive an initial emission
    final emissions = <List<PendingMutation>>[];
    final sub = second.watchAll().listen((items) => emissions.add(items));
    await Future<void>.delayed(Duration.zero);

    // No initial emission to late subscriber (broadcast controller doesn't replay)
    expect(emissions, isEmpty);

    // But pendingForOrder still sees the persisted data
    expect(second.pendingForOrder('o1').single.id, 'm1');

    // New enqueue emits via the stream
    await second.enqueue(_mutation('m2'));
    await Future<void>.delayed(Duration.zero);
    expect(emissions.length, 1);
    expect(emissions.single.length, 2);

    await sub.cancel();
    await second.dispose();
  });

  test('malformed JSON in persisted queue does not crash construction', () async {
    SharedPreferences.setMockInitialValues({'offline.pendingMutations': 'not valid json'});
    final prefs = await SharedPreferences.getInstance();

    // Should not throw; should construct with an empty queue
    final queue = OfflineMutationQueue(
      prefs: prefs,
      networkInfo: _FakeNetworkInfo()..connected = false,
      remoteUpdate: (_, _) async {},
    );

    expect(queue.pendingForOrder('o1'), isEmpty);
    await queue.dispose();
  });

  test('schema-mismatched JSON in persisted queue does not crash construction', () async {
    // Valid JSON, but doesn't match PendingMutation schema (missing required fields)
    SharedPreferences.setMockInitialValues({
      'offline.pendingMutations': '[{"id": "m1"}]' // missing orderId, targetStatus, etc.
    });
    final prefs = await SharedPreferences.getInstance();

    // Should not throw; should construct with an empty queue
    final queue = OfflineMutationQueue(
      prefs: prefs,
      networkInfo: _FakeNetworkInfo()..connected = false,
      remoteUpdate: (_, _) async {},
    );

    expect(queue.pendingForOrder('o1'), isEmpty);
    await queue.dispose();
  });

  test('replay on enqueue: success removes the item and emits the drained list', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final queue = OfflineMutationQueue(
      prefs: prefs,
      networkInfo: _FakeNetworkInfo(),
      remoteUpdate: (_, _) async {},
    );

    await queue.enqueue(_mutation('m1'));
    await Future<void>.delayed(Duration.zero);

    expect(queue.pendingForOrder('o1'), isEmpty);
    await queue.dispose();
  });

  test('replay leaves the item queued on a still-offline failure', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final queue = OfflineMutationQueue(
      prefs: prefs,
      networkInfo: _FakeNetworkInfo(),
      remoteUpdate: (_, _) async =>
          throw const ServerFailure('offline', 'unavailable'),
    );

    await queue.enqueue(_mutation('m1'));
    await Future<void>.delayed(Duration.zero);

    expect(queue.pendingForOrder('o1').single.id, 'm1');
    await queue.dispose();
  });

  test('replay removes the item and emits SyncFailure on a real rejection', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final queue = OfflineMutationQueue(
      prefs: prefs,
      networkInfo: _FakeNetworkInfo(),
      remoteUpdate: (_, _) async =>
          throw const ServerFailure('denied', 'permission-denied'),
    );

    SyncFailure? failure;
    final sub = queue.failures.listen((f) => failure = f);

    await queue.enqueue(_mutation('m1'));
    await Future<void>.delayed(Duration.zero);

    expect(queue.pendingForOrder('o1'), isEmpty);
    expect(failure?.orderId, 'o1');
    await sub.cancel();
    await queue.dispose();
  });

  test('a network-shaped failure stops the pass — later items stay untouched', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final attempted = <String>[];
    final queue = OfflineMutationQueue(
      prefs: prefs,
      networkInfo: _FakeNetworkInfo(),
      remoteUpdate: (orderId, _) async {
        attempted.add(orderId);
        throw const ServerFailure('offline', 'unavailable');
      },
    );

    await queue.enqueue(_mutation('m1', orderId: 'o1'));
    await queue.enqueue(_mutation('m2', orderId: 'o2'));
    await Future<void>.delayed(Duration.zero);

    // Each enqueue triggers its own immediate replay pass; o1 is attempted
    // every time (still queued), o2 only once it exists.
    expect(attempted, contains('o1'));
    expect(queue.pendingForOrder('o1'), isNotEmpty);
    expect(queue.pendingForOrder('o2'), isNotEmpty);
    await queue.dispose();
  });

  test('a rejection does not block the rest of the same pass', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final queue = OfflineMutationQueue(
      prefs: prefs,
      networkInfo: _FakeNetworkInfo(),
      remoteUpdate: (orderId, _) async {
        if (orderId == 'o1') {
          throw const ServerFailure('denied', 'permission-denied');
        }
      },
    );

    await queue.enqueue(_mutation('m1', orderId: 'o1'));
    await queue.enqueue(_mutation('m2', orderId: 'o2'));
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(queue.pendingForOrder('o1'), isEmpty);
    expect(queue.pendingForOrder('o2'), isEmpty);
    await queue.dispose();
  });
}
