# SESSION 3 — Console Shell: /console subtree, guard, desktop-first navigation
# Files: lib/core/router/app_router.dart, lib/presentation/console/shell/** (new),
#        lib/presentation/console/dashboard/pages/dashboard_page.dart (placeholder, new),
#        lib/presentation/settings/pages/settings_page.dart,
#        lib/l10n/app_ar.arb + app_en.arb, Docs/Brand/BRAND.md

---

## Before You Start

1. Open `lib/core/router/app_router.dart` — the route list and `_redirect`; note how
   `/finance` is guarded (session-1 version with `adminProfile`).
2. Open `lib/presentation/shell/courier_home_shell.dart` — existing shell pattern
   (scaffold + tabs) for style reference.
3. Open `lib/presentation/settings/pages/settings_page.dart` — find `_FinanceRow`.
4. Recall `dukkan-brand` skill if not already loaded — the console must still FEEL Dukkan
   (calm, warm, minimal) even though it is desktop-first and information-dense.

Do not write anything yet.

---

## Task A — Console section registry

Create `lib/presentation/console/shell/console_sections.dart`:

```dart
/// One entry per console area. The nav shell builds its menu from this list,
/// filtered by AdminProfile.can(requiredPerm) — sections the staff member
/// cannot use simply do not render (rules + Worker still enforce underneath).
class ConsoleSection {
  const ConsoleSection({required this.route, required this.icon,
    required this.labelKey, required this.requiredPerm});
  final String route;        // '/console', '/console/users', …
  final IconData icon;
  final String labelKey;     // l10n key name, resolved in the shell
  final String? requiredPerm; // null = any active staff (dashboard)
}
```

Seed it with the full map (routes land across sessions 05–17; unregistered routes are
simply absent from `consoleSections` until their session adds them — start with
dashboard + audit placeholders only, append per session):
dashboard `/console` (null) · audit `/console/audit` (auditlogs.read).

## Task B — ShellRoute + guard

In `app_router.dart` add a `ShellRoute` whose builder wraps children in `ConsoleShell`,
with `GoRoute(path: '/console', …DashboardPage())` (placeholder page this session) inside.
In `_redirect`, after the authenticated checks, add:

```dart
if (location.startsWith('/console')) {
  final admin = _authBloc.state.adminProfile;
  if (admin == null || !admin.isActive) return '/home';
}
```

## Task C — `ConsoleShell` (desktop-first)

`lib/presentation/console/shell/console_shell.dart`:
- `LayoutBuilder`: width ≥ 900 → `Row[ NavigationRail(extended ≥ 1200), VerticalDivider,
  Expanded(child) ]`; below 900 → normal `Scaffold` with `Drawer`.
- Rail items = `consoleSections.where((s) => admin.can-or-null)`; selected index derived
  from current location; `context.go(section.route)`.
- Top bar: current section title + the signed-in staff chip (name + role, e.g. «المؤسس»).
- Wrap body in `Shortcuts`/`Actions` scaffold now (empty map except a `SearchIntent`
  placeholder bound to Ctrl+K — handler filled in Session 17; until then the intent is
  simply not mapped, no dead SnackBar).
- All colors via `AppColors`/theme — verify dark mode by eye. RTL: rail must sit on the
  START side (it does automatically in a `Row` under RTL — verify, don't assume).

`DashboardPage` placeholder: designed empty state ("لوحة التحكم" + one-line subtitle),
NOT a bare stub — Session 5 replaces the body.

## Task D — Entry point in Settings

In `settings_page.dart`, above `_FinanceRow`, add `_ConsoleRow` — visible when
`adminProfile?.isActive == true`, navigates `/console`. Same row style/chevron logic as
`_FinanceRow` (including the RTL chevron pick).

i18n: `consoleTitle` («لوحة التحكم»/"Console"), `consoleNavDashboard`, `consoleNavAudit`,
`settingsConsoleRow`, staff-role display names (`roleFounder` «المؤسس», `roleAdmin`
«مشرف عام», `roleModerator` «مشرف», `roleSupport` «دعم») — BOTH ARB files.
Lexicon rows in `BRAND.md`: Console → لوحة التحكم · Founder → المؤسس.

---

## Smoke Test

- [ ] Gates green (analyze 0, test, parity).
- [ ] Founder account: Settings shows Console row → `/console` opens shell; rail on desktop
      width (`flutter run -d windows` or web), drawer on phone width.
- [ ] Customer account: no Console row; typing `/console` URL (web) or deep link bounces
      to `/home`.
- [ ] Dark mode + Arabic RTL + English LTR all render correctly (rail side, chevrons).
- [ ] Widget test: ConsoleShell filters sections by permissions (fake AdminProfile).

---

## After This Session

```
Smoke test passed?
→ Update dukkan-status, commit, push
→ Fresh session → FILE_04_AUDIT_LOG.md
```
