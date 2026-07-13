import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/admin/datasources/admin_api_datasource.dart';
import '../../data/admin/datasources/admin_remote_datasource.dart';
import '../../data/admin/datasources/admin_shops_remote_datasource.dart';
import '../../data/admin/datasources/admin_users_remote_datasource.dart';
import '../../data/admin/repositories/admin_repository_impl.dart';
import '../../data/admin/repositories/admin_shops_repository_impl.dart';
import '../../data/admin/repositories/admin_user_actions_impl.dart';
import '../../data/admin/repositories/admin_users_repository_impl.dart';
import '../../data/areas/datasources/areas_local_datasource.dart';
import '../../data/areas/datasources/areas_remote_datasource.dart';
import '../../data/areas/repositories/areas_repository_impl.dart';
import '../../data/audit/datasources/audit_remote_datasource.dart';
import '../../data/audit/repositories/audit_repository_impl.dart';
import '../../data/dashboard/datasources/dashboard_remote_datasource.dart';
import '../../data/dashboard/repositories/dashboard_repository_impl.dart';
import '../../data/auth/datasources/auth_remote_datasource.dart';
import '../../data/auth/repositories/auth_repository_impl.dart';
import '../../data/collections/datasources/collections_remote_datasource.dart';
import '../../data/collections/repositories/collections_repository_impl.dart';
import '../../data/config/datasources/platform_config_remote_datasource.dart';
import '../../data/config/repositories/platform_config_repository_impl.dart';
import '../../data/driver/datasources/driver_remote_datasource.dart';
import '../../data/driver/repositories/driver_repository_impl.dart';
import '../../data/favorites/datasources/favorites_remote_datasource.dart';
import '../../data/favorites/repositories/favorites_repository_impl.dart';
import '../../data/finance/datasources/finance_remote_datasource.dart';
import '../../data/finance/repositories/finance_repository_impl.dart';
import '../../data/notifications/datasources/notification_remote_datasource.dart';
import '../../data/notifications/repositories/notification_repository_impl.dart';
import '../../data/order/datasources/order_remote_datasource.dart';
import '../../data/order/repositories/order_repository_impl.dart';
import '../../data/product/datasources/product_local_datasource.dart';
import '../../data/product/datasources/product_remote_datasource.dart';
import '../../data/product/repositories/product_repository_impl.dart';
import '../../data/shop/datasources/shop_local_datasource.dart';
import '../../data/shop/datasources/shop_remote_datasource.dart';
import '../../data/shop/repositories/shop_repository_impl.dart';
import '../../data/storage/datasources/image_upload_remote_datasource.dart';
import '../../data/storage/repositories/storage_repository_impl.dart';
import '../../data/taxonomy/datasources/taxonomy_local_datasource.dart';
import '../../data/taxonomy/datasources/taxonomy_remote_datasource.dart';
import '../../data/taxonomy/repositories/taxonomy_repository_impl.dart';
import '../../domain/admin/repositories/admin_repository.dart';
import '../../domain/admin/repositories/admin_shops_repository.dart';
import '../../domain/admin/repositories/admin_user_actions.dart';
import '../../domain/admin/repositories/admin_users_repository.dart';
import '../../domain/admin/usecases/change_user_email.dart';
import '../../domain/admin/usecases/create_shop_as_staff.dart';
import '../../domain/admin/usecases/create_user.dart';
import '../../domain/admin/usecases/get_admin_profile.dart';
import '../../domain/admin/usecases/get_all_shops.dart';
import '../../domain/admin/usecases/get_shop_by_id.dart';
import '../../domain/admin/usecases/get_staff_profile_for_uid.dart';
import '../../domain/admin/usecases/get_user_by_email.dart';
import '../../domain/admin/usecases/get_user_by_phone.dart';
import '../../domain/admin/usecases/get_users.dart';
import '../../domain/admin/usecases/lookup_user_auth.dart';
import '../../domain/admin/usecases/remove_admin.dart';
import '../../domain/admin/usecases/reset_admin_profile.dart';
import '../../domain/admin/usecases/restore_shop.dart';
import '../../domain/admin/usecases/restore_user.dart';
import '../../domain/admin/usecases/set_admin.dart';
import '../../domain/admin/usecases/set_shop_featured.dart';
import '../../domain/admin/usecases/set_shop_status.dart';
import '../../domain/admin/usecases/set_shop_verified.dart';
import '../../domain/admin/usecases/set_user_disabled.dart';
import '../../domain/admin/usecases/set_user_persona_role.dart';
import '../../domain/admin/usecases/soft_delete_shop.dart';
import '../../domain/admin/usecases/soft_delete_user.dart';
import '../../domain/admin/usecases/transfer_shop_ownership.dart';
import '../../domain/admin/usecases/update_shop_details.dart';
import '../../domain/areas/repositories/areas_repository.dart';
import '../../domain/areas/usecases/get_areas.dart';
import '../../domain/audit/repositories/audit_repository.dart';
import '../../domain/audit/usecases/get_audit_entries.dart';
import '../../domain/dashboard/repositories/dashboard_repository.dart';
import '../../domain/dashboard/usecases/get_dashboard_summary.dart';
import '../../domain/auth/repositories/auth_repository.dart';
import '../../domain/auth/usecases/get_user_by_id.dart';
import '../../domain/auth/usecases/log_in.dart';
import '../../domain/auth/usecases/log_out.dart';
import '../../domain/auth/usecases/send_password_reset.dart';
import '../../domain/auth/usecases/sign_up.dart';
import '../../domain/auth/usecases/watch_auth_state.dart';
import '../../domain/collections/repositories/collections_repository.dart';
import '../../domain/collections/usecases/create_collection.dart';
import '../../domain/collections/usecases/delete_collection.dart';
import '../../domain/collections/usecases/get_collections.dart';
import '../../domain/collections/usecases/rename_collection.dart';
import '../../domain/collections/usecases/watch_collections.dart';
import '../../domain/config/repositories/platform_config_repository.dart';
import '../../domain/config/usecases/get_platform_config.dart';
import '../../domain/driver/repositories/driver_repository.dart';
import '../../domain/driver/usecases/assign_driver.dart';
import '../../domain/driver/usecases/available_drivers.dart';
import '../../domain/driver/usecases/create_driver_profile.dart';
import '../../domain/driver/usecases/get_driver.dart';
import '../../domain/driver/usecases/set_driver_online.dart';
import '../../domain/driver/usecases/watch_driver.dart';
import '../../domain/favorites/repositories/favorites_repository.dart';
import '../../domain/favorites/usecases/toggle_favorite_product.dart';
import '../../domain/favorites/usecases/toggle_favorite_shop.dart';
import '../../domain/favorites/usecases/watch_favorites.dart';
import '../../domain/finance/repositories/finance_repository.dart';
import '../../domain/finance/usecases/get_finance_summary.dart';
import '../../domain/notifications/repositories/notification_repository.dart';
import '../../domain/notifications/usecases/notify_order_event.dart';
import '../../domain/order/repositories/order_repository.dart';
import '../../domain/order/usecases/cancel_order.dart';
import '../../domain/order/usecases/place_order.dart';
import '../../domain/order/usecases/rate_order.dart';
import '../../domain/order/usecases/update_order_status.dart';
import '../../domain/order/usecases/watch_customer_orders.dart';
import '../../domain/order/usecases/watch_driver_active_orders.dart';
import '../../domain/order/usecases/watch_driver_order_history.dart';
import '../../domain/order/usecases/watch_order.dart';
import '../../domain/order/usecases/watch_shop_orders.dart';
import '../../domain/product/repositories/product_repository.dart';
import '../../domain/product/usecases/create_product.dart';
import '../../domain/product/usecases/delete_product.dart';
import '../../domain/product/usecases/get_product.dart';
import '../../domain/product/usecases/update_product.dart';
import '../../domain/product/usecases/watch_all_products.dart';
import '../../domain/product/usecases/watch_products_by_shop.dart';
import '../../domain/shop/entities/shop.dart';
import '../../domain/shop/repositories/shop_repository.dart';
import '../../domain/shop/usecases/create_shop.dart';
import '../../domain/shop/usecases/get_shop_by_owner.dart';
import '../../domain/shop/usecases/watch_shop.dart';
import '../../domain/shop/usecases/watch_shops.dart';
import '../../domain/storage/repositories/storage_repository.dart';
import '../../domain/storage/usecases/upload_image.dart';
import '../../domain/taxonomy/repositories/taxonomy_repository.dart';
import '../../domain/taxonomy/usecases/get_taxonomy.dart';
import '../../presentation/auth/bloc/auth_bloc.dart';
import '../../presentation/cart/bloc/cart_bloc.dart';
import '../../presentation/catalog/bloc/collections_bloc.dart';
import '../../domain/admin/entities/managed_user.dart';
import '../../presentation/console/audit/bloc/audit_log_bloc.dart';
import '../../presentation/console/dashboard/bloc/dashboard_bloc.dart';
import '../../presentation/console/shops/bloc/shop_detail_bloc.dart';
import '../../presentation/console/shops/bloc/shops_board_bloc.dart';
import '../../presentation/console/users/bloc/user_detail_bloc.dart';
import '../../presentation/console/users/bloc/users_bloc.dart';
import '../../presentation/driver/bloc/deliveries_bloc.dart';
import '../../presentation/favorites/bloc/favorites_bloc.dart';
import '../../presentation/favorites/bloc/favorites_page_bloc.dart';
import '../../presentation/finance/bloc/finance_bloc.dart';
import '../../presentation/home/bloc/shops_bloc.dart';
import '../../presentation/orders/bloc/order_detail_bloc.dart';
import '../../presentation/orders/bloc/orders_bloc.dart';
import '../../presentation/orders/bloc/owner_orders_bloc.dart';
import '../../presentation/orders/order_viewer_role.dart';
import '../../presentation/search/bloc/search_bloc.dart';
import '../../presentation/shop/bloc/products_bloc.dart';
import '../l10n/locale_controller.dart';
import '../network/network_info.dart';
import '../notifications/notification_service.dart';
import '../router/app_router.dart';
import '../theme/theme_controller.dart';

