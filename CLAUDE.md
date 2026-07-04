# Dukkan — working agreement

**Dukkan (دكان)** — two-sided grocery marketplace for Egypt. Flutter + Firebase, Clean
Architecture + BLoC, **Arabic/RTL-first**. One app, two roles (customer / shop owner).
Brand feel: **your neighborhood shop, in your pocket** — friendly, warm, trustworthy.

This file is deliberately short. The real rules live in **skills** — recall them; don't reinvent.

## Recall the right skill BEFORE you act
- **Any UI / design / styling / copy / Arabic term / "is this on-brand"** → **`dukkan-brand`**.
- **Building/editing Flutter code** → **`dukkan-flutter`** (architecture, BLoC patterns,
  Shoppy lessons, gates).
- **Resuming / status / "where are we"** → **`dukkan-resume`** (reads `dukkan-status` first).
- Task touches UI **and** code → recall both `dukkan-brand` and `dukkan-flutter`.

## Source-of-truth map
- What next / phases / locked decisions → `Docs/plan/dukkan-roadmap.md` — read BEFORE picking a task
- Live status / NEXT ACTION / blockers → **`dukkan-status`** skill
- Brand: colors, type, voice, Arabic lexicon → `Docs/Brand/BRAND.md`
- Architecture ancestor + fixed-bugs list → `Docs/legacy/SHOPPY_PROJECT_KNOWLEDGE.md` (reference only)
- UI/UX reference screenshots (Ben Soliman) → `Docs/ui-ref/`

## Hard rules — the safety net
- **Tokens only.** Raw hex lives ONLY in `AppColors`; everywhere else `AppColors.*` / theme helpers.
- **RTL-first.** Directional widgets/`EdgeInsetsDirectional`, `start/end` — never `left/right`.
- **i18n ar/en parity is build-blocking.** Every user-facing string is a key in BOTH ARB files.
- **Money = integer piasters** on the wire and in Firestore (`priceMinor`, `totalMinor`).
  Format/parse only at the edge. Never `double` for money.
- **One Arabic word per concept** — lexicon in `Docs/Brand/BRAND.md`; add there before shipping.
- **Designed states.** Every empty/error/loading state designed; never bare "No data"/blank.
- **Clean Architecture boundaries.** No business logic in widgets; BLoC → use case → repository;
  `domain/` never imports `data/`.
- **No new dependencies** without asking.
- **Firebase is real from day 1** — no mock auth, no commented wiring (Shoppy lesson).

## Before you say "done"
`flutter analyze` (0 issues) · `flutter test` · i18n parity script (once it exists in `scripts/`).
Green gates + brand-feel check (`dukkan-brand` checklist) = actually done.

## Session protocol (token economy — same as Conductor)
One session = one roadmap session-block. When done: update **`dukkan-status`** skill →
commit + push → report with **How to test** → tell the user to clear and start a fresh session.
Blocked? Write blocker into `dukkan-status`, stop, ask.
