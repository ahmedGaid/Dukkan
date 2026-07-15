import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/area_model.dart';

/// Cached area list for offline checkout use. Same `_ready` guard pattern as
/// `TaxonomyLocalDataSource`.
class AreasLocalDataSource {
  AreasLocalDataSource() {
    _ready = SharedPreferences.getInstance().then((p) => _prefs = p);
  }

  static const _key = 'cache.areas';

  late final Future<void> _ready;
  late final SharedPreferences _prefs;

  Future<void> cacheAreas(List<AreaModel> areas) async {
    await _ready;
    final raw = jsonEncode(areas.map((a) => a.toJson()).toList());
    await _prefs.setString(_key, raw);
  }

  Future<List<AreaModel>> getCachedAreas() async {
    await _ready;
    final raw = _prefs.getString(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => AreaModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Devtools "clear caches" tool (FC15) — forces the next read to hit remote.
  Future<void> clear() async {
    await _ready;
    await _prefs.remove(_key);
  }
}
