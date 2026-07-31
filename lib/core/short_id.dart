/// Short, human-readable form of a Firestore document id, for list rows and
/// card headers where the full id is noise.
///
/// Takes the **tail**, not the head. Seeded and Worker-created ids are
/// prefixed (`order_demo_0_1`, `order_demo_1_2`), so the first characters are
/// identical across every document — a head-truncating short id renders every
/// row as the same string (`#order_de`), which is what shipped on the console
/// orders board and the driver detail page until 2026-07-31. Firestore's own
/// auto-ids are random throughout, so a tail is equally good for them.
String shortId(String id, {int length = 6}) {
  if (length <= 0) return '';
  return id.length <= length ? id : id.substring(id.length - length);
}
