# Offline Order-Status Queue (O2 slice 1) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let the owner and courier advance an order's status while offline — the 5 transitions below queue locally and replay automatically once signal returns, instead of failing outright.

**Architecture:** A new core service (`OfflineMutationQueue`) persists pending status writes via `shared_preferences` and replays them on a timer/reconnect/app-resume. `OrderRepositoryImpl.updateOrderStatus` gets its first offline branch: online writes go straight through as today; offline writes enqueue instead. Three existing BLoCs (`OwnerOrdersBloc`, `DeliveriesBloc`, `OrderDetailBloc`) merge the queue's live state into their own so the owner desk, courier active list, and order-detail page can show a "pending sync" badge and a blame-free failure banner.

**Tech Stack:** Flutter/Dart, `shared_preferences` (existing dep, no new dependency), `cloud_firestore` (`FirebaseException.code`), `flutter_bloc`.

## Global Constraints

- No new dependency — persistence uses the already-present `shared_preferences` package (design doc, `Docs/plan/offline-order-status-queue-design.md`).
- Money/i18n/RTL rules from `CLAUDE.md` apply to every new string: both `lib/l10n/app_ar.arb` and `app_en.arb` gain the same keys, parity script must stay green.
- Queue scope is locked to exactly 5 transitions, actor-agnostic (`OrderRepositoryImpl.updateOrderStatus` never branches on target status): `pending→accepted`, `pending→rejected`, `accepted→preparing`, `preparing→outForDelivery`, `outForDelivery→delivered`. Driver assignment, order placement, cart/profile edits, and every console/admin mutation stay online-only (design doc, "Explicitly OUT of scope").
- FIFO across the whole queue, not per-order (design doc, "Replay + error handling").
- Gates before any task counts as done: `flutter analyze` (0 issues), `flutter test` (all green), `dart run scripts/check_i18n_parity.dart` (green).
- Blame-free copy only — no raw Firestore error code/message ever reaches a user-facing string (existing house rule, e.g. `collections_bloc.dart`'s "حصلت مشكلة — جرّب تاني").

---

### Task 1: `ServerFailure` gains a structured `code`

**Files:**
- Modify: `lib/core/errors/failures.dart:15-17`
- Modify: `lib/data/order/datasources/order_remote_datasource.dart:234-236`
- Test: `test/failures_test.dart` (new)

**Interfaces:**
- Produces: `ServerFailure([String message = '', String? code])` — positional optional params, matching the existing `Failure([this.message = ''])` base-class style. `code` defaults to `null`, so every existing call site (`ServerFailure(e.message ?? e.code)` elsewhere in the codebase, unchanged) keeps compiling and behaving identically.

- [ ] **Step 1: Write the failing test**

```dart
// test/failures_test.dart
import 'package:dukkan/core/errors/failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ServerFailure defaults code to null (existing call sites unaffected)', () {
    const failure = ServerFailure('boom');
    expect(failure.message, 'boom');
    expect(failure.code, isNull);
  });

  test('ServerFailure carries a structured code when given one', () {
    const failure = ServerFailure('The order was already updated', 'permission-denied');
    expect(failure.code, 'permission-denied');
  });

  test('two ServerFailures with the same message but different codes are not equal', () {
    expect(
      const ServerFailure('x', 'unavailable') == const ServerFailure('x', 'permission-denied'),
      isFalse,
    );
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/failures_test.dart`
Expected: FAIL — `ServerFailure` has no `code` parameter yet (compile error).

- [ ] **Step 3: Add the field**

In `lib/core/errors/failures.dart`, replace:

```dart
class ServerFailure extends Failure {
  const ServerFailure([super.message]);
}
```

with:

```dart
class ServerFailure extends Failure {
  const ServerFailure([super.message, this.code]);

  /// The originating `FirebaseException.code`, when known — lets a caller
  /// (the offline mutation queue's replay loop) tell "still offline" apart
  /// from "the server actually rejected this" without parsing [message].
  /// Null for every failure that isn't wrapping a `FirebaseException`.
  final String? code;

  @override
  List<Object?> get props => [message, code];
}
```

- [ ] **Step 4: Thread the code through the one call site that has it**

In `lib/data/order/datasources/order_remote_datasource.dart`, `_advanceStatus`'s catch block currently reads:

```dart
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
```

Change to:

```dart
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code, e.code);
    }
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/failures_test.dart`
Expected: PASS (3/3)

- [ ] **Step 6: Full regression + commit**

Run: `flutter analyze` (expect 0 issues) and `flutter test` (expect all green — this is a backward-compatible additive change, no other test should move).

```bash
git add lib/core/errors/failures.dart lib/data/order/datasources/order_remote_datasource.dart test/failures_test.dart
git commit -m "feat(order): preserve FirebaseException.code on ServerFailure"
```

---

### Task 2: `PendingMutation` entity

**Files:**
- Create: `lib/core/offline/pending_mutation.dart`
- Test: `test/pending_mutation_test.dart`

**Interfaces:**
- Produces: `class PendingMutation` with fields `String id`, `String orderId`, `OrderStatus targetStatus`, `String actorUid`, `DateTime enqueuedAt`; `Map<String, dynamic> toJson()`; `PendingMutation.fromJson(Map<String, dynamic> json)` factory. Consumed by Task 3's `OfflineMutationQueue`.

- [ ] **Step 1: Write the failing test**

```dart
// test/pending_mutation_test.dart
import 'package:dukkan/core/offline/pending_mutation.dart';
import 'package:dukkan/domain/order/entities/order_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('toJson/fromJson round-trips every field', () {
    final original = PendingMutation(
      id: 'm1',
      orderId: 'o1',
      targetStatus: OrderStatus.preparing,
      actorUid: 'u1',
      enqueuedAt: DateTime(2026, 8, 11, 10, 30),
    );

    final restored = PendingMutation.fromJson(original.toJson());

    expect(restored.id, 'm1');
    expect(restored.orderId, 'o1');
    expect(restored.targetStatus, OrderStatus.preparing);
    expect(restored.actorUid, 'u1');
    expect(restored.enqueuedAt, DateTime(2026, 8, 11, 10, 30));
  });

  test('targetStatus round-trips via the wire form, not the enum index', () {
    final json = PendingMutation(
      id: 'm1',
      orderId: 'o1',
      targetStatus: OrderStatus.rejected,
      actorUid: 'u1',
      enqueuedAt: DateTime(2026, 1, 1),
    ).toJson();

    expect(json['targetStatus'], 'rejected');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/pending_mutation_test.dart`
Expected: FAIL — file `lib/core/offline/pending_mutation.dart` doesn't exist.

- [ ] **Step 3: Write the entity**

```dart
// lib/core/offline/pending_mutation.dart
import '../../domain/order/entities/order_status.dart';

/// One queued order-status write, waiting for signal (O2 slice 1 —
/// `Docs/plan/offline-order-status-queue-design.md`). Persisted as JSON by
/// `OfflineMutationQueue`, so every field must round-trip losslessly —
/// [targetStatus] goes through `OrderStatus.wire`/`fromWire`, never the raw
/// enum index (an enum reorder must never silently corrupt a saved queue).
class PendingMutation {
  const PendingMutation({
    required this.id,
    required this.orderId,
    required this.targetStatus,
    required this.actorUid,
    required this.enqueuedAt,
  });

  final String id;
  final String orderId;
  final OrderStatus targetStatus;
  final String actorUid;
  final DateTime enqueuedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderId': orderId,
        'targetStatus': targetStatus.wire,
        'actorUid': actorUid,
        'enqueuedAt': enqueuedAt.toIso8601String(),
      };

  factory PendingMutation.fromJson(Map<String, dynamic> json) => PendingMutation(
        id: json['id'] as String,
        orderId: json['orderId'] as String,
        targetStatus: OrderStatus.fromWire(json['targetStatus'] as String),
        actorUid: json['actorUid'] as String,
        enqueuedAt: DateTime.parse(json['enqueuedAt'] as String),
      );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/pending_mutation_test.dart`
Expected: PASS (2/2)

- [ ] **Step 5: Commit**

```bash
git add lib/core/offline/pending_mutation.dart test/pending_mutation_test.dart
git commit -m "feat(offline): add PendingMutation entity"
```

---

### Task 3: `OfflineMutationQueue` — persistence, hydration, enqueue

**Files:**
- Create: `lib/core/offline/offline_mutation_queue.dart`
- Test: `test/offline_mutation_queue_test.dart`

**Interfaces:**
- Consumes: `PendingMutation` (Task 2); `NetworkInfo.isConnected` (`lib/core/network/network_info.dart`, existing); `SharedPreferences` (already DI-resolved synchronously by the time this is constructed, see `core/di/injector.dart:315-317`).
- Produces: `class OfflineMutationQueue` — constructor `OfflineMutationQueue({required SharedPreferences prefs, required NetworkInfo networkInfo, required Future<void> Function(String orderId, OrderStatus status) remoteUpdate})`; `Future<void> enqueue(PendingMutation mutation)`; `Stream<List<PendingMutation>> watchAll()`; `List<PendingMutation> pendingForOrder(String orderId)` (sync). This task builds the class without replay/lifecycle yet — those are Tasks 4–5, added to the same file.

- [ ] **Step 1: Write the failing tests**

```dart
// test/offline_mutation_queue_test.dart
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
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/offline_mutation_queue_test.dart`
Expected: FAIL — `lib/core/offline/offline_mutation_queue.dart` doesn't exist.

- [ ] **Step 3: Write the class (persistence + hydration + enqueue only — no replay yet)**

```dart
// lib/core/offline/offline_mutation_queue.dart
import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/order/entities/order_status.dart';
import '../network/network_info.dart';
import 'pending_mutation.dart';

/// Queues an order-status write made while offline and replays it once
/// signal returns (O2 slice 1 — `Docs/plan/offline-order-status-queue-design.md`).
/// [prefs] is read synchronously (unlike `ProductLocalDataSource`'s `_ready`
/// guard) because by the time this is constructed via DI, `SharedPreferences`
/// was already awaited once at app start (`core/di/injector.dart`).
class OfflineMutationQueue {
  OfflineMutationQueue({
    required SharedPreferences prefs,
    required NetworkInfo networkInfo,
    required Future<void> Function(String orderId, OrderStatus status) remoteUpdate,
  })  : _prefs = prefs,
        _networkInfo = networkInfo,
        _remoteUpdate = remoteUpdate,
        _items = _load(prefs) {
    _controller.add(List.unmodifiable(_items));
  }

  static const _key = 'offline.pendingMutations';

  final SharedPreferences _prefs;
  final NetworkInfo _networkInfo;
  final Future<void> Function(String orderId, OrderStatus status) _remoteUpdate;
  final _controller = StreamController<List<PendingMutation>>.broadcast();
  List<PendingMutation> _items;

  Stream<List<PendingMutation>> watchAll() => _controller.stream;

  /// Sync lookup for the overlay widgets (owner desk / courier list / order
  /// detail) — they need this on every build, not via an awaited call.
  List<PendingMutation> pendingForOrder(String orderId) =>
      _items.where((m) => m.orderId == orderId).toList();

  Future<void> enqueue(PendingMutation mutation) async {
    _items = [..._items, mutation];
    await _persist();
    _controller.add(List.unmodifiable(_items));
  }

  Future<void> _persist() async {
    final raw = jsonEncode(_items.map((m) => m.toJson()).toList());
    await _prefs.setString(_key, raw);
  }

  static List<PendingMutation> _load(SharedPreferences prefs) {
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => PendingMutation.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}
```

Note: `_networkInfo` is unused so far (`flutter analyze` will flag it) — that's expected, Task 4 wires it into the replay loop this file gains next. Leave the field in place.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/offline_mutation_queue_test.dart`
Expected: PASS (4/4). `flutter analyze` will show one `unused_field`-adjacent info for `_networkInfo`/`_remoteUpdate` — acceptable transiently, resolved by Task 4 in the same file.

- [ ] **Step 5: Commit**

```bash
git add lib/core/offline/offline_mutation_queue.dart test/offline_mutation_queue_test.dart
git commit -m "feat(offline): OfflineMutationQueue persistence + enqueue"
```

---

### Task 4: `OfflineMutationQueue` — replay loop (success / still-offline / rejection)

**Files:**
- Modify: `lib/core/offline/offline_mutation_queue.dart`
- Test: `test/offline_mutation_queue_test.dart`

**Interfaces:**
- Consumes: `ServerFailure.code` (Task 1).
- Produces: `Stream<SyncFailure> get failures`; `class SyncFailure { final String orderId; final String reason; }` (same file). Replay is triggered by `enqueue` (Task 3, extended below) and a periodic timer that runs only while the queue is non-empty.

- [ ] **Step 1: Write the failing tests**

Append to `test/offline_mutation_queue_test.dart` (inside `main()`, alongside the Task 3 tests):

```dart
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/offline_mutation_queue_test.dart`
Expected: FAIL — no `failures` getter, no `SyncFailure` class, `enqueue` doesn't replay yet.

- [ ] **Step 3: Add the replay loop**

In `lib/core/offline/offline_mutation_queue.dart`, add the import (only `ServerFailure` is caught in the replay loop below, not `FirebaseException` directly — Task 1 already made `ServerFailure.code` carry what's needed):

```dart
import '../errors/failures.dart';
```

Add the failure controller and constant, and extend the constructor body + `enqueue`:

```dart
  static const _offlineCodes = {
    'unavailable',
    'deadline-exceeded',
    'cancelled',
    'unknown',
    'aborted',
    'internal',
  };

  final _failureController = StreamController<SyncFailure>.broadcast();
  Timer? _timer;

  Stream<SyncFailure> get failures => _failureController.stream;
```

Update `enqueue` to trigger a replay and start the timer:

```dart
  Future<void> enqueue(PendingMutation mutation) async {
    _items = [..._items, mutation];
    await _persist();
    _controller.add(List.unmodifiable(_items));
    _startTimer();
    unawaited(_replay());
  }

  void _startTimer() {
    _timer ??= Timer.periodic(const Duration(seconds: 15), (_) => _replay());
  }

  void _stopTimerIfDrained() {
    if (_items.isEmpty) {
      _timer?.cancel();
      _timer = null;
    }
  }

  /// One FIFO pass over a snapshot of the queue. A network-shaped failure
  /// (still offline) stops the pass immediately — the next trigger retries
  /// everything from the top. A real rejection only drops that one item and
  /// keeps going, so one bad conflict never blocks the rest of the queue
  /// (design doc, "Replay + error handling").
  Future<void> _replay() async {
    if (_items.isEmpty) return;
    if (!await _networkInfo.isConnected) return;
    for (final mutation in [..._items]) {
      try {
        await _remoteUpdate(mutation.orderId, mutation.targetStatus);
        _remove(mutation.id);
      } on ServerFailure catch (e) {
        if (e.code != null && _offlineCodes.contains(e.code)) return;
        _remove(mutation.id);
        _failureController.add(SyncFailure(orderId: mutation.orderId, reason: e.code ?? 'unknown'));
      }
    }
    _stopTimerIfDrained();
  }

  void _remove(String id) {
    _items = _items.where((m) => m.id != id).toList();
    unawaited(_persist());
    _controller.add(List.unmodifiable(_items));
  }
```

Update `dispose`:

```dart
  Future<void> dispose() async {
    _timer?.cancel();
    await _controller.close();
    await _failureController.close();
  }
```

Add the `SyncFailure` class at the bottom of the file:

```dart
/// One queued mutation the server actually rejected (not a network blip) —
/// e.g. someone else already changed the order while this device was
/// offline. The screen that owns the affected order shows a blame-free
/// banner; [reason] is the raw Firestore code, for logs only, never shown.
class SyncFailure {
  const SyncFailure({required this.orderId, required this.reason});

  final String orderId;
  final String reason;
}
```

Also add `import 'dart:async';` at the top if not already present (it already is, from Task 3).

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/offline_mutation_queue_test.dart`
Expected: PASS (9/9 — 4 from Task 3 + 5 new).

- [ ] **Step 5: Commit**

```bash
git add lib/core/offline/offline_mutation_queue.dart test/offline_mutation_queue_test.dart
git commit -m "feat(offline): OfflineMutationQueue replay loop"
```

---

### Task 5: `OfflineMutationQueue` — app-resume replay trigger

**Files:**
- Modify: `lib/core/offline/offline_mutation_queue.dart`
- Test: `test/offline_mutation_queue_test.dart`

**Interfaces:**
- Produces: `OfflineMutationQueue` now implements `WidgetsBindingObserver` and registers itself with `WidgetsBinding.instance` on construction, removes itself on `dispose()`.

- [ ] **Step 1: Write the failing test**

Append to `test/offline_mutation_queue_test.dart`:

```dart
  test('an app resume with a non-empty queue triggers a replay', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    var attempts = 0;
    final queue = OfflineMutationQueue(
      prefs: prefs,
      networkInfo: _FakeNetworkInfo()..connected = false,
      remoteUpdate: (_, _) async => attempts++,
    );
    // Offline enqueue: the immediate post-enqueue replay attempt is skipped
    // (isConnected is false), so attempts is still 0 here.
    await queue.enqueue(_mutation('m1'));
    expect(attempts, 0);

    (queue as WidgetsBindingObserver)
      .didChangeAppLifecycleState(AppLifecycleState.resumed);
    // Lifecycle callback doesn't flip connectivity itself — simulate signal
    // coming back at the same moment the app resumes.
    await queue.dispose();
  });

  test('an app resume with an empty queue does not call remoteUpdate', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    var attempts = 0;
    final queue = OfflineMutationQueue(
      prefs: prefs,
      networkInfo: _FakeNetworkInfo(),
      remoteUpdate: (_, _) async => attempts++,
    );

    (queue as WidgetsBindingObserver)
      .didChangeAppLifecycleState(AppLifecycleState.resumed);
    await Future<void>.delayed(Duration.zero);

    expect(attempts, 0);
    await queue.dispose();
  });
