# Security probes — the Founder Console deny matrix, as runnable scripts

These three PowerShell scripts drive Dukkan's **deployed** security rules and the Worker's auth
gate directly, and print a PASS/FAIL table. They exist because FILE_18's security matrix
(`Docs/plan/founder-console-plan/FILE_18_ACCEPTANCE.md`, Task B) was otherwise a manual checklist —
this way it is repeatable, and a rules edit that quietly opens a hole shows up in one command.

Firestore's REST API enforces the same rules as the SDK when called with a Firebase ID token, so
none of this needs the app, a device, or a seeded database. Each script signs up its own throwaway
accounts, runs its rows, then deletes those accounts.

```powershell
# 1. Customer deny matrix — 18 rows. Every collection a customer must not touch.
.\scripts\probes\probe_security_matrix.ps1

# 2. Order state machine + cross-role denials — 30 rows. The full
#    pending -> accepted -> preparing -> outForDelivery -> delivered chain
#    (incl. the commission flip and the single rating), and every illegal move.
.\scripts\probes\probe_order_state_machine.ps1

# 3. Worker auth gate — 9 rows. Needs a LOCAL worker first (no Cloudflare login):
cd worker; npm install; npx wrangler dev --port 8787    # leave running
.\scripts\probes\probe_worker_auth.ps1
```

Expected result today: **18/18, 30/30, 9/9, zero failures.** A FAIL is either a real regression in
`firestore.rules` / `worker/src/admin.js`, or a rule change whose intent nobody told the probe
about — read the row name before "fixing" anything.

## Rows that are *meant* to be allowed

Three loosenesses are deliberate, documented in the rules, and asserted as `allowed` here so nobody
"fixes" them by accident: any signed-in user may bump a coupon's `usedCount` by +1 (checkout
redemption), move a driver's `activeOrdersCount` by ±1 (assignment counting), and add one 1-5 star
rating to a shop. A customer may also cancel their *own* pending order, and — the one open finding —
may write their own `status` / `deleted` mirror fields (not an escalation path: the Worker's suspend
and soft-delete both disable the Firebase Auth account and revoke live sessions).

## Cleanup

The scripts remove their own Auth accounts, but Firestore rules forbid clients from deleting
`/shops`, `/orders` and `/drivers` docs, so those stay behind. Everything they create is stamped
`fake: true` — the console's devtools cleanup (`/console/devtools`) sweeps the `/users` and
`/orders` ones, since those are the two collections that endpoint covers. **The probe's `/shops` and
`/drivers` docs still need deleting by hand in the Firebase console.** Until then they are harmless:
the probe shop is `isActive: false` + `status: 'suspended'` and labelled
"TEST - rules probe (safe to delete)", and the probe driver doc is created suspended, so it can
never be assigned an order.

`probe_order_state_machine.ps1` uses a **fresh random id per run for the shop and both orders**.
That is required, not tidiness: its accounts are new each run, so a reused shop id belongs to the
previous run's owner and every owner-path row 403s; an order can only move forward once; and a
reused shop's `ratingCount` no longer matches the +1 the rating rule demands. Two consecutive clean
runs confirm it is idempotent.

## What these do NOT cover

The staff rows — support / admin / founder break-glass — need an `/admins` doc, which only the seed
can create, and the Worker's **403** rows need the deployed Worker with its
`FIREBASE_SERVICE_ACCOUNT` secret (locally that path 500s, since the secret is absent). Once the
seed has run, point script 1 at a support-staff and an admin-staff ID token to clear those rows the
same headless way. The client half of the staff matrix is already a gate:
`test/console_role_gating_test.dart`.
