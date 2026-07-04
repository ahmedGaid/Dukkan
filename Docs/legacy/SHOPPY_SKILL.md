---
name: shoppy-app
description: "Use this skill whenever working on the Shoppy Flutter e-commerce app project. Triggers include: any mention of 'Shoppy', 'shoppy_app', working on the Flutter shopping app, questions about the app architecture, adding features to the app, fixing bugs in the app, or continuing development on the project. Also triggers when the user uploads dart files from the project (repositories_impl.dart, local_datasources.dart, catalog_bloc.dart, etc.) and asks for help. This skill provides complete project context so Claude can work at full quality without needing long explanations."
---

# Shoppy — Flutter E-Commerce App

## Quick Reference

- **Package:** `shoppy_app` | **Flutter SDK:** `>=3.2.0 <4.0.0`
- **Architecture:** Clean Architecture — Domain / Data / Presentation
- **State:** `flutter_bloc` + `Equatable` | **DI:** `get_it` (`sl` global)
- **Nav:** `go_router` | **Local storage:** `shared_preferences`
- **Remote:** Firebase Firestore + Auth (currently **mocked/commented** — not active)
- **Target:** Arabic/Egyptian market — default location Cairo, EGP currency option

---

## Directory Structure

```
lib/
├── core/
│   ├── bloc_observer/     AppBlocObserver
│   ├── constants/         AppConstants (SharedPrefs keys), AppStrings, FirestoreCollections
│   ├── di/                injection_container.dart  ← single DI file, sl = GetIt.instance
│   ├── errors/            Failure hierarchy (ServerFailure, NetworkFailure, CacheFailure…)
│   ├── maps/              MapsConfig (API key), PlacesService (autocomplete/geocoding REST)
│   ├── network/           NetworkInfoImpl — HTTP HEAD probe, NOT InternetConnectionChecker
│   ├── router/            AppRouter, AppRoutes constants, _AuthNotifier
│   ├── theme/             AppTheme, AppColors, AppSpacing, AppRadius
│   └── usecases/          UseCase<Type,Params>, NoParams
│
├── data/
│   ├── datasources/local/ local_datasources.dart  ← ALL local datasources in one file
│   ├── datasources/remote/firebase/
│   │   ├── firebase_datasources.dart      (Catalog, Orders, User)
│   │   └── firebase_auth_datasource.dart
│   ├── models/            models.dart  ← ALL models in one file
│   └── repositories/      repositories_impl.dart + auth_repository_impl.dart
│
├── domain/
│   ├── entities/          entities.dart + auth_entity.dart
│   ├── repositories/      repositories.dart (interfaces) + auth_repository.dart
│   └── usecases/          catalog_, cart_, orders_, user_, auth_usecases.dart
│
└── presentation/
    ├── blocs/             catalog, cart, orders, user, favorites, auth, settings, location
    ├── pages/             auth, catalog, checkout, home, location, orders, profile, settings, splash
    └── widgets/           common/widgets.dart, catalog/product_card.dart, cart/cart_item_widget.dart
```

### Architecture Rules — Always Enforce
- No business logic in pages/widgets → use BLoC events
- No direct repository calls from BLoC → use use cases
- No `data/` imports in `domain/`
- Side-effects (navigation, snackbars) → `BlocListener` or `BlocConsumer`, never `BlocBuilder`

---

## Design Tokens — Use These, Never Invent New Ones

