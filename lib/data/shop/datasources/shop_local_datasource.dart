import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/shop_model.dart';

/// Cached shop list for offline browsing. `_ready` guard is the Shoppy
/// pattern — every public method awaits the prefs handle before touching it.
class ShopLocalDataSource {
  ShopLocalDataSource() {
    _ready = SharedPreferences.getInstance().then((p) => _prefs = p);
  }

  static const _key = 'cache.shops';

  late final Future<void> _ready;
  late final SharedPreferences _prefs;

  Future<void> cacheShops(List<ShopModel> shops) async {
    await _ready;
    final raw = jsonEncode(shops.map((s) => s.toJson()).toList());
    await _prefs.setString(_key, raw);
  }

  Future<List<ShopModel>> getCachedShops() async {
    await _ready;
    final raw = _prefs.getString(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => ShopModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Devtools "clear caches" tool (FC15) — forces the next read to hit remote.
  Future<void> clear() async {
    await _ready;
    await _prefs.remove(_key);
  }
}