```

Add `import 'package:flutter/widgets.dart';` to the test file's imports (needed for `AppLifecycleState`/`WidgetsBindingObserver`).

Note: the first test above only asserts `attempts == 0` right after the offline enqueue — it doesn't yet prove the resume trigger fired a *successful* replay, because flipping `_FakeNetworkInfo.connected` from inside the test after construction and re-triggering resume is simpler to assert directly. Replace that test with a more precise version:

```dart
  test('an app resume with a non-empty queue triggers a replay', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final network = _FakeNetworkInfo()..connected = false;
    var attempts = 0;
    final queue = OfflineMutationQueue(
      prefs: prefs,
      networkInfo: network,
      remoteUpdate: (_, _) async => attempts++,
    );
    await queue.enqueue(_mutation('m1'));
    expect(attempts, 0); // still offline, the post-enqueue attempt no-ops

    network.connected = true;
    (queue as WidgetsBindingObserver)
      .didChangeAppLifecycleState(AppLifecycleState.resumed);
    await Future<void>.delayed(Duration.zero);

    expect(attempts, 1);
    await queue.dispose();
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/offline_mutation_queue_test.dart`
Expected: FAIL — `OfflineMutationQueue` doesn't implement `WidgetsBindingObserver`, so the cast fails at runtime (`type 'OfflineMutationQueue' is not a subtype of type 'WidgetsBindingObserver'`).

- [ ] **Step 3: Implement the observer**

In `lib/core/offline/offline_mutation_queue.dart`:

- Add import: `import 'package:flutter/widgets.dart';`
- Change the class declaration: `class OfflineMutationQueue with WidgetsBindingObserver {`
- In the constructor body (after the existing `_controller.add(...)` line), add:

```dart
    WidgetsBinding.instance.addObserver(this);
```

- Add the override method:

```dart
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _items.isNotEmpty) {
      unawaited(_replay());
    }
  }
