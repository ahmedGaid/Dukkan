# Shoppy — Complete Project Knowledge Base

> **Purpose:** This document contains everything a new Claude session needs to continue working on this project at full quality. Read this entirely before making any changes.

---

## 1. Project Identity

| Field | Value |
|---|---|
| App name | **Shoppy** |
| Package name | `shoppy_app` |
| Flutter SDK | `>=3.2.0 <4.0.0` |
| Version | `1.0.0+1` |
| Architecture | Clean Architecture (Domain / Data / Presentation) |
| State management | `flutter_bloc` + `Equatable` |
| DI | `get_it` (service locator, `sl` global) |
| Navigation | `go_router` |
| Local storage | `shared_preferences` |
| Remote storage | Firebase Firestore (currently behind a comment block — not yet active) |
| Auth | Firebase Auth (currently mocked — not yet active) |
| Target audience | Arabic/Egyptian market (default location: Cairo, EGP currency option) |

---

## 2. Architecture Overview

```
lib/
├── core/
│   ├── bloc_observer/     AppBlocObserver
│   ├── constants/         AppConstants, AppStrings, FirestoreCollections
│   ├── di/                injection_container.dart  ← single DI file
│   ├── errors/            Failure hierarchy
│   ├── maps/              MapsConfig, PlacesService
│   ├── network/           NetworkInfo (HTTP probe, NOT InternetConnectionChecker)
│   ├── router/            AppRouter, AppRoutes, _AuthNotifier
│   ├── theme/             AppTheme, AppColors, AppSpacing, AppRadius
│   └── usecases/          UseCase<Type,Params>, NoParams
│
├── data/
│   ├── datasources/
│   │   ├── local/         local_datasources.dart  ← ALL local DSes in one file
│   │   └── remote/firebase/
│   │       ├── firebase_datasources.dart   ← Catalog, Orders, User Firebase DSes
│   │       └── firebase_auth_datasource.dart
│   ├── models/            models.dart  ← ALL models in one file
│   └── repositories/      repositories_impl.dart + auth_repository_impl.dart
│
├── domain/
│   ├── entities/          entities.dart + auth_entity.dart
│   ├── repositories/      repositories.dart (interfaces) + auth_repository.dart
│   └── usecases/          catalog_, cart_, orders_, user_, auth_usecases.dart
│
└── presentation/
    ├── blocs/             catalog/, cart/, orders/, user/, favorites/,
    │                      auth/, settings/, location/
    ├── pages/             auth/, catalog/, checkout/, home/, location/,
    │                      orders/, profile/, settings/, splash/
    └── widgets/           common/, catalog/, cart/
```

### Key architectural rules to always follow
- **Never** put business logic in pages or widgets — use BLoC events.
- **Never** call repositories directly from BLoCs — use use cases.
- **Never** import `data/` layer from `domain/` layer.
- Pages read BLoC state with `BlocBuilder`; side-effects (navigation, snackbars) use `BlocListener` or `BlocConsumer`.
- Every file in `data/` that the presentation layer needs must be exposed through a repository interface in `domain/`.

---

## 3. Design Tokens (never invent new colors — use these)

```dart
// Brand
AppColors.primary        = Color(0xFF5C6BC0)  // indigo — main CTA, icons, badges
AppColors.primaryLight   = Color(0xFF8E99F3)  // dark mode primary
AppColors.primaryDark    = Color(0xFF26418F)  // gradients, shadows
AppColors.accent         = Color(0xFFFF6B6B)  // coral — badges, alerts, fav heart

// Semantic
AppColors.success = Color(0xFF4CAF50)
AppColors.warning = Color(0xFFFFA726)
AppColors.error   = Color(0xFFEF5350)
AppColors.info    = Color(0xFF29B6F6)

// Neutrals (light mode)
AppColors.surface        = Color(0xFFFFFFFF)
AppColors.surfaceVariant = Color(0xFFF5F6FA)  // scaffold bg
AppColors.outline        = Color(0xFFE8EAF6)

// Dark mode surfaces
AppColors.darkBg      = Color(0xFF0F0F1A)
AppColors.darkSurface = Color(0xFF1A1A2E)
AppColors.darkCard    = Color(0xFF22223B)

// Spacing: AppSpacing.xs=4, sm=8, md=16, lg=24, xl=32, xxl=48
// Radius:  AppRadius.sm=8, md=12, lg=16, xl=24, round=100
```

