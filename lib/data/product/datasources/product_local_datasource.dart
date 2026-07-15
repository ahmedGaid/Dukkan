import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/product_model.dart';

/// Cached products keyed by shop, for offline browsing. Same `_ready` guard
/// pattern as `ShopLocalDataSource`.
class ProductLocalDataSource {
  ProductLocalDataSource() {
    _ready = SharedPreferences.getInstance().then((p) => _prefs = p);
  }

  static const _keyPrefix = 'cache.products.';

  /// The whole-catalog cache (global search). Kept under the same prefix so it
  /// clears with the rest, but skipped by [getCachedProduct]'s per-shop scan so
  /// a product isn't matched twice.
  static const _allKey = '${_keyPrefix}__all__';

  late final Future<void> _ready;
  late final SharedPreferences _prefs;

  Future<void> cacheProductsByShop(
    String shopId,
    List<ProductModel> products,
  ) async {
    await _ready;
    final raw = jsonEncode(products.map((p) => p.toJson()).toList());
    await _prefs.setString('$_keyPrefix$shopId', raw);
  }

  Future<List<ProductModel>> getCachedProductsByShop(String shopId) async {
    await _ready;
    final raw = _prefs.getString('$_keyPrefix$shopId');
    if (raw == null) return [];
    return _decode(raw);
  }

  Future<void> cacheAllProducts(List<ProductModel> products) async {
    await _ready;
    final raw = jsonEncode(products.map((p) => p.toJson()).toList());
    await _prefs.setString(_allKey, raw);
  }

  Future<List<ProductModel>> getCachedAllProducts() async {
    await _ready;
    final raw = _prefs.getString(_allKey);
    if (raw == null) return [];
    return _decode(raw);
  }

  /// Scans every cached shop's product list for a single product id — used
  /// when `getProduct` is called offline without knowing the shop upfront.
  Future<ProductModel?> getCachedProduct(String productId) async {
    await _ready;
    for (final key in _prefs.getKeys()) {
      if (!key.startsWith(_keyPrefix) || key == _allKey) continue;
      final raw = _prefs.getString(key);
      if (raw == null) continue;
      for (final product in _decode(raw)) {
        if (product.id == productId) return product;
      }
    }
    return null;
  }

  /// Devtools "clear caches" tool (FC15) — every per-shop key plus the
  /// whole-catalog key share [_keyPrefix], so one scan clears all of them.
  Future<void> clear() async {
    await _ready;
    for (final key in _prefs.getKeys().where((k) => k.startsWith(_keyPrefix)).toList()) {
      await _prefs.remove(key);
    }
  }

  List<ProductModel> _decode(String raw) {
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => ProductModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
