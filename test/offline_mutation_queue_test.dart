import 'package:dukkan/core/errors/failures.dart';
import 'package:dukkan/core/offline/offline_mutation_queue.dart';
import 'package:dukkan/core/offline/pending_mutation.dart';
import 'package:dukkan/domain/order/entities/order_status.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Always throws an offline-shaped [ServerFailure] — used wherever a test
/// needs a replay attempt to be made (so it counts as "attempted") but never
/// succeed, deterministically, instead of racing a trivially-succeeding
/// fake against the test's own un-awaited assertions.
Future<void> _neverReaches(String orderId, OrderStatus status) async =>
    throw const ServerFailure('offline', 'unavailable');

PendingMutation _mutation(String id, {String orderId = 'o1', String actorUid = 'u1'}) =>
    PendingMutation(
      id: id,
      orderId: orderId,
      targetStatus: OrderStatus.preparing,
      actorUid: actorUid,
      enqueuedAt: DateTime(2026, 8, 11),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('starts empty when nothing was persisted', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final queue = OfflineMutationQueue(
      prefs: prefs,
      currentUidProvider: () => 'u1',
      remoteUpdate: _neverReaches,
    );

    expect(queue.pendingForOrder('o1'), isEmpty);
    await queue.dispose();
  });

  test('enqueue makes the mutation visible via pendingForOrder immediately', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final queue = OfflineMutationQueue(
      prefs: prefs,
      currentUidProvider: () => 'u1',
      remoteUpdate: _neverReaches,
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
      currentUidProvider: () => 'u1',
      remoteUpdate: _neverReaches,
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
      currentUidProvider: () => 'u1',
      remoteUpdate: _neverReaches,
    );
    await first.enqueue(_mutation('m1'));
    await first.dispose();

    final second = OfflineMutationQueue(
      prefs: prefs,
      currentUidProvider: () => 'u1',
      remoteUpdate: _neverReaches,
    );

    expect(second.pendingForOrder('o1').single.id, 'm1');
    await second.dispose();
  });

  test('late subscriber to watchAll does not receive initial state (broadcast behavior)', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final first = OfflineMutationQueue(
      prefs: prefs,
      currentUidProvider: () => 'u1',
      remoteUpdate: _neverReaches,
    );
    await first.enqueue(_mutation('m1'));
    await first.dispose();

    // Construct a fresh queue with m1 already persisted. `_neverReaches`
    // keeps the constructor's own auto-replay (final-review I1) from ever
    // succeeding, so this test's late-subscriber assertion below stays
    // about broadcast-stream semantics, not a race against that replay.
    final second = OfflineMutationQueue(
      prefs: prefs,
      currentUidProvider: () => 'u1',
      remoteUpdate: _neverReaches,
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
      currentUidProvider: () => 'u1',
      remoteUpdate: _neverReaches,
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
      currentUidProvider: () => 'u1',
      remoteUpdate: _neverReaches,
    );

    expect(queue.pendingForOrder('o1'), isEmpty);
    await queue.dispose();
  });

  test('replay on enqueue: success removes the item and emits the drained list', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final queue = OfflineMutationQueue(
      prefs: prefs,
      currentUidProvider: () => 'u1',
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
      currentUidProvider: () => 'u1',
      remoteUpdate: (_, _) async =>
          throw const ServerFailure('offline', 'unavailable'),
    );

    await queue.enqueue(_mutation('m1'));
    await Future<void>.delayed(Duration.zero);

    expect(queue.pendingForOrder('o1').single.id, 'm1');
    await queue.dispose();
  });

  test(
      'a code-less ServerFailure (e.g. "not signed in" before the write ever '
      'reaches Firestore) is retried, never treated as a real rejection '
      '(final-review C2)', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    SyncFailure? failure;
    final queue = OfflineMutationQueue(
      prefs: prefs,
      currentUidProvider: () => 'u1',
      // No `code` — mirrors `_advanceStatus`'s "Not signed in" guard, which
      // fires before any FirebaseException could carry one.
      remoteUpdate: (_, _) async => throw const ServerFailure('Not signed in'),
    );
    final sub = queue.failures.listen((f) => failure = f);

    await queue.enqueue(_mutation('m1'));
    await Future<void>.delayed(Duration.zero);

    expect(queue.pendingForOrder('o1').single.id, 'm1');
    expect(failure, isNull);
    await sub.cancel();
    await queue.dispose();
  });

  test('replay removes the item and emits SyncFailure on a real rejection', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final queue = OfflineMutationQueue(
      prefs: prefs,
      currentUidProvider: () => 'u1',
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
      currentUidProvider: () => 'u1',
      remoteUpdate: (orderId, _) async {
        attempted.add(orderId);
        // Only o1 is still-offline; o2 would succeed if it were ever
        // attempted — this is what lets the test tell "stopped early" apart
        // from "tried everything and everything happened to fail".
        if (orderId == 'o1') {
          throw const ServerFailure('offline', 'unavailable');
        }
      },
    );

    await queue.enqueue(_mutation('m1', orderId: 'o1'));
    await queue.enqueue(_mutation('m2', orderId: 'o2'));
    await Future<void>.delayed(Duration.zero);

    // Each enqueue triggers its own immediate replay pass; o1 is attempted
    // every time (still queued, stops the pass), o2 is never reached.
    expect(attempted, contains('o1'));
    expect(attempted, isNot(contains('o2')));
    expect(queue.pendingForOrder('o1'), isNotEmpty);
    expect(queue.pendingForOrder('o2'), isNotEmpty);
    await queue.dispose();
  });

  test('an unexpected (non-ServerFailure) exception does not crash the pass or the item', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final attempted = <String>[];
    final queue = OfflineMutationQueue(
      prefs: prefs,
      currentUidProvider: () => 'u1',
      remoteUpdate: (orderId, _) async {
        attempted.add(orderId);
        if (orderId == 'o1') {
          throw Exception('boom: malformed response');
        }
      },
    );

    SyncFailure? failure;
    final sub = queue.failures.listen((f) => failure = f);

    await queue.enqueue(_mutation('m1', orderId: 'o1'));
    await queue.enqueue(_mutation('m2', orderId: 'o2'));
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    // The crash on o1 doesn't propagate and doesn't wedge the pass: o1 is
    // dropped (not retried forever) and o2, later in the same pass, still
    // gets attempted and succeeds.
    expect(queue.pendingForOrder('o1'), isEmpty);
    expect(queue.pendingForOrder('o2'), isEmpty);
    expect(attempted, contains('o2'));
    expect(failure?.orderId, 'o1');
    await sub.cancel();
    await queue.dispose();
  });

  test('a rejection does not block the rest of the same pass', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final queue = OfflineMutationQueue(
      prefs: prefs,
      currentUidProvider: () => 'u1',
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

  test('an app resume with a non-empty queue triggers a replay', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    var succeed = false;
    var attempts = 0;
    final queue = OfflineMutationQueue(
      prefs: prefs,
      currentUidProvider: () => 'u1',
      remoteUpdate: (_, _) async {
        attempts++;
        if (!succeed) throw const ServerFailure('offline', 'unavailable');
      },
    );
    await queue.enqueue(_mutation('m1'));
    await Future<void>.delayed(Duration.zero);
    expect(attempts, 1); // enqueue's own immediate pass; still offline, stays queued
    expect(queue.pendingForOrder('o1'), isNotEmpty);

    succeed = true;
    (queue as WidgetsBindingObserver)
      .didChangeAppLifecycleState(AppLifecycleState.resumed);
    await Future<void>.delayed(Duration.zero);

    expect(attempts, 2);
    expect(queue.pendingForOrder('o1'), isEmpty);
    await queue.dispose();
  });

  test('an app resume with an empty queue does not call remoteUpdate', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    var attempts = 0;
    final queue = OfflineMutationQueue(
      prefs: prefs,
      currentUidProvider: () => 'u1',
      remoteUpdate: (_, _) async => attempts++,
    );

    (queue as WidgetsBindingObserver)
      .didChangeAppLifecycleState(AppLifecycleState.resumed);
    await Future<void>.delayed(Duration.zero);

    expect(attempts, 0);
    await queue.dispose();
  });

  test(
      'a fresh instance over a persisted non-empty queue attempts remoteUpdate '
      'without any external trigger (final-review I1)', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final seed = OfflineMutationQueue(
      prefs: prefs,
      currentUidProvider: () => 'u1',
      remoteUpdate: _neverReaches,
    );
    await seed.enqueue(_mutation('m1'));
    await seed.dispose();

    var attempts = 0;
    final revived = OfflineMutationQueue(
      prefs: prefs,
      currentUidProvider: () => 'u1',
      remoteUpdate: (_, _) async => attempts++,
    );
    // No enqueue(), no didChangeAppLifecycleState() call — nothing external
    // triggers a replay here; the constructor itself must have started one.
    await Future<void>.delayed(Duration.zero);

    expect(attempts, 1);
    expect(revived.pendingForOrder('o1'), isEmpty);
    await revived.dispose();
  });

  test(
      'a mutation queued under a different signed-in identity is left queued, '
      'never replayed under the current one (final-review I4)', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final attempted = <String>[];
    final queue = OfflineMutationQueue(
      prefs: prefs,
      currentUidProvider: () => 'u2', // a different user is signed in now
      remoteUpdate: (orderId, _) async => attempted.add(orderId),
    );

    await queue.enqueue(_mutation('m1', actorUid: 'u1'));
    await Future<void>.delayed(Duration.zero);

    expect(attempted, isEmpty);
    expect(queue.pendingForOrder('o1').single.id, 'm1');
    await queue.dispose();
  });

  test(
      'a mismatched actor does not block a same-pass mutation from a matching '
      'actor (final-review I4)', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final attempted = <String>[];
    final queue = OfflineMutationQueue(
      prefs: prefs,
      currentUidProvider: () => 'u2',
      remoteUpdate: (orderId, _) async => attempted.add(orderId),
    );

    await queue.enqueue(_mutation('m1', orderId: 'o1', actorUid: 'u1'));
    await queue.enqueue(_mutation('m2', orderId: 'o2', actorUid: 'u2'));
    await Future<void>.delayed(Duration.zero);

    expect(attempted, ['o2']);
    expect(queue.pendingForOrder('o1'), isNotEmpty); // skipped, not attempted
    expect(queue.pendingForOrder('o2'), isEmpty); // matching actor, replayed
    await queue.dispose();
  });

  test(
      'replay never attempts or drops anything while nobody is signed in '
      '(final-review C2/I4)', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final attempted = <String>[];
    final queue = OfflineMutationQueue(
      prefs: prefs,
      currentUidProvider: () => null,
      remoteUpdate: (orderId, _) async => attempted.add(orderId),
    );

    await queue.enqueue(_mutation('m1'));
    await Future<void>.delayed(Duration.zero);

    expect(attempted, isEmpty);
    expect(queue.pendingForOrder('o1').single.id, 'm1');
    await queue.dispose();
  });

  test(
      'a sync failure survives with nobody subscribed at emission time, and '
      'is retrievable afterward (final-review I2)', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final queue = OfflineMutationQueue(
      prefs: prefs,
      currentUidProvider: () => 'u1',
      remoteUpdate: (_, _) async =>
          throw const ServerFailure('denied', 'permission-denied'),
    );

    // Nobody is listening to `failures` right now — no `.listen(...)` call
    // anywhere in this test before the failure fires.
    await queue.enqueue(_mutation('m1'));
    await Future<void>.delayed(Duration.zero);

    expect(queue.pendingForOrder('o1'), isEmpty); // dropped as a real rejection
    expect(queue.unseenFailures.single.orderId, 'o1'); // but not lost

    queue.markFailureSeen('o1');
    expect(queue.unseenFailures, isEmpty);

    await queue.dispose();
  });

  test('markFailureSeen only clears the named order, not every unseen failure', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final queue = OfflineMutationQueue(
      prefs: prefs,
      currentUidProvider: () => 'u1',
      remoteUpdate: (_, _) async =>
          throw const ServerFailure('denied', 'permission-denied'),
    );

    await queue.enqueue(_mutation('m1', orderId: 'o1'));
    await queue.enqueue(_mutation('m2', orderId: 'o2'));
    await Future<void>.delayed(Duration.zero);

    expect(queue.unseenFailures.map((f) => f.orderId), containsAll(['o1', 'o2']));

    queue.markFailureSeen('o1');

    expect(queue.unseenFailures.map((f) => f.orderId), ['o2']);
    await queue.dispose();
  });
}
