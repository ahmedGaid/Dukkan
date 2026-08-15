import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/order/entities/order_status.dart';
import '../errors/failures.dart';
import '../network/network_info.dart';
import 'pending_mutation.dart';

/// Queues an order-status write made while offline and replays it once
/// signal returns (O2 slice 1 — `Docs/plan/offline-order-status-queue-design.md`).
/// [prefs] is read synchronously (unlike `ProductLocalDataSource`'s `_ready`
/// guard) because by the time this is constructed via DI, `SharedPreferences`
/// was already awaited once at app start (`core/di/injector.dart`).
class OfflineMutationQueue with WidgetsBindingObserver {
  OfflineMutationQueue({
    required SharedPreferences prefs,
    required NetworkInfo networkInfo,
    required Future<void> Function(String orderId, OrderStatus status) remoteUpdate,
  })  : _prefs = prefs,
        _networkInfo = networkInfo,
        _remoteUpdate = remoteUpdate,
        _items = _load(prefs) {
    WidgetsBinding.instance.addObserver(this);
  }


  static const _key = 'offline.pendingMutations';

  /// `FirebaseException.code`s that mean "couldn't reach the server" rather
  /// than "the server looked at this and said no" — the replay loop treats
  /// these as still-offline (leave queued, stop the pass) and everything
  /// else as a real rejection (drop the item, emit a [SyncFailure]).
  static const _offlineCodes = {
    'unavailable',
    'deadline-exceeded',
    'cancelled',
    'unknown',
    'aborted',
    'internal',
  };

  final SharedPreferences _prefs;
  final NetworkInfo _networkInfo;
  final Future<void> Function(String orderId, OrderStatus status) _remoteUpdate;
  final _controller = StreamController<List<PendingMutation>>.broadcast();
  final _failureController = StreamController<SyncFailure>.broadcast();
  List<PendingMutation> _items;
  Timer? _timer;

  /// Stream of mutations the server actually rejected during replay (not a
  /// network blip) — see [SyncFailure].
  Stream<SyncFailure> get failures => _failureController.stream;

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
      } catch (e) {
        // Anything that isn't a ServerFailure (a bug, a cast failure while
        // parsing a response, ...) is not a "still offline" signal we know
        // how to retry — treat it like a rejection so it can't wedge this
        // item (and, via the 15s timer, the whole queue) in an infinite
        // crash loop with zero user-facing signal.
        _remove(mutation.id);
        _failureController.add(SyncFailure(orderId: mutation.orderId, reason: 'unexpected'));
      }
    }
    _stopTimerIfDrained();
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