**Theme helpers:**
```dart
AppTheme.card(context)   // white in light, darkCard in dark
AppTheme.bg(context)     // surfaceVariant in light, darkBg in dark
AppTheme.isDark(context) // bool
```

---

## 4. All Routes

```dart
AppRoutes.splash            = '/'
AppRoutes.home              = '/home'          // ShellRoute wraps bottom nav
AppRoutes.login             = '/login'
AppRoutes.register          = '/register'
AppRoutes.forgotPassword    = '/forgot-password'
AppRoutes.subcategory       = '/subcategory'   // extra: CategoryEntity
AppRoutes.productsList      = '/products'      // extra: Map<String,dynamic>{title,categoryId,subcategoryId}
AppRoutes.productDetail     = '/product-detail'// extra: ProductEntity
AppRoutes.checkout          = '/checkout'
AppRoutes.orderConfirmation = '/order-confirmation' // extra: String (orderId)
AppRoutes.orderDetail       = '/order-detail'  // extra: OrderEntity
AppRoutes.editProfile       = '/edit-profile'
AppRoutes.rechargeWallet    = '/recharge-wallet'
AppRoutes.settings          = '/settings'
AppRoutes.locationPicker    = '/location-picker' // extra: AddressEntity? — returns LocationPickerResult via pop
```

**Auth redirect guard logic:**
- `AuthInitial` or `AuthLoading` → stay on splash (wait)
- `Unauthenticated` → redirect to `/login` (unless already on auth page)
- `Authenticated` on splash or auth page → redirect to `/home`

---

## 5. Domain Entities (source of truth)

### ProductEntity
```dart
id, name, description, imageUrl, additionalImages: List<String>
price: double, categoryId: String, subcategoryId: String?
stockStatus: StockStatus (inStock/outOfStock/preOrder)
availablePieces: int?, rating: double?, reviewCount: int
isPopular: bool
// Getters: isAvailable, hasLimitedStock, stockLabel
```

### CartEntity / CartItemEntity
```dart
CartItemEntity: id, product: ProductEntity, quantity: int
  // Getters: subtotal (price × qty)
CartEntity: items: List<CartItemEntity>
  // Getters: total (sum subtotals), itemCount (sum quantities), isEmpty
  // BADGE: always use items.length (distinct products), NOT itemCount
```

### OrderEntity
```dart
id, items, total, status: OrderStatus, createdAt: DateTime
deliveryAddress: AddressEntity, paymentMethod: PaymentMethod, notes: String?
// itemCount getter: sum of item quantities
```

**Enums:**
```dart
enum OrderStatus   { pending, confirmed, processing, shipped, delivered, cancelled }
enum PaymentMethod { wallet, cashOnDelivery, creditCard }
enum StockStatus   { inStock, outOfStock, preOrder }
// OrderStatus has .label extension (human-readable string)
```

**Cancel order is allowed when:**
```dart
status == OrderStatus.pending || status == OrderStatus.confirmed
```

### AddressEntity
```dart
street, city, state, country: String  (all required)
postalCode: String?
latitude: double?, longitude: double?    // set when picked from map
formattedAddress: String?                // Google Places full string
label: String?                           // e.g. "Home", "Work"
// Getters:
//   fullAddress → formattedAddress ?? "${street}, ${city}, ${state}, ${country} [postalCode]"
//   hasCoordinates → latitude != null && longitude != null
```

### UserEntity
```dart
id, name, email, phone: String
avatarUrl: String?, address: AddressEntity?, walletBalance: double
```

### AuthUserEntity (separate file)
```dart
uid, email: String, displayName: String?, photoUrl: String?
emailVerified: bool
```

---

## 6. BLoC Catalogue

### CatalogBloc
| Event | Result |
|---|---|
| `LoadCatalogEvent` | Fetches categories + popular in **parallel** (`Future.wait`) → single `CatalogLoaded` emit |
| `LoadProductsEvent(categoryId?, subcategoryId?)` | Updates `filteredProducts` on existing `CatalogLoaded` |
| `SearchProductsEvent(query)` | Updates `searchResults` on existing `CatalogLoaded` |
| `ClearSearchEvent` | Clears `searchResults` |

**States:** `CatalogInitial`, `CatalogLoading`, `CatalogLoaded`, `CatalogError`

`CatalogLoaded` holds: `categories`, `popularProducts`, `filteredProducts?`, `searchResults?`, `activeQuery?`

