import 'package:flutter/material.dart';

import '../../../core/theme/app_radius.dart';
import '../../../l10n/app_localizations.dart';

/// The one −/qty/+ control, reused everywhere a quantity is adjusted (product
/// grid tile, product detail, cart line) — never forked per-screen.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.qty,
    required this.onIncrement,
    required this.onDecrement,
    this.expand = false,
  });

  final int qty;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  /// Stretches to fill its parent's width (the product-grid tile control);
  /// otherwise sizes to its content (inline rows like the cart line).
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.roundAll,
        border: Border.all(color: scheme.primary),
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _StepButton(
            icon: Icons.remove_rounded,
            onTap: onDecrement,
            semanticLabel: l10n.qtyDecrease,
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$qty',
              textAlign: TextAlign.center,
              style: text.titleSmall?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            onTap: onIncrement,
            semanticLabel: l10n.qtyIncrease,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Icon(
          icon,
          size: 18,
          color: scheme.primary,
          semanticLabel: semanticLabel,
        ),
      ),
    );
  }
}