```dart
// Brand
AppColors.primary      = Color(0xFF5C6BC0)   // indigo — CTAs, icons, badges
AppColors.primaryLight = Color(0xFF8E99F3)   // dark mode
AppColors.primaryDark  = Color(0xFF26418F)   // gradients, shadows
AppColors.accent       = Color(0xFFFF6B6B)   // coral — badges, fav heart, alerts

// Semantic
AppColors.success = Color(0xFF4CAF50)
AppColors.warning = Color(0xFFFFA726)
AppColors.error   = Color(0xFFEF5350)
AppColors.info    = Color(0xFF29B6F6)

// Surfaces (light)
AppColors.surface        = Color(0xFFFFFFFF)
AppColors.surfaceVariant = Color(0xFFF5F6FA)  // scaffold bg
AppColors.outline        = Color(0xFFE8EAF6)

// Dark mode
AppColors.darkBg      = Color(0xFF0F0F1A)
AppColors.darkSurface = Color(0xFF1A1A2E)
AppColors.darkCard    = Color(0xFF22223B)

// Grey scale: grey100=0xFFF5F5F5, grey200=0xFFEEEEEE, grey400=0xFFBDBDBD,
//             grey600=0xFF757575, grey900=0xFF212121

// Spacing: xs=4, sm=8, md=16, lg=24, xl=32, xxl=48
// Radius:  sm=8, md=12, lg=16, xl=24, round=100

// Helpers:
AppTheme.card(context)    // white / darkCard
AppTheme.bg(context)      // surfaceVariant / darkBg
AppTheme.isDark(context)  // bool
```

---

## All Routes

```dart
AppRoutes.splash            = '/'
AppRoutes.home              = '/home'              // ShellRoute
AppRoutes.login             = '/login'
AppRoutes.register          = '/register'
AppRoutes.forgotPassword    = '/forgot-password'
AppRoutes.subcategory       = '/subcategory'        // extra: CategoryEntity
AppRoutes.productsList      = '/products'           // extra: Map{title,categoryId,subcategoryId}
AppRoutes.productDetail     = '/product-detail'     // extra: ProductEntity
AppRoutes.checkout          = '/checkout'
AppRoutes.orderConfirmation = '/order-confirmation' // extra: String (orderId)
AppRoutes.orderDetail       = '/order-detail'       // extra: OrderEntity
AppRoutes.editProfile       = '/edit-profile'
AppRoutes.rechargeWallet    = '/recharge-wallet'
AppRoutes.settings          = '/settings'
AppRoutes.locationPicker    = '/location-picker'    // extra: AddressEntity?, returns LocationPickerResult via pop
```

**Auth guard:** `AuthInitial/Loading` → stay on splash | `Unauthenticated` → `/login` | `Authenticated` on auth/splash → `/home`

---

## Domain Entities

### Key entity fields

**ProductEntity:** `id, name, description, imageUrl, additionalImages, price, categoryId, subcategoryId?, stockStatus (StockStatus enum), availablePieces?, rating?, reviewCount, isPopular`
Getters: `isAvailable`, `hasLimitedStock` (pieces ≤ 5), `stockLabel`

**CartEntity:** `items: List<CartItemEntity>`
Getters: `total` (sum subtotals), `itemCount` (sum quantities), `isEmpty`
**BADGE RULE:** Always use `items.length` (distinct products), NEVER `itemCount`

**CartItemEntity:** `id, product, quantity` | Getter: `subtotal`

**OrderEntity:** `id, items, total, status (OrderStatus), createdAt, deliveryAddress, paymentMethod, notes?`
Getter: `itemCount`

**AddressEntity:** `street, city, state, country` (required) + `postalCode?, latitude?, longitude?, formattedAddress?, label?`
Getters: `fullAddress` (uses formattedAddress if present), `hasCoordinates`

**UserEntity:** `id, name, email, phone, avatarUrl?, address?, walletBalance`

**AuthUserEntity:** `uid, email, displayName?, photoUrl?, emailVerified`

**Enums:**
```dart
enum OrderStatus   { pending, confirmed, processing, shipped, delivered, cancelled }
enum PaymentMethod { wallet, cashOnDelivery, creditCard }
enum StockStatus   { inStock, outOfStock, preOrder }
// OrderStatus has .label extension
```

**Cancel allowed when:** `status == pending || status == confirmed`

---

## BLoC Quick Reference

### CatalogBloc
- `LoadCatalogEvent` → runs `getCategories` + `getPopular` via **`Future.wait`** (parallel, single emit)
- `LoadProductsEvent(categoryId?, subcategoryId?)` → updates `filteredProducts` on `CatalogLoaded`
- `SearchProductsEvent(query)` / `ClearSearchEvent`
- States: `CatalogInitial`, `CatalogLoading`, `CatalogLoaded`, `CatalogError`

