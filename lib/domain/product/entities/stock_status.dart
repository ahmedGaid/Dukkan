/// Shelf state an owner sets per product (S2) and the customer sees on the
/// product card (C2) — `lowStock` is a nudge to buy soon, not a hard block.
enum StockStatus {
  inStock,
  lowStock,
  outOfStock;

  /// Wire form stored in Firestore. Kept explicit so a future enum rename
  /// can't silently break existing docs.
  String get wire => switch (this) {
        StockStatus.inStock => 'inStock',
        StockStatus.lowStock => 'lowStock',
        StockStatus.outOfStock => 'outOfStock',
      };

  static StockStatus fromWire(String value) => switch (value) {
        'lowStock' => StockStatus.lowStock,
        'outOfStock' => StockStatus.outOfStock,
        _ => StockStatus.inStock,
      };
}
