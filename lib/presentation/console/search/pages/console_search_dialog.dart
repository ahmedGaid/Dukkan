import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/money.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../domain/admin/entities/admin_profile.dart';
import '../../../../domain/admin/entities/console_search_results.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../catalog/pages/product_form_page.dart';
import '../../../widgets/common/empty_state.dart';
import '../../../widgets/common/skeletons.dart';
import '../bloc/console_search_bloc.dart';

/// Global Ctrl+K search over the console (FC17) — opened from
/// `ConsoleShell`'s `ConsoleSearchIntent` binding and from the top bar's
/// search icon (phone has no Ctrl+K). One dialog instance per open; the
/// bloc is permission-scoped to the signed-in [admin] for its lifetime.
class ConsoleSearchDialog {
  const ConsoleSearchDialog._();

  static void show(BuildContext context, AdminProfile admin) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => BlocProvider(
        create: (_) => sl<ConsoleSearchBloc>(param1: admin),
        child: const _ConsoleSearchDialogBody(),
      ),
    );
  }
}

class _ConsoleSearchDialogBody extends StatefulWidget {
  const _ConsoleSearchDialogBody();

  @override
  State<_ConsoleSearchDialogBody> createState() => _ConsoleSearchDialogBodyState();
}

class _ConsoleSearchDialogBodyState extends State<_ConsoleSearchDialogBody> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  int _selectedIndex = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _selectedIndex = 0);
      context.read<ConsoleSearchBloc>().add(ConsoleSearchQueryChanged(value));
    });
  }

  void _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final hits = _flattenResults(
      context.read<ConsoleSearchBloc>().state.results,
      AppLocalizations.of(context)!,
      Localizations.localeOf(context).languageCode == 'ar',
    );
    if (hits.isEmpty) return;
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() => _selectedIndex = (_selectedIndex + 1) % hits.length);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() => _selectedIndex = (_selectedIndex - 1 + hits.length) % hits.length);
    }
  }

  void _activateSelected(BuildContext context) {
    final hits = _flattenResults(
      context.read<ConsoleSearchBloc>().state.results,
      AppLocalizations.of(context)!,
      Localizations.localeOf(context).languageCode == 'ar',
    );
    if (_selectedIndex < hits.length) hits[_selectedIndex].onTap(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 96),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: KeyboardListener(
                focusNode: _focusNode,
                onKeyEvent: _onKey,
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: l10n.consoleSearchHint,
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: AppRadius.mdAll),
                  ),
                  onChanged: _onChanged,
                  onSubmitted: (_) => _activateSelected(context),
                ),
              ),
            ),
            const Divider(height: 1, thickness: 1),
            Flexible(
              child: BlocBuilder<ConsoleSearchBloc, ConsoleSearchState>(
                builder: (context, state) => _ResultsList(
                  state: state,
                  selectedIndex: _selectedIndex,
                  onActivate: (hit) => hit.onTap(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultsList extends StatelessWidget {
  const _ResultsList({required this.state, required this.selectedIndex, required this.onActivate});

  final ConsoleSearchState state;
  final int selectedIndex;
  final void Function(_Hit hit) onActivate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    if (state.query.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: EmptyState(
          icon: Icons.search,
          title: l10n.consoleSearchPromptTitle,
          message: l10n.consoleSearchPromptBody,
        ),
      );
    }
    if (state.status == ConsoleSearchStatus.loading) {
      return const Padding(padding: EdgeInsets.all(AppSpacing.md), child: ListShimmer());
    }

    final hits = _flattenResults(state.results, l10n, isArabic);
    if (hits.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: EmptyState(
          icon: Icons.search_off,
          title: l10n.consoleSearchEmptyTitle,
          message: l10n.consoleSearchEmptyBody,
        ),
      );
    }

    String? lastGroup;
    final rows = <Widget>[];
    for (var i = 0; i < hits.length; i++) {
      final hit = hits[i];
      if (hit.groupLabel != lastGroup) {
        lastGroup = hit.groupLabel;
        rows.add(Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
          child: Text(
            hit.groupLabel,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary),
          ),
        ));
      }
      rows.add(_HitRow(hit: hit, selected: i == selectedIndex, onTap: () => onActivate(hit)));
    }
    return ListView(padding: const EdgeInsets.only(bottom: AppSpacing.md), children: rows);
  }
}