### CartBloc
- `AddToCartEvent(product, quantity=1)` | `RemoveFromCartEvent(cartItemId)` | `UpdateQuantityEvent` | `ClearCartEvent` | `LoadCartEvent`
- States: `CartInitial`, `CartLoading`, `CartLoaded(cart)`, `CartError`

### OrdersBloc
- `PlaceOrderEvent` → emits `OrderPlaced` then immediately `OrdersLoaded([placed,...existing])` — **no second Loading flash**
- `CancelOrderEvent(orderId)` → emits `OrderCancelled` then updates list in-place
- `LoadOrdersEvent`
- States: `OrdersInitial`, `OrdersLoading`, `OrdersLoaded`, `OrderPlaced`, `OrderCancelled`, `OrdersError`

### AuthBloc
- `CheckAuthEvent` | `LoginEvent(LoginParams)` | `RegisterEvent(RegisterParams)` | `LogoutEvent` | `ResetPasswordEvent(email)` | `AuthStateChangedEvent(user?)`
- States: `AuthInitial`, `AuthLoading`, `Authenticated(user)`, `Unauthenticated`, `AuthError(message)`, `PasswordResetSent(email)`

### SettingsBloc (lazy singleton, started in DI `init()`)
- `LoadSettingsEvent` | `ToggleThemeEvent(ThemeMode)` | `ToggleNotificationsEvent(bool)` | `ToggleBiometricsEvent(bool)` | `ChangeCurrencyEvent(String)` | `ChangeLanguageEvent(String)`
- Persisted to SharedPreferences

### FavoritesBloc
- `LoadFavoritesEvent` | `ToggleFavoriteEvent(ProductEntity)`
- `FavoritesLoaded` has `isFavorite(id)` helper

### LocationPickerBloc
- `InitLocationEvent(initial?)` | `SearchAddressEvent(query)` | `SelectSuggestionEvent(suggestion)` | `MapPinMovedEvent(lat, lng)` | `UseCurrentLocationEvent` | `ClearSuggestionsEvent`
- State: `LocationPickerState{latitude, longitude, formattedAddress?, resolvedAddress?, suggestions, isSearching, isResolving, isLocatingDevice, error?}`

---

## Data Layer Critical Details

### SharedPreferences Keys
```
'user_data'            → UserModel JSON  ← also used by _getLocalUserId() to scope Firestore queries
'cart_data'            → List<CartItemModel> JSON
'orders_data'          → List<OrderModel> JSON
'favorites_data'       → List<ProductModel> JSON
'catalog_categories'   → List<CategoryModel> JSON
'catalog_products'     → List<ProductModel> JSON
'settings_theme_mode'  → 'light'|'dark'|'system'
'settings_notifications', 'settings_biometrics', 'settings_currency', 'settings_language'
```

### CatalogLocalDataSourceImpl — CRITICAL
```dart
// Constructor MUST have:
late final Future<void> _ready;
CatalogLocalDataSourceImpl(this.prefs) { _ready = _seedIfEmpty(); }

// _seedIfEmpty() seeds 15 products + 6 categories if 'catalog_categories' key is absent
// All public methods MUST await _ready before reading prefs
// DO NOT comment out _ready or seed calls — causes offline instability
```

### CatalogRepositoryImpl — online/offline decision
```dart
Future<bool> _shouldUseRemote() async {
  if (remote == null) return false;
  return await networkInfo.isConnected;  // online=Firebase, offline=local, NO TTL
}
// getPopularProducts MUST cache result: await local.cacheProducts(prods)
// NO _cacheTTL, NO _stampFetch — these caused constant flicker when TTL=1s
```

### OrdersRepositoryImpl
```dart
// Constructor needs: local, networkInfo, prefs (for userId), remote?
// _getLocalUserId() reads prefs.getString('user_data') → parses JSON 'id' field
// placeOrder calls: remote!.placeOrder(OrderModel.fromEntity(order), userId)
// Firebase method signature: placeOrder(OrderModel order, String userId)
```