```

- In `dispose()`, add as the first line: `WidgetsBinding.instance.removeObserver(this);`

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/offline_mutation_queue_test.dart`
Expected: PASS (11/11).

- [ ] **Step 5: Commit**

```bash
git add lib/core/offline/offline_mutation_queue.dart test/offline_mutation_queue_test.dart
git commit -m "feat(offline): replay on app resume via WidgetsBindingObserver"
```

---

### Task 6: Wire the queue into `OrderRepositoryImpl` + DI

**Files:**
- Modify: `lib/data/order/repositories/order_repository_impl.dart`
- Modify: `lib/core/di/injector.dart:976-980` (Order — data section)
- Modify: `lib/main.dart`
- Test: `test/order_repository_impl_test.dart` (new)

**Interfaces:**
- Consumes: `OfflineMutationQueue` (Tasks 3–5), `NetworkInfo` (existing).
- Produces: `OrderRepositoryImpl(OrderRemoteDataSource remote, {required NetworkInfo networkInfo, required OfflineMutationQueue queue, required String? Function() currentUidProvider})` — every other repository method is untouched. `currentUidProvider` is a `FirebaseAuth`-free seam (production wires `() => FirebaseAuth.instance.currentUser?.uid`) so the test can fake the current uid without a Firebase test harness, which this project doesn't have.

- [ ] **Step 1: Write the failing test**

```dart
// test/order_repository_impl_test.dart
import 'package:dukkan/core/network/network_info.dart';
import 'package:dukkan/core/offline/offline_mutation_queue.dart';
import 'package:dukkan/data/order/repositories/order_repository_impl.dart';
import 'package:dukkan/domain/order/entities/order_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeNetworkInfo implements NetworkInfo {
  bool connected = true;
  @override
  Future<bool> get isConnected async => connected;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('online: updateOrderStatus calls the remote directly, never the queue', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final network = _FakeNetworkInfo()..connected = true;
    var remoteCalls = 0;
    final queue = OfflineMutationQueue(
      prefs: prefs,
      networkInfo: network,
      remoteUpdate: (_, _) async {},
    );
    final repo = OrderRepositoryImpl.forTest(
      updateOrderStatusRemote: (_, _) async => remoteCalls++,
      networkInfo: network,
      queue: queue,
      currentUidProvider: () => 'u1',
    );

    await repo.updateOrderStatus('o1', OrderStatus.accepted);

    expect(remoteCalls, 1);
    expect(queue.pendingForOrder('o1'), isEmpty);
    addTearDown(queue.dispose);
  });

  test('offline: updateOrderStatus enqueues instead of calling the remote', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final network = _FakeNetworkInfo()..connected = false;
    var remoteCalls = 0;
    final queue = OfflineMutationQueue(
      prefs: prefs,
      networkInfo: network,
      remoteUpdate: (_, _) async {},
    );
    final repo = OrderRepositoryImpl.forTest(
      updateOrderStatusRemote: (_, _) async => remoteCalls++,
      networkInfo: network,
      queue: queue,
      currentUidProvider: () => 'u1',
    );

    await repo.updateOrderStatus('o1', OrderStatus.rejected);

    expect(remoteCalls, 0);
    expect(queue.pendingForOrder('o1').single.targetStatus, OrderStatus.rejected);
    expect(queue.pendingForOrder('o1').single.actorUid, 'u1');
    addTearDown(queue.dispose);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/order_repository_impl_test.dart`
Expected: FAIL — `OrderRepositoryImpl.forTest` doesn't exist yet.

- [ ] **Step 3: Add the offline branch**

Replace `lib/data/order/repositories/order_repository_impl.dart` in full:

```dart
import '../../../core/network/network_info.dart';
import '../../../core/offline/offline_mutation_queue.dart';
import '../../../core/offline/pending_mutation.dart';
import '../../../domain/order/entities/address.dart';
import '../../../domain/order/entities/order.dart';
import '../../../domain/order/entities/order_item.dart';
import '../../../domain/order/entities/order_status.dart';
import '../../../domain/order/repositories/order_repository.dart';
import '../datasources/order_remote_datasource.dart';

/// No offline branch on any method except [updateOrderStatus] (O2 slice 1) —
/// every other order write still needs a live round trip (placing an order,
/// cancelling, rating are all out of this slice's locked scope, see
/// `Docs/plan/offline-order-status-queue-design.md`); realtime status only
/// matters while connected too.
class OrderRepositoryImpl implements OrderRepository {
  OrderRepositoryImpl(
    OrderRemoteDataSource remote, {
    required NetworkInfo networkInfo,
    required OfflineMutationQueue queue,
    required String? Function() currentUidProvider,
  })  : _updateOrderStatusRemote = remote.updateOrderStatus,
        _remote = remote,
        _networkInfo = networkInfo,
        _queue = queue,
        _currentUidProvider = currentUidProvider;

  /// Test seam — lets `order_repository_impl_test.dart` fake just the one
  /// remote call this offline branch touches, without a real `FirebaseAuth`/
  /// `FirebaseFirestore`. Production always goes through the real
  /// [OrderRemoteDataSource.updateOrderStatus].
  OrderRepositoryImpl.forTest({
    required Future<void> Function(String orderId, OrderStatus status) updateOrderStatusRemote,
    required NetworkInfo networkInfo,
    required OfflineMutationQueue queue,
    required String? Function() currentUidProvider,
  })  : _updateOrderStatusRemote = updateOrderStatusRemote,
        _remote = null,
        _networkInfo = networkInfo,
        _queue = queue,
        _currentUidProvider = currentUidProvider;

  final OrderRemoteDataSource? _remote;
  final Future<void> Function(String orderId, OrderStatus status) _updateOrderStatusRemote;
  final NetworkInfo _networkInfo;
  final OfflineMutationQueue _queue;
  final String? Function() _currentUidProvider;

  @override
  Future<Order> placeOrder({
    required String shopId,
    required String customerUid,
    required List<OrderItem> items,
    required Address deliveryAddress,
    required int subtotalMinor,
    required int deliveryFeeMinor,
    required int commissionBps,
    required int commissionMinor,
    required int driverDeliveryShareMinor,
    required int platformDeliveryShareMinor,
    required int totalMinor,
    String? notes,
    String? couponCode,
    int discountMinor = 0,
  }) {
    return _remote!.placeOrder(
      shopId: shopId,
      customerUid: customerUid,
      items: items,
      deliveryAddress: deliveryAddress,
      subtotalMinor: subtotalMinor,
      deliveryFeeMinor: deliveryFeeMinor,
      commissionBps: commissionBps,
      commissionMinor: commissionMinor,
      driverDeliveryShareMinor: driverDeliveryShareMinor,
      platformDeliveryShareMinor: platformDeliveryShareMinor,
      totalMinor: totalMinor,
      notes: notes,
      couponCode: couponCode,
      discountMinor: discountMinor,
    );
  }

  @override
  Stream<List<Order>> watchCustomerOrders(String customerUid) =>
      _remote!.watchCustomerOrders(customerUid);

  @override
  Stream<List<Order>> watchShopOrders(String shopId) => _remote!.watchShopOrders(shopId);

  @override
  Stream<Order> watchOrder(String orderId) => _remote!.watchOrder(orderId);

  @override
  Stream<List<Order>> watchDriverActiveOrders(String driverUid) =>
      _remote!.watchDriverActiveOrders(driverUid);

  @override
  Stream<List<Order>> watchDriverHistory(String driverUid) =>
      _remote!.watchDriverHistory(driverUid);

  @override
  Future<void> cancelOrder(String orderId) => _remote!.cancelOrder(orderId);

  @override
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    if (await _networkInfo.isConnected) {
      return _updateOrderStatusRemote(orderId, status);
    }
    await _queue.enqueue(PendingMutation(
      id: '${DateTime.now().microsecondsSinceEpoch}-$orderId',
      orderId: orderId,
      targetStatus: status,
      actorUid: _currentUidProvider() ?? '',
      enqueuedAt: DateTime.now(),
    ));
  }

  @override
  Future<void> rateOrder({
    required String orderId,
    required String shopId,
    required int rating,
  }) =>
      _remote!.rateOrder(orderId: orderId, shopId: shopId, rating: rating);
}
```

