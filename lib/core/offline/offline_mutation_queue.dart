import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/order/entities/order_status.dart';
import '../errors/failures.dart';
import 'pending_mutation.dart';

/// `FirebaseException.code`s that mean "couldn't reach the server" rather
/// than "the server looked at this and said no" — [isOfflineShapedFailure]
/// treats these (plus a null `code`) as still-offline; everything else is a
/// real rejection.
const _offlineCodes = {
  'unavailable',
  'deadline-exceeded',
  'cancelled',
  'unknown',
  'aborted',
  'internal',
};

/// True when [failure] looks like "couldn't reach the server" rather than
/// "the server looked at this and said no". Shared between
/// [OfflineMutationQueue]'s replay classification and `OrderRepositoryImpl`'s
/// try-then-queue write, so both agree on what counts as offline.
///
/// A null [ServerFailure.code] counts as offline-shaped too: the one place
/// that throws a code-less `ServerFailure` on the order-status write path is
/// `OrderRemoteDataSource._advanceStatus`'s "Not signed in" guard, which can
/// fire legitimately in the real window right after cold start where
/// `FirebaseAuth` is still restoring `currentUser` asynchronously — that is
/// a "not ready yet" condition, not a real rejection, and must be retried
/// once auth (or signal) catches up rather than dropped.
bool isOfflineShapedFailure(ServerFailure failure) =>
    failure.code == null || _offlineCodes.contains(failure.code);

/// Queues an order-status write made while offline and replays it once
/// signal returns (O2 slice 1 — `Docs/plan/offline-order-status-queue-design.md`).
/// [prefs] is read synchronously (unlike `ProductLocalDataSource`'s `_ready`
/// guard) because by the time this is constructed via DI, `SharedPreferences`
/// was already awaited once at app start (`core/di/injector.dart`).
///
/// [currentUidProvider] scopes every replay attempt to whoever is signed in
/// right now — mirrors `OrderRepositoryImpl`'s own seam. A shared device
/// (plausible for shop staff) can have one user's mutation still queued when
/// another signs in; [_replay] must never attempt or drop that mutation
/// under the wrong identity (final-review I4), and must never touch the
/// queue at all while nobody is signed in (final-review C2/I1 — this is
/// what makes replaying from the constructor, below, safe against the
/// cold-start window where `FirebaseAuth.currentUser` hasn't restored yet).
class OfflineMutationQueue with WidgetsBindingObserver {
  OfflineMutationQueue({
    required SharedPreferences prefs,
    required Future<void> Function(String orderId, OrderStatus status) remoteUpdate,
    required String? Function() currentUidProvider,
  })  : _prefs = prefs,
        _remoteUpdate = remoteUpdate,
        _currentUidProvider = currentUidProvider,
        _items = _load(prefs) {
    WidgetsBinding.instance.addObserver(this);
    // A queue hydrated from a persisted, non-empty state (the app was
    // killed with pending mutations) must not sit inert until the user
    // makes another change or the app backgrounds/foregrounds — cold start
    // gets no synthetic `resumed` lifecycle event (final-review I1).
    if (_items.isNotEmpty) {
      _startTimer();
      unawaited(_replay());
    }
  }

  static const _key = 'offline.pendingMutations';

  final SharedPreferences _prefs;
  final Future<void> Function(String orderId, OrderStatus status) _remoteUpdate;
  final String? Function() _currentUidProvider;
  final _controller = StreamController<List<PendingMutation>>.broadcast();
  final _failureController = StreamController<SyncFailure>.broadcast();
  List<PendingMutation> _items;
  Timer? _timer;

  /// Failures that fired while nobody was subscribed to [failures] (or
  /// while the wrong page was open) — [failures] is a broadcast stream with
  /// no buffering, and replay runs on a 15s timer / app-resume, not "the
  /// user has this order's page open" (final-review I2). Any surface can
  /// drain this to show a rejection it would otherwise never see.
  final List<SyncFailure> _unseenFailures = [];

  /// Stream of mutations the server actually rejected during replay (not a
  /// network blip) — see [SyncFailure].
  Stream<SyncFailure> get failures => _failureController.stream;

  /// Sync snapshot of failures no surface has shown yet — pairs with
  /// [failures] the same way [pendingForOrder] pairs with [watchAll]: read
  /// this once on construction/open to catch anything missed while nobody
  /// was listening, then rely on [failures] for what happens next.
  List<SyncFailure> get unseenFailures => List.unmodifiable(_unseenFailures);

  /// Marks every unseen failure for [orderId] as shown (there is at most
  /// one per order — a later failure for the same order replaces the
  /// earlier one, see [_recordFailure]).
  void markFailureSeen(String orderId) {
    _unseenFailures.removeWhere((f) => f.orderId == orderId);
  }

