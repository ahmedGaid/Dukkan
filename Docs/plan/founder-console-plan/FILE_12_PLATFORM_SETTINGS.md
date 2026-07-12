# SESSION 12 — Platform Settings: config editor, feature flags, maintenance + version gates
# Files: lib/domain/config/** (extend), lib/data/config/** (extend), firestore.rules,
#        lib/presentation/console/settings/** (new), lib/presentation/splash/splash_page.dart,
#        lib/core/config/app_config.dart, lib/dev/seed_demo_data.dart,
#        lib/core/di/injector.dart, lib/l10n/app_ar.arb + app_en.arb

---

## Before You Start

1. Open `lib/domain/config/entities/platform_config.dart` + repo impl — M12 fields
   (commissionBps, deliveryFeeMinor, driverDeliveryShareMinor) + the per-session memo.
2. Open `lib/presentation/splash/splash_page.dart` — the boot path where the gates hook in.
3. Open `lib/core/config/app_config.dart` — `version` const doc comment (hand-synced).
4. Open `firestore.rules` `/config` block (`write: false`).

Do not write anything yet.

---

## Task A — Config fields + repository refresh

`PlatformConfig` additive fields (all optional-with-default so the live doc parses):
`minOrderMinor` (0), `vatBps` (0 — display/reporting only for COD v1, comment it),
`supportPhone` (''), `supportWhatsApp` (''), `businessHoursNote` (''),
`maintenanceMode` (false), `minSupportedBuild` (0), `flagsVersion` (0).

`PlatformConfigRepository`: add `Future<PlatformConfig> refresh()` (clears memo, refetches)
— console save calls it; app sessions still memoize.

New `/config/flags` doc: `{flags: {key: bool}}` — `FeatureFlags` entity +
`FlagsRepository` (same one-shot + refresh contract). Consumer helper
`bool flag(String key, {bool orElse = false})`.

`AppConfig`: add `static const int buildNumber` (sync with pubspec `version: x.y.z+N` —
same hand-sync note as `version`).

## Task B — Rules

```
    match /config/{docId} {
      allow read: if isSignedIn();
      allow update: if hasPerm('settings.edit');
      allow create, delete: if false;   // docs are seeded once, never removed
    }
```

Seed: `_seedConfig()` gains the new fields + creates `/config/flags` (empty map).

## Task C — Console settings page

`/console/settings` (section perm settings.edit), grouped form:
- **العمولة والتوصيل**: commissionBps (shown as % with one decimal, stored bps),
  deliveryFeeMinor / driverDeliveryShareMinor / minOrderMinor (money fields — display
  EGP at the edge via `core/money.dart`, store piasters; validate driverShare ≤ deliveryFee),
  vatBps.
- **التواصل**: supportPhone, supportWhatsApp, businessHoursNote.
- **التطبيق**: maintenanceMode switch (red-tinted tile + confirm dialog spelling out the
  effect), minSupportedBuild int field (confirm dialog too — can lock users out).
- **Feature flags** card: list of key+switch rows, add-flag field, delete flag.
- Save per group (not one giant submit); each save = patch + `refresh()` +
  `reportAudit` with before/after (`settings.update`, `flags.update`) — append to
  `audit_actions.dart`. Show "آخر تعديل" from the newest matching audit entry.

## Task D — App gates (splash)

In the boot sequence after auth resolves, fetch config (already fetched for checkout —
reuse; **fail-open**: any fetch error skips both gates, never lock users out on a network
blip):
- `maintenanceMode && !(adminProfile?.isActive ?? false)` → designed full-screen
  maintenance state (Dukkan mark, «نرجع لكم حالًا», support phone) — blocks the app.
- `buildNumber < minSupportedBuild` → designed "حدّث التطبيق" screen (Play link as
  selectable text — no url_launcher).
Order: maintenance first, then version. Staff bypass maintenance (they fix things
DURING maintenance).

i18n both ARBs. Lexicon rows: Maintenance mode → وضع الصيانة · Feature flag → خاصية تجريبية.

---

## Smoke Test

- [ ] Gates green (analyze 0, test, parity).
- [ ] Entity test: live-shaped config doc (only 3 M12 fields) parses with defaults.
- [ ] Edit commission 5% → 6% in console → audit entry with before/after; a NEW order
      snapshots 600 bps (place one); old orders untouched.
- [ ] maintenanceMode on → customer app shows maintenance screen; founder passes; off
      restores (needs app restart or pull-to-refresh — note observed behavior honestly).
- [ ] minSupportedBuild > current build → update screen; reset → normal.
- [ ] Non-settings.edit staff: section hidden; direct `/config` write rules-denied.

---

## After This Session

```
Smoke test passed?
→ Update dukkan-status, commit, push
→ Fresh session → FILE_13_NOTIFICATION_CENTER.md
User action: deploy rules; re-run config seed once (founder-signed-in write now legal).
```