- [ ] **Step 4: Run the new test to verify it passes**

Run: `flutter test test/order_repository_impl_test.dart`
Expected: PASS (2/2)

- [ ] **Step 5: Wire real DI**

In `lib/core/di/injector.dart`:

Add imports near the other `core/` imports (around line 300):

```dart
import '../offline/offline_mutation_queue.dart';
```

Replace the "Order — data" block (currently lines 976–980):

```dart
  // Order — data
  sl.registerLazySingleton(
    () => OrderRemoteDataSource(firestore: sl(), auth: sl()),
  );
  sl.registerLazySingleton<OrderRepository>(() => OrderRepositoryImpl(sl()));
```

with:

```dart
  // Order — data. OfflineMutationQueue (O2 slice 1) is resolved eagerly
  // right after this block (not lazily) so its WidgetsBindingObserver is
  // registered from app start, not only after the first status write.
  sl.registerLazySingleton(
    () => OrderRemoteDataSource(firestore: sl(), auth: sl()),
  );
  sl.registerLazySingleton(
    () => OfflineMutationQueue(
      prefs: sl(),
      networkInfo: sl(),
      remoteUpdate: (orderId, status) => sl<OrderRemoteDataSource>().updateOrderStatus(orderId, status),
    ),
  );
  sl.registerLazySingleton<OrderRepository>(
    () => OrderRepositoryImpl(
      sl(),
      networkInfo: sl(),
      queue: sl(),
      currentUidProvider: () => sl<FirebaseAuth>().currentUser?.uid,
    ),
  );
```

- [ ] **Step 6: Eagerly resolve the queue at app start**

In `lib/main.dart`, add the import:

```dart
import 'core/offline/offline_mutation_queue.dart';
```

Right after `await initDependencies();`, add:

```dart
  sl<OfflineMutationQueue>(); // registers the app-resume observer from boot
```

- [ ] **Step 7: Full regression**

Run: `flutter analyze` (expect 0) and `flutter test` (expect all green, including every existing order/owner/deliveries/order-detail bloc test — none of their fakes implement the changed constructor since they construct `OrderRepositoryImpl`... check: do any existing tests construct `OrderRepositoryImpl` directly, or only via `OrderRepository` fakes?). Grep first:

```bash
grep -rn "OrderRepositoryImpl(" test/ lib/
```

Only `lib/core/di/injector.dart` and `lib/data/order/repositories/order_repository_impl.dart` itself should construct it — every test file (`owner_orders_bloc_test.dart`, `order_detail_bloc_test.dart`, etc.) implements the abstract `OrderRepository` interface directly and is untouched by this change.

- [ ] **Step 8: Commit**

```bash
git add lib/data/order/repositories/order_repository_impl.dart lib/core/di/injector.dart lib/main.dart test/order_repository_impl_test.dart
git commit -m "feat(order): route updateOrderStatus through the offline queue when offline"
```

---

### Task 7: i18n keys

**Files:**
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_ar.arb`

**Interfaces:**
- Produces: `offlineSyncPendingBadge`, `offlineSyncFailedBody` — consumed by Tasks 8–10's UI widgets.

- [ ] **Step 1: Add the English keys**

In `lib/l10n/app_en.arb`, add near the other order-action keys (alongside `orderForcedChip` at line 195):

```json
  "offlineSyncPendingBadge": "Pending sync",
  "offlineSyncFailedBody": "Couldn't sync — try again.",
```

- [ ] **Step 2: Add the matching Arabic keys**

In `lib/l10n/app_ar.arb`, add the same two keys at the equivalent position:

```json
  "offlineSyncPendingBadge": "قيد المزامنة",
  "offlineSyncFailedBody": "حصلت مشكلة في المزامنة — جرّب تاني",
```

- [ ] **Step 3: Regenerate + verify parity**

Run: `flutter gen-l10n` then `dart run scripts/check_i18n_parity.dart`
Expected: parity count goes up by 2 (from 785 to 787), no missing/extra key errors.

- [ ] **Step 4: Commit**

```bash
git add lib/l10n/app_en.arb lib/l10n/app_ar.arb lib/l10n/app_localizations*.dart
git commit -m "feat(i18n): add offline sync pending/failed strings"
```

---

### Task 8: Shared `PendingSyncBadge` widget

**Files:**
- Create: `lib/presentation/widgets/common/pending_sync_badge.dart`

**Interfaces:**
- Produces: `class PendingSyncBadge extends StatelessWidget` (no params beyond `key`) — a small inline row (sync icon + `l10n.offlineSyncPendingBadge`), consumed by Tasks 9–11 in all three screens instead of three copies (mirrors the design doc's "shared core, not three copies" reasoning, applied to the UI layer too).

- [ ] **Step 1: Write the widget**

No test — this mirrors every other pure-presentation widget in `widgets/common/` (`StatusChip`, `PriceTag`), none of which have widget tests in this codebase; `flutter analyze` + a manual device pass are the gate, same as those.

```dart
// lib/presentation/widgets/common/pending_sync_badge.dart
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';

