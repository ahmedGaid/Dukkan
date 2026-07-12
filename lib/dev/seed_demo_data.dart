// Dev-only seed script — NOT part of the shipping app (nothing under lib/dev
// is imported from lib/main.dart). Writes the full demo dataset to Firestore:
// 1 owner (7 shops, ~53 products, 2 shop collections), 2 couriers (real
// Firebase Auth accounts so they can actually log in and see deliveries),
// and 3 customers (real accounts, profiles, favorites, and orders spanning
// every OrderStatus) — plus the seed-managed taxonomy/areas/config.
//
// Firebase plugins need Flutter engine bindings, so this can't run as a plain
// `dart run` — it's a second Flutter entrypoint instead:
//   flutter run -t lib/dev/seed_demo_data.dart -d <device>
//
// Idempotent: every id (shops/products/drivers-by-uid/orders) is fixed, so
// re-running overwrites the same docs instead of duplicating them. Requires
// `firestore.rules`'s /categories, /areas, /drivers, /config, /roles, /admins
// `write: false` lines temporarily relaxed to `allow write: if isSignedIn();`
// for the pass (then restored) — /shops, /products, /users, /orders,
// /collections need no relax since their normal rules already permit the
// owner/courier/customer writes this script does while signed in as each of
// those accounts.
//
// Demo accounts (all created on first run, password same across each role):
//   owner@dukkan.dev / owner123        — owns all 7 shops
//   courier1@dukkan.dev / courier123   — online, active, Abu Atwa + El Sheikh Zayed
//   courier2@dukkan.dev / courier123   — offline, suspended (tests the blocked state)
//   customer1@dukkan.dev / customer123
//   customer2@dukkan.dev / customer123
//   customer3@dukkan.dev / customer123
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../core/config/app_config.dart';
import '../domain/admin/entities/permissions.dart';
import '../firebase_options.dart';

const _seedEmail = 'owner@dukkan.dev';
const _seedPassword = 'owner123';

const _couriers = <Map<String, Object>>[
  {
    'email': 'courier1@dukkan.dev',
    'password': 'courier123',
    'name': 'كريم عبد العزيز',
    'phone': '01011111111',
    'areaIds': ['abu-atwa', 'el-sheikh-zayed'],
    'maxActiveOrders': 5,
    'isOnline': true,
    'isSuspended': false,
  },
  {
    'email': 'courier2@dukkan.dev',
    'password': 'courier123',
    'name': 'محمود سعيد',
    'phone': '01022222222',
    'areaIds': ['downtown-ismailia'],
    'maxActiveOrders': 5,
    'isOnline': false,
    'isSuspended': true,
  },
];

const _customers = <Map<String, String>>[
  {
    'email': 'customer1@dukkan.dev',
    'password': 'customer123',
    'name': 'أحمد',
    'phone': '01011112222',
  },
  {
    'email': 'customer2@dukkan.dev',
    'password': 'customer123',
    'name': 'مريم',
    'phone': '01022223333',
  },
  {
    'email': 'customer3@dukkan.dev',
    'password': 'customer123',
    'name': 'يوسف',
    'phone': '01033334444',
  },
];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const _SeedApp());

  final log = StringBuffer();
  try {
    // Phase 1 — couriers: real Firebase Auth accounts, signed in as
    // themselves to write their own /users profile (rules gate /users
    // create to isSelf). The driver doc (phase 2) is keyed by this same uid
    // so logging in as courier1@dukkan.dev opens straight onto their
    // deliveries.
    final courierUids = <String>[];
    for (final courier in _couriers) {
      await FirebaseAuth.instance.signOut();
      final uid = await _signInOrCreate(
        courier['email'] as String,
        courier['password'] as String,
      );
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': courier['name'],
        'email': courier['email'],
        'role': 'courier',
        'phone': courier['phone'],
        'createdAt': FieldValue.serverTimestamp(),
      });
      courierUids.add(uid);
      log.writeln('Courier ${courier['email']} -> $uid');
    }

    // Phase 2 — owner: catalog (shops + products + collections) + driver
    // docs (keyed by the real courier uids from phase 1) + taxonomy/areas/
    // config, all written while signed in as the seed owner.
    await FirebaseAuth.instance.signOut();
    final ownerUid = await _signInOrCreate(_seedEmail, _seedPassword);
    log.writeln('Signed in as seed owner ($ownerUid).');
    await _seed(ownerUid, courierUids, log);

    // Phase 3 — customers: each signs in as themselves (rules gate /orders
    // create to isSelf(customerUid)) and gets a profile + favorites + a full
    // spread of orders across every status, some assigned to courier1.
    final courier1Uid = courierUids.first;
    for (var i = 0; i < _customers.length; i++) {
      final customer = _customers[i];
      await FirebaseAuth.instance.signOut();
      final uid = await _signInOrCreate(
        customer['email']!,
        customer['password']!,
      );
      await _seedCustomer(uid, customer, i, ownerUid, courier1Uid, log);
    }

    // Don't leave the device authenticated as a seed account — otherwise the
    // next launch of the real app opens as the last seeded customer instead
    // of whoever was signed in before. Sign out so the app returns to login.
    await FirebaseAuth.instance.signOut();

    log.writeln('Seed complete. Signed out — log in as your own account.');
  } catch (e) {
    log.writeln('Seed FAILED: $e');
  }
  _SeedApp.log.value = log.toString();
}

Future<String> _signInOrCreate(String email, String password) async {
  final auth = FirebaseAuth.instance;
  try {
    final cred = await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred.user!.uid;
  } on FirebaseAuthException catch (e) {
    if (e.code != 'user-not-found' && e.code != 'invalid-credential') rethrow;
    final cred = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred.user!.uid;
  }
}

