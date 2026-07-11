/// The order events that trigger a push (P2b, M11). Wire form matches what
/// the Worker's `/notify` endpoint expects — see `worker/src/index.js`.
enum NotificationEventType {
  newOrder,
  statusUpdate,
  driverAssigned;

  String get wire => switch (this) {
        NotificationEventType.newOrder => 'newOrder',
        NotificationEventType.statusUpdate => 'statusUpdate',
        NotificationEventType.driverAssigned => 'driverAssigned',
      };
}

/// Best-effort push trigger. The app never sends FCM messages itself — it
/// asks the Worker to, which resolves the recipient and authorizes the
/// request server-side (a customer can only trigger `newOrder` for their own
/// order; a shop owner can only trigger `statusUpdate` for their own shop's
/// order). A failure here must never surface to the UI or block the order
/// flow — implementations swallow their own errors.
abstract class NotificationRepository {
  Future<void> notifyOrderEvent({
    required String orderId,
    required NotificationEventType type,
    required String title,
    required String body,
  });
}
