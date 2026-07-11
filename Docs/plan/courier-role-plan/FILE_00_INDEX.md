# Courier Role Plan — Master Index

> **SUPERSEDED 2026-07-11** by `Docs/plan/marketplace-v2-plan/` (Sessions 08–11).
> Decision: shared platform driver pool replaces shop-owned couriers. Do not execute.

> **Load this file first in every session.** Then open the one session file you are executing.
> Feature: add a third user role — **courier / مندوب التوصيل** — to Dukkan, alongside
> customer (عميل) and shop owner (صاحب دكان).

## Project Goal

Today Dukkan has two roles chosen at signup: customer and shop owner. V1 ops said "each shop
delivers itself" — the owner taps `outForDelivery → delivered` manually. This plan adds a real
**courier** role: a courier signs up, joins one or more shops with an invite code, gets orders
assigned by the shop owner, sees an assigned-deliveries screen, and advances the last leg of the
status flow (`outForDelivery → delivered`) himself. Owner self-delivery keeps working unchanged
when no courier is assigned.

**Canonical Arabic term (add to brand lexicon): مندوب التوصيل — short form مندوب.**
Never mix with "ديليفري" or "طيار" in UI copy. English: **Courier**.

## Design decisions (locked for this plan)

| Decision | Choice |
|---|---|
| Enum / wire value | `UserRole.courier`, wire string `'courier'` |
| How courier ↔ shop link | Courier enters shop invite code (= the shop's Firestore doc id, shared by owner). Membership doc at `/shops/{shopId}/couriers/{courierUid}` — subcollection, not an array, because security rules stay one-line simple |
| Assignment | Owner assigns a linked courier to an order (`courierUid` field on the order) while status is `accepted` or `preparing` |
| Courier permissions | Read orders where `courierUid == uid`; advance `preparing → outForDelivery` and `outForDelivery → delivered`. Nothing else |
| Owner fallback | All existing owner transitions stay valid — shop with no couriers works exactly as today |
| Courier home | Own shell: active deliveries list (realtime) + history, order detail with address/phone/call, one primary action button |
| Push | Extend existing Worker `/notify` pattern (P2b): assignment → courier device |

## Affected files (exhaustive)

- `lib/domain/auth/entities/user_role.dart` — add `courier`
- `lib/presentation/auth/pages/signup_page.dart` — third role card
- `lib/presentation/settings/pages/settings_page.dart` — role label
- `lib/presentation/home/pages/home_page.dart` — route courier to courier shell
- `lib/core/router/app_router.dart` — courier redirect (no shop-onboarding)
- `lib/l10n/app_ar.arb` + `lib/l10n/app_en.arb` — all new keys (parity build-blocking)
- `firestore.rules` — users role list, couriers subcollection, order assignment + courier transitions
- `lib/domain/shop/…` + `lib/data/shop/…` — courier membership entity/model/datasource/repo/usecases
- `lib/domain/order/entities/order.dart` + `lib/data/order/…` — `courierUid` field, assign usecase
- `lib/presentation/orderdesk/…` (S3 order desk) — assign-courier action
- `lib/presentation/courier/…` — NEW: courier shell, deliveries bloc, detail page, join-shop page
- `lib/presentation/shop/…` or owner shell — owner couriers management page (list, invite code, remove)
- `lib/core/di/injector.dart` — new registrations
- `worker/` `/notify` call sites — assignment push
- `test/…` — new unit/bloc tests per session
- `Docs/testing/E2E_MASTER_PROMPT.md` — courier journey added at the end

## Never touch

- `lib/firebase_options.dart`, `android/`, `ios/`, `pubspec.yaml` (**no new dependencies**)
- Money handling (`totalMinor` stays integer piasters)
- Existing customer browse/cart/checkout flows
- `run_dukkan.vbs`, `Dukkan Logo Assets/`

## Session Map

| # | File | What gets built | Est. |
|---|------|-----------------|------|
| 01 | `FILE_01_ROLE_FOUNDATION.md` | `UserRole.courier` end-to-end: enum, model, signup card, router, placeholder shell, settings label, users rules, i18n | 25 min |
| 02 | `FILE_02_SHOP_LINK.md` | Courier↔shop membership: subcollection, join-by-code (courier), couriers page + invite code (owner), rules | 30 min |
| 03 | `FILE_03_ORDER_ASSIGNMENT.md` | `courierUid` on orders, owner assign action in order desk, order rules for courier | 30 min |
| 04 | `FILE_04_COURIER_SHELL.md` | Real courier home: deliveries list (realtime), detail, mark out-for-delivery/delivered, designed states | 30 min |
| 05 | `FILE_05_NOTIFICATIONS.md` | Assignment push via Worker `/notify`, dark-mode + states audit, E2E prompt journeys | 20 min |
| 06 | `FILE_06_ACCEPTANCE.md` | Full acceptance + regression + sign-off | 25 min |

Dependency order is strict: 01 → 02 → 03 → 04 → 05 → 06.

## Ground Rules (every session)

1. **Read before write.** Every session starts with its "Before You Start" reads. Never assume file shape.
2. **Additive only.** Existing customer/owner behavior must not change; owner-with-no-courier is the regression baseline.
3. **Gates before "done":** `flutter analyze` (0 issues) · `flutter test` (all green) · `dart run scripts/check_i18n_parity.dart`. After editing `.arb` files run `flutter gen-l10n` first.
4. **Brand:** recall `dukkan-brand` + `dukkan-flutter` skills at session start. One Arabic word per concept (مندوب التوصيل). Every empty/error/loading state designed. No new deps, no raw hex, reuse existing primitives (AppCard, EmptyState, StatusChip, AppButton…).
5. **Rules parity:** every Firestore behavior change lands in `firestore.rules` in the same session, and gets deployed (`firebase deploy --only firestore:rules` is user-side if CLI login blocked — note it in the report).
6. **One session file per session.** Finish → smoke test → update `dukkan-status` → commit + push → fresh session.

## How to use this plan

1. Fresh Claude Code session → `/dukkan-resume` → open `FILE_00_INDEX.md` (this file).
2. Open the next unchecked session file. Execute it exactly.
3. Run the smoke test checklist on device `R5CNC0NK6ZT`.
4. Update `dukkan-status`, mark the block in `Docs/plan/dukkan-roadmap.md` (Phase 5), commit, push.
5. Clear session. Repeat until FILE_06 signs off.

## After all sessions complete

- Run the full E2E master prompt (`Docs/testing/E2E_MASTER_PROMPT.md`) including the new courier journey.
- Update `dukkan-status` + roadmap Phase 5 all `[x]`.
- Add مندوب التوصيل to `Docs/Brand/BRAND.md` lexicon if not done in session 01.

*Generated by ag-plan skill. Do not edit this index manually.*
