# Dukkan E2E Report — 2026-07-11 (partial — device disconnected mid-run)

**Summary:** 3 passed · 1 fix landed but UNVERIFIED · 1 finding (broken test evidence) · rest NOT RUN (no device)
**Verdict:** RED — resume required. Gates green, backend healthy, but Phase 2+ journeys never ran; the one fix claimed done has no valid on-device proof.

## What actually happened today

A prior session (this repo, same branch) started R0 live on device `R5CNC0NK6ZT`/`SM G998U`, got partway through Phase 0/1 + J1 (signup), found and fixed a bug, then lost the device connection (`flutter_run.log` ends mid-session with "Lost connection to device," no formal report was written, and `dukkan-roadmap.md`/`dukkan-status` were never updated). This session: device not connected at all (`adb devices` empty) — did everything possible without it, then wrote up what the evidence actually shows.

## Results by journey

| Journey | Result | Notes |
|---|---|---|
| Phase 0 boot | PASS | App launched on `SM G998U`, Firestore `(default)` confirmed live (europe-west3, FIRESTORE_NATIVE) via `firebase-tools firestore:databases:list`. Benign `GoogleApiManager` GMS noise in log, not app-caused. |
| S1 wrong-password error | PASS | `04_wrong_password.png` — Arabic blame-free error "البريد أو كلمة السر مش مظبوطين", no raw exception text, keyboard state clean. |
| J1 signup (initial) | **BUG FOUND** | `15_j1_profile.png` (11:34) — after signup, Settings shows email as display name instead of entered name (`e2e-cust-20260711@...` instead of the typed name). Root-caused as an auth-stream race (profile loads before `/users` doc write completes) — fixed in `ef32ae4` "wait for /users doc when auth stream races signup". |
| J1 signup (fix re-check, account "b") | STILL SHOWING BUG | `21_j1_fixed_profile.png` (11:49) — same fallback-to-email behavior, taken around/before the fix commit landed. Not proof the fix works. |
| J1 signup (fix re-check, account "c") | **UNVERIFIED — broken evidence** | `27_signup3_result.png` and `28_signup3_settings_immediate.png` (both 12:16) are byte-identical: the empty signup form with a "password required" validation error, not a settings screen. Whatever the session intended to capture, it didn't — no actual evidence the fix works. Commit `002aa79`'s message overclaims what the attached screenshots show. |
| S2–S5, J2–J12, Phase 3 | NOT RUN | Session lost device connection before reaching these. |

## Findings

1. **Auth-race fix unverified** (`ef32ae4`). Code change looks correct on read (waits for `/users` doc before reading profile), but needs an actual on-device signup → immediate Settings-tab screenshot to close out. Do this first when the device is back.
2. **Test-evidence hygiene**: two "before/after" screenshots in `002aa79` are duplicate frames — likely `adb exec-out screencap` fired before the app finished navigating (no wait between "submit signup" and "capture"). Add a short settle/wait (or wait for a specific widget) before each screenshot in future E2E runs so this doesn't recur. Not a product bug — a test-script bug.

## Skipped — needs human

- Device `R5CNC0NK6ZT` not connected this session — plug in + unlock to resume Phase 1 (S2–S5) through Phase 3.
- Worker (`worker/`) deploy status not re-checked — J6/J7 image-upload and J10 push steps will be `SKIPPED-NEEDS-HUMAN` again unless it's been deployed since the last status update.

## Non-device work done this session

- `flutter analyze`: 0 issues.
- `flutter test`: 56/56 passed.
- `dart run scripts/check_i18n_parity.dart`: 196 keys OK.
- Firestore `(default)` confirmed live via `firebase-tools` CLI.
- Local branch `feat/c2c-search` was 5 commits ahead / 1 behind `origin` (remote had `dc4f1a8`, seed placeholder images, pushed from the other worktree per `dukkan-status`). Rebased local `e72736c..002aa79` cleanly onto `dc4f1a8`. Re-ran analyze after rebase — still clean.

## Environment

Commit tested: `002aa79` (rebased onto `dc4f1a8`) → new tip after rebase, see `git log -1`.
Device: `R5CNC0NK6ZT` (`SM G998U`) — connected in the prior partial session, disconnected for this one.
Debug build only; release re-verify (Phase 6) not reached.
