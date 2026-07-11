/// Which role is looking at `OrderDetailPage` — gates the owner-only and
/// courier-only blocks and drives the bloc's side lookups (the customer's
/// `/users` profile for owner+courier, the delivery area's name for courier).
enum OrderViewerRole { customer, owner, courier }
