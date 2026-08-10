# Offline order-status-advance queue — design (Phase 8 / O2, part 1)

> Brainstormed 2026-08-11. This is a **scope slice** of the full O2 initiative
> (`Docs/plan/dukkan-roadmap.md` Phase 8) — order status advances only. Order
> placement, driver assignment, catalog edits, console mutations are explicitly
> OUT of this slice; each needs its own design pass if/when queued later.

## Scope (locked)

Queue exactly these 4 status transitions, offline-capable:
- `pending → accepted` (owner)
- `accepted → preparing` (owner)
- `preparing → outForDelivery` (courier)
- `outForDelivery → delivered` (courier)

Explicitly OUT of scope for this slice (deferred, own design needed):
- **Driver assignment** (owner picks a courier for an accepted order) — a property
  write, not a status transition, with a real multi-actor race (two owners/couriers
  grabbing the same unassigned order while both offline). Stays online-only.
- Order placement, cart/profile edits, catalog edits, console/admin force-actions —
  untouched by this slice; console mutations stay live-only by design (per O1).

## Why a shared core service, not a repository-level fix

Three live screens watch the same order's status independently: owner's order
desk, courier's active-orders list, customer's order-tracking page. All three
must show the identical "pending sync" overlay and the identical revert-on-reject
behavior when a queued write is later rejected. Building the overlay/replay logic
once in a shared core service avoids three copies of the same correctness-sensitive
merge logic, and matches the roadmap's framing of O2 as a mechanism meant to extend
to other mutation types later — not a one-off fix wedged into `OrderRepositoryImpl`.

## Components

- **`PendingMutation`** (entity, `lib/core/offline/`): `id, orderId, targetStatus,
  actorRole, actorUid, enqueuedAt`.
- **`OfflineMutationQueue`** (core service, singleton via `sl`): in-memory
  `List<PendingMutation>`, persisted as a JSON array via `shared_preferences`
  (existing dependency — no new dependency needed) so it survives app kill.
  Exposes:
  - `Future<void> enqueue(PendingMutation)`
  - `Stream<List<PendingMutation>> watchAll()`
  - `List<PendingMutation> pendingForOrder(String orderId)` (sync lookup for
    overlay use)
  - internal replay loop (see below)
- **Replay trigger.** `NetworkInfo` today is a one-shot `Future<bool>` HTTP probe
  (no stream — Shoppy lesson: socket-based connectivity streams are unreliable on
  Android). Three triggers feed the same replay function, no new dependency:
  1. `Timer.periodic(~15s)`, running only while the queue is non-empty (cancelled
     when it drains).
  2. One immediate replay attempt right after `enqueue()` (covers "just got a bar
     of signal back" cases without waiting for the timer).
  3. `WidgetsBindingObserver.didChangeAppLifecycleState` → `resumed` triggers one
     attempt (covers a courier re-foregrounding the app after a signal gap).
- **`OrderRepositoryImpl.updateOrderStatus`** (existing file, currently has "no
  offline branch" by design comment — that comment is amended for this one method
  only, all other methods on this repo stay online-only):
  ```
  if (await networkInfo.isConnected) {
    return remote.updateOrderStatus(orderId, status);
  }
  await queue.enqueue(PendingMutation(...));
  ```
- **Overlay helper.** BLoCs that render order status (`OrderDeskBloc`/
  equivalent owner board, courier active-list bloc, customer order-tracking
  bloc) combine the repository's real-time stream (`watchOrder` /
  `watchShopOrders` / `watchDriverActiveOrders`) with
  `queue.watchAll()` filtered to that order: if a pending mutation exists for
  the order, render its `targetStatus` + a pending-sync chip instead of the
  remote value.

## Replay + error handling

Per queued item, on each trigger: attempt the real write via
`OrderRemoteDataSource.updateOrderStatus`. Three outcomes:

1. **Success** → remove from queue. Remote stream now reflects the new status;
   overlay naturally stops overriding (nothing pending left for that order).
2. **Still offline** (network-shaped exception — timeout/unavailable) → leave
   queued, retry on the next trigger, no user-facing error. Silent.
3. **Real rejection** (`permission-denied` / Firestore rules reject — someone
   else already advanced or cancelled the order while this device was offline;
   the order state machine already guards illegal jumps server-side, verified
   live in FILE_18's 30/30 state-machine probe) → remove from queue, overlay
   reverts to the real remote status, emit a one-shot event on a
   `Stream<SyncFailure>` that the relevant screen listens to and renders as a
   dismissible banner: "couldn't sync: `<order>` — `<reason>`". The rest of the
   queue keeps replaying — one bad conflict does not freeze other pending items.

Distinguishing outcome 2 from outcome 3 requires catching `FirebaseException`
by `.code`: `unavailable`/`deadline-exceeded`/etc. → treat as still-offline;
`permission-denied`/anything else → treat as a real rejection.

Queue order: **FIFO across the whole queue**, not per-order. Expected volume is
a handful of items between signal gaps (an owner or courier doesn't advance
dozens of orders per outage), so strict global FIFO is simpler than per-order
sequencing and good enough at this volume.

## UI (scope note, not detailed here — `dukkan-brand` territory)

A pending-sync chip on the affected order row (owner desk, courier active
list, customer tracking) and the dismissible conflict banner described above.
Exact visual treatment (icon, chip copy, banner placement) is a `dukkan-brand`
decision for the implementation session, not fixed by this design doc.

## Testing

- Unit tests for `OfflineMutationQueue`: enqueue persists across a fresh
  instance (simulates app kill), replay removes on success, replay leaves item
  queued on network-shaped failure, replay removes + fires `SyncFailure` on
  rejection. Mirrors the existing local-datasource `_ready`-guard test pattern
  already used elsewhere in the codebase.
- New i18n keys (pending-chip label, sync-failed banner text) added to both
  `lib/l10n/app_ar.arb` and `app_en.arb` — parity script must stay green.
- Gates before "done": `flutter analyze` (0), `flutter test` (all green),
  `dart run scripts/check_i18n_parity.dart` (green).

## Open questions for the implementation plan (not blocking this design)

- Exact FirebaseException `.code` set to treat as "still offline" vs "real
  rejection" — needs confirming against what `firestore.rules` actually throws
  for each of the 4 guarded transitions (should match FILE_18's live probe
  findings, not require a new live pass).
- Where exactly the pending-sync chip renders on each of the 3 screens (owner
  desk row, courier active-list row, customer tracking timeline) — a UI detail
  for the implementation session with `dukkan-brand`.