### CartBloc
| Event | Notes |
|---|---|
| `LoadCartEvent` | Loads from SharedPreferences |
| `AddToCartEvent(product, quantity=1)` | Creates new `CartItemEntity` with UUID id; if product already in cart, local DS merges quantities |
| `RemoveFromCartEvent(cartItemId)` | |
| `UpdateQuantityEvent(cartItemId, quantity)` | quantity ≤ 0 → triggers remove |
| `ClearCartEvent` | Used automatically by `PlaceOrderUseCase` on success |

**States:** `CartInitial`, `CartLoading`, `CartLoaded(cart)`, `CartError`

### OrdersBloc
| Event | Notes |
|---|---|
| `LoadOrdersEvent` | |
| `PlaceOrderEvent(cart, address, notes?, paymentMethod)` | Creates order with UUID, delegates to `PlaceOrderUseCase` (which also clears cart). After success: emits `OrderPlaced` then immediately `OrdersLoaded([placed, ...existing])` — **no second Loading flash** |
| `CancelOrderEvent(orderId)` | Only valid for pending/confirmed. Emits `OrderCancelled` then updates list in-place |

**States:** `OrdersInitial`, `OrdersLoading`, `OrdersLoaded(orders)`, `OrderPlaced(order)`, `OrderCancelled(orderId)`, `OrdersError`

### AuthBloc
| Event | Result |
|---|---|
| `CheckAuthEvent` | Loading → Authenticated or Unauthenticated |
| `LoginEvent(LoginParams)` | Loading → Authenticated or AuthError |
| `RegisterEvent(RegisterParams)` | Loading → Authenticated or AuthError |
| `LogoutEvent` | Loading → Unauthenticated |
| `ResetPasswordEvent(email)` | Loading → PasswordResetSent or AuthError |
| `AuthStateChangedEvent(user?)` | Updates state from Firebase stream subscription |

**States:** `AuthInitial`, `AuthLoading`, `Authenticated(user)`, `Unauthenticated`, `AuthError(message)`, `PasswordResetSent(email)`

### SettingsBloc
Persists to SharedPreferences. Keys: `settings_theme_mode`, `settings_notifications`, `settings_biometrics`, `settings_currency`, `settings_language`.

| Event | Notes |
|---|---|
| `LoadSettingsEvent` | Called on startup in DI |
| `ToggleThemeEvent(ThemeMode)` | `ThemeMode.light/dark/system` |
| `ToggleNotificationsEvent(bool)` | |
| `ToggleBiometricsEvent(bool)` | |
| `ChangeCurrencyEvent(String)` | e.g. 'USD', 'EGP', 'SAR' |
| `ChangeLanguageEvent(String)` | language code: 'en', 'ar' |

### UserBloc
Events: `LoadUserEvent`, `UpdateUserEvent(UserEntity)`, `RechargeWalletEvent(double)`
States: `UserInitial`, `UserLoading`, `UserLoaded(user)`, `UserError`

### FavoritesBloc
Events: `LoadFavoritesEvent`, `ToggleFavoriteEvent(ProductEntity)`
States: `FavoritesInitial`, `FavoritesLoaded(favorites)` — `isFavorite(id)` helper on state

### LocationPickerBloc
Events: `InitLocationEvent(initial?)`, `SearchAddressEvent(query)`, `SelectSuggestionEvent(suggestion)`, `MapPinMovedEvent(lat, lng)`, `UseCurrentLocationEvent`, `ClearSuggestionsEvent`

State: `LocationPickerState` with: `latitude, longitude, formattedAddress?, resolvedAddress?, suggestions, isSearching, isResolving, isLocatingDevice, error?`

---

## 7. Data Layer Details

### SharedPreferences Keys
```
'user_data'           → UserModel JSON
'cart_data'           → List<CartItemModel> JSON
'orders_data'         → List<OrderModel> JSON
'favorites_data'      → List<ProductModel> JSON
'catalog_categories'  → List<CategoryModel> JSON  (seed + Firebase cache)
'catalog_products'    → List<ProductModel> JSON   (seed + Firebase cache)
'settings_theme_mode' → 'light'|'dark'|'system'
'settings_notifications' → bool
'settings_biometrics' → bool
'settings_currency'   → String
'settings_language'   → String
```