Future<void> _seed(
  String ownerUid,
  List<String> courierUids,
  StringBuffer log,
) async {
  final firestore = FirebaseFirestore.instance;

  // The owner's own /users profile — so logging in as the seed owner lands on
  // the owner UI (order desk) instead of falling back to a customer.
  await firestore.collection('users').doc(ownerUid).set({
    'name': 'Owner',
    'email': _seedEmail,
    'role': 'owner',
    'phone': '01000000000',
    'createdAt': FieldValue.serverTimestamp(),
  });

  // Shops must land in their own commit BEFORE products: the /products create
  // rule does a get() on the parent shop to verify ownership, and rules never
  // see other writes from the same atomic batch — so a single combined batch
  // would fail permission-denied on every product.
  final shopBatch = firestore.batch();
  for (final shop in _demoShops(ownerUid)) {
    shopBatch.set(firestore.collection('shops').doc(shop['id'] as String), shop);
  }
  await shopBatch.commit();

  final productBatch = firestore.batch();
  for (final product in _demoProducts()) {
    productBatch.set(
      firestore.collection('products').doc(product['id'] as String),
      product,
    );
  }
  await productBatch.commit();

  await _seedShopCollections(firestore);
  await _seedTaxonomy(firestore);
  await _seedAreas(firestore);
  await _seedDrivers(firestore, courierUids);
  await _seedPlatformConfig(firestore);
  await _seedRbac(firestore);

  log.writeln('Wrote ${_demoShops(ownerUid).length} shops, '
      '${_demoProducts().length} products, ${_shopCollections.length} shop '
      'collections, ${_taxonomy.length} categories, ${_areas.length} areas, '
      '${courierUids.length} couriers, the platform config, 4 roles, and the '
      'founder admin.');
}

/// `/shops/{shopId}/collections` (M6) — owner-curated product groupings.
/// Rules require `ownsThisShop()`, which the seed owner satisfies directly
/// (no relax needed, unlike taxonomy/areas/drivers). Only `shop_demo_1` gets
/// collections for the demo; a few of its products carry matching
/// `collectionIds` (see `_demoProducts`).
Future<void> _seedShopCollections(FirebaseFirestore firestore) async {
  final batch = firestore.batch();
  for (final collection in _shopCollections) {
    batch.set(
      firestore
          .collection('shops')
          .doc('shop_demo_1')
          .collection('collections')
          .doc(collection['id'] as String),
      {
        'nameAr': collection['nameAr'],
        'nameEn': collection['nameEn'],
        'sort': collection['sort'],
        'createdAt': FieldValue.serverTimestamp(),
      },
    );
  }
  await batch.commit();
}

final _shopCollections = <Map<String, dynamic>>[
  {'id': 'col_deals', 'nameAr': 'عروض اليوم', 'nameEn': "Today's Deals", 'sort': 1},
  {'id': 'col_essentials', 'nameAr': 'أساسيات', 'nameEn': 'Essentials', 'sort': 2},
];

/// `/config/platform` (M12) — founder-managed commission/fee rates;
/// `firestore.rules` denies all client writes (`allow write: if false`),
/// same relax-then-restore trick as `_seedTaxonomy`. 5% commission, 30 EGP
/// delivery fee with 25 EGP going to the driver (5 EGP platform share).
Future<void> _seedPlatformConfig(FirebaseFirestore firestore) async {
  await firestore.collection('config').doc('platform').set({
    'commissionBps': 500,
    'deliveryFeeMinor': 3000,
    'driverDeliveryShareMinor': 2500,
  });
}

/// `/roles` + `/admins` (Founder Console session 1) — the four role permission
/// sets and the founder's own admin doc. `firestore.rules` denies all client
/// writes to both (`allow write: if false`), so this needs the same relax-
/// then-restore pass as `_seedTaxonomy`. Permission strings come from
/// [Permissions] so the three sources (constants / rules / seed) stay in sync;
/// the founder gets the `*` wildcard and rank 100. Runs in the owner-signed-in
/// phase — the writes only work because the rules are relaxed, not because the
/// owner is staff.
Future<void> _seedRbac(FirebaseFirestore firestore) async {
  final batch = firestore.batch();

  batch.set(firestore.collection('roles').doc('founder'), {
    'permissions': [Permissions.all],
    'rank': 100,
  });
  batch.set(firestore.collection('roles').doc('admin'), {
    'permissions': _adminPermissions,
    'rank': 80,
  });
  batch.set(firestore.collection('roles').doc('moderator'), {
    'permissions': _moderatorPermissions,
    'rank': 60,
  });
  batch.set(firestore.collection('roles').doc('support'), {
    'permissions': _supportPermissions,
    'rank': 40,
  });

  batch.set(firestore.collection('admins').doc(AppConfig.founderUid), {
    'role': 'founder',
    'permissions': [Permissions.all],
    'isActive': true,
    'rank': 100,
    'createdAt': FieldValue.serverTimestamp(),
  });

  await batch.commit();
}

// admin = everything except the three founder-reserved powers (managing other
// admins, impersonation, platform settings).
const _adminPermissions = <String>[
  Permissions.usersRead,
  Permissions.usersCreate,
  Permissions.usersUpdate,
  Permissions.usersDelete,
  Permissions.shopsUpdate,
  Permissions.shopsTransfer,
  Permissions.productsCreate,
  Permissions.productsUpdate,
  Permissions.productsDelete,
  Permissions.ordersRead,
  Permissions.ordersUpdate,
  Permissions.ordersForceStatus,
  Permissions.ordersAssignDriver,
  Permissions.driversManage,
  Permissions.taxonomyEdit,
  Permissions.geoEdit,
  Permissions.financeRead,
  Permissions.notificationsSend,
  Permissions.promosEdit,
  Permissions.reportsExport,
  Permissions.imagesDelete,
  Permissions.auditlogsRead,
  Permissions.systemTools,
];

// moderator = day-to-day content + order handling, no destructive/staff powers.
const _moderatorPermissions = <String>[
  Permissions.shopsUpdate,
  Permissions.productsUpdate,
  Permissions.taxonomyEdit,
  Permissions.ordersRead,
  Permissions.ordersUpdate,
];

// support = read users, read + nudge orders.
const _supportPermissions = <String>[
  Permissions.usersRead,
  Permissions.ordersRead,
  Permissions.ordersUpdate,
];

