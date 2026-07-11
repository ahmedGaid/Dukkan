import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/auth/datasources/auth_remote_datasource.dart';
import '../../data/auth/repositories/auth_repository_impl.dart';
import '../../data/favorites/datasources/favorites_remote_datasource.dart';
import '../../data/favorites/repositories/favorites_repository_impl.dart';
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
import '../../domain/auth/repositories/auth_repository.dart';
import '../../domain/auth/usecases/log_in.dart';
import '../../domain/auth/usecases/log_out.dart';
import '../../domain/auth/usecases/send_password_reset.dart';
import '../../domain/auth/usecases/sign_up.dart';
import '../../domain/auth/usecases/watch_auth_state.dart';
import '../../domain/favorites/repositories/favorites_repository.dart';
import '../../domain/favorites/usecases/toggle_favorite_product.dart';
import '../../domain/favorites/usecases/toggle_favorite_shop.dart';
import '../../domain/favorites/usecases/watch_favorites.dart';
import '../../domain/notifications/repositories/notification_repository.dart';
import '../../domain/notifications/usecases/notify_order_event.dart';
import '../../domain/order/repositories/order_repository.dart';
import '../../domain/order/usecases/cancel_order.dart';
import '../../domain/order/usecases/place_order.dart';
import '../../domain/order/usecases/rate_order.dart';
import '../../domain/order/usecases/update_order_status.dart';
import '../../domain/order/usecases/watch_customer_orders.dart';
import '../../domain/order/usecases/watch_order.dart';
import '../../domain/order/usecases/watch_shop_orders.dart';
import '../../domain/product/repositories/product_repository.dart';
import '../../domain/product/usecases/create_product.dart';
import '../../domain/product/usecases/delete_product.dart';
import '../../domain/product/usecases/get_product.dart';
import '../../domain/product/usecases/update_product.dart';
import '../../domain/product/usecases/watch_all_products.dart';
import '../../domain/product/usecases/watch_products_by_shop.dart';
import '../../domain/shop/repositories/shop_repository.dart';
import '../../domain/shop/usecases/create_shop.dart';
import '../../domain/shop/usecases/get_shop_by_owner.dart';
import '../../domain/shop/usecases/watch_shop.dart';
import '../../domain/shop/usecases/watch_shops.dart';
import '../../domain/storage/repositories/storage_repository.dart';
import '../../domain/storage/usecases/upload_image.dart';
import '../../presentation/auth/bloc/auth_bloc.dart';
import '../../presentation/cart/bloc/cart_bloc.dart';
import '../../presentation/favorites/bloc/favorites_bloc.dart';
import '../../presentation/favorites/bloc/favorites_page_bloc.dart';
import '../../presentation/home/bloc/shops_bloc.dart';
import '../../presentation/orders/bloc/order_detail_bloc.dart';
import '../../presentation/orders/bloc/orders_bloc.dart';
import '../../presentation/orders/bloc/owner_orders_bloc.dart';
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

  // Auth — bloc (app lifetime)
  sl.registerLazySingleton(
    () => AuthBloc(
      watchAuthState: sl(),
      logIn: sl(),
      signUp: sl(),
      sendPasswordReset: sl(),
      logOut: sl(),
    ),
  );

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
  // shop id is the factory param).
  sl.registerFactoryParam<ProductsBloc, String, void>(
    (shopId, _) => ProductsBloc(
      shopId: shopId,
      watchShop: sl(),
      watchProductsByShop: sl(),
    ),
  );

  // Search — bloc (page-scoped: fresh product + shop subscriptions per open).
  sl.registerFactory(
    () => SearchBloc(watchAllProducts: sl(), watchShops: sl()),
  );

  // Order — data
  sl.registerLazySingleton(
    () => OrderRemoteDataSource(firestore: sl(), auth: sl()),
  );
  sl.registerLazySingleton<OrderRepository>(() => OrderRepositoryImpl(sl()));

  // Order — use cases
  sl.registerLazySingleton(() => PlaceOrder(sl()));
  sl.registerLazySingleton(() => WatchCustomerOrders(sl()));
  sl.registerLazySingleton(() => WatchShopOrders(sl()));
  sl.registerLazySingleton(() => WatchOrder(sl()));
  sl.registerLazySingleton(() => CancelOrder(sl()));
  sl.registerLazySingleton(() => UpdateOrderStatus(sl()));
  sl.registerLazySingleton(() => RateOrder(sl()));

  // Order — blocs (page-scoped: the customer uid / shop id / order id is the
  // factory param, mirroring ProductsBloc's shopId).
  sl.registerFactoryParam<OrdersBloc, String, void>(
    (customerUid, _) =>
        OrdersBloc(customerUid: customerUid, watchCustomerOrders: sl()),
  );
  sl.registerFactoryParam<OwnerOrdersBloc, String, void>(
    (shopId, _) => OwnerOrdersBloc(shopId: shopId, watchShopOrders: sl()),
  );
  sl.registerFactoryParam<OrderDetailBloc, String, void>(
    (orderId, _) => OrderDetailBloc(
      orderId: orderId,
      watchOrder: sl(),
      cancelOrder: sl(),
      rateOrder: sl(),
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
