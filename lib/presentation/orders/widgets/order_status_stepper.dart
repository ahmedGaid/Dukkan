import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/order/entities/order_status.dart';
import '../../../l10n/app_localizations.dart';
import '../order_status_view.dart';

/// The linear delivery progress (pending → accepted → preparing →
/// outForDelivery → delivered). `cancelled`/`rejected` are terminal branches
/// off this line (see `order_status.dart`) — the caller shows a
/// [StatusChip] banner for those instead of this stepper.
class OrderStatusStepper extends StatelessWidget {
  const OrderStatusStepper({super.key, required this.status});

  final OrderStatus status;

  static const _steps = [
    OrderStatus.pending,
    OrderStatus.accepted,
    OrderStatus.preparing,
    OrderStatus.outForDelivery,
    OrderStatus.delivered,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentIndex = _steps.indexOf(status);

    return Column(
      children: [
        for (var i = 0; i < _steps.length; i++)
          _StepRow(
            label: orderStatusView(l10n, _steps[i]).label,
            done: i <= currentIndex,
            isLast: i == _steps.length - 1,
          ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.label,
    required this.done,
    required this.isLast,
  });

  final String label;
  final bool done;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lineColor = done ? AppColors.success : scheme.outline;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: done ? AppColors.success : scheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: done ? AppColors.success : scheme.outline,
                    width: 2,
                  ),
                ),
              ),
              if (!isLast) Expanded(child: Container(width: 2, color: lineColor)),
            ],
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: done ? FontWeight.w600 : FontWeight.w400,
                      color: done
                          ? scheme.onSurface
                          : scheme.onSurface.withValues(alpha: 0.5),
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