/// Shown next to an order's status chip when a status change is queued
/// offline (O2 slice 1) — one shared widget instead of three copies across
/// the owner desk, courier deliveries list, and order-detail page.
class PendingSyncBadge extends StatelessWidget {
  const PendingSyncBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.sync_outlined, size: 14, color: AppColors.warning),
        const SizedBox(width: AppSpacing.xs),
        Text(
          l10n.offlineSyncPendingBadge,
          style: text.bodySmall?.copyWith(color: AppColors.warning, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Verify it compiles**

Run: `flutter analyze`
Expected: 0 issues (unused-widget warnings don't fire for public classes).

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/widgets/common/pending_sync_badge.dart
git commit -m "feat(widgets): add shared PendingSyncBadge"
```

---

### Task 9: `OwnerOrdersBloc` — merge queue state, wire the owner desk

**Files:**
- Modify: `lib/presentation/orders/bloc/owner_orders_bloc.dart`
- Modify: `lib/presentation/orders/bloc/owner_orders_state.dart`
- Modify: `lib/presentation/orders/bloc/owner_orders_event.dart`
- Modify: `lib/presentation/orders/pages/order_desk_page.dart`
- Modify: `lib/core/di/injector.dart` (`OwnerOrdersBloc` factory)
- Test: `test/owner_orders_bloc_test.dart`

**Interfaces:**
- Consumes: `OfflineMutationQueue.watchAll()`/`.pendingForOrder()` (Tasks 3–5), `PendingSyncBadge` (Task 8).
- Produces: `OwnerOrdersState.pendingStatuses` (`Map<String, OrderStatus>`, orderId → queued target status); `OwnerOrdersBloc(shopId: ..., watchShopOrders: ..., queue: ...)`.

- [ ] **Step 1: Write the failing test**

Append to `test/owner_orders_bloc_test.dart` (new imports at top: `package:dukkan/core/offline/offline_mutation_queue.dart`, `package:dukkan/core/offline/pending_mutation.dart`, `package:dukkan/core/network/network_info.dart`, `package:shared_preferences/shared_preferences.dart`):

```dart
import 'package:dukkan/core/network/network_info.dart';
import 'package:dukkan/core/offline/offline_mutation_queue.dart';
import 'package:dukkan/core/offline/pending_mutation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeNetworkInfo implements NetworkInfo {
  @override
  Future<bool> get isConnected async => false;
}
```

Add inside `main()`, after the existing `setUp`/`tearDown`:

```dart
  test('a queued mutation for a listed order surfaces in pendingStatuses', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final queue = OfflineMutationQueue(
      prefs: prefs,
      networkInfo: _FakeNetworkInfo(),
      remoteUpdate: (_, _) async {},
    );
    final queuedBloc = OwnerOrdersBloc(
      shopId: 's1',
      watchShopOrders: WatchShopOrders(repo),
      queue: queue,
    );
    addTearDown(queuedBloc.close);
    addTearDown(queue.dispose);

    queuedBloc.add(const OwnerOrdersStarted());
    await tick();
    repo.controller.add([_order('a', OrderStatus.pending)]);
    await tick();

    await queue.enqueue(PendingMutation(
      id: 'm1',
      orderId: 'a',
      targetStatus: OrderStatus.accepted,
      actorUid: 'u1',
      enqueuedAt: DateTime(2026, 8, 11),
    ));
    await tick();

    expect(queuedBloc.state.pendingStatuses['a'], OrderStatus.accepted);
  });

  test('an order not in the queue has no pendingStatuses entry', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final queue = OfflineMutationQueue(
      prefs: prefs,
      networkInfo: _FakeNetworkInfo(),
      remoteUpdate: (_, _) async {},
    );
    final queuedBloc = OwnerOrdersBloc(
      shopId: 's1',
      watchShopOrders: WatchShopOrders(repo),
      queue: queue,
    );
    addTearDown(queuedBloc.close);
    addTearDown(queue.dispose);

    queuedBloc.add(const OwnerOrdersStarted());
    await tick();
    repo.controller.add([_order('a', OrderStatus.pending)]);
    await tick();

    expect(queuedBloc.state.pendingStatuses.containsKey('a'), isFalse);
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/owner_orders_bloc_test.dart`
Expected: FAIL — `OwnerOrdersBloc` has no `queue` parameter, `OwnerOrdersState` has no `pendingStatuses`.

- [ ] **Step 3: Extend the state**

In `lib/presentation/orders/bloc/owner_orders_state.dart`:

```dart
part of 'owner_orders_bloc.dart';

enum OwnerOrdersStatus { loading, loaded, error }

class OwnerOrdersState extends Equatable {
  const OwnerOrdersState({
    this.status = OwnerOrdersStatus.loading,
    this.orders = const [],
    this.pendingStatuses = const {},
  });

  final OwnerOrdersStatus status;

  /// Newest-first (query order lives in the remote datasource).
  final List<Order> orders;

  /// orderId → queued target status (O2 slice 1) — non-empty only for an
  /// order with a pending offline mutation; the desk card overrides its
  /// displayed status with this and shows [PendingSyncBadge].
  final Map<String, OrderStatus> pendingStatuses;

  OwnerOrdersState copyWith({
    OwnerOrdersStatus? status,
    List<Order>? orders,
    Map<String, OrderStatus>? pendingStatuses,
  }) {
    return OwnerOrdersState(
      status: status ?? this.status,
      orders: orders ?? this.orders,
      pendingStatuses: pendingStatuses ?? this.pendingStatuses,
    );
  }

  @override
  List<Object?> get props => [status, orders, pendingStatuses];
}
```

- [ ] **Step 4: Extend the events**

In `lib/presentation/orders/bloc/owner_orders_event.dart`, add at the bottom (before the closing of the file):

```dart
/// Internal: the offline queue's contents changed.
class _PendingMutationsUpdated extends OwnerOrdersEvent {
  const _PendingMutationsUpdated(this.mutations);

  final List<PendingMutation> mutations;

  @override
  List<Object?> get props => [mutations];
}
```

Add the import at the top of `owner_orders_bloc.dart` (not the part file — part files share the parent's imports): `import '../../../core/offline/pending_mutation.dart';`

- [ ] **Step 5: Extend the bloc**

Replace `lib/presentation/orders/bloc/owner_orders_bloc.dart` in full:

```dart
import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/offline/offline_mutation_queue.dart';
import '../../../core/offline/pending_mutation.dart';
import '../../../domain/order/entities/order.dart';
import '../../../domain/order/usecases/watch_shop_orders.dart';

part 'owner_orders_event.dart';
part 'owner_orders_state.dart';

/// Drives the owner's order desk (S3). Subscribes to [WatchShopOrders] for
/// the signed-in owner's shop — newest first (query order lives in the
/// remote datasource). Page-scoped: one subscription per page-open, the shop
/// id is the factory param (mirrors [OrdersBloc]'s customerUid). Status
/// changes (accept/reject/advance) are one-shot [UpdateOrderStatus] calls
/// made directly from the card widget — same pattern as catalog CRUD — the
/// resulting status change comes back through this same stream. Also
/// subscribes to [OfflineMutationQueue.watchAll] (O2 slice 1) so a queued
/// mutation for one of this shop's orders shows a pending-sync overlay
/// before the real write lands.
class OwnerOrdersBloc extends Bloc<OwnerOrdersEvent, OwnerOrdersState> {
  OwnerOrdersBloc({
    required String shopId,
    required WatchShopOrders watchShopOrders,
    required OfflineMutationQueue queue,
  })  : _shopId = shopId,
        _watchShopOrders = watchShopOrders,
        _queue = queue,
        super(const OwnerOrdersState()) {
    on<OwnerOrdersStarted>(_onStarted);
    on<OwnerOrdersRetryRequested>(_onStarted);
    on<_OwnerOrdersUpdated>(_onUpdated);
    on<_OwnerOrdersFailed>(_onFailed);
    on<_PendingMutationsUpdated>(_onPendingMutationsUpdated);

    _queueSub = _queue.watchAll().listen(
      (mutations) => add(_PendingMutationsUpdated(mutations)),
    );
  }

  final String _shopId;
  final WatchShopOrders _watchShopOrders;
  final OfflineMutationQueue _queue;
  StreamSubscription<List<Order>>? _sub;
  StreamSubscription<List<PendingMutation>>? _queueSub;

  Future<void> _onStarted(
    OwnerOrdersEvent event,
    Emitter<OwnerOrdersState> emit,
  ) async {
    emit(state.copyWith(status: OwnerOrdersStatus.loading));
    await _sub?.cancel();
    _sub = _watchShopOrders(_shopId).listen(
      (orders) => add(_OwnerOrdersUpdated(orders)),
      onError: (Object error) => add(_OwnerOrdersFailed(error)),
    );
  }

  void _onUpdated(_OwnerOrdersUpdated event, Emitter<OwnerOrdersState> emit) {
    emit(state.copyWith(status: OwnerOrdersStatus.loaded, orders: event.orders));
  }

  void _onFailed(_OwnerOrdersFailed event, Emitter<OwnerOrdersState> emit) {
    emit(state.copyWith(status: OwnerOrdersStatus.error));
  }

  void _onPendingMutationsUpdated(
    _PendingMutationsUpdated event,
    Emitter<OwnerOrdersState> emit,
  ) {
    final byOrder = <String, OrderStatus>{};
    for (final mutation in event.mutations) {
      byOrder[mutation.orderId] = mutation.targetStatus;
    }
    emit(state.copyWith(pendingStatuses: byOrder));
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    _queueSub?.cancel();
    return super.close();
  }
}
```

Note: `OrderStatus` needs importing too — add `import '../../../domain/order/entities/order_status.dart';`.

- [ ] **Step 6: Run test to verify it passes**

Run: `flutter test test/owner_orders_bloc_test.dart`
Expected: PASS — all prior tests still pass (they'll need updating: every existing `OwnerOrdersBloc(...)` construction in this file's `setUp` must now also pass `queue: <a real-or-fake queue>`; simplest fix is a shared `late OfflineMutationQueue queue;` built once in `setUp` using `_FakeNetworkInfo()` and an empty `remoteUpdate`, torn down in `tearDown`). Apply that `setUp`/`tearDown` change before re-running.

- [ ] **Step 7: Wire DI**

In `lib/core/di/injector.dart`, the `OwnerOrdersBloc` factory (around line 999):

```dart
  sl.registerFactoryParam<OwnerOrdersBloc, String, void>(
    (shopId, _) => OwnerOrdersBloc(shopId: shopId, watchShopOrders: sl()),
  );
```

becomes:

```dart
  sl.registerFactoryParam<OwnerOrdersBloc, String, void>(
    (shopId, _) => OwnerOrdersBloc(shopId: shopId, watchShopOrders: sl(), queue: sl()),
  );
```

- [ ] **Step 8: Wire the UI**

In `lib/presentation/orders/pages/order_desk_page.dart`:

- Add imports: `import '../../widgets/common/pending_sync_badge.dart';` and `import '../../../core/di/injector.dart';` (already present) and `import '../../../l10n/app_localizations.dart';` (already present).
- `_OwnerOrderCard` needs a new `pendingStatus` field. Change its declaration and the call site:

```dart
class _OwnerOrderCard extends StatefulWidget {
  const _OwnerOrderCard({required this.order, this.pendingStatus});

  final Order order;
  final OrderStatus? pendingStatus;
```

At the `itemBuilder` call site (currently `_OwnerOrderCard(order: state.orders[i - 1])`):

```dart
                          itemBuilder: (context, i) => i == 0
                              ? _DailySummaryStrip(orders: state.orders)
                              : _OwnerOrderCard(
                                  order: state.orders[i - 1],
                                  pendingStatus: state.pendingStatuses[state.orders[i - 1].id],
                                ),
```

- In `_OwnerOrderCardState.build`, use `pendingStatus` to override the displayed chip and disable the action buttons while a mutation is queued for this order (avoids double-queuing the same order):

```dart
    final order = widget.order;
    final effectiveStatus = widget.pendingStatus ?? order.status;
    final view = orderStatusView(l10n, effectiveStatus);
    final primary = widget.pendingStatus == null ? orderPrimaryAction(l10n, order.status) : null;
    final secondary = widget.pendingStatus == null ? orderSecondaryAction(l10n, order.status) : null;
```

Add the badge next to the chip:

```dart
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        StatusChip(label: view.label, tone: view.tone),
                        if (widget.pendingStatus != null) ...[
                          const SizedBox(width: AppSpacing.xs),
                          const PendingSyncBadge(),
                        ],
                      ],
                    ),
```

(replaces the bare `StatusChip(label: view.label, tone: view.tone),` line in the existing card layout).

- [ ] **Step 9: Full regression + commit**

Run: `flutter analyze` (0 issues) and `flutter test` (all green) and `dart run scripts/check_i18n_parity.dart` (green, unchanged from Task 7).

```bash
git add lib/presentation/orders/bloc/owner_orders_bloc.dart lib/presentation/orders/bloc/owner_orders_state.dart lib/presentation/orders/bloc/owner_orders_event.dart lib/presentation/orders/pages/order_desk_page.dart lib/core/di/injector.dart test/owner_orders_bloc_test.dart
git commit -m "feat(owner): show pending-sync badge on the order desk"
```

---

### Task 10: `DeliveriesBloc` — merge queue state, wire the courier list

**Files:**
- Modify: `lib/presentation/driver/bloc/deliveries_bloc.dart`
- Modify: `lib/presentation/driver/bloc/deliveries_state.dart`
- Modify: `lib/presentation/driver/bloc/deliveries_event.dart`
- Modify: `lib/presentation/driver/pages/deliveries_page.dart`
- Modify: `lib/core/di/injector.dart` (`DeliveriesBloc` factory)
- Test: `test/deliveries_bloc_test.dart` (already exists — extend it, don't replace it)

**Interfaces:**
- Same shape as Task 9: `DeliveriesState.pendingStatuses` (`Map<String, OrderStatus>`), `DeliveriesBloc(..., queue: OfflineMutationQueue)`.

This task mirrors Task 9 exactly, applied to the courier's **active** list only (history is all-`delivered`, terminal, never has a pending mutation — `pendingStatuses` is still computed from the whole queue for simplicity, but in practice only ever matches an active-tab order). `test/deliveries_bloc_test.dart` already exists with a `_FakeOrderRepository` (separate `activeController`/`historyController` broadcast `StreamController`s), a `_FakeAreasRepository`, and an `_order(id, status, {createdAt})` helper whose orders all carry `driverUid: 'd1'` — reuse these exactly, don't recreate them.

- [ ] **Step 1: Write the failing test**

Add these imports to the top of `test/deliveries_bloc_test.dart` (alongside the existing ones):

```dart
import 'package:dukkan/core/network/network_info.dart';
import 'package:dukkan/core/offline/offline_mutation_queue.dart';
import 'package:dukkan/core/offline/pending_mutation.dart';
import 'package:shared_preferences/shared_preferences.dart';
```

Add this fake near the top-level `_FakeOrderRepository`/`_FakeAreasRepository` declarations:

```dart
class _FakeNetworkInfo implements NetworkInfo {
  @override
  Future<bool> get isConnected async => false;
}
```

Add these two tests inside `main()`, after the existing `'tab switch flips which list the page reads'` test:

```dart
  test('a queued mutation for an active order surfaces in pendingStatuses', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final queue = OfflineMutationQueue(
      prefs: prefs,
      networkInfo: _FakeNetworkInfo(),
      remoteUpdate: (_, _) async {},
    );
    final queuedBloc = DeliveriesBloc(
      driverUid: 'd1',
      watchActive: WatchDriverActiveOrders(repo),
      watchHistory: WatchDriverOrderHistory(repo),
      getAreas: GetAreas(_FakeAreasRepository()),
      queue: queue,
    );
    addTearDown(queuedBloc.close);
    addTearDown(queue.dispose);

    queuedBloc.add(const DeliveriesStarted());
    await tick();
    repo.activeController.add([_order('a', OrderStatus.preparing)]);
    await tick();

    await queue.enqueue(PendingMutation(
      id: 'm1',
      orderId: 'a',
      targetStatus: OrderStatus.outForDelivery,
      actorUid: 'd1',
      enqueuedAt: DateTime(2026, 8, 11),
    ));
    await tick();

    expect(queuedBloc.state.pendingStatuses['a'], OrderStatus.outForDelivery);
  });

  test('an active order not in the queue has no pendingStatuses entry', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final queue = OfflineMutationQueue(
      prefs: prefs,
      networkInfo: _FakeNetworkInfo(),
      remoteUpdate: (_, _) async {},
    );
    final queuedBloc = DeliveriesBloc(
      driverUid: 'd1',
      watchActive: WatchDriverActiveOrders(repo),
      watchHistory: WatchDriverOrderHistory(repo),
      getAreas: GetAreas(_FakeAreasRepository()),
      queue: queue,
    );
    addTearDown(queuedBloc.close);
    addTearDown(queue.dispose);

    queuedBloc.add(const DeliveriesStarted());
    await tick();
    repo.activeController.add([_order('a', OrderStatus.preparing)]);
    await tick();

    expect(queuedBloc.state.pendingStatuses.containsKey('a'), isFalse);
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/deliveries_bloc_test.dart`
Expected: FAIL — no `queue` param, no `pendingStatuses` field.

- [ ] **Step 3: Extend the state**

In `lib/presentation/driver/bloc/deliveries_state.dart`, add `pendingStatuses` following the exact same pattern as Task 9 Step 3 (`this.pendingStatuses = const {}`, field, `copyWith` param, `props` entry). Type: `Map<String, OrderStatus>`. Add `import '../../../domain/order/entities/order_status.dart';` if not already present in the part-of file's parent.

- [ ] **Step 4: Extend the events**

In `lib/presentation/driver/bloc/deliveries_event.dart`, add:

```dart
/// Internal: the offline queue's contents changed.
class _PendingMutationsUpdated extends DeliveriesEvent {
  const _PendingMutationsUpdated(this.mutations);

  final List<PendingMutation> mutations;

  @override
  List<Object?> get props => [mutations];
}
```

- [ ] **Step 5: Extend the bloc**

In `lib/presentation/driver/bloc/deliveries_bloc.dart`:

- Add imports: `import '../../../core/offline/offline_mutation_queue.dart';`, `import '../../../core/offline/pending_mutation.dart';`, `import '../../../domain/order/entities/order_status.dart';`
- Add `required OfflineMutationQueue queue` to the constructor, store as `_queue`.
- In the constructor body, register the new event handler and subscribe:

```dart
    on<_PendingMutationsUpdated>(_onPendingMutationsUpdated);
    _queueSub = _queue.watchAll().listen(
      (mutations) => add(_PendingMutationsUpdated(mutations)),
    );
```

- Add the field `StreamSubscription<List<PendingMutation>>? _queueSub;` and the handler:

```dart
  void _onPendingMutationsUpdated(
    _PendingMutationsUpdated event,
    Emitter<DeliveriesState> emit,
  ) {
    final byOrder = <String, OrderStatus>{};
    for (final mutation in event.mutations) {
      byOrder[mutation.orderId] = mutation.targetStatus;
    }
    emit(state.copyWith(pendingStatuses: byOrder));
  }
```

- In `close()`, add `_queueSub?.cancel();`.

- [ ] **Step 6: Run test to verify it passes**

Run: `flutter test test/deliveries_bloc_test.dart`
Expected: PASS. Same as Task 9 — every existing `DeliveriesBloc(...)` construction in this test file needs `queue: ...` added; use the same shared fake-queue `setUp`/`tearDown` pattern.

- [ ] **Step 7: Wire DI**

In `lib/core/di/injector.dart`, the `DeliveriesBloc` factory (around line 1024–1031):

```dart
  sl.registerFactoryParam<DeliveriesBloc, String, void>(
    (driverUid, _) => DeliveriesBloc(
      driverUid: driverUid,
      watchActive: sl(),
      watchHistory: sl(),
      getAreas: sl(),
    ),
  );
```

add `queue: sl(),` to the constructor call.

- [ ] **Step 8: Wire the UI**

In `lib/presentation/driver/pages/deliveries_page.dart`:

- Add import: `import '../../widgets/common/pending_sync_badge.dart';`
- `_DeliveryCard` needs a `pendingStatus` field (mirrors Task 9's `_OwnerOrderCard`):

```dart
class _DeliveryCard extends StatefulWidget {
  const _DeliveryCard({required this.order, required this.areas, this.pendingStatus});

  final Order order;
  final List<Area> areas;
  final OrderStatus? pendingStatus;
```

- At the `itemBuilder` call site in `_DeliveriesList` (only meaningful for the active tab, but harmless to pass for history too since a delivered order never has a pending mutation):

```dart
                  itemBuilder: (context, i) => _DeliveryCard(
                    order: orders[i],
                    areas: state.areas,
                    pendingStatus: state.pendingStatuses[orders[i].id],
                  ),
```

- In `_DeliveryCardState.build`, override the chip the same way as Task 9:

```dart
    final order = widget.order;
    final effectiveStatus = widget.pendingStatus ?? order.status;
    final view = orderStatusView(l10n, effectiveStatus);
```

and the chip row:

```dart
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StatusChip(label: view.label, tone: view.tone),
                  if (widget.pendingStatus != null) ...[
                    const SizedBox(width: AppSpacing.xs),
                    const PendingSyncBadge(),
                  ],
                ],
              ),
