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
        _items = _load(prefs);


  static const _key = 'offline.pendingMutations';

  final SharedPreferences _prefs;
  final NetworkInfo _networkInfo;
  final Future<void> Function(String orderId, OrderStatus status) _remoteUpdate;
  final _controller = StreamController<List<PendingMutation>>.broadcast();
  List<PendingMutation> _items;

  /// Stream of mutation list updates. Does not emit an initial state to late
  /// subscribers (broadcast controller behavior). Callers must pair this with
  /// [pendingForOrder] to read the current state on first render, then use
  /// this stream for updates.
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
    await _controller.close();
  }
}