**Critical:** `_getLocalUserId()` in `OrdersRepositoryImpl` reads `prefs.getString('user_data')` and parses the `id` field. This is used to scope Firestore orders queries to the logged-in user.

### CatalogLocalDataSourceImpl — seed behavior
- Constructor assigns `_ready = _seedIfEmpty()` (a `Future<void>`)
- `_seedIfEmpty()` only runs if `'catalog_categories'` key is absent from prefs
- All public methods `await _ready` before reading prefs
- **Never remove or comment out `_ready`** — this was the root cause of offline instability

### CatalogRepositoryImpl — remote vs local decision
```dart
Future<bool> _shouldUseRemote() async {
  if (remote == null) return false;
  final connected = await networkInfo.isConnected;
  return connected;  // online → Firebase always, offline → local always
}
// NO TTL. TTL caused constant flicker when set to 1 second.
// getPopularProducts caches result locally via local.cacheProducts(prods)
```

### NetworkInfo — HTTP probe (critical)
```dart
// Uses dart:io HttpClient, NOT InternetConnectionChecker
// Probes https://www.google.com and https://1.1.1.1 in parallel
// 5 second timeout. Returns true if ANY probe succeeds.
// InternetConnectionChecker is REMOVED from pubspec — do not add it back.
```

### Firebase Datasource — placeOrder signature
```dart
Future<OrderModel> placeOrder(OrderModel order, String userId)
// userId is stored as a field in the Firestore document
// Required for security rules: where('userId', isEqualTo: userId)
// Firestore Timestamps are converted to ISO strings before model parsing
```

---

## 8. Firestore Schema

```
/categories/{categoryId}
  name: string
  imageUrl: string
  subcategories: [{id, name, imageUrl, parentCategoryId}]

/products/{productId}
  name, description, imageUrl: string
  price: number
  categoryId: string, subcategoryId: string?
  stockStatus: 'inStock'|'outOfStock'|'preOrder'
  availablePieces: number?
  rating: number?, reviewCount: number
  isPopular: boolean

/orders/{orderId}
  userId: string          ← REQUIRED for security rules
  items: [{id, product:{...}, quantity}]
  total: number
  status: 'pending'|'confirmed'|'processing'|'shipped'|'delivered'|'cancelled'
  createdAt: Timestamp
  deliveryAddress: {street, city, state, country, postalCode?, latitude?, longitude?, formattedAddress?}
  paymentMethod: 'wallet'|'cashOnDelivery'|'creditCard'
  notes: string?

/users/{userId}
  name, email, phone: string
  avatarUrl: string?
  walletBalance: number
  address: {street, city, state, country, postalCode?, latitude?, longitude?, formattedAddress?}
```

---

## 9. Firebase Activation Checklist (NOT YET DONE)

When ready to activate Firebase, do these steps IN ORDER:

1. `flutterfire configure --project=YOUR_PROJECT_ID` → generates `lib/firebase_options.dart`
2. Place `google-services.json` → `android/app/`
3. Place `GoogleService-Info.plist` → `ios/Runner/` (via Xcode only, not file explorer)
4. In `lib/main.dart` uncomment:
   ```dart
   import 'package:firebase_core/firebase_core.dart';
   import 'firebase_options.dart';
   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
   ```
5. In `lib/core/di/injection_container.dart` uncomment the **FIREBASE WIRING** block and remove `_MockAuthRepository` class + its registration
6. Add Firestore security rules (see `docs/FIRESTORE_RULES.md` or below)
7. Seed Firestore: the local seed data in `CatalogLocalDataSourceImpl._seedProducts()` and `_seedCategories()` has the product catalog — write a one-time script to push it to Firestore