final sl = GetIt.instance;

/// DI registration order: network → firebase → datasources → repositories →
/// use cases → BLoCs → router (Shoppy convention; `shared_preferences` slots in
/// ahead of network once a cache datasource needs it). App-lifetime BLoCs are
/// lazy singletons. Everything is lazy, so nothing touches Firebase until first
/// resolved — tests override `AuthRepository` with a fake before that happens.
Future<void> initDependencies() async {
  // Core — prefs loaded once here (async); the locale/theme controllers and
  // the local cache datasources all read this same instance synchronously.
  final prefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => prefs);
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl());
  sl.registerLazySingleton<LocaleController>(() => LocaleController(sl()));
  sl.registerLazySingleton<ThemeController>(() => ThemeController(sl()));

  // Firebase
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  sl.registerLazySingleton<FirebaseMessaging>(() => FirebaseMessaging.instance);

  // Auth — data
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSource(auth: sl(), firestore: sl()),
  );
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));

  // Auth — use cases
  sl.registerLazySingleton(() => WatchAuthState(sl()));
  sl.registerLazySingleton(() => LogIn(sl()));
  sl.registerLazySingleton(() => SignUp(sl()));
  sl.registerLazySingleton(() => SendPasswordReset(sl()));
  sl.registerLazySingleton(() => LogOut(sl()));
  sl.registerLazySingleton(() => GetUserById(sl()));

  // Admin / RBAC — data (Founder Console: /admins staff profile, memoized per
  // uid for the app session, reset on sign-out). Datasource -> repo -> cases.
  sl.registerLazySingleton(() => AdminRemoteDataSource(firestore: sl()));
  sl.registerLazySingleton<AdminRepository>(() => AdminRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetAdminProfile(sl()));
  sl.registerLazySingleton(() => GetStaffProfileForUid(sl()));
  sl.registerLazySingleton(() => ResetAdminProfile(sl()));
  // Worker `/admin/*` client (privileged back-office ops + best-effort audit
  // reporting). Uses the Firebase ID token as bearer.
  sl.registerLazySingleton(() => AdminApiDataSource(auth: sl()));

  // User + staff management (Founder Console session 6). AdminUserActions is
  // Worker-routed (every mutation); AdminUsersRepository is a direct,
  // no-cache Firestore read (rules allow `users.read`).
  sl.registerLazySingleton<AdminUserActions>(() => AdminUserActionsImpl(sl()));
  sl.registerLazySingleton(() => AdminUsersRemoteDataSource(firestore: sl()));
  sl.registerLazySingleton<AdminUsersRepository>(() => AdminUsersRepositoryImpl(sl()));
  sl.registerLazySingleton(() => SetUserDisabled(sl()));
  sl.registerLazySingleton(() => SetUserPersonaRole(sl()));
  sl.registerLazySingleton(() => ChangeUserEmail(sl()));
  sl.registerLazySingleton(() => SoftDeleteUser(sl()));
  sl.registerLazySingleton(() => RestoreUser(sl()));
  sl.registerLazySingleton(() => CreateUser(sl()));
  sl.registerLazySingleton(() => LookupUserAuth(sl()));
  sl.registerLazySingleton(() => SetAdmin(sl()));
  sl.registerLazySingleton(() => RemoveAdmin(sl()));
  sl.registerLazySingleton(() => GetUsers(sl()));
  sl.registerLazySingleton(() => GetUserByEmail(sl()));
  sl.registerLazySingleton(() => GetUserByPhone(sl()));

  // Shop management (Founder Console session 7). AdminShopsRepository reads
  // are direct + unfiltered (shops read is public — no permission gate to
  // route through, unlike AdminUsersRepository); every write except
  // transferOwnership is also direct (gated by `shops.update` rules) —
  // transferOwnership alone is Worker-routed.
  sl.registerLazySingleton(() => AdminShopsRemoteDataSource(firestore: sl()));
  sl.registerLazySingleton<AdminShopsRepository>(
    () => AdminShopsRepositoryImpl(sl(), sl()),
  );
  sl.registerLazySingleton(() => GetAllShops(sl()));
  sl.registerLazySingleton(() => GetShopById(sl()));
  sl.registerLazySingleton(() => SetShopStatus(sl()));
  sl.registerLazySingleton(() => SetShopFeatured(sl()));
  sl.registerLazySingleton(() => SetShopVerified(sl()));
  sl.registerLazySingleton(() => UpdateShopDetails(sl()));
  sl.registerLazySingleton(() => SoftDeleteShop(sl()));
  sl.registerLazySingleton(() => RestoreShop(sl()));
  sl.registerLazySingleton(() => CreateShopAsStaff(sl()));
  sl.registerLazySingleton(() => TransferShopOwnership(sl()));

  // Shop management — bloc (page-scoped: board loads its own snapshot per
  // open; detail is seeded with the tapped Shop + the signed-in staff uid,
  // used for `deletedBy` on a self-reported soft delete).
  sl.registerFactory(() => ShopsBoardBloc(getAllShops: sl()));
  sl.registerFactoryParam<ShopDetailBloc, Shop, String>(
    (seed, actorUid) => ShopDetailBloc(
      seed: seed,
      actorUid: actorUid,
      getShopById: sl(),
      setShopStatus: sl(),
      setShopFeatured: sl(),
      setShopVerified: sl(),
      updateShopDetails: sl(),
      softDeleteShop: sl(),
      restoreShop: sl(),
      transferShopOwnership: sl(),
    ),
  );

  // Auth — bloc (app lifetime; createDriverProfile only fires for a courier
  // signup, see AuthBloc._onSignUpRequested; getAdminProfile enriches the
  // session with the staff profile, resetAdminProfile clears it on sign-out)
  sl.registerLazySingleton(
    () => AuthBloc(
      watchAuthState: sl(),
      logIn: sl(),
      signUp: sl(),
      sendPasswordReset: sl(),
      logOut: sl(),
      createDriverProfile: sl(),
      getAdminProfile: sl(),
      resetAdminProfile: sl(),
    ),
  );

  // Areas — data (seed-managed, read-only to clients; mirrors Taxonomy).
  sl.registerLazySingleton(() => AreasRemoteDataSource(firestore: sl()));
  sl.registerLazySingleton(() => AreasLocalDataSource());
  sl.registerLazySingleton<AreasRepository>(
    () => AreasRepositoryImpl(sl(), sl(), sl()),
  );

  // Areas — use case
  sl.registerLazySingleton(() => GetAreas(sl()));

  // Driver — data (always-online realtime profile doc, no local cache —
  // mirrors Collections).
  sl.registerLazySingleton(() => DriverRemoteDataSource(firestore: sl()));
  sl.registerLazySingleton<DriverRepository>(
    () => DriverRepositoryImpl(sl()),
  );

  // Driver — use cases
  sl.registerLazySingleton(() => CreateDriverProfile(sl()));
  sl.registerLazySingleton(() => GetDriver(sl()));
  sl.registerLazySingleton(() => WatchDriver(sl()));
  sl.registerLazySingleton(() => SetDriverOnline(sl()));
  sl.registerLazySingleton(() => AvailableDrivers(sl()));
  sl.registerLazySingleton(() => AssignDriver(sl()));

  // Shop — data
  sl.registerLazySingleton(() => ShopRemoteDataSource(firestore: sl()));
  sl.registerLazySingleton(() => ShopLocalDataSource());
  sl.registerLazySingleton<ShopRepository>(
    () => ShopRepositoryImpl(sl(), sl(), sl()),
  );

  // Shop — use cases
  sl.registerLazySingleton(() => WatchShops(sl()));
  sl.registerLazySingleton(() => WatchShop(sl()));
  sl.registerLazySingleton(() => GetShopByOwner(sl()));
  sl.registerLazySingleton(() => CreateShop(sl()));

  // Shop — bloc (page-scoped: a fresh subscription per Home open; also feeds
  // the promo carousel from WatchAllProducts, see ShopsBloc doc)
  sl.registerFactory(() => ShopsBloc(watchShops: sl(), watchAllProducts: sl()));

  // Product — data
  sl.registerLazySingleton(() => ProductRemoteDataSource(firestore: sl()));
  sl.registerLazySingleton(() => ProductLocalDataSource());
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(sl(), sl(), sl()),
  );

  // Product — use cases
  sl.registerLazySingleton(() => WatchProductsByShop(sl()));
  sl.registerLazySingleton(() => WatchAllProducts(sl()));
  sl.registerLazySingleton(() => GetProduct(sl()));
  sl.registerLazySingleton(() => CreateProduct(sl()));
  sl.registerLazySingleton(() => UpdateProduct(sl()));
  sl.registerLazySingleton(() => DeleteProduct(sl()));

  // Product — bloc (page-scoped: one shop's catalog per shop-page open; the
  // shop id is param1, an optional carried-over home category is param2 —
  // M5, mirrors OrderDetailBloc's two-param factory).
  sl.registerFactoryParam<ProductsBloc, String, String?>(
    (shopId, initialCategory) => ProductsBloc(
      shopId: shopId,
      watchShop: sl(),
      watchProductsByShop: sl(),
      watchCollections: sl(),
      initialCategory: initialCategory,
    ),
  );

  // Taxonomy — data (seed-managed, read-only to clients; small fixed tree,
  // so a one-shot get + shared_preferences cache, not a stream).
  sl.registerLazySingleton(() => TaxonomyRemoteDataSource(firestore: sl()));
  sl.registerLazySingleton(() => TaxonomyLocalDataSource());
  sl.registerLazySingleton<TaxonomyRepository>(
    () => TaxonomyRepositoryImpl(sl(), sl(), sl()),
  );

  // Taxonomy — use case
  sl.registerLazySingleton(() => GetTaxonomy(sl()));

  // Collections — data (owner-scoped subcollection, no local cache — see
  // `CollectionsRepository` doc).
  sl.registerLazySingleton(() => CollectionsRemoteDataSource(firestore: sl()));
  sl.registerLazySingleton<CollectionsRepository>(
    () => CollectionsRepositoryImpl(sl(), sl()),
  );

  // Collections — use cases
  sl.registerLazySingleton(() => WatchCollections(sl()));
  sl.registerLazySingleton(() => GetCollections(sl()));
  sl.registerLazySingleton(() => CreateCollection(sl()));
  sl.registerLazySingleton(() => RenameCollection(sl()));
  sl.registerLazySingleton(() => DeleteCollection(sl()));

  // Collections — bloc (page-scoped: the owner manager, one shop's
  // collections per open; shop id is the factory param, mirrors ProductsBloc).
  sl.registerFactoryParam<CollectionsBloc, String, void>(
    (shopId, _) => CollectionsBloc(
      shopId: shopId,
      watchCollections: sl(),
      createCollection: sl(),
      renameCollection: sl(),
      deleteCollection: sl(),
    ),
  );

  // Search — bloc (page-scoped: fresh product + shop subscriptions per open).
  sl.registerFactory(
    () => SearchBloc(watchAllProducts: sl(), watchShops: sl()),
  );

  // Platform config — data (founder-managed rate doc, M12; one-shot read,
  // memoized in the repository for the app session — mirrors Areas/Taxonomy
  // but no local cache datasource, checkout is the only reader today).
  sl.registerLazySingleton(
    () => PlatformConfigRemoteDataSource(firestore: sl()),
  );
  sl.registerLazySingleton<PlatformConfigRepository>(
    () => PlatformConfigRepositoryImpl(sl()),
  );

  // Platform config — use case
  sl.registerLazySingleton(() => GetPlatformConfig(sl()));

  // Finance — data (founder-only cross-shop aggregate reads, M13; always a
  // fresh remote read, no cache — mirrors Order's no-offline-branch contract).
  sl.registerLazySingleton(() => FinanceRemoteDataSource(firestore: sl()));
  sl.registerLazySingleton<FinanceRepository>(
    () => FinanceRepositoryImpl(sl()),
  );

  // Finance — use case
  sl.registerLazySingleton(() => GetFinanceSummary(sl()));

  // Finance — bloc (page-scoped: one load per settings-gated page open).
  sl.registerFactory(() => FinanceBloc(getFinanceSummary: sl()));

  // Audit log — data (Founder Console session 4; immutable Worker-written
  // trail, read-only + cursor-paginated for the console viewer, no cache —
  // a stale security log is worse than a network wait, mirrors Finance).
  sl.registerLazySingleton(() => AuditRemoteDataSource(firestore: sl()));
  sl.registerLazySingleton<AuditRepository>(
    () => AuditRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetAuditEntries(sl()));

  // Audit log — bloc (page-scoped: one viewer per /console/audit open).
  sl.registerFactory(() => AuditLogBloc(getAuditEntries: sl()));

  // Users — bloc (page-scoped: one viewer per /console/users open).
  sl.registerFactory(() => UsersBloc(
        getUsers: sl(),
        getUserByEmail: sl(),
        getUserByPhone: sl(),
        setUserDisabled: sl(),
      ));

  // User detail — bloc (page-scoped, one per /console/users/:uid open; needs
  // the tapped row's `ManagedUser` as a seed — there is no get-by-uid read).
  sl.registerFactoryParam<UserDetailBloc, ManagedUser, void>(
    (seed, _) => UserDetailBloc(
      seed: seed,
      lookupUserAuth: sl(),
      getStaffProfileForUid: sl(),
      getUserByEmail: sl(),
      setUserDisabled: sl(),
      setUserPersonaRole: sl(),
      changeUserEmail: sl(),
      softDeleteUser: sl(),
      restoreUser: sl(),
      sendPasswordReset: sl(),
      setAdmin: sl(),
      removeAdmin: sl(),
    ),
  );

  // Dashboard — data (Founder Console session 5; live cross-collection
  // aggregate snapshot, no cache — mirrors Finance).
  sl.registerLazySingleton(() => DashboardRemoteDataSource(firestore: sl()));
  sl.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetDashboardSummary(sl()));

  // Dashboard — bloc (page-scoped: one live view per /console open; reuses the
  // audit repo for the recent-activity strip. Read permissions arrive on the
  // start event from the page's AuthBloc — no AuthBloc dependency here).
  sl.registerFactory(
    () => DashboardBloc(getDashboardSummary: sl(), getAuditEntries: sl()),
  );

  // Order — data
  sl.registerLazySingleton(
    () => OrderRemoteDataSource(firestore: sl(), auth: sl()),
  );
  sl.registerLazySingleton<OrderRepository>(() => OrderRepositoryImpl(sl()));

  // Order — use cases
  sl.registerLazySingleton(() => PlaceOrder(sl(), sl()));
  sl.registerLazySingleton(() => WatchCustomerOrders(sl()));
  sl.registerLazySingleton(() => WatchShopOrders(sl()));
  sl.registerLazySingleton(() => WatchOrder(sl()));
  sl.registerLazySingleton(() => CancelOrder(sl()));
  sl.registerLazySingleton(() => UpdateOrderStatus(sl()));
  sl.registerLazySingleton(() => RateOrder(sl()));
  sl.registerLazySingleton(() => WatchDriverActiveOrders(sl()));
  sl.registerLazySingleton(() => WatchDriverOrderHistory(sl()));

  // Order — blocs (page-scoped: the customer uid / shop id / order id is the
  // factory param, mirroring ProductsBloc's shopId).
  sl.registerFactoryParam<OrdersBloc, String, void>(
    (customerUid, _) =>
        OrdersBloc(customerUid: customerUid, watchCustomerOrders: sl()),
  );
  sl.registerFactoryParam<OwnerOrdersBloc, String, void>(
    (shopId, _) => OwnerOrdersBloc(shopId: shopId, watchShopOrders: sl()),
  );
  sl.registerFactoryParam<OrderDetailBloc, String, OrderViewerRole>(
    (orderId, role) => OrderDetailBloc(
      orderId: orderId,
      watchOrder: sl(),
      cancelOrder: sl(),
      rateOrder: sl(),
      updateOrderStatus: sl(),
      getUserById: sl(),
      getAreas: sl(),
      notifyOrderEvent: sl(),
      role: role,
    ),
  );

  // Deliveries — bloc (page-scoped: the courier's own uid is the factory
  // param, mirroring OrdersBloc's customerUid; lives inside CourierHomeShell,
  // one subscription pair per courier session).
  sl.registerFactoryParam<DeliveriesBloc, String, void>(
    (driverUid, _) => DeliveriesBloc(
      driverUid: driverUid,
      watchActive: sl(),
      watchHistory: sl(),
      getAreas: sl(),
    ),
  );

  // Storage — data (image upload via the Cloudflare Worker + R2). No local
  // datasource: uploads are write-only, nothing to cache.
  sl.registerLazySingleton<ImageUploadRemoteDataSource>(
    () => HttpImageUploadRemoteDataSource(auth: sl()),
  );
  sl.registerLazySingleton<StorageRepository>(
    () => StorageRepositoryImpl(sl(), sl()),
  );

  // Storage — use case
  sl.registerLazySingleton(() => UploadImage(sl()));

  // Notifications — data (best-effort push trigger via the same Worker as
  // Storage; the Worker owns FCM auth/authorization — see
  // worker/src/index.js). No local datasource: nothing to cache.
  sl.registerLazySingleton<NotificationRemoteDataSource>(
    () => HttpNotificationRemoteDataSource(auth: sl()),
  );
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(sl()),
  );

  // Notifications — use case
  sl.registerLazySingleton(() => NotifyOrderEvent(sl()));

  // Cart — bloc (app lifetime: one basket across the whole session; no
  // repository — nothing to sync until PlaceOrder runs at checkout).
  sl.registerLazySingleton(() => CartBloc());

  // Favorites — data
  sl.registerLazySingleton(() => FavoritesRemoteDataSource(firestore: sl()));
  sl.registerLazySingleton<FavoritesRepository>(
    () => FavoritesRepositoryImpl(sl(), sl()),
  );

  // Favorites — use cases
  sl.registerLazySingleton(() => WatchFavorites(sl()));
  sl.registerLazySingleton(() => ToggleFavoriteShop(sl()));
  sl.registerLazySingleton(() => ToggleFavoriteProduct(sl()));

  // Favorites — bloc (app lifetime: one heart-state feed across Home/Shop/
  // Search/ProductDetail/Favorites-tab; re-subscribes on every uid change,
  // mirroring how AuthBloc drives the router).
  sl.registerLazySingleton(() => FavoritesBloc(authBloc: sl(), watchFavorites: sl()));

  // Favorites — page bloc (tab-scoped: combines the id feed above with the
  // existing shops/products feeds, mirroring how SearchBloc combines them).
  sl.registerFactory(
    () => FavoritesPageBloc(favoritesBloc: sl(), watchShops: sl(), watchAllProducts: sl()),
  );

  // Router (reads AuthBloc)
  sl.registerLazySingleton(() => AppRouter(sl()));

  // Notifications — service (app lifetime: permission + token lifecycle +
  // foreground display + tap-to-navigate; started once from `main.dart`).
  sl.registerLazySingleton(
    () => NotificationService(
      messaging: sl(),
      authRepository: sl(),
      authBloc: sl(),
      appRouter: sl(),
    ),
  );
}