### NetworkInfo — HTTP probe
```dart
// Uses dart:io HttpClient — probes google.com + 1.1.1.1 in parallel, 5s timeout
// InternetConnectionChecker is REMOVED from pubspec — do NOT add it back
// Was causing Firebase to never be reached on firewalled Android devices
```

---

## DI Registration Order (critical)

```dart
1. SharedPreferences (singleton, awaited before di.init() completes)
2. Dio, NetworkInfo (no constructor args — HTTP probe)
3. All local datasources
4. [COMMENTED BLOCK] Firebase datasources — uncomment to activate
5. AuthRepository — _MockAuthRepository (returns Unauthenticated, replace with Firebase)
6. CatalogRepository(local, networkInfo, remote?)  ← no prefs param
7. CartRepository(local)
8. OrdersRepository(local, networkInfo, prefs, remote?)  ← needs prefs for userId
9. UserRepository(local), FavoritesRepository(local)
10. All use cases
11. BLoCs as registerFactory (except SettingsBloc — lazy singleton, auto-started)
```

## MultiBlocProvider Order in main.dart (AuthBloc MUST be first)
```dart
BlocProvider(create: (_) => sl<AuthBloc>()..add(CheckAuthEvent())),
BlocProvider(create: (_) => sl<SettingsBloc>()),
BlocProvider(create: (_) => sl<UserBloc>()..add(LoadUserEvent())),
BlocProvider(create: (_) => sl<CatalogBloc>()..add(LoadCatalogEvent())),
BlocProvider(create: (_) => sl<CartBloc>()..add(LoadCartEvent())),
BlocProvider(create: (_) => sl<FavoritesBloc>()..add(LoadFavoritesEvent())),
BlocProvider(create: (_) => sl<OrdersBloc>()..add(LoadOrdersEvent())),
```

App widget wrapping:
```dart
BlocListener<AuthBloc, AuthState>(
  listener: (_, state) => AppRouter.notifyAuthChange(state),
  child: BlocBuilder<SettingsBloc, SettingsState>(
    buildWhen: (p, c) => p.themeMode != c.themeMode,
    builder: (_, s) => MaterialApp.router(themeMode: s.themeMode, ...),
  ),
)
```

---

## Standard UI Patterns

```dart
// Cards
AppCard(child: ..., padding: ..., onTap: ..., radius: ...)

// Snackbars
AppSnackBar.success(context, 'msg') / .error / .info

// Empty states
EmptyState(emoji: '📦', title: '...', subtitle: '...', actionLabel: '...', onAction: ...)

// Images (always shimmer)
ShimmerImage(url: url, width: w, height: h, borderRadius: ..., fit: BoxFit.cover)

// Loading skeletons
GridShimmer(count: 6)

// Responsive breakpoint
final isSmallDevice = MediaQuery.of(context).size.width < 360 || MediaQuery.of(context).size.height < 600;
```

### BLoC page pattern
```dart
// Read-only UI:
BlocBuilder<XBloc, XState>(
  buildWhen: (p, c) => c is XLoaded || c is XLoading || c is XError,
  builder: (ctx, state) { ... }
)

// With navigation/snackbars:
BlocConsumer<XBloc, XState>(
  listener: (ctx, state) { /* side effects */ },
  buildWhen: (p, c) => /* only states that rebuild UI */,
  builder: (ctx, state) { ... }
)
```

---

## Firestore Schema

```
/categories/{id}  name, imageUrl, subcategories:[{id,name,imageUrl,parentCategoryId}]
/products/{id}    name, description, imageUrl, price, categoryId, subcategoryId?, stockStatus,
                  availablePieces?, rating?, reviewCount, isPopular
/orders/{id}      userId (required!), items, total, status, createdAt:Timestamp,
                  deliveryAddress:{street,city,state,country,postalCode?,lat?,lng?,formattedAddress?},
                  paymentMethod, notes?
/users/{id}       name, email, phone, avatarUrl?, walletBalance, address?
```

**Timestamp handling in Firebase datasource:**
```dart
if (data['createdAt'] is Timestamp) {
  data['createdAt'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
} else {
  data['createdAt'] = DateTime.now().toIso8601String();
}
```

