import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/category_model.dart';

/// Cached taxonomy tree for offline product-form/browse use. Same `_ready`
/// guard pattern as `ShopLocalDataSource`/`ProductLocalDataSource`.
class TaxonomyLocalDataSource {
  TaxonomyLocalDataSource() {
    _ready = SharedPreferences.getInstance().then((p) => _prefs = p);
  }

  static const _key = 'cache.taxonomy';

  late final Future<void> _ready;
  late final SharedPreferences _prefs;

  Future<void> cacheTaxonomy(List<CategoryModel> categories) async {
    await _ready;
    final raw = jsonEncode(categories.map((c) => c.toJson()).toList());
    await _prefs.setString(_key, raw);
  }

  Future<List<CategoryModel>> getCachedTaxonomy() async {
    await _ready;
    final raw = _prefs.getString(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => CategoryModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