```

(replaces the bare `StatusChip(label: view.label, tone: view.tone),` in the existing card's top `Row`).

- [ ] **Step 9: Full regression + commit**

Run: `flutter analyze` (0), `flutter test` (all green), parity script (green).

```bash
git add lib/presentation/driver/bloc/deliveries_bloc.dart lib/presentation/driver/bloc/deliveries_state.dart lib/presentation/driver/bloc/deliveries_event.dart lib/presentation/driver/pages/deliveries_page.dart lib/core/di/injector.dart test/deliveries_bloc_test.dart
git commit -m "feat(courier): show pending-sync badge on the deliveries list"
```

---

### Task 11: `OrderDetailBloc` — merge queue state + failure banner, wire the detail page

**Files:**
- Modify: `lib/presentation/orders/bloc/order_detail_bloc.dart`
- Modify: `lib/presentation/orders/bloc/order_detail_state.dart`
- Modify: `lib/presentation/orders/bloc/order_detail_event.dart`
- Modify: `lib/presentation/orders/pages/order_detail_page.dart`
- Modify: `lib/core/di/injector.dart` (`OrderDetailBloc` factory)
- Test: `test/order_detail_bloc_test.dart`

**Interfaces:**
- Consumes: `OfflineMutationQueue.pendingForOrder()`/`.watchAll()`/`.failures` (Tasks 3–5).
- Produces: `OrderDetailState.pendingTargetStatus` (`OrderStatus?`), `OrderDetailState.syncFailureReason` (`String?`, transient — cleared by a new `OrderDetailSyncFailureDismissed` event fired from the page right after showing the banner).

- [ ] **Step 1: Write the failing tests**

Add to the top of `test/order_detail_bloc_test.dart`:

```dart
import 'package:dukkan/core/network/network_info.dart';
import 'package:dukkan/core/offline/offline_mutation_queue.dart';
import 'package:dukkan/core/offline/pending_mutation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeNetworkInfo implements NetworkInfo {
  bool connected = true;
  @override
  Future<bool> get isConnected async => connected;
}
```

Add inside `main()`:

```dart
  test('a queued mutation for this order surfaces as pendingTargetStatus', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final network = _FakeNetworkInfo()..connected = false;
    final queue = OfflineMutationQueue(
      prefs: prefs,
      networkInfo: network,
      remoteUpdate: (_, _) async {},
    );
    final queuedBloc = OrderDetailBloc(
      orderId: 'o1',
      watchOrder: WatchOrder(repo),
      cancelOrder: CancelOrder(repo),
      rateOrder: RateOrder(repo),
      updateOrderStatus: UpdateOrderStatus(repo),
      forceOrderStatus: ForceOrderStatus(adminRepo),
      reassignOrderDriver: ReassignOrderDriver(adminRepo),
      staffCancelOrder: CancelOrderAsStaff(adminRepo),
      watchOrderNotes: WatchOrderNotes(adminRepo),
      addOrderNote: AddOrderNote(adminRepo),
      queue: queue,
    );
    addTearDown(queuedBloc.close);
    addTearDown(queue.dispose);

    queuedBloc.add(const OrderDetailStarted());
    await tick();
    repo.controller.add(_order(OrderStatus.preparing));
    await tick();

    await queue.enqueue(PendingMutation(
      id: 'm1',
      orderId: 'o1',
      targetStatus: OrderStatus.outForDelivery,
      actorUid: 'u1',
      enqueuedAt: DateTime(2026, 8, 11),
    ));
    await tick();

    expect(queuedBloc.state.pendingTargetStatus, OrderStatus.outForDelivery);
  });

  test('a sync failure for this order surfaces syncFailureReason once', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final network = _FakeNetworkInfo()..connected = true;
    final queue = OfflineMutationQueue(
      prefs: prefs,
      networkInfo: network,
      remoteUpdate: (_, _) async => throw const ServerFailure('denied', 'permission-denied'),
    );
    final queuedBloc = OrderDetailBloc(
      orderId: 'o1',
      watchOrder: WatchOrder(repo),
      cancelOrder: CancelOrder(repo),
      rateOrder: RateOrder(repo),
      updateOrderStatus: UpdateOrderStatus(repo),
      forceOrderStatus: ForceOrderStatus(adminRepo),
      reassignOrderDriver: ReassignOrderDriver(adminRepo),
      staffCancelOrder: CancelOrderAsStaff(adminRepo),
      watchOrderNotes: WatchOrderNotes(adminRepo),
      addOrderNote: AddOrderNote(adminRepo),
      queue: queue,
    );
    addTearDown(queuedBloc.close);
    addTearDown(queue.dispose);

    queuedBloc.add(const OrderDetailStarted());
    await tick();
    repo.controller.add(_order(OrderStatus.preparing));
    await tick();

    await queue.enqueue(PendingMutation(
      id: 'm1',
      orderId: 'o1',
      targetStatus: OrderStatus.outForDelivery,
      actorUid: 'u1',
      enqueuedAt: DateTime(2026, 8, 11),
    ));
    await tick();

    expect(queuedBloc.state.syncFailureReason, isNotNull);

    queuedBloc.add(const OrderDetailSyncFailureDismissed());
    await tick();

    expect(queuedBloc.state.syncFailureReason, isNull);
  });
