/// Canonical upload folders. These strings must stay in sync with the Worker's
/// allow-list (`ALLOWED_FOLDERS` in `worker/src/index.js`) — the Worker rejects
/// anything else.
class StorageFolder {
  const StorageFolder._();

  static const String shopLogos = 'shop-logos';
  static const String productImages = 'product-images';
  static const String driverDocs = 'driver-docs';
}