/// `/categories` (M3) — fixed, seed-managed tree; `firestore.rules` denies
/// all client writes to this collection (`allow write: if false`), so this
/// step only succeeds if that line is temporarily relaxed to
/// `allow write: if isSignedIn();` for the re-seed, then restored. Top-level
/// ids are the SAME Arabic strings already used as `Shop.categories` /
/// `Product.category` (see `_demoShops`/`_demoProducts` below), so existing
/// home-chip filtering keeps matching without a translation table.
Future<void> _seedTaxonomy(FirebaseFirestore firestore) async {
  final batch = firestore.batch();
  for (final category in _taxonomy) {
    batch.set(
      firestore.collection('categories').doc(category['id'] as String),
      {
        'nameAr': category['nameAr'],
        'nameEn': category['nameEn'],
        'sort': category['sort'],
        'subcategories': category['subcategories'],
      },
    );
  }
  await batch.commit();
}

/// `/areas` (M8) — fixed, seed-managed delivery districts; `firestore.rules`
/// denies all client writes (`allow write: if false`), same relax-then-
/// restore trick as `_seedTaxonomy`. Ismailia / Abu Atwa districts — matches
/// where the 3 real seeded shops (`shop_demo_5/6/7`) actually sit.
Future<void> _seedAreas(FirebaseFirestore firestore) async {
  final batch = firestore.batch();
  for (final area in _areas) {
    batch.set(
      firestore.collection('areas').doc(area['id'] as String),
      {
        'nameAr': area['nameAr'],
        'nameEn': area['nameEn'],
        'sort': area['sort'],
      },
    );
  }
  await batch.commit();
}

final _areas = <Map<String, dynamic>>[
  {'id': 'abu-atwa', 'nameAr': 'أبو عطوة', 'nameEn': 'Abu Atwa', 'sort': 1},
  {
    'id': 'el-sheikh-zayed',
    'nameAr': 'الشيخ زايد',
    'nameEn': 'El Sheikh Zayed',
    'sort': 2,
  },
  {
    'id': 'downtown-ismailia',
    'nameAr': 'وسط البلد',
    'nameEn': 'Downtown Ismailia',
    'sort': 3,
  },
  {'id': 'el-salam', 'nameAr': 'السلام', 'nameEn': 'El Salam', 'sort': 4},
  {'id': 'el-quds', 'nameAr': 'القدس', 'nameEn': 'El Quds', 'sort': 5},
];

/// `/drivers` (M8) demo profiles — doc id IS the courier's real Firebase Auth
/// uid (phase 1), so logging in as `courier1@dukkan.dev` opens straight onto
/// that same driver's deliveries. `firestore.rules` restricts `create` to
/// `isSelf(uid)` with `isSuspended == true` pinned, which even a driver's own
/// signup can't satisfy for the active case — so, same as `_seedTaxonomy`,
/// this only succeeds with `/drivers`'s `write: false` temporarily relaxed to
/// `isSignedIn()`. Written while signed in as the owner (any signed-in user
/// works under the relaxed rule).
Future<void> _seedDrivers(
  FirebaseFirestore firestore,
  List<String> courierUids,
) async {
  final batch = firestore.batch();
  for (var i = 0; i < _couriers.length; i++) {
    final courier = _couriers[i];
    batch.set(
      firestore.collection('drivers').doc(courierUids[i]),
      {
        'name': courier['name'],
        'phone': courier['phone'],
        'areaIds': courier['areaIds'],
        'maxActiveOrders': courier['maxActiveOrders'],
        'activeOrdersCount': 0,
        'isOnline': courier['isOnline'],
        'isSuspended': courier['isSuspended'],
        'createdAt': FieldValue.serverTimestamp(),
      },
    );
  }
  await batch.commit();
}

Map<String, dynamic> _subcat(String id, String nameAr, String nameEn) =>
    {'id': id, 'nameAr': nameAr, 'nameEn': nameEn};

final _taxonomy = <Map<String, dynamic>>[
  {
    'id': 'خضروات وفواكه',
    'nameAr': 'خضروات وفواكه',
    'nameEn': 'Vegetables & Fruits',
    'sort': 1,
    'subcategories': [
      _subcat('fruits', 'فواكه', 'Fruits'),
      _subcat('vegetables', 'خضروات', 'Vegetables'),
    ],
  },
  {
    'id': 'ألبان',
    'nameAr': 'ألبان',
    'nameEn': 'Dairy',
    'sort': 2,
    'subcategories': [
      _subcat('milk', 'لبن', 'Milk'),
      _subcat('cheese', 'جبن', 'Cheese'),
      _subcat('yogurt', 'زبادي', 'Yogurt'),
      _subcat('butter', 'زبدة', 'Butter'),
      _subcat('eggs', 'بيض', 'Eggs'),
    ],
  },
  {
    'id': 'مشروبات',
    'nameAr': 'مشروبات',
    'nameEn': 'Drinks',
    'sort': 3,
    'subcategories': [
      _subcat('juice', 'عصير', 'Juice'),
      _subcat('water', 'مياه', 'Water'),
      _subcat('soda', 'مشروبات غازية', 'Soda'),
      _subcat('energyDrinks', 'مشروبات طاقة', 'Energy Drinks'),
      _subcat('icedTea', 'شاي مثلج', 'Iced Tea'),
    ],
  },
  {
    'id': 'معلبات',
    'nameAr': 'معلبات',
    'nameEn': 'Canned & Pantry',
    'sort': 4,
    'subcategories': [
      _subcat('oils', 'زيوت', 'Oils'),
      _subcat('rice', 'أرز', 'Rice'),
      _subcat('tuna', 'تونة', 'Tuna'),
      _subcat('beans', 'فول', 'Fava Beans'),
    ],
  },
  {
    'id': 'مخبوزات',
    'nameAr': 'مخبوزات',
    'nameEn': 'Bakery',
    'sort': 5,
    'subcategories': [
      _subcat('baladiBread', 'عيش بلدي', 'Baladi Bread'),
      _subcat('toastBread', 'توست', 'Toast Bread'),
      _subcat('croissant', 'كرواسون', 'Croissant'),
      _subcat('finoBread', 'عيش فينو', 'Fino Bread'),
      _subcat('rusk', 'بقسماط', 'Rusk'),
    ],
  },
  {
    'id': 'لحوم ودواجن',
    'nameAr': 'لحوم ودواجن',
    'nameEn': 'Meat & Poultry',
    'sort': 6,
    'subcategories': [
      _subcat('chicken', 'دجاج', 'Chicken'),
      _subcat('mincedMeat', 'لحمة مفرومة', 'Minced Meat'),
      _subcat('kofta', 'كفتة', 'Kofta'),
    ],
  },
  {
    'id': 'منظفات',
    'nameAr': 'منظفات',
    'nameEn': 'Cleaning',
    'sort': 7,
    'subcategories': [
      _subcat('dishSoap', 'سائل جلي', 'Dish Soap'),
      _subcat('laundryPowder', 'مسحوق غسيل', 'Laundry Powder'),
      _subcat('floorCleaner', 'منظف أرضيات', 'Floor Cleaner'),
      _subcat('tissues', 'مناديل', 'Tissues'),
    ],
  },
];