```

Add `import '../../../core/errors/failures.dart';` — actually this import belongs in the test file: add `import 'package:dukkan/core/errors/failures.dart';` to the test file's imports for `ServerFailure`.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/order_detail_bloc_test.dart`
Expected: FAIL — no `queue` param, no `pendingTargetStatus`/`syncFailureReason` fields, no `OrderDetailSyncFailureDismissed` event.

- [ ] **Step 3: Extend the state**

In `lib/presentation/orders/bloc/order_detail_state.dart`, add two fields following the existing pattern:

```dart
  const OrderDetailState({
    this.status = OrderDetailStatus.loading,
    this.order,
    this.cancelStatus = OrderCancelStatus.idle,
    this.rateStatus = OrderRateStatus.idle,
    this.advanceStatus = OrderAdvanceStatus.idle,
    this.staffActionStatus = StaffActionStatus.idle,
    this.customer,
    this.area,
    this.notes,
    this.pendingTargetStatus,
    this.syncFailureReason,
  });
```

```dart
  /// The offline-queued target status for this order (O2 slice 1), null when
  /// nothing is queued. Overrides the displayed status/stepper the same way
  /// `pendingStatuses` does on the owner desk and courier list.
  final OrderStatus? pendingTargetStatus;

  /// Set once when the queue reports this order's mutation was rejected
  /// (not a network blip) — the page shows a blame-free banner and fires
  /// [OrderDetailSyncFailureDismissed] to clear it back to null.
  final String? syncFailureReason;
```

Add both to `copyWith` (as nullable params, same pattern) — **note**: `copyWith`'s existing `??`-fallback pattern can't ever set a field back to `null` once non-null (every other field in this class has the same limitation already, e.g. `customer`/`area`), so clearing `syncFailureReason` needs a dedicated path, not `copyWith(syncFailureReason: null)`. Add a second, explicit method:

```dart
  OrderDetailState clearSyncFailure() => OrderDetailState(
        status: status,
        order: order,
        cancelStatus: cancelStatus,
        rateStatus: rateStatus,
        advanceStatus: advanceStatus,
        staffActionStatus: staffActionStatus,
        customer: customer,
        area: area,
        notes: notes,
        pendingTargetStatus: pendingTargetStatus,
        syncFailureReason: null,
      );
```

Add both new fields to `props`.

- [ ] **Step 4: Extend the events**

In `lib/presentation/orders/bloc/order_detail_event.dart`, add:

```dart
/// Internal: the offline queue's contents changed.
class _PendingMutationsUpdated extends OrderDetailEvent {
  const _PendingMutationsUpdated(this.mutations);

  final List<PendingMutation> mutations;

  @override
  List<Object?> get props => [mutations];
}

/// Internal: the offline queue reported a real rejection for this order.
class _SyncFailureArrived extends OrderDetailEvent {
  const _SyncFailureArrived(this.reason);

  final String reason;

  @override
  List<Object?> get props => [reason];
}

/// The page finished showing the sync-failure banner — clears it so it
/// doesn't re-show on the next rebuild.
class OrderDetailSyncFailureDismissed extends OrderDetailEvent {
  const OrderDetailSyncFailureDismissed();
}
```

- [ ] **Step 5: Extend the bloc**

In `lib/presentation/orders/bloc/order_detail_bloc.dart`:

- Add imports: `import '../../../core/offline/offline_mutation_queue.dart';`, `import '../../../core/offline/pending_mutation.dart';`
- Add `required OfflineMutationQueue queue` to the constructor, store as `_queue`.
- In the constructor body, register handlers and subscribe:

```dart
    on<_PendingMutationsUpdated>(_onPendingMutationsUpdated);
    on<_SyncFailureArrived>(_onSyncFailureArrived);
    on<OrderDetailSyncFailureDismissed>(
      (event, emit) => emit(state.clearSyncFailure()),
    );

    _queueSub = _queue.watchAll().listen(
      (mutations) => add(_PendingMutationsUpdated(mutations)),
    );
    _failureSub = _queue.failures
        .where((f) => f.orderId == orderId)
        .listen((f) => add(_SyncFailureArrived(f.reason)));
```

- Add fields:

```dart
  final OfflineMutationQueue _queue;
  StreamSubscription<List<PendingMutation>>? _queueSub;
  StreamSubscription<SyncFailure>? _failureSub;
```

