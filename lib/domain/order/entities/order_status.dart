/// Order lifecycle (locked in `dukkan-roadmap.md`). Linear progression
/// `pending -> accepted -> preparing -> outForDelivery -> delivered`, with
/// `cancelled` (customer, pending/accepted only) and `rejected` (owner) as
/// terminal branches.
enum OrderStatus {
  pending,
  accepted,
  preparing,
  outForDelivery,
  delivered,
  cancelled,
  rejected;

  /// Wire form stored in Firestore. Kept explicit so a future enum rename
  /// can't silently break existing docs.
  String get wire => switch (this) {
        OrderStatus.pending => 'pending',
        OrderStatus.accepted => 'accepted',
        OrderStatus.preparing => 'preparing',
        OrderStatus.outForDelivery => 'outForDelivery',
        OrderStatus.delivered => 'delivered',
        OrderStatus.cancelled => 'cancelled',
        OrderStatus.rejected => 'rejected',
      };

  static OrderStatus fromWire(String value) => switch (value) {
        'accepted' => OrderStatus.accepted,
        'preparing' => OrderStatus.preparing,
        'outForDelivery' => OrderStatus.outForDelivery,
        'delivered' => OrderStatus.delivered,
        'cancelled' => OrderStatus.cancelled,
        'rejected' => OrderStatus.rejected,
        _ => OrderStatus.pending,
      };

  /// Customer can only back out before the shop starts preparing.
  bool get isCancellable => this == pending || this == accepted;

  /// No further transition happens from here — mirrors the Worker's
  /// `TERMINAL_STATUSES` (force-status/cancel side-effect guards, FC10).
  bool get isTerminal => this == delivered || this == cancelled || this == rejected;
}