---

## Activation Checklists

### Firebase (NOT YET ACTIVE)
1. `flutterfire configure --project=YOUR_PROJECT_ID` → `lib/firebase_options.dart`
2. `google-services.json` → `android/app/`
3. `GoogleService-Info.plist` → `ios/Runner/` (via Xcode)
4. Uncomment in `main.dart`: `Firebase.initializeApp(...)`
5. Uncomment Firebase block in `injection_container.dart`, remove `_MockAuthRepository`
6. Set Firestore security rules

### Google Maps (NOT YET ACTIVE)
1. Enable: Maps SDK Android/iOS, Places API, Geocoding API
2. Set `MapsConfig.apiKey` in `lib/core/maps/maps_config.dart`
3. Android: `<meta-data android:name="com.google.android.geo.API_KEY" android:value="KEY"/>`
4. iOS: `GMSServices.provideAPIKey("KEY")` in AppDelegate.swift
5. **Add to pubspec.yaml** (not yet added): `google_maps_flutter: ^2.5.3` + `geolocator: ^11.0.0`
6. Android permissions: `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`
7. iOS Info.plist: `NSLocationWhenInUseUsageDescription`

---

## Known Bugs Fixed (Do Not Re-Introduce)

| Bug | Cause | Fix |
|---|---|---|
| Products empty offline | `_ready` + seed calls commented out | Restored in constructor |
| Popular not cached offline | `getPopularProducts` never called `cacheProducts` | Added cache call after remote fetch |
| Firebase never reached | `InternetConnectionChecker` socket firewalled on Android | HTTP probe via `dart:io` |
| Constant catalog flicker | TTL was `Duration(seconds: 1)` | Removed TTL entirely |
| Catalog double-emit flicker | Sequential `await` in `_onLoad` (2 rebuilds) | `Future.wait` → single emit |
| Orders badge showed cart count | Shell page used `CartBloc.itemCount` on Orders tab | Badge removed from Orders tab |
| Cart badge wrong number | Used `cart.itemCount` (total qty) | Changed to `items.length` (distinct) |
| Orders empty after placing | `LoadOrdersEvent` caused Loading flash | Optimistic prepend, no reload |
| Checkout spinner flash | Missing `buildWhen`; background `OrdersLoaded` triggered rebuild | Local `_placing` bool + `buildWhen` |
| Orders not sent to Firebase | `placeOrder` only called local | Calls `remote.placeOrder(model, userId)` |
| `_getLocalUserId()` null | Was a stub | Reads `prefs.getString('user_data')` → parses `id` |

---

## Feature Status

| Feature | Status |
|---|---|
| Home, categories, popular, search | ✅ |
| Product detail, gallery, add to cart | ✅ |
| Cart (distinct badge, merge quantities) | ✅ |
| Checkout + address picker (map + manual) | ✅ (Maps needs API key + pubspec packages) |
| Orders: place, list, detail, cancel | ✅ |
| Profile, edit, wallet, favorites | ✅ |
| Settings (theme, notifications, currency…) | ✅ |
| Dark mode (SettingsBloc driven) | ✅ |
| Auth (login, register, forgot password) | ✅ UI — 🔲 Firebase not active |
| Firebase Firestore | 🔲 Code ready, comment block in DI |
| Google Maps interactive picker | ✅ Code ready — 🔲 pubspec + API key needed |

---

## Outstanding TODOs

1. Add `google_maps_flutter: ^2.5.3` + `geolocator: ^11.0.0` to `pubspec.yaml`
2. Activate Firebase (checklist above)
3. Set Google Maps API key
4. Register `LocationPickerBloc` in `injection_container.dart` (currently inline in page)
5. Implement avatar upload to Firebase Storage (`image_picker` is in pubspec)
6. Real-time order updates via Firestore `snapshots()` stream
7. Push notifications (`firebase_messaging`)
8. Arabic localization (`intl` in pubspec, `ChangeLanguageEvent` wired, strings not translated)
9. Payment gateway (credit card option disabled in UI)
10. Production Firestore security rules (test-mode expires in 30 days)