**Firestore security rules:**
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /categories/{id} { allow read: if true; allow write: if false; }
    match /products/{id}   { allow read: if true; allow write: if false; }
    match /users/{userId}  { allow read, write: if request.auth != null && request.auth.uid == userId; }
    match /orders/{orderId} {
      allow read, write: if request.auth != null && request.auth.uid == resource.data.userId;
      allow create: if request.auth != null;
    }
  }
}
```

---

## 10. Google Maps / Places Activation Checklist (NOT YET DONE)

1. Enable in Google Cloud Console: Maps SDK Android, Maps SDK iOS, Places API, Geocoding API
2. Create restricted API key
3. Set key in `lib/core/maps/maps_config.dart`: `static const String apiKey = 'YOUR_KEY';`
4. Add to `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <meta-data android:name="com.google.android.geo.API_KEY" android:value="YOUR_KEY"/>
   ```
5. Add to `ios/Runner/AppDelegate.swift`:
   ```swift
   GMSServices.provideAPIKey("YOUR_KEY")
   ```
6. Add to `pubspec.yaml` (not yet added — must be added manually):
   ```yaml
   google_maps_flutter: ^2.5.3
   geolocator: ^11.0.0
   ```
7. Add Android permissions to `AndroidManifest.xml`:
   ```xml
   <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
   <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
   ```
8. Add iOS permissions to `ios/Runner/Info.plist`:
   ```xml
   <key>NSLocationWhenInUseUsageDescription</key>
   <string>We need your location to deliver to you.</string>
   ```
9. **Before adding packages:** run `flutter pub get` and verify no conflicts

---

## 11. Key Known Bugs Fixed (do not re-introduce)

| Bug | What it was | Fix applied |
|---|---|---|
| Products unstable offline | `_ready` and seed calls were commented out in `CatalogLocalDataSourceImpl` | Restored `_ready = _seedIfEmpty()` in constructor; restored seed calls |
| Popular products not cached offline | `getPopularProducts()` fetched from Firebase but never stored locally | Added `await local.cacheProducts(prods)` after remote fetch |
| Firebase never reached despite internet | `InternetConnectionChecker` used TCP socket to `8.8.8.8:53` — firewalled on Android | Replaced with `dart:io HttpClient` HTTP HEAD probe |
| Catalog flickered / disappeared | TTL was `Duration(seconds: 1)` — cache expired every second causing constant refetch | Removed TTL entirely; `_shouldUseRemote` now just `return connected` |
| Catalog double-emit flicker | `_onLoad` called `getCategories` then `getPopular` sequentially (2 rebuilds) | Changed to `Future.wait([...])` — single emit |
| Orders badge showed cart count | Shell page used `CartBloc.itemCount` on the Orders tab | Removed badge from Orders tab; only Favorites tab has a badge |
| Cart badge wrong number | Used `cart.itemCount` (total qty) instead of `cart.items.length` (distinct products) | Changed to `items.length` everywhere |
| Orders empty after placing | `OrderPlaced` → `LoadOrdersEvent` → second `Loading` flash | After `OrderPlaced`, optimistically prepend to list, no reload |
| Checkout spinner flash | `BlocConsumer.buildWhen` was missing; background `OrdersLoaded` triggered rebuild | Added `buildWhen`; local `_placing` bool drives spinner instead of bloc state |
| Orders not sent to Firebase | `OrdersRepositoryImpl.placeOrder` only called local | Now calls `remote!.placeOrder(model, userId)` when connected |
| `_getLocalUserId()` always null | Was a stub returning null | Reads `prefs.getString('user_data')` and parses JSON `id` field |
| `placeOrder` signature mismatch | Repo called `remote.placeOrder(model)`, datasource needed `(model, userId)` | Both fixed to accept `(OrderModel, String userId)` |

---

## 12. Current Feature Status

| Feature | Status | Notes |
|---|---|---|
| Home + categories strip | ✅ Working | Offline seed + Firebase when online |
| Popular products | ✅ Working | Cached locally after remote fetch |
| Category → subcategory → products | ✅ Working | |
| Search (autocomplete) | ✅ Local | Firebase prefix search when online |
| Product detail | ✅ Working | Image gallery, quantity picker |
| Add to cart | ✅ Working | Distinct product badge |
| Checkout | ✅ Working | Address picker integrated |
| Delivery address — map picker | ✅ Built | Requires `google_maps_flutter` + `geolocator` in pubspec + API key |
| Delivery address — manual entry + autocomplete | ✅ Built | Uses `PlacesService` REST, requires API key |
| Order placement | ✅ Working | Local + Firebase when connected |
| Cancel order | ✅ Working | pending/confirmed only; updates list in-place |
| Order detail + stepper | ✅ Working | |
| Profile page | ✅ Working | Stats, wallet, favorites preview, recent orders, logout |
| Edit profile | ✅ Working | All fields + address |
| Wallet recharge | ✅ Simulated | Online payment not implemented |
| Favorites | ✅ Working | Local only |
| Settings | ✅ Working | Theme persisted, notifications, biometrics, currency, language |
| Dark mode | ✅ Working | Driven by SettingsBloc |
| Firebase Auth | 🔲 Mocked | `_MockAuthRepository` returns Unauthenticated always |
| Firebase Firestore | 🔲 Commented out | DI block ready to uncomment |
| Google Maps | 🔲 API key needed | All Dart code written; pubspec packages not added yet |
| Push notifications | 🔲 Not started | |
| Payment gateway | 🔲 Not started | |
| Admin panel | 🔲 Not started | |
| Order tracking (real-time) | 🔲 Not started | Would use Firestore onSnapshot stream |

---

## 13. DI Registration Order (critical — do not reorder)

```dart
// 1. SharedPreferences (singleton, awaited)
// 2. Dio, NetworkInfo
// 3. All local datasources
// 4. [COMMENTED] Firebase datasources
// 5. AuthRepository (mock until Firebase)
// 6. CatalogRepository (no prefs param — TTL removed)
// 7. CartRepository, OrdersRepository (needs prefs + networkInfo), UserRepository, FavoritesRepository
// 8. All use cases (depends on repositories)
// 9. BLoCs as factories (except SettingsBloc — lazy singleton, started in init)
```

**OrdersRepositoryImpl requires:**
```dart
OrdersRepositoryImpl(local: sl(), networkInfo: sl(), prefs: sl(), remote: sl()?) 
```

**CatalogRepositoryImpl requires:**
```dart
CatalogRepositoryImpl(local: sl(), networkInfo: sl(), remote: sl()?)
// No prefs param — TTL was removed
```

---

## 14. MultiBlocProvider Order in main.dart (critical)

```dart
// AuthBloc MUST be first — router notifier subscribes to it
BlocProvider(create: (_) => sl<AuthBloc>()..add(CheckAuthEvent())),
BlocProvider(create: (_) => sl<SettingsBloc>()),   // drives themeMode
BlocProvider(create: (_) => sl<UserBloc>()..add(LoadUserEvent())),
BlocProvider(create: (_) => sl<CatalogBloc>()..add(LoadCatalogEvent())),
BlocProvider(create: (_) => sl<CartBloc>()..add(LoadCartEvent())),
BlocProvider(create: (_) => sl<FavoritesBloc>()..add(LoadFavoritesEvent())),
BlocProvider(create: (_) => sl<OrdersBloc>()..add(LoadOrdersEvent())),
```

**Auth listener must wrap MaterialApp.router:**
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

## 15. UI Patterns — Always Follow These

### Cards
```dart
AppCard(child: ..., padding: ..., onTap: ..., radius: ...)
// Never use Card widget directly
```

### Snackbars
```dart
AppSnackBar.success(context, 'message');
AppSnackBar.error(context, 'message');
AppSnackBar.info(context, 'message');
```

### Empty states
```dart
EmptyState(emoji: '📦', title: 'No orders yet', subtitle: '...', actionLabel: '...', onAction: ...)
```

### Images (always use shimmer)
```dart
ShimmerImage(url: url, width: 68, height: 68, borderRadius: ..., fit: BoxFit.cover)
```

### Price
```dart
PriceTag(price: product.price, fontSize: 15)
```

### Loading skeletons
```dart
GridShimmer(count: 6)  // for product grids
CircularProgressIndicator(color: AppColors.primary)  // for full screens
LinearProgressIndicator(minHeight: 2)  // inline
```

### Responsive breakpoints
```dart
final isSmallDevice = MediaQuery.of(context).size.width < 360 
                   || MediaQuery.of(context).size.height < 600;
