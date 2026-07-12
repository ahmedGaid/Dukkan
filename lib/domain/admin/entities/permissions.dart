/// Single source of truth for permission names. Dotted strings, grouped by
/// area. `all` ('*') is the founder wildcard — checked by [AdminProfile.can]
/// and by the `hasPerm` helper in firestore.rules; keep the three in sync.
class Permissions {
  const Permissions._();

  static const all = '*';

  static const usersRead = 'users.read';
  static const usersCreate = 'users.create';
  static const usersUpdate = 'users.update';
  static const usersDelete = 'users.delete';
  static const adminsManage = 'admins.manage';

  static const shopsUpdate = 'shops.update';
  static const shopsTransfer = 'shops.transfer';
  static const productsCreate = 'products.create';
  static const productsUpdate = 'products.update';
  static const productsDelete = 'products.delete';

  static const ordersRead = 'orders.read';
  static const ordersUpdate = 'orders.update';
  static const ordersForceStatus = 'orders.forceStatus';
  static const ordersAssignDriver = 'orders.assignDriver';

  static const driversManage = 'drivers.manage';
  static const taxonomyEdit = 'taxonomy.edit';
  static const geoEdit = 'geo.edit';
  static const financeRead = 'finance.read';
  static const settingsEdit = 'settings.edit';
  static const notificationsSend = 'notifications.send';
  static const promosEdit = 'promos.edit';
  static const reportsExport = 'reports.export';
  static const imagesDelete = 'images.delete';
  static const auditlogsRead = 'auditlogs.read';
  static const systemTools = 'system.tools';
  static const systemImpersonate = 'system.impersonate';
}