class _HitRow extends StatelessWidget {
  const _HitRow({required this.hit, required this.selected, required this.onTap});

  final _Hit hit;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: selected ? scheme.primary.withValues(alpha: 0.08) : null,
      child: ListTile(
        dense: true,
        leading: Icon(hit.icon, size: 20),
        title: Text(hit.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: hit.subtitle == null ? null : Text(hit.subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis),
        onTap: onTap,
      ),
    );
  }
}

class _Hit {
  const _Hit({
    required this.icon,
    required this.groupLabel,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String groupLabel;
  final String title;
  final String? subtitle;
  final void Function(BuildContext context) onTap;
}

/// Every group in a fixed order (order, users, shops, products, drivers,
/// areas, categories) — a group simply contributes zero rows when the caller
/// lacks its permission (the bloc already left it empty).
List<_Hit> _flattenResults(ConsoleSearchResults r, AppLocalizations l10n, bool isArabic) {
  final hits = <_Hit>[];

  final order = r.order;
  if (order != null) {
    hits.add(_Hit(
      icon: Icons.receipt_long_outlined,
      groupLabel: l10n.consoleNavOrders,
      title: '#${order.id}',
      subtitle: Money.format(order.totalMinor, languageCode: isArabic ? 'ar' : 'en'),
      onTap: (context) {
        Navigator.of(context).pop();
        context.push('/order/${order.id}?role=staff');
      },
    ));
  }

  for (final u in r.users) {
    hits.add(_Hit(
      icon: Icons.person_outline,
      groupLabel: l10n.consoleNavUsers,
      title: u.name.isEmpty ? u.email : u.name,
      subtitle: u.email,
      onTap: (context) {
        Navigator.of(context).pop();
        context.push('/console/users/${u.uid}', extra: u);
      },
    ));
  }

  for (final s in r.shops) {
    hits.add(_Hit(
      icon: Icons.storefront_outlined,
      groupLabel: l10n.consoleNavShops,
      title: isArabic ? s.nameAr : s.name,
      subtitle: isArabic ? s.name : s.nameAr,
      onTap: (context) {
        Navigator.of(context).pop();
        context.push('/console/shops/${s.id}', extra: s);
      },
    ));
  }

  for (final p in r.products) {
    hits.add(_Hit(
      icon: Icons.inventory_2_outlined,
      groupLabel: l10n.consoleNavProducts,
      title: isArabic ? p.nameAr : p.name,
      onTap: (context) {
        Navigator.of(context).pop();
        context.push(
          '/catalog/product-form',
          extra: ProductFormArgs(shopId: p.shopId, product: p),
        );
      },
    ));
  }

  for (final d in r.drivers) {
    hits.add(_Hit(
      icon: Icons.delivery_dining_outlined,
      groupLabel: l10n.consoleNavDrivers,
      title: d.name,
      subtitle: d.phone,
      onTap: (context) {
        Navigator.of(context).pop();
        context.push('/console/drivers/${d.uid}', extra: d);
      },
    ));
  }

  for (final a in r.areas) {
    hits.add(_Hit(
      icon: Icons.map_outlined,
      groupLabel: l10n.consoleNavGeo,
      title: isArabic ? a.nameAr : a.nameEn,
      onTap: (context) {
        Navigator.of(context).pop();
        context.go('/console/geo');
      },
    ));
  }

  for (final c in r.categories) {
    hits.add(_Hit(
      icon: Icons.category_outlined,
      groupLabel: l10n.consoleNavTaxonomy,
      title: isArabic ? c.nameAr : c.nameEn,
      onTap: (context) {
        Navigator.of(context).pop();
        context.go('/console/taxonomy');
      },
    ));
  }

  return hits;
}