// Use isSmallDevice to scale padding, font sizes, button heights
```

### BLoC in pages — standard pattern
```dart
// For list pages:
BlocBuilder<XBloc, XState>(
  buildWhen: (prev, cur) => cur is XLoaded || cur is XLoading || cur is XError,
  builder: (context, state) { ... }
)

// For pages with side-effects (navigation, snackbars):
BlocConsumer<XBloc, XState>(
  listener: (ctx, state) { /* navigate, show snackbar */ },
  buildWhen: (p, c) => /* only states that change UI */,
  builder: (ctx, state) { ... }
)
```

---

## 16. Checkout Address Flow (newly built)

The checkout page holds `_orderAddress: AddressEntity?` in state. This is separate from the user's saved profile address and is used only for the current order.

**Flow:**
1. On first build, `_orderAddress` is initialized from `UserBloc` state (profile address)
2. User can tap **"Pick on Map"** → pushes `/location-picker` → returns `LocationPickerResult` via `context.push<LocationPickerResult>(...)` → updates `_orderAddress`
3. User can tap **"Edit"** / **"Enter Manually"** → opens `_ManualAddressSheet` bottom sheet
4. Manual sheet has: Google Places Autocomplete search field (fills all fields automatically) + individual text fields for street/city/state/country/postal
5. `_confirm()` uses `_orderAddress` (not profile address) for the order

**`LocationPickerPage`** accepts `AddressEntity? initialAddress` as `extra` in route.
Returns `LocationPickerResult(address)` via `Navigator.of(context).pop(result)`.

**`PlacesService`** (in `lib/core/maps/places_service.dart`):
- `autocomplete(query)` → `List<PlaceSuggestion>`
- `getPlaceDetails(placeId)` → `PlaceDetails?` (lat/lng + structured address)
- `reverseGeocode(lat, lng)` → `PlaceDetails?`
- Uses `Dio` for REST calls — no extra package needed
- Falls back gracefully (returns empty/null) if API key not configured

---

## 17. Seed Product Catalog (15 products across 6 categories)

Categories: Electronics (Phones, Laptops, Audio), Fashion (Men's, Women's), Home & Living (Furniture, Kitchen), Sports (Fitness, Outdoor), Beauty, Books

Products include: iPhone 15 Pro, Samsung Galaxy S24, MacBook Pro, Sony WH-1000XM5, AirPods Pro, Classic Linen Shirt, Floral Wrap Dress, Ergonomic Office Chair, Smart Coffee Maker, Yoga Mat Pro, Adjustable Dumbbells, Vitamin C Serum, Wireless Hair Dryer, Atomic Habits, Clean Code.

All images use Unsplash URLs (free, no key needed).

---

## 18. Test Files

Location: `test/blocs/` and `test/domain/`

| File | Coverage |
|---|---|
| `test/blocs/auth_bloc_test.dart` | CheckAuth, Login, Register, Logout, ResetPassword |
| `test/blocs/orders_bloc_test.dart` | LoadOrders, PlaceOrder (no flash), CancelOrder |
| `test/blocs/settings_bloc_test.dart` | Load, ToggleTheme, Notifications, Currency |
| `test/domain/catalog_usecases_test.dart` | GetCategories, GetPopular, Search, GetProducts |
| `test/domain/cart_orders_usecases_test.dart` | CartEntity logic, AddToCart, PlaceOrder (clears cart), CancelOrder |
| `test/domain/entity_tests.dart` | ProductEntity, AddressEntity, UserEntity, OrderStatus, JSON round-trip |

Run: `flutter test`

---

## 19. Files That Must Never Be Modified Without Reading First

| File | Why |
|---|---|
| `lib/core/di/injection_container.dart` | DI order matters; Firebase block must stay commented until step-by-step activation |
| `lib/data/datasources/local/local_datasources.dart` | `_ready` and seed calls are critical for offline stability |
| `lib/core/network/network_info.dart` | Must use HTTP probe, not `InternetConnectionChecker` |
| `lib/data/repositories/repositories_impl.dart` | `_shouldUseRemote` must be simple connection check; `OrdersRepositoryImpl` needs `prefs` for userId |
| `lib/core/router/app_router.dart` | Auth redirect guard logic is delicate; `_AuthNotifier` must match all auth states |
| `lib/main.dart` | BLoC provider order matters; auth listener must wrap MaterialApp |

---

## 20. Outstanding TODOs (next work items)

1. **Add `google_maps_flutter` and `geolocator` to pubspec.yaml** — these are required by `LocationPickerPage` but not yet in the pubspec
2. **Activate Firebase** — follow the checklist in section 9
3. **Activate Google Maps** — follow the checklist in section 10
4. **Wire `LocationPickerBloc` into DI** — currently instantiated inline in `LocationPickerPage`; for consistency should be registered in `injection_container.dart`
5. **User avatar upload** — `image_picker` is in pubspec but the upload logic (to Firebase Storage) is not implemented
6. **Real-time order status updates** — use `FirebaseFirestore.instance.collection('orders').doc(id).snapshots()` stream
7. **Push notifications** — add `firebase_messaging`
8. **Payment gateway** — placeholder exists in UI (credit card option is disabled)
9. **Arabic localization** — `intl` package is present; `ChangeLanguageEvent` is wired; actual string translation not done
10. **Production Firestore security rules** — test-mode rules expire after 30 days
