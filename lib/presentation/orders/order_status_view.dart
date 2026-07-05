import '../../domain/order/entities/order_status.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/common/status_chip.dart';

/// Human label + chip tone for an order status — the one place order-status
/// wording lives (lexicon: `Docs/Brand/BRAND.md`).
({String label, StatusTone tone}) orderStatusView(
  AppLocalizations l10n,
  OrderStatus status,
) {
  return switch (status) {
    OrderStatus.pending => (
        label: l10n.orderStatusPending,
        tone: StatusTone.neutral,
      ),
    OrderStatus.accepted => (
        label: l10n.orderStatusAccepted,
        tone: StatusTone.positive,
      ),
    OrderStatus.preparing => (
        label: l10n.orderStatusPreparing,
        tone: StatusTone.neutral,
      ),
    OrderStatus.outForDelivery => (
        label: l10n.orderStatusOutForDelivery,
        tone: StatusTone.positive,
      ),
    OrderStatus.delivered => (
        label: l10n.orderStatusDelivered,
        tone: StatusTone.positive,
      ),
    OrderStatus.cancelled => (
        label: l10n.orderStatusCancelled,
        tone: StatusTone.caution,
      ),
    OrderStatus.rejected => (
        label: l10n.orderStatusRejected,
        tone: StatusTone.caution,
      ),
  };
}
