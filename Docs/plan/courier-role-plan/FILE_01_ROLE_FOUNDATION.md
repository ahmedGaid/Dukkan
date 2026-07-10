# SESSION 1 — Courier Role Foundation
# Files: lib/domain/auth/entities/user_role.dart, lib/presentation/auth/pages/signup_page.dart,
#        lib/presentation/home/pages/home_page.dart, lib/core/router/app_router.dart,
#        lib/presentation/settings/pages/settings_page.dart, lib/presentation/courier/pages/courier_home_shell.dart (NEW),
#        lib/l10n/app_ar.arb, lib/l10n/app_en.arb, firestore.rules, test/domain/auth/user_role_test.dart

---

## Before You Start

1. Recall the `dukkan-brand` and `dukkan-flutter` skills.
2. Open `lib/domain/auth/entities/user_role.dart` → read the whole enum (it is ~18 lines).
3. Open `lib/presentation/auth/pages/signup_page.dart` → find the `Row` with two `_RoleCard` widgets (~line 85) and the `_RoleCard` class at the bottom.
4. Open `lib/presentation/home/pages/home_page.dart` → confirm it branches `isOwner ? OwnerHomeShell() : HomeShell()`.
5. Open `lib/core/router/app_router.dart` → find `_redirect`, the `SessionStatus.authenticated` case (~line 116).
6. Open `lib/presentation/settings/pages/settings_page.dart` → find `roleLabel` (~line 95).
7. Open `lib/l10n/app_en.arb` → find `roleCustomer` / `roleOwner` keys to match naming style.
8. Open `firestore.rules` → find the `/users/{userId}` create rule (role list, ~line 22).

Do not write anything yet.

---

## Task A — Add `courier` to the enum

In `lib/domain/auth/entities/user_role.dart`, replace the enum body so it reads:

```dart
enum UserRole {
  customer,
  owner,
  courier;

  /// Wire form stored in Firestore. Kept explicit (not `.name`) so a future
  /// rename of the Dart enum can't silently break existing docs.
  String get wire => switch (this) {
        UserRole.customer => 'customer',
        UserRole.owner => 'owner',
        UserRole.courier => 'courier',
      };

  static UserRole fromWire(String value) => switch (value) {
        'owner' => UserRole.owner,
        'courier' => UserRole.courier,
        _ => UserRole.customer,
      };
}
```

Keep the existing doc comment above the enum; extend its first line to mention the courier.
No changes needed in `app_user_model.dart` — it already goes through `fromWire`.

## Task B — Third role card at signup

In `signup_page.dart`, the two `_RoleCard`s sit in a `Row` of two `Expanded`s. Three cards in one
row is too cramped for Arabic labels — restructure to: keep the customer/owner `Row` as is, then
add the courier card full-width below it:

Find the closing `],\n)` of that `Row` (after the owner `_RoleCard`), and insert directly after
the `Row`:

```dart
const SizedBox(height: AppSpacing.sm),
_RoleCard(
  icon: Icons.delivery_dining_outlined,
  label: l10n.roleCourier,
  selected: _role == UserRole.courier,
  onTap: () => setState(() => _role = UserRole.courier),
),
```

`_RoleCard` needs no changes (it already renders icon + label + selected border).

## Task C — i18n keys

Add to `lib/l10n/app_ar.arb`:

```json
"roleCourier": "مندوب توصيل",
"roleCourierLabel": "مندوب التوصيل",
"courierComingSoonTitle": "لا توصيلات بعد",
"courierComingSoonBody": "انضم لدكان بكود الدعوة لتبدأ استلام الطلبات."
```

And matching keys to `app_en.arb`:

```json
"roleCourier": "Courier",
"roleCourierLabel": "Courier",
"courierComingSoonTitle": "No deliveries yet",
"courierComingSoonBody": "Join a shop with its invite code to start receiving orders."
```

Then run `flutter gen-l10n`.

## Task D — Placeholder courier shell + role routing

Create `lib/presentation/courier/pages/courier_home_shell.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../widgets/common/empty_state.dart';

/// Courier landing (D1 placeholder — replaced by the real deliveries shell in
/// session 4). Shows a designed empty state, never a blank screen.
class CourierHomeShell extends StatelessWidget {
  const CourierHomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.roleCourierLabel)),
      body: EmptyState(
        icon: Icons.delivery_dining_outlined,
        title: l10n.courierComingSoonTitle,
        message: l10n.courierComingSoonBody,
      ),
    );
  }
}
```

> Before writing: open `lib/presentation/widgets/common/empty_state.dart` and match its actual
> constructor parameter names (`title`/`message`/`icon` may differ — use what exists).

In `home_page.dart`, replace the two-way branch with a role switch:

```dart
final role = context.watch<AuthBloc>().state.user?.role;
return switch (role) {
  UserRole.owner => const OwnerHomeShell(),
  UserRole.courier => const CourierHomeShell(),
  _ => const HomeShell(),
};
```

(add the import for `courier_home_shell.dart`; update the class doc comment to mention the third branch).

In `app_router.dart` `_redirect`, the authenticated case currently sends any non-owner to
`/home` — `UserRole.courier` already falls into that branch (`user?.role != UserRole.owner`),
so **no logic change is needed**; just extend the class doc comment (the `authenticated →` line)
to say couriers land on `/home` like customers. Verify by reading the condition once more.

In `settings_page.dart`, `roleLabel` is a two-way ternary on `UserRole.owner`. Convert it to a
switch over the three roles, courier case → `l10n.roleCourierLabel`.

## Task E — Firestore rules: accept the third role

In `firestore.rules`, `/users/{userId}` create rule, change:

```
&& request.resource.data.role in ['customer', 'owner']
```

to:

```
&& request.resource.data.role in ['customer', 'owner', 'courier']
```

Deploy the rules (or note for the user if CLI login is blocked).

## Task F — Test

Create `test/domain/auth/user_role_test.dart` covering: `wire` round-trips for all three roles,
`fromWire('courier')`, and unknown string falls back to customer. Match the style of existing
domain tests in `test/`.

---

## Smoke Test

- [ ] `flutter analyze` → 0 issues; `flutter test` → all green; i18n parity script passes.
- [ ] Signup screen shows THREE role cards; courier card selectable with mint border, label "مندوب توصيل" in Arabic build.
- [ ] Sign up a fresh account as courier → lands on courier placeholder screen (designed empty state, not blank).
- [ ] Firestore `/users/{uid}` doc for that account has `role: 'courier'` (create not rejected by rules).
- [ ] Settings for the courier account shows "مندوب التوصيل" as the role label.
- [ ] Log in with the existing customer account → customer home unchanged. Owner account → owner shell + shop-onboarding redirect logic unchanged.

---

## After This Session

```
Smoke test passed?
→ Update dukkan-status, mark D1 in the roadmap, commit + push
→ Clear session, then open FILE_02_SHOP_LINK.md and continue
```