/// Customer-side demo: profile (with favorites) + a spread of orders. Runs
/// while signed in AS the customer (rules gate /users and /orders create to
/// isSelf). `index` (0/1/2) picks a distinct favorites set and order slice
/// from `_demoOrders` so the 3 demo customers don't look identical, and
/// together their orders cover every `OrderStatus`.
final _favoritesByCustomer = <List<List<String>>>[
  [
    ['shop_demo_1', 'shop_demo_5'],
    ['p1', 'p5', 'p33', 'p36'],
  ],
  [
    ['shop_demo_2', 'shop_demo_6'],
    ['p13', 'p20', 'p41', 'p45'],
  ],
  [
    ['shop_demo_3', 'shop_demo_7'],
    ['p22', 'p23', 'p48', 'p52'],
  ],
];

Future<void> _seedCustomer(
  String customerUid,
  Map<String, String> customer,
  int index,
  String ownerUid,
  String courier1Uid,
  StringBuffer log,
) async {
  final firestore = FirebaseFirestore.instance;
  final favorites = _favoritesByCustomer[index];

  await firestore.collection('users').doc(customerUid).set({
    'name': customer['name'],
    'email': customer['email'],
    'role': 'customer',
    'phone': customer['phone'],
    'favoriteShopIds': favorites[0],
    'favoriteProductIds': favorites[1],
    'createdAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  final orders = _demoOrders(customerUid, index, ownerUid, courier1Uid);
  for (final order in orders) {
    await firestore.collection('orders').doc(order['id'] as String).set(order);
  }

  log.writeln('Customer ${customer['email']}: profile + '
      '${favorites[1].length} favorites + ${orders.length} orders.');
}

List<Map<String, dynamic>> _demoShops(String ownerUid) => [
      {
        'id': 'shop_demo_1',
        'ownerUid': ownerUid,
        'name': 'Al Nour Grocery',
        'nameAr': 'بقالة النور',
        'address': '12 شارع الجمهورية، وسط البلد، القاهرة',
        'isOpen': true,
        'categories': ['خضروات وفواكه', 'ألبان', 'مشروبات', 'معلبات'],
        'logoUrl': 'assets/shops/grocery.png',
        'ratingSum': 44, // 10 votes, ~4.4 avg
        'ratingCount': 10,
      },
      {
        'id': 'shop_demo_2',
        'ownerUid': ownerUid,
        'name': 'Al Amal Supermarket',
        'nameAr': 'سوبر ماركت الأمل',
        'address': '45 شارع النصر، مدينة نصر، القاهرة',
        'isOpen': true,
        'categories': ['مخبوزات', 'لحوم ودواجن', 'منظفات', 'مشروبات'],
        'logoUrl': 'assets/shops/bakery.png',
        'ratingSum': 33, // 7 votes, ~4.7 avg
        'ratingCount': 7,
      },
      {
        'id': 'shop_demo_3',
        'ownerUid': ownerUid,
        'name': 'Green Basket',
        'nameAr': 'السلة الخضراء',
        'address': '8 شارع مصدق، الدقي، الجيزة',
        'isOpen': true,
        'categories': ['خضروات وفواكه', 'ألبان', 'معلبات'],
        'logoUrl': 'assets/shops/vege.png',
        'ratingSum': 19, // 4 votes, ~4.8 avg
        'ratingCount': 4,
      },
      {
        'id': 'shop_demo_4',
        'ownerUid': ownerUid,
        'name': 'City Market',
        'nameAr': 'ماركت المدينة',
        'address': '120 شارع الهرم، الجيزة',
        'isOpen': false, // closed — shows the "مغلق" state
        'categories': ['مشروبات', 'منظفات', 'معلبات', 'مخبوزات'],
        'logoUrl': 'assets/shops/drinks.png',
        'ratingSum': 21, // 6 votes, ~3.5 avg
        'ratingCount': 6,
      },
      // Real Ismailia / Abu Atwa neighborhood shops.
      {
        'id': 'shop_demo_5',
        'ownerUid': ownerUid,
        'name': 'Othman',
        'nameAr': 'عثمان',
        'address': 'الشارع التجاري، أبوعطوة، الإسماعيلية',
        'isOpen': true,
        'categories': ['خضروات وفواكه', 'ألبان', 'مشروبات', 'معلبات', 'منظفات'],
        'logoUrl': 'assets/shops/general.png',
        'ratingSum': 47, // 10 votes, ~4.7 avg
        'ratingCount': 10,
      },
      {
        'id': 'shop_demo_6',
        'ownerUid': ownerUid,
        'name': 'Al Tawheed',
        'nameAr': 'التوحيد',
        'address': 'الشارع التجاري، أبوعطوة، الإسماعيلية',
        'isOpen': true,
        'categories': ['مشروبات', 'معلبات', 'مخبوزات', 'منظفات'],
        'logoUrl': 'assets/shops/cleaning.png',
        'ratingSum': 40, // 9 votes, ~4.4 avg
        'ratingCount': 9,
      },
      {
        'id': 'shop_demo_7',
        'ownerUid': ownerUid,
        'name': 'El Semti',
        'nameAr': 'السمطي',
        'address': 'الزغابة، أمام فرن عبد الحي، أبوعطوة، الإسماعيلية',
        'isOpen': true,
        'categories': ['خضروات وفواكه', 'لحوم ودواجن', 'ألبان', 'مخبوزات'],
        'logoUrl': 'assets/shops/meat.png',
        'ratingSum': 23, // 5 votes, ~4.6 avg
        'ratingCount': 5,
      },
    ];

/// A clean flat food illustration from Servier Medical Art (SMART), a
/// CC-licensed set hosted on Wikimedia Commons. [subject] is the SMART food
/// name, e.g. 'Tomato' → `File:Food - Tomato -- Smart-Servier.png`. Returns null
/// for products SMART has no illustration for (cucumber, apple, onion,
/// croissant, and the non-food household items) — those tiles fall back to
/// ShimmerImage's branded glyph.
///
/// The Wikimedia file is routed through the weserv image CDN rather than
/// hotlinked directly: weserv fetches the PNG once, caches it on Cloudflare, and
/// serves every later request from cache. Hotlinking Wikimedia directly fails in
/// practice — a catalog loading ~40 tiles at once trips Wikimedia's bulk-request
/// rate limit (HTTP 429 → blank tiles); weserv's cache absorbs that burst. It
/// also resizes to 600px. Free, no API key, no pub dependency (just a URL).
/// Resolves a product's image. An `asset:<name>` subject ships our own bundled
/// sticker-style art (white bg, flat outline — see Docs/Brand/BRAND.md "Image /
/// illustration style") at `assets/products/<name>.png`, rendered by
/// ShimmerImage via Image.asset. Anything else falls through to a Servier
/// illustration; null keeps the branded-glyph fallback.
String? _productImage(String? subject) {
  if (subject != null && subject.startsWith('asset:')) {
    return 'assets/products/${subject.substring(6)}.png';
  }
  return _servierImage(subject);
}

String? _servierImage(String? subject) {
  if (subject == null) return null;
  final file = 'Food - $subject -- Smart-Servier.png';
  final source = 'commons.wikimedia.org/wiki/Special:FilePath/$file';
  return 'https://images.weserv.nl/?url=${Uri.encodeComponent(source)}&w=600';
}

List<Map<String, dynamic>> _demoProducts() {
  const shop1 = 'shop_demo_1';
  const shop2 = 'shop_demo_2';
  const shop3 = 'shop_demo_3';
  const shop4 = 'shop_demo_4';
  const shop5 = 'shop_demo_5';
  const shop6 = 'shop_demo_6';
  const shop7 = 'shop_demo_7';
  return [
    _product('p1', shop1, 'Tomatoes (1kg)', 'طماطم (1 كجم)', 1500, 'خضروات وفواكه', 'vegetables', 'Tomato', promo: true, collectionIds: ['col_deals']),
    _product('p2', shop1, 'Cucumbers (1kg)', 'خيار (1 كجم)', 1200, 'خضروات وفواكه', 'vegetables', null), // SMART has no cucumber
    _product('p3', shop1, 'Bananas (1kg)', 'موز (1 كجم)', 2200, 'خضروات وفواكه', 'fruits', 'Banana'),
    _product('p4', shop1, 'Oranges (1kg)', 'برتقال (1 كجم)', 1800, 'خضروات وفواكه', 'fruits', 'Orange'),
    _product('p5', shop1, 'Milk 1L', 'لبن 1 لتر', 3500, 'ألبان', 'milk', 'Milk', collectionIds: ['col_essentials']),
    _product('p6', shop1, 'White Cheese 500g', 'جبنة بيضاء 500 جم', 6500, 'ألبان', 'cheese', 'Cottage cheese', low: true),
    _product('p7', shop1, 'Yogurt Cup', 'زبادي كوب', 1200, 'ألبان', 'yogurt', 'asset:yogurt'),
    _product('p8', shop1, 'Cola 1.5L', 'كولا 1.5 لتر', 2000, 'مشروبات', 'soda', 'Soda', promo: true, collectionIds: ['col_deals']),
    _product('p9', shop1, 'Bottled Water 1.5L', 'مياه معدنية 1.5 لتر', 800, 'مشروبات', 'water', 'asset:water', collectionIds: ['col_essentials']),
    _product('p10', shop1, 'Canned Fava Beans', 'فول معلب', 1000, 'معلبات', 'beans', 'Beans', out: true),
    _product('p11', shop2, 'Baladi Bread (5pcs)', 'عيش بلدي (5 أرغفة)', 500, 'مخبوزات', 'baladiBread', 'Bread'),
    _product('p12', shop2, 'Toast Bread', 'توست', 2500, 'مخبوزات', 'toastBread', 'Bread'),
    _product('p13', shop2, 'Croissant', 'كرواسون', 1500, 'مخبوزات', 'croissant', null, promo: true), // SMART has no croissant
    _product('p14', shop2, 'Chicken (1kg)', 'دجاج (1 كجم)', 9000, 'لحوم ودواجن', 'chicken', 'Chicken'),
    _product('p15', shop2, 'Minced Meat (1kg)', 'لحمة مفرومة (1 كجم)', 25000, 'لحوم ودواجن', 'mincedMeat', 'Sausage'),
    _product('p16', shop2, 'Frozen Kofta (1kg)', 'كفتة مجمدة (1 كجم)', 18000, 'لحوم ودواجن', 'kofta', 'Sausage', low: true),
    _product('p17', shop2, 'Dish Soap 750ml', 'سائل جلي 750 مل', 4500, 'منظفات', 'dishSoap', null), // non-food, no SMART art
    _product('p18', shop2, 'Laundry Powder 1kg', 'مسحوق غسيل 1 كجم', 8000, 'منظفات', 'laundryPowder', null), // non-food
    _product('p19', shop2, 'Iced Tea 500ml', 'شاي مثلج 500 مل', 1500, 'مشروبات', 'icedTea', 'Tea'),
    _product('p20', shop2, 'Orange Juice 1L', 'عصير برتقال 1 لتر', 3000, 'مشروبات', 'juice', 'Orange juice', out: true),
    // shop_demo_3 — Green Basket (fresh + dairy)
    _product('p21', shop3, 'Potatoes (1kg)', 'بطاطس (1 كجم)', 1300, 'خضروات وفواكه', 'vegetables', 'Potato'),
    _product('p22', shop3, 'Apples (1kg)', 'تفاح (1 كجم)', 4000, 'خضروات وفواكه', 'fruits', null, promo: true), // SMART has no apple
    _product('p23', shop3, 'Strawberries (500g)', 'فراولة (500 جم)', 3500, 'خضروات وفواكه', 'fruits', 'Strawberry'),
    _product('p24', shop3, 'Onions (1kg)', 'بصل (1 كجم)', 900, 'خضروات وفواكه', 'vegetables', null), // SMART has no onion
    _product('p25', shop3, 'Feta Cheese 250g', 'جبنة فيتا 250 جم', 4800, 'ألبان', 'cheese', 'Cottage cheese'),
    _product('p26', shop3, 'Butter 200g', 'زبدة 200 جم', 5500, 'ألبان', 'butter', 'Butter', low: true),
    _product('p27', shop3, 'Canned Tuna', 'تونة معلبة', 3200, 'معلبات', 'tuna', 'Fish'),
    // shop_demo_4 — City Market (drinks + household)
    _product('p28', shop4, 'Sparkling Water 1L', 'مياه غازية 1 لتر', 1200, 'مشروبات', 'water', 'Water'),
    _product('p29', shop4, 'Energy Drink 250ml', 'مشروب طاقة 250 مل', 2500, 'مشروبات', 'energyDrinks', 'Soda', promo: true),
    _product('p30', shop4, 'Floor Cleaner 1L', 'منظف أرضيات 1 لتر', 5000, 'منظفات', 'floorCleaner', null), // non-food
    _product('p31', shop4, 'Tissue Box', 'علبة مناديل', 2000, 'منظفات', 'tissues', null), // non-food
    _product('p32', shop4, 'Rusk (Baksimat)', 'بقسماط', 1800, 'مخبوزات', 'rusk', 'Bread', out: true),
    // shop_demo_5 — عثمان (general grocery, الشارع التجاري)
    _product('p33', shop5, 'Tomatoes (1kg)', 'طماطم (1 كجم)', 1400, 'خضروات وفواكه', 'vegetables', 'Tomato', promo: true),
    _product('p34', shop5, 'Potatoes (1kg)', 'بطاطس (1 كجم)', 1250, 'خضروات وفواكه', 'vegetables', 'Potato'),
    _product('p35', shop5, 'Eggs (30)', 'بيض (طبق 30)', 13500, 'ألبان', 'eggs', 'Egg'),
    _product('p36', shop5, 'Milk 1L', 'لبن 1 لتر', 3400, 'ألبان', 'milk', 'Milk'),
    _product('p37', shop5, 'Cola 1.5L', 'كولا 1.5 لتر', 2000, 'مشروبات', 'soda', 'Soda'),
    _product('p38', shop5, 'Sunflower Oil 1L', 'زيت عباد الشمس 1 لتر', 6500, 'معلبات', 'oils', 'Oil', low: true),
    _product('p39', shop5, 'Rice (1kg)', 'أرز (1 كجم)', 3000, 'معلبات', 'rice', 'Rice'),
    _product('p40', shop5, 'Dish Soap 750ml', 'سائل جلي 750 مل', 4300, 'منظفات', 'dishSoap', null), // non-food
    // shop_demo_6 — التوحيد (drinks + canned + bakery, نفس الشارع)
    _product('p41', shop6, 'Water 1.5L (6-pack)', 'مياه 1.5 لتر (6 عبوات)', 4500, 'مشروبات', 'water', 'asset:water', promo: true),
    _product('p42', shop6, 'Juice 1L', 'عصير 1 لتر', 2800, 'مشروبات', 'juice', 'Orange juice'),
    _product('p43', shop6, 'Canned Tuna', 'تونة معلبة', 3100, 'معلبات', 'tuna', 'Fish'),
    _product('p44', shop6, 'Canned Beans', 'فول معلب', 1000, 'معلبات', 'beans', 'Beans'),
    _product('p45', shop6, 'Baladi Bread (5pcs)', 'عيش بلدي (5 أرغفة)', 500, 'مخبوزات', 'baladiBread', 'Bread'),
    _product('p46', shop6, 'Fino Bread', 'عيش فينو', 1500, 'مخبوزات', 'finoBread', 'Bread'),
    _product('p47', shop6, 'Laundry Powder 1kg', 'مسحوق غسيل 1 كجم', 7800, 'منظفات', 'laundryPowder', null, out: true), // non-food
    // shop_demo_7 — السمطي (fresh + butcher, الزغابة أمام فرن عبد الحي)
    _product('p48', shop7, 'Oranges (1kg)', 'برتقال (1 كجم)', 1700, 'خضروات وفواكه', 'fruits', 'Orange', promo: true),
    _product('p49', shop7, 'Bananas (1kg)', 'موز (1 كجم)', 2100, 'خضروات وفواكه', 'fruits', 'Banana'),
    _product('p50', shop7, 'Chicken (1kg)', 'دجاج (1 كجم)', 8800, 'لحوم ودواجن', 'chicken', 'Chicken'),
    _product('p51', shop7, 'Minced Meat (1kg)', 'لحمة مفرومة (1 كجم)', 24500, 'لحوم ودواجن', 'mincedMeat', 'Sausage', low: true),
    _product('p52', shop7, 'White Cheese 500g', 'جبنة بيضاء 500 جم', 6300, 'ألبان', 'cheese', 'Cottage cheese'),
    _product('p53', shop7, 'Baladi Bread (5pcs)', 'عيش بلدي (5 أرغفة)', 500, 'مخبوزات', 'baladiBread', 'Bread'),
  ];
}

/// Orders spanning every `OrderStatus` across the 3 demo customers (`index`
/// 0/1/2), so طلباتي / order desk / driver deliveries / finance all have
/// something real to show. `statusHistory`, driver-assignment fields, and
/// the commission split are pre-baked to match what the real app writes at
/// each transition (`firestore.rules`'s `/orders` `create` only checks
/// `isSelf(customerUid)`, so a full pre-populated lifecycle is a valid
/// create, not just a valid update). `platform` mirrors `_seedPlatformConfig`
/// (5% commission, 30 EGP delivery fee, 25 EGP of it to the driver).
List<Map<String, dynamic>> _demoOrders(
  String customerUid,
  int index,
  String ownerUid,
  String courierUid,
) {
  final now = DateTime.now();
  Timestamp ts(Duration d) => Timestamp.fromDate(now.subtract(d));
  String iso(Duration d) => now.subtract(d).toIso8601String();

  Map<String, dynamic> item(
    String productId,
    String name,
    String nameAr,
    int priceMinor,
    int quantity,
  ) => {
        'productId': productId,
        'name': name,
        'nameAr': nameAr,
        'priceMinor': priceMinor,
        'quantity': quantity,
      };

  Map<String, dynamic> statusEntry(String status, Duration d, String byUid) =>
      {'status': status, 'at': iso(d), 'byUid': byUid};

  const courierName = 'كريم عبد العزيز';
  const courierPhone = '01011111111';
  const deliveryFeeMinor = 3000;
  const commissionBps = 500;
  const driverDeliveryShareMinor = 2500;
  const platformDeliveryShareMinor = 500;

  Map<String, dynamic> order({
    required String id,
    required String shopId,
    required List<Map<String, dynamic>> items,
    required int subtotalMinor,
    required String status,
    required Duration createdAgo,
    required List<Map<String, dynamic>> statusHistory,
    required Map<String, String> address,
    Duration? assignedAgo,
    int? rating,
  }) {
    final delivered = status == 'delivered';
    return {
      'id': id,
      'shopId': shopId,
      'customerUid': customerUid,
      'items': items,
      'subtotalMinor': subtotalMinor,
      'deliveryFeeMinor': deliveryFeeMinor,
      'totalMinor': subtotalMinor + deliveryFeeMinor,
      'commissionBps': commissionBps,
      'commissionMinor': (subtotalMinor * commissionBps / 10000).round(),
      'driverDeliveryShareMinor': driverDeliveryShareMinor,
      'platformDeliveryShareMinor': platformDeliveryShareMinor,
      'commissionPayable': delivered,
      'status': status,
      'createdAt': ts(createdAgo),
      'deliveryAddress': address,
      'statusHistory': statusHistory,
      if (assignedAgo != null) 'driverUid': courierUid,
      if (assignedAgo != null) 'driverName': courierName,
      if (assignedAgo != null) 'driverPhone': courierPhone,
      if (assignedAgo != null) 'assignedAt': iso(assignedAgo),
      'rating': ?rating,
    };
  }

  const cairo = {
    'line1': '12 شارع الجمهورية، الدور 3',
    'city': 'الإسماعيلية',
    'areaId': 'downtown-ismailia',
  };
  const abuAtwa = {
    'line1': 'الشارع التجاري، أبوعطوة',
    'city': 'الإسماعيلية',
    'areaId': 'abu-atwa',
  };

  switch (index) {
    case 0:
      return [
        order(
          id: 'order_demo_0_1',
          shopId: 'shop_demo_1',
          items: [
            item('p1', 'Tomatoes (1kg)', 'طماطم (1 كجم)', 1500, 2),
            item('p5', 'Milk 1L', 'لبن 1 لتر', 3500, 1),
          ],
          subtotalMinor: 6500,
          status: 'pending',
          createdAgo: const Duration(minutes: 20),
          statusHistory: [
            statusEntry('pending', const Duration(minutes: 20), customerUid),
          ],
          address: cairo,
        ),
        order(
          id: 'order_demo_0_2',
          shopId: 'shop_demo_2',
          items: [
            item('p14', 'Chicken (1kg)', 'دجاج (1 كجم)', 9000, 1),
            item('p11', 'Baladi Bread (5pcs)', 'عيش بلدي (5 أرغفة)', 500, 3),
          ],
          subtotalMinor: 10500,
          status: 'accepted',
          createdAgo: const Duration(hours: 1),
          statusHistory: [
            statusEntry('pending', const Duration(hours: 1), customerUid),
            statusEntry('accepted', const Duration(minutes: 50), ownerUid),
          ],
          address: cairo,
        ),
        order(
          id: 'order_demo_0_3',
          shopId: 'shop_demo_1',
          items: [
            item('p8', 'Cola 1.5L', 'كولا 1.5 لتر', 2000, 2),
            item('p9', 'Bottled Water 1.5L', 'مياه معدنية 1.5 لتر', 800, 6),
          ],
          subtotalMinor: 8800,
          status: 'outForDelivery',
          createdAgo: const Duration(hours: 2),
          statusHistory: [
            statusEntry('pending', const Duration(hours: 2), customerUid),
            statusEntry('accepted', const Duration(hours: 1, minutes: 50), ownerUid),
            statusEntry('preparing', const Duration(hours: 1, minutes: 30), ownerUid),
            statusEntry('outForDelivery', const Duration(minutes: 20), courierUid),
          ],
          address: cairo,
          assignedAgo: const Duration(minutes: 25),
        ),
      ];
    case 1:
      return [
        order(
          id: 'order_demo_1_1',
          shopId: 'shop_demo_3',
          items: [
            item('p22', 'Apples (1kg)', 'تفاح (1 كجم)', 4000, 1),
            item('p23', 'Strawberries (500g)', 'فراولة (500 جم)', 3500, 2),
          ],
          subtotalMinor: 11000,
          status: 'preparing',
          createdAgo: const Duration(hours: 3),
          statusHistory: [
            statusEntry('pending', const Duration(hours: 3), customerUid),
            statusEntry('accepted', const Duration(hours: 2, minutes: 50), ownerUid),
            statusEntry('preparing', const Duration(hours: 2, minutes: 30), ownerUid),
          ],
          address: cairo,
        ),
        order(
          // preparing WITH a driver already assigned — waiting pickup, hasn't
          // hit outForDelivery yet (the courier's own two-step handoff, M10).
          id: 'order_demo_1_2',
          shopId: 'shop_demo_5',
          items: [
            item('p33', 'Tomatoes (1kg)', 'طماطم (1 كجم)', 1400, 3),
            item('p36', 'Milk 1L', 'لبن 1 لتر', 3400, 2),
          ],
          subtotalMinor: 11000,
          status: 'preparing',
          createdAgo: const Duration(hours: 4),
          statusHistory: [
            statusEntry('pending', const Duration(hours: 4), customerUid),
            statusEntry('accepted', const Duration(hours: 3, minutes: 50), ownerUid),
            statusEntry('preparing', const Duration(hours: 3, minutes: 30), ownerUid),
          ],
          address: abuAtwa,
          assignedAgo: const Duration(hours: 1),
        ),
        order(
          id: 'order_demo_1_3',
          shopId: 'shop_demo_3',
          items: [
            item('p25', 'Feta Cheese 250g', 'جبنة فيتا 250 جم', 4800, 1),
          ],
          subtotalMinor: 4800,
          status: 'cancelled',
          createdAgo: const Duration(days: 6),
          statusHistory: [
            statusEntry('pending', const Duration(days: 6), customerUid),
            statusEntry(
              'cancelled',
              const Duration(days: 5, hours: 23, minutes: 50),
              customerUid,
            ),
          ],
          address: cairo,
        ),
      ];
    default:
      return [
        order(
          id: 'order_demo_2_1',
          shopId: 'shop_demo_4',
          items: [
            item('p29', 'Energy Drink 250ml', 'مشروب طاقة 250 مل', 2500, 4),
          ],
          subtotalMinor: 10000,
          status: 'rejected',
          createdAgo: const Duration(days: 8),
          statusHistory: [
            statusEntry('pending', const Duration(days: 8), customerUid),
            statusEntry(
              'rejected',
              const Duration(days: 7, hours: 23, minutes: 50),
              ownerUid,
            ),
          ],
          address: cairo,
        ),
        order(
          id: 'order_demo_2_2',
          shopId: 'shop_demo_7',
          items: [
            item('p48', 'Oranges (1kg)', 'برتقال (1 كجم)', 1700, 2),
            item('p50', 'Chicken (1kg)', 'دجاج (1 كجم)', 8800, 1),
          ],
          subtotalMinor: 12200,
          status: 'delivered',
          createdAgo: const Duration(days: 2),
          statusHistory: [
            statusEntry('pending', const Duration(days: 2), customerUid),
            statusEntry(
              'accepted',
              const Duration(days: 1, hours: 23, minutes: 50),
              ownerUid,
            ),
            statusEntry(
              'preparing',
              const Duration(days: 1, hours: 23, minutes: 30),
              ownerUid,
            ),
            statusEntry(
              'outForDelivery',
              const Duration(days: 1, hours: 23),
              courierUid,
            ),
            statusEntry(
              'delivered',
              const Duration(days: 1, hours: 22, minutes: 30),
              courierUid,
            ),
          ],
          address: abuAtwa,
          assignedAgo: const Duration(days: 1, hours: 23, minutes: 20),
          rating: 5,
        ),
        order(
          id: 'order_demo_2_3',
          shopId: 'shop_demo_7',
          items: [
            item('p52', 'White Cheese 500g', 'جبنة بيضاء 500 جم', 6300, 1),
            item('p53', 'Baladi Bread (5pcs)', 'عيش بلدي (5 أرغفة)', 500, 2),
          ],
          subtotalMinor: 7300,
          status: 'delivered',
          createdAgo: const Duration(days: 4),
          statusHistory: [
            statusEntry('pending', const Duration(days: 4), customerUid),
            statusEntry(
              'accepted',
              const Duration(days: 3, hours: 23, minutes: 50),
              ownerUid,
            ),
            statusEntry(
              'preparing',
              const Duration(days: 3, hours: 23, minutes: 30),
              ownerUid,
            ),
            statusEntry(
              'outForDelivery',
              const Duration(days: 3, hours: 21),
              courierUid,
            ),
            statusEntry(
              'delivered',
              const Duration(days: 3, hours: 20),
              courierUid,
            ),
          ],
          address: abuAtwa,
          assignedAgo: const Duration(days: 3, hours: 21, minutes: 30),
        ),
      ];
  }
}

Map<String, dynamic> _product(
  String id,
  String shopId,
  String name,
  String nameAr,
  int priceMinor,
  String category,
  String subcategoryId,
  String? imageSubject, {
  bool promo = false,
  bool low = false,
  bool out = false,
  List<String> collectionIds = const [],
}) {
  final status = out
      ? 'outOfStock'
      : low
          ? 'lowStock'
          : 'inStock';
  final imageUrl = _productImage(imageSubject);
  return {
    'id': id,
    'shopId': shopId,
    'name': name,
    'nameAr': nameAr,
    // Omit entirely (not null) when SMART has no illustration → the tile shows
    // ShimmerImage's branded glyph instead of a broken/blank image.
    'imageUrl': ?imageUrl,
    'priceMinor': priceMinor,
    'category': category,
    'subcategoryId': subcategoryId,
    'stockStatus': status,
    'isPromo': promo,
    'collectionIds': collectionIds,
  };
}

class _SeedApp extends StatelessWidget {
  const _SeedApp();

  static final log = ValueNotifier<String>('Seeding…');

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ValueListenableBuilder<String>(
              valueListenable: log,
              builder: (context, value, _) => Text(value),
            ),
          ),
        ),
      ),
    );
  }
}