  /// Stream of mutation list updates. Does not emit an initial state to late
  /// subscribers (broadcast controller behavior). Callers must pair this with
  /// [pendingForOrder] to read the current state on first render, then use
  /// this stream for updates.
  Stream<List<PendingMutation>> watchAll() => _controller.stream;

  /// Sync lookup for the overlay widgets (owner desk / courier list / order
  /// detail) — they need this on every build, not via an awaited call.
  List<PendingMutation> pendingForOrder(String orderId) =>
      _items.where((m) => m.orderId == orderId).toList();

  /// Sync snapshot of every currently-queued mutation, across all orders —
  /// pairs with [watchAll] the same way [pendingForOrder] does: a list-scoped
  /// subscriber (a bloc caching an orderId→status map for a whole page) reads
  /// this once to seed its initial state, then relies on [watchAll] for
  /// updates, since the broadcast stream never replays to a late subscriber.
  List<PendingMutation> get allPending => List.unmodifiable(_items);

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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _items.isNotEmpty) {
      unawaited(_replay());
    }
  }

  /// One FIFO pass over a snapshot of the queue. A network-shaped failure
  /// (still offline) stops the pass immediately — the next trigger retries
  /// everything from the top. A real rejection only drops that one item and
  /// keeps going, so one bad conflict never blocks the rest of the queue
  /// (design doc, "Replay + error handling"). Drops straight to Firestore's
  /// own write via [_remoteUpdate] with no upfront `NetworkInfo` probe — the
  /// classification below already tells "still offline" apart from "really
  /// rejected" after attempting, so a separate connectivity check ahead of
  /// every 15s tick was pure extra network cost (final-review I3).
  Future<void> _replay() async {
    if (_items.isEmpty) return;
    // Nobody signed in — never attempt, never drop. Covers both a real
    // signed-out state and the narrow cold-start window before
    // `FirebaseAuth.currentUser` restores (final-review C2/I4).
    final uid = _currentUidProvider();
    if (uid == null) return;
    for (final mutation in [..._items]) {
      // A stale mutation queued under a different signed-in identity (a
      // shared device) must never replay under this one — leave it queued
      // and move on to the rest of the pass (final-review I4).
      if (mutation.actorUid != uid) continue;
      try {
        await _remoteUpdate(mutation.orderId, mutation.targetStatus);
        _remove(mutation.id);
      } on ServerFailure catch (e) {
        if (isOfflineShapedFailure(e)) return;
        _remove(mutation.id);
        _recordFailure(SyncFailure(orderId: mutation.orderId, reason: e.code ?? 'unknown'));
      } catch (e) {
        // Anything that isn't a ServerFailure (a bug, a cast failure while
        // parsing a response, ...) is not a "still offline" signal we know
        // how to retry — treat it like a rejection so it can't wedge this
        // item (and, via the 15s timer, the whole queue) in an infinite
        // crash loop with zero user-facing signal.
        _remove(mutation.id);
        _recordFailure(SyncFailure(orderId: mutation.orderId, reason: 'unexpected'));
      }
    }
    _stopTimerIfDrained();
  }

  /// Emits [failure] on the live [failures] stream and retains it as unseen
  /// (final-review I2) so a surface that wasn't listening at the moment it
  /// fired can still discover it later. At most one unseen failure per
  /// order — a later rejection for the same order replaces the earlier one
  /// rather than piling up.
  void _recordFailure(SyncFailure failure) {
    _unseenFailures.removeWhere((f) => f.orderId == failure.orderId);
    _unseenFailures.add(failure);
    _failureController.add(failure);
  }

  void _remove(String id) {
    _items = _items.where((m) => m.id != id).toList();
    unawaited(_persist());
    _controller.add(List.unmodifiable(_items));
  }

  Future<void> _persist() async {
    final raw = jsonEncode(_items.map((m) => m.toJson()).toList());
    await _prefs.setString(_key, raw);
  }

  static List<PendingMutation> _load(SharedPreferences prefs) {
    try {
      final raw = prefs.getString(_key);
      if (raw == null) return [];
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => PendingMutation.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      // Treat any parse/schema error as "nothing persisted" — corrupted or
      // future-schema entries must never crash app startup.
      return [];
    }
  }

  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    await _controller.close();
    await _failureController.close();
  }
}

/// One queued mutation the server actually rejected (not a network blip) —
/// e.g. someone else already changed the order while this device was
/// offline. The screen that owns the affected order shows a blame-free
/// banner; [reason] is the raw Firestore code, for logs only, never shown.
class SyncFailure {
  const SyncFailure({required this.orderId, required this.reason});

  final String orderId;
  final String reason;
}
