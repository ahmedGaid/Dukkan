import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injector.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/order/entities/order.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/price_tag.dart';
import '../../widgets/common/skeletons.dart';
import '../../widgets/common/status_chip.dart';
import '../bloc/orders_bloc.dart';
import '../order_status_view.dart';

/// The customer "Orders" tab. Owns its [OrdersBloc] (customer uid from the
/// signed-in session); every state (loading/empty/error) is designed.
class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthBloc>().state.user!.uid;
    return BlocProvider(
      create: (_) =>
          sl<OrdersBloc>(param1: uid)..add(const OrdersStarted()),
      child: const _OrdersView(),
    );
  }
}

class _OrdersView extends StatelessWidget {
  const _OrdersView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Text(l10n.navOrders, style: text.headlineSmall),
            ),
            Expanded(
              child: BlocBuilder<OrdersBloc, OrdersState>(
                builder: (context, state) => switch (state.status) {
                  OrdersStatus.loading => const Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: ListShimmer(),
                    ),
                  OrdersStatus.error => EmptyState(
                      icon: Icons.error_outline,
                      title: l10n.errorTitle,
                      message: l10n.ordersErrorBody,
                      actionLabel: l10n.actionRetry,
                      onAction: () => context
                          .read<OrdersBloc>()
                          .add(const OrdersRetryRequested()),
                    ),
                  OrdersStatus.loaded => state.orders.isEmpty
                      ? EmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: l10n.ordersEmptyTitle,
                          message: l10n.ordersEmptyBody,
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          itemCount: state.orders.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, i) =>
                              _OrderCard(order: state.orders[i]),
                        ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final view = orderStatusView(l10n, order.status);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () => context.push('/order/${order.id}'),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                StatusChip(label: view.label, tone: view.tone),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  DateFormat.yMMMd(locale).add_Hm().format(order.createdAt),
                  style: text.bodySmall
                      ?.copyWith(color: scheme.onSurface.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shopping_basket_outlined,
                      size: 16,
                      color: scheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text('${order.items.length}', style: text.bodySmall),
                  ],
                ),
              ],
            ),
          ),
          PriceTag(
            order.totalMinor,
            style:
                text.titleMedium?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