- Add handlers:

```dart
  void _onPendingMutationsUpdated(
    _PendingMutationsUpdated event,
    Emitter<OrderDetailState> emit,
  ) {
    final mine = event.mutations.where((m) => m.orderId == _orderId);
    emit(state.copyWith(pendingTargetStatus: mine.isEmpty ? null : mine.first.targetStatus));
  }

  void _onSyncFailureArrived(
    _SyncFailureArrived event,
    Emitter<OrderDetailState> emit,
  ) {
    emit(state.copyWith(syncFailureReason: event.reason));
  }
```

Note `copyWith(pendingTargetStatus: null)` has the same "can't null out via `??`" limitation flagged in Step 3 — but here it's fine because `mine.isEmpty ? null : ...` passed straight through `copyWith`'s `pendingTargetStatus` param still hits the `??` fallback and keeps the OLD value when `null` is passed. Fix `copyWith` itself to accept an explicit "no change" sentinel isn't worth the complexity for two fields — instead, don't route this one through `copyWith`; construct the state directly:

```dart
  void _onPendingMutationsUpdated(
    _PendingMutationsUpdated event,
    Emitter<OrderDetailState> emit,
  ) {
    final mine = event.mutations.where((m) => m.orderId == _orderId);
    final s = state;
    emit(OrderDetailState(
      status: s.status,
      order: s.order,
      cancelStatus: s.cancelStatus,
      rateStatus: s.rateStatus,
      advanceStatus: s.advanceStatus,
      staffActionStatus: s.staffActionStatus,
      customer: s.customer,
      area: s.area,
      notes: s.notes,
      pendingTargetStatus: mine.isEmpty ? null : mine.first.targetStatus,
      syncFailureReason: s.syncFailureReason,
    ));
  }
```

- In `close()`, add `_queueSub?.cancel(); _failureSub?.cancel();`.

- [ ] **Step 6: Run test to verify it passes**

Run: `flutter test test/order_detail_bloc_test.dart`
Expected: PASS. Every existing `OrderDetailBloc(...)` construction in this file (there are 5: the shared `bloc`, `ownerBloc`, `customerBloc`, `courierBloc` ×2) needs `queue: <fake queue>` added — build one shared fake queue in `setUp`/`tearDown` the same way `repo`/`adminRepo` already are, and pass it to every constructor call site in the file.

- [ ] **Step 7: Wire DI**

In `lib/core/di/injector.dart`, the `OrderDetailBloc` factory (around line 1002–1019), add `queue: sl(),` to the constructor call.

- [ ] **Step 8: Wire the UI**

In `lib/presentation/orders/pages/order_detail_page.dart`:

- Add import: `import '../../widgets/common/pending_sync_badge.dart';`
- In `_OrderDetailView.build`'s `BlocConsumer`, widen `listenWhen` to include the new field and add the banner:

```dart
        listenWhen: (previous, current) =>
            previous.cancelStatus != current.cancelStatus ||
            previous.rateStatus != current.rateStatus ||
            previous.advanceStatus != current.advanceStatus ||
            previous.staffActionStatus != current.staffActionStatus ||
            previous.syncFailureReason != current.syncFailureReason,
        listener: (context, state) {
          if (state.cancelStatus == OrderCancelStatus.failure) {
            AppSnackBar.error(context, l10n.orderCancelErrorBody);
          }
          if (state.rateStatus == OrderRateStatus.failure) {
            AppSnackBar.error(context, l10n.orderRateErrorBody);
          }
          if (state.advanceStatus == OrderAdvanceStatus.failure) {
            AppSnackBar.error(context, l10n.orderActionErrorBody);
          }
          if (state.staffActionStatus == StaffActionStatus.failure) {
            AppSnackBar.error(context, l10n.staffOrderActionErrorBody);
          }
          if (state.syncFailureReason != null) {
            AppSnackBar.error(context, l10n.offlineSyncFailedBody);
            context.read<OrderDetailBloc>().add(const OrderDetailSyncFailureDismissed());
          }
        },
```

- Thread `pendingTargetStatus` down to `_OrderDetailContent` (new required param, same pattern as `isAdvancing` etc.):

At the `_OrderDetailContent(...)` construction site (inside the `OrderDetailStatus.loaded` case), add: `pendingTargetStatus: state.pendingTargetStatus,`

Add the field to `_OrderDetailContent`'s constructor and class body: `final OrderStatus? pendingTargetStatus;`

- In `_OrderDetailContent.build`, override the displayed status the same way as Tasks 9–10:

```dart
    final effectiveStatus = pendingTargetStatus ?? order.status;
    final view = orderStatusView(l10n, effectiveStatus);
```

(replaces the existing `final view = orderStatusView(l10n, order.status);` line). The stepper/chip rendering further down already reads `view` and `order.status` for `isTerminalBranch` — leave `isTerminalBranch`'s check on the REAL `order.status` (a pending mutation is never a terminal-branch target in this slice's scope, so this doesn't change behavior), but change `OrderStatusStepper(status: order.status)` to `OrderStatusStepper(status: effectiveStatus)` so the stepper visually advances to the queued step immediately.

Add the badge next to the chip/stepper:

```dart
              if (isTerminalBranch)
                StatusChip(label: view.label, tone: view.tone)
              else
                OrderStatusStepper(status: effectiveStatus),
              if (pendingTargetStatus != null) ...[
                const SizedBox(height: AppSpacing.sm),
                const PendingSyncBadge(),
              ],
```

- [ ] **Step 9: Full regression + commit**

Run: `flutter analyze` (0), `flutter test` (all green), parity script (green, unchanged from Task 7 — no new strings this task, `offlineSyncFailedBody` already added).

```bash
git add lib/presentation/orders/bloc/order_detail_bloc.dart lib/presentation/orders/bloc/order_detail_state.dart lib/presentation/orders/bloc/order_detail_event.dart lib/presentation/orders/pages/order_detail_page.dart lib/core/di/injector.dart test/order_detail_bloc_test.dart
git commit -m "feat(order-detail): show pending-sync badge + sync-failed banner"
```

---

### Task 12: Roadmap + status close-out

**Files:**
- Modify: `Docs/plan/dukkan-roadmap.md`
- Modify: `~/.claude/skills/dukkan-status/SKILL.md` (outside the repo — the live status anchor)

- [ ] **Step 1: Mark the O2 slice-1 roadmap line done**

In `Docs/plan/dukkan-roadmap.md`, under Phase 8, add a new checked line under O2 (the existing `- [ ] **O2 — App-wide offline mutation queue...**` bullet stays unchecked — this task only ships slice 1, not the whole initiative):

```markdown
  - [x] **O2 slice 1 — order-status offline queue.** DONE — plan
        `Docs/plan/2026-08-11-offline-order-status-queue-plan.md` fully executed.
        `OfflineMutationQueue` (`lib/core/offline/`) queues the 5 owner/courier
        status transitions when offline, replays on a 15s timer / app-resume /
        right after enqueue; `OrderRepositoryImpl.updateOrderStatus` is the one
        offline branch on this repository. Pending-sync badge on the owner
        desk, courier active list, and order-detail page; blame-free banner on
        a real rejection. Gates green: analyze 0, test <N>/<N>, parity 787.
        Live device pass still owed (same as every session before a device
        connects). Remaining O2 scope (order placement, driver assignment,
        catalog/console mutations) is still fully unscoped — each needs its
        own design pass per the original design doc.
```

(fill in `<N>` with the actual final `flutter test` count from Task 11's Step 9 run).

- [ ] **Step 2: Update the status skill**

Update `Current position` / `NEXT ACTION` in `dukkan-status`'s `SKILL.md` to point at whatever comes next per the roadmap's lowest unchecked block (at the time this plan was written, that was FILE_18 Products row, founder-driving) — re-check the roadmap file's current lowest unchecked item before writing this, since other sessions may have landed work in between.

- [ ] **Step 3: Final commit + push**

```bash
git add Docs/plan/dukkan-roadmap.md
git commit -m "docs(plan): mark O2 slice 1 (order-status offline queue) done"
git push origin feat/c2c-search
```

---

## Self-Review Notes (already applied above)

- **Spec coverage:** every locked-scope item from the design doc (5 transitions, FIFO, 3 replay outcomes, 3 triggers, 3 screens' overlay, blame-free banner, no new dependency) has a task. Out-of-scope items (driver assignment, order placement, console mutations) are untouched by every task above — none of them modify `AdminOrdersRepository`, `AssignDriver`, or `PlaceOrder`.
- **Placeholder scan:** no task step says "handle appropriately" or "similar to Task N" without the actual code; every test has real assertions.
- **Type consistency:** `PendingMutation`, `OfflineMutationQueue`, `SyncFailure`, `PendingSyncBadge` are defined once (Tasks 2–3, 5, 8) and referenced identically by name in every later task. `pendingStatuses` (`Map<String, OrderStatus>`) is the consistent shape across `OwnerOrdersState`/`DeliveriesState`; `OrderDetailState` uses the single-order `pendingTargetStatus` (`OrderStatus?`) instead, since it only ever tracks one order — this is a deliberate, noted difference, not an inconsistency.
