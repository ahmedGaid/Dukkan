/// Known audit `action` codes and `targetType` values, used to populate the
/// console filter dropdowns. NOT an allow-list — the trail may contain any
/// string the Worker wrote; these are just the convenient presets. Later
/// Founder Console sessions (06–17) append their own ops here as they ship.
///
/// Codes are shown verbatim (they are the honest, language-neutral record of
/// what happened); only the surrounding chrome is localized.
class AuditActions {
  const AuditActions._();

  /// Dotted operation codes, grouped by area in the order sessions land them.
  static const knownActions = <String>[
    // Users + staff (session 06)
    'user.disable',
    'user.enable',
    'user.setRole',
    'user.changeEmail',
    'user.softDelete',
    'user.restore',
    'user.create',
    'admin.set',
    'admin.remove',
    // Shops (session 07)
    'shop.status',
    'shop.transfer',
    'shop.feature',
    'shop.verify',
    'shop.edit',
    // Products (session 08)
    'product.edit',
    'product.softDelete',
    'product.restore',
    // Orders (session 10)
    'order.forceStatus',
    'order.reassign',
    'order.note',
    // Drivers (session 11)
    'driver.activate',
    'driver.suspend',
    'driver.edit',
    // Taxonomy / geo / settings (sessions 09, 12)
    'taxonomy.edit',
    'geo.edit',
    'settings.update',
    'flags.update',
    // Notifications / media (sessions 13, 14)
    'notification.broadcast',
    'media.delete',
    // Impersonation (session 15)
    'impersonation.start',
    'impersonation.stop',
  ];

  /// The kinds of thing an action targets.
  static const knownTargetTypes = <String>[
    'user',
    'shop',
    'product',
    'order',
    'driver',
    'config',
    'taxonomy',
    'area',
    'media',
    'notification',
    'admin',
  ];
}
