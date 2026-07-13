import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/admin/entities/staff_role.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/bloc/auth_bloc.dart';
import 'console_sections.dart';

/// Ctrl+K global search. The handler is wired in Session 17; until then the
/// intent is deliberately left unmapped (no dead action, no stray SnackBar) —
/// the binding lives here now so the shortcut surface exists from the start.
class ConsoleSearchIntent extends Intent {
  const ConsoleSearchIntent();
}

/// The desktop-first back-office frame (Founder Console). Wide (≥ 900 px) shows
/// a [NavigationRail] on the START side + a top bar; narrower falls back to an
/// app bar with a [Drawer]. The menu is [visibleConsoleSections] for the
/// signed-in staff member, so a support agent never even sees an area they
/// cannot open. All colours come from the theme — verified in light and dark.
class ConsoleShell extends StatelessWidget {
  const ConsoleShell({super.key, required this.child});

  /// The routed console page, supplied by the go_router `ShellRoute`.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = context.watch<AuthBloc>().state;
    final admin = authState.adminProfile;
    final sections = visibleConsoleSections(admin);
    final location = GoRouterState.of(context).matchedLocation;

    // Selected = exact route, else the deepest section that prefixes the
    // current location (nested pages added in later sessions), else the first.
    var selected = sections.indexWhere((s) => s.route == location);
    if (selected < 0) {
      selected = sections.lastIndexWhere(
        (s) => location == s.route || location.startsWith('${s.route}/'),
      );
    }
    if (selected < 0) selected = 0;

    final title = sections.isEmpty
        ? l10n.consoleTitle
        : _sectionLabel(l10n, sections[selected].labelKey);

    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.keyK, control: true):
            ConsoleSearchIntent(),
      },
      child: Actions(
        // ConsoleSearchIntent is intentionally unmapped until Session 17.
        actions: const <Type, Action<Intent>>{},
        child: LayoutBuilder(
          builder: (context, constraints) {
            // NavigationRail needs ≥ 2 destinations; a staff member who can see
            // only the dashboard falls back to the drawer layout even on desktop.
            final useRail = constraints.maxWidth >= 900 && sections.length >= 2;
            if (useRail) {
              return _WideLayout(
                sections: sections,
                selected: selected,
                extended: constraints.maxWidth >= 1200,
                title: title,
                staff: _StaffChip(authState: authState),
                child: child,
              );
            }
            return _NarrowLayout(
              sections: sections,
              selected: selected,
              title: title,
              staff: _StaffChip(authState: authState),
              child: child,
            );
          },
        ),
      ),
    );
  }
}

class _WideLayout extends StatelessWidget {
  const _WideLayout({
    required this.sections,
    required this.selected,
    required this.extended,
    required this.title,
    required this.staff,
    required this.child,
  });

  final List<ConsoleSection> sections;
  final int selected;
  final bool extended;
  final String title;
  final Widget staff;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            NavigationRail(
              extended: extended,
              selectedIndex: selected,
              onDestinationSelected: (i) => context.go(sections[i].route),
              backgroundColor: scheme.surface,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Icon(Icons.storefront_rounded, color: scheme.primary),
              ),
              destinations: [
                for (final s in sections)
                  NavigationRailDestination(
                    icon: Icon(s.icon),
                    selectedIcon: Icon(s.icon, color: scheme.primary),
                    label: Text(_sectionLabel(l10n, s.labelKey)),
                  ),
              ],
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(
              child: Column(
                children: [
                  _TopBar(title: title, staff: staff),
                  const Divider(height: 1, thickness: 1),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout({
    required this.sections,
    required this.selected,
    required this.title,
    required this.staff,
    required this.child,
  });

  final List<ConsoleSection> sections;
  final int selected;
  final String title;
  final Widget staff;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: AppSpacing.md),
            child: Center(child: staff),
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Icon(Icons.storefront_rounded, color: scheme.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      l10n.consoleTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  children: [
                    for (var i = 0; i < sections.length; i++)
                      ListTile(
                        selected: i == selected,
                        selectedColor: scheme.primary,
                        leading: Icon(sections[i].icon),
                        title: Text(_sectionLabel(l10n, sections[i].labelKey)),
                        onTap: () {
                          Navigator.of(context).pop();
                          context.go(sections[i].route);
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: child,
    );
  }
}

/// Top bar for the wide layout — current section title on the START side, the
/// signed-in staff chip on the END side.
class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, required this.staff});

  final String title;
  final Widget staff;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          staff,
        ],
      ),
    );
  }
}

/// Name + role of the signed-in staff member, e.g. «المؤسس».
class _StaffChip extends StatelessWidget {
  const _StaffChip({required this.authState});

  final AuthState authState;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final admin = authState.adminProfile;
    if (admin == null) return const SizedBox.shrink();

    final name = authState.user?.name.trim() ?? '';
    final display = name.isEmpty ? (authState.user?.email ?? '') : name;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: scheme.secondary.withValues(alpha: 0.16),
        borderRadius: AppRadius.smAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_outlined, size: 16, color: scheme.secondary),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              display.isEmpty
                  ? _roleLabel(l10n, admin.role)
                  : '$display · ${_roleLabel(l10n, admin.role)}',
              style: text.labelMedium?.copyWith(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Resolve a [ConsoleSection.labelKey] to its localized string. A small switch
/// (not reflection) — one arm added per section as sessions land.
String _sectionLabel(AppLocalizations l10n, String key) => switch (key) {
      'consoleNavDashboard' => l10n.consoleNavDashboard,
      'consoleNavAudit' => l10n.consoleNavAudit,
      'consoleNavUsers' => l10n.consoleNavUsers,
      'consoleNavShops' => l10n.consoleNavShops,
      _ => key,
    };

String _roleLabel(AppLocalizations l10n, StaffRole role) => switch (role) {
      StaffRole.founder => l10n.roleFounder,
      StaffRole.admin => l10n.roleAdmin,
      StaffRole.moderator => l10n.roleModerator,
      StaffRole.support => l10n.roleSupport,
    };
