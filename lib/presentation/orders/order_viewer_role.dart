/// Which role is looking at `OrderDetailPage` — gates the owner-only and
/// courier-only blocks and drives the bloc's side lookups (the customer's
/// `/users` profile for owner+courier, the delivery area's name for courier).
/// `staff` is the Founder Console board view (FC10) — sees every existing
/// block plus the internal-notes card and the staff action bar; the router
/// only grants it when the signed-in account has `orders.read`, else it
/// falls back to `customer`.
enum OrderViewerRole { customer, owner, courier, staff }
