# SESSION 11 — Assignment Push + Delivery Regression Pass
# Files: lib/ notifications feature (existing /notify caller), worker/src/index.js (new notify type ONLY), arb files

---

## Before You Start

1. Open the existing notifications feature (`lib/domain/notifications` or search for `/notify`) — read how order push types are requested today (customer↔owner).
2. Open `worker/src/index.js` `/notify` handler — read how it verifies the caller is a party to the order and resolves the recipient's FCM token.
3. Confirm Worker deploy status with the user — if not deployed (dukkan-status blocker 2), build + verify request-side code, mark live-push verification deferred.

Do not write anything yet.

---

## Task A — `driverAssigned` notify type

Worker: extend the party check so a `driverAssigned` type resolves the order's `driverUid` token as recipient, caller must be the order's shop owner. App: after a successful assignment (Session 9 use case), fire the notify call. Copy: ar title `طلب جديد لتوصيله`, body = shop name + area; en parallel.

Optional second type if trivial in the same pattern: `orderDelivered` → owner notified when courier completes. Skip if the handler needs restructuring — not worth it this session.

## Task B — Courier as order party

Verify the existing notify types (status updates to customer) still authorize correctly now that a third uid sits on order docs — the Worker's party check must treat `driverUid` as a valid party where relevant, and must NOT let a courier trigger customer-facing types that don't concern them.

## Task C — Delivery regression pass (the fallback promise)

Walk the full matrix on device once, fixing anything broken before calling (D) done:

1. No-driver order: owner runs pending→…→delivered solo (v1 behavior intact).
2. Driver order: assign at accepted, courier picks up + delivers.
3. Driver order cancelled by owner (reject at accepted) after assignment → driver count decrements, order leaves courier's list.
4. Customer cancels pending order → untouched by driver logic.

---

## Smoke Test

- [ ] Assignment on device fires push to the courier device/emulator (if Worker deployed; else unit-test the request payload and log the deferral in dukkan-status).
- [ ] Courier cannot trigger arbitrary notify types (Worker rejects).
- [ ] Regression matrix items 1–4 all pass.
- [ ] Gates green.

---

## After This Session

```
Smoke test passed?
→ update dukkan-status (plan D complete) → commit
→ /compact → open FILE_12_COMMISSION_LEDGER.md
```
