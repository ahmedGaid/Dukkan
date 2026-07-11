// Dev-only seed script — NOT part of the shipping app (nothing under lib/dev
// is imported from lib/main.dart). Writes 2 demo shops + ~20 demo products to
// Firestore so C2 (Browse) has real data to build against.
//
// Firebase plugins need Flutter engine bindings, so this can't run as a plain
// `dart run` — it's a second Flutter entrypoint instead:
//   flutter run -t lib/dev/seed_demo_data.dart -d chrome
// (only the Web app is registered in Firebase so far — see dukkan-status).
//
// Idempotent: shop/product ids are fixed, so re-running overwrites the same
// docs instead of duplicating them. Requires `firestore.rules` deployed with
// the /shops and /products rules (C1) — write needs a signed-in user, so this
// signs into (or creates) a throwaway "seed-owner" account first.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../firebase_options.dart';

const _seedEmail = 'owner@dukkan.dev';
const _seedPassword = 'owner123';

// Customer to fill with orders + favorites, passed at runtime so no real
// password ever lands in source:
//   flutter run -t lib/dev/seed_demo_data.dart -d <device> \
//     --dart-define=SEED_CUSTOMER_EMAIL=you@example.com \
//     --dart-define=SEED_CUSTOMER_PASSWORD=yourpassword
const _customerEmail = String.fromEnvironment('SEED_CUSTOMER_EMAIL');
const _customerPassword = String.fromEnvironment('SEED_CUSTOMER_PASSWORD');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const _SeedApp());

  final log = StringBuffer();
  try {
    // Phase 1 — owner: catalog (shops + products) + the owner's own profile,
    // written while signed in as the seed owner so the /shops + /products +
    // /users(self) rules pass.
    final ownerUid = await _signInSeedOwner();
    log.writeln('Signed in as seed owner ($ownerUid).');
    await _seed(ownerUid, log);

    // Phase 2 — customer: profile + favorites + order history, written while
    // signed in AS that customer (rules gate /users and /orders to the owner).
    if (_customerEmail.isEmpty || _customerPassword.isEmpty) {
      log.writeln('No SEED_CUSTOMER_* creds — skipped customer data '
          '(orders/favorites). Pass --dart-define to fill them.');
    } else {
      await FirebaseAuth.instance.signOut();
      final customerUid = await _signInCustomer();
      log.writeln('Signed in as customer ($customerUid).');
      await _seedCustomer(customerUid, log);
    }

    // Don't leave the device authenticated as a seed account — otherwise the
    // next launch of the real app opens as the seed owner/customer instead of
    // whoever was signed in before. Sign out so the app returns to its login.
    await FirebaseAuth.instance.signOut();

    log.writeln('Seed complete. Signed out — log in as your own account.');
  } catch (e) {
    log.writeln('Seed FAILED: $e');
  }
  _SeedApp.log.value = log.toString();
}

Future<String> _signInCustomer() async {
  final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
    email: _customerEmail.trim(),
    password: _customerPassword,
  );
  return cred.user!.uid;
}

Future<String> _signInSeedOwner() async {
  final auth = FirebaseAuth.instance;
  try {
    final cred = await auth.signInWithEmailAndPassword(
      email: _seedEmail,
      password: _seedPassword,
    );
    return cred.user!.uid;
  } on FirebaseAuthException catch (e) {
    if (e.code != 'user-not-found' && e.code != 'invalid-credential') rethrow;
    final cred = await auth.createUserWithEmailAndPassword(
      email: _seedEmail,
      password: _seedPassword,
    );
    return cred.user!.uid;
  }
}

Future<void> _seed(String ownerUid, StringBuffer log) async {
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

  await _seedTaxonomy(firestore);
  await _seedAreas(firestore);
  await _seedDrivers(firestore);

  log.writeln('Wrote ${_demoShops(ownerUid).length} shops, '
      '${_demoProducts().length} products, ${_taxonomy.length} '
      'categories, ${_areas.length} areas, and ${_drivers.length} demo '
      'drivers.');
}

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

/// `/drivers` (M8) demo profiles — id is a fixed doc id, not a real Firebase
/// Auth uid (these never log in; real couriers get their own doc via the app
/// signup flow). `firestore.rules` restricts `create` to `isSelf(uid)`, which
/// an owner-authenticated seed write can never satisfy, and even a driver's
/// own signup can't create the ACTIVE case (the rule pins `isSuspended ==
/// true` at create) — so, same as `_seedTaxonomy`, this only succeeds with
/// `/drivers`'s `write: false` temporarily relaxed to `isSignedIn()`.
Future<void> _seedDrivers(FirebaseFirestore firestore) async {
  final batch = firestore.batch();
  for (final driver in _drivers) {
    batch.set(
      firestore.collection('drivers').doc(driver['id'] as String),
      {
        'name': driver['name'],
        'phone': driver['phone'],
        'areaIds': driver['areaIds'],
        'maxActiveOrders': driver['maxActiveOrders'],
        'activeOrdersCount': driver['activeOrdersCount'],
        'isOnline': driver['isOnline'],
        'isSuspended': driver['isSuspended'],
        'createdAt': FieldValue.serverTimestamp(),
      },
    );
  }
  await batch.commit();
}

final _drivers = <Map<String, dynamic>>[
  {
    'id': 'driver_demo_1',
    'name': 'كريم عبد العزيز',
    'phone': '01011111111',
    'areaIds': ['abu-atwa', 'el-sheikh-zayed'],
    'maxActiveOrders': 5,
    'activeOrdersCount': 0,
    'isOnline': true,
    'isSuspended': false,
  },
  {
    'id': 'driver_demo_2',
    'name': 'محمود سعيد',
    'phone': '01022222222',
    'areaIds': ['downtown-ismailia'],
    'maxActiveOrders': 5,
    'activeOrdersCount': 0,
    'isOnline': false,
    'isSuspended': true,
  },
];

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

/// Customer-side demo: profile (with favorites) + a spread of orders across
/// every status. Runs while signed in AS the customer.
Future<void> _seedCustomer(String customerUid, StringBuffer log) async {
  final firestore = FirebaseFirestore.instance;

  await firestore.collection('users').doc(customerUid).set({
    'name': 'أحمد',
    'email': _customerEmail,
    'role': 'customer',
    'phone': '01234567890',
    'favoriteShopIds': ['shop_demo_1', 'shop_demo_3'],
    'favoriteProductIds': ['p1', 'p5', 'p13', 'p23'],
    'createdAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  final orders = _demoOrders(customerUid);
  for (final order in orders) {
    await firestore.collection('orders').doc(order['id'] as String).set(order);
  }

  log.writeln('Wrote customer profile + 4 favorites and '
      '${orders.length} orders.');
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
        'logoUrl': _seedImage('grocery-store', 'shop_demo_1', 200),
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
        'logoUrl': _seedImage('supermarket', 'shop_demo_2', 200),
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
        'logoUrl': _seedImage('greengrocer', 'shop_demo_3', 200),
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
        'logoUrl': _seedImage('supermarket', 'shop_demo_4', 200),
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
        'logoUrl': _seedImage('grocery-store', 'shop_demo_5', 200),
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
        'logoUrl': _seedImage('grocery-store', 'shop_demo_6', 200),
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
        'logoUrl': _seedImage('butcher-shop', 'shop_demo_7', 200),
        'ratingSum': 23, // 5 votes, ~4.6 avg
        'ratingCount': 5,
      },
    ];

/// Deterministic loremflickr placeholder — used for SHOP logos only (a real
/// storefront photo suits a shop avatar; Servier's set is food-only). `lock`,
/// derived from [seedId], pins one stable photo per shop across re-seeds.
String _seedImage(String keyword, String seedId, int size) {
  final lock = int.tryParse(seedId.replaceAll(RegExp(r'\D'), '')) ?? 1;
  return 'https://loremflickr.com/$size/$size/$keyword?lock=$lock';
}

/// A clean flat food illustration from Servier Medical Art (SMART), hosted on
/// Wikimedia Commons' CDN — CC-licensed, hotlinkable, and a permanent, stable
/// URL (no MD5 hash needed; `Special:FilePath` 302-redirects to the file, which
/// Image.network follows). [subject] is the SMART food name, e.g. 'Tomato' →
/// `File:Food - Tomato -- Smart-Servier.png`. Returns null for products SMART
/// has no illustration for (cucumber, apple, onion, croissant, and the non-food
/// household items) — those tiles fall back to ShimmerImage's branded glyph.
String? _servierImage(String? subject) {
  if (subject == null) return null;
  final file = 'Food - $subject -- Smart-Servier.png';
  return 'https://commons.wikimedia.org/wiki/Special:FilePath/'
      '${Uri.encodeComponent(file)}?width=600';
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
    _product('p1', shop1, 'Tomatoes (1kg)', 'طماطم (1 كجم)', 1500, 'خضروات وفواكه', 'vegetables', 'Tomato', promo: true),
    _product('p2', shop1, 'Cucumbers (1kg)', 'خيار (1 كجم)', 1200, 'خضروات وفواكه', 'vegetables', null), // SMART has no cucumber
    _product('p3', shop1, 'Bananas (1kg)', 'موز (1 كجم)', 2200, 'خضروات وفواكه', 'fruits', 'Banana'),
    _product('p4', shop1, 'Oranges (1kg)', 'برتقال (1 كجم)', 1800, 'خضروات وفواكه', 'fruits', 'Orange'),
    _product('p5', shop1, 'Milk 1L', 'لبن 1 لتر', 3500, 'ألبان', 'milk', 'Milk'),
    _product('p6', shop1, 'White Cheese 500g', 'جبنة بيضاء 500 جم', 6500, 'ألبان', 'cheese', 'Cottage cheese', low: true),
    _product('p7', shop1, 'Yogurt Cup', 'زبادي كوب', 1200, 'ألبان', 'yogurt', 'Yogurt'),
    _product('p8', shop1, 'Cola 1.5L', 'كولا 1.5 لتر', 2000, 'مشروبات', 'soda', 'Soda', promo: true),
    _product('p9', shop1, 'Bottled Water 1.5L', 'مياه معدنية 1.5 لتر', 800, 'مشروبات', 'water', 'Water'),
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
    _product('p41', shop6, 'Water 1.5L (6-pack)', 'مياه 1.5 لتر (6 عبوات)', 4500, 'مشروبات', 'water', 'Water', promo: true),
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

/// Orders spanning every status so طلباتي shows a realistic history: an active
/// order on the way, one being prepared, a just-placed one, plus delivered
/// (one rated), cancelled, and rejected history. Ordered newest-first via
/// createdAt so the list reads top-to-bottom by recency.
List<Map<String, dynamic>> _demoOrders(String customerUid) {
  final now = DateTime.now();
  Timestamp ago(Duration d) => Timestamp.fromDate(now.subtract(d));

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

  const cairo = {'line1': '12 شارع الجمهورية، الدور 3', 'city': 'القاهرة'};

  return [
    {
      'id': 'order_demo_1',
      'shopId': 'shop_demo_1',
      'customerUid': customerUid,
      'items': [
        item('p1', 'Tomatoes (1kg)', 'طماطم (1 كجم)', 1500, 2),
        item('p5', 'Milk 1L', 'لبن 1 لتر', 3500, 1),
      ],
      'totalMinor': 6500,
      'status': 'outForDelivery',
      'createdAt': ago(const Duration(minutes: 25)),
      'deliveryAddress': cairo,
    },
    {
      'id': 'order_demo_2',
      'shopId': 'shop_demo_2',
      'customerUid': customerUid,
      'items': [
        item('p14', 'Chicken (1kg)', 'دجاج (1 كجم)', 9000, 1),
        item('p11', 'Baladi Bread (5pcs)', 'عيش بلدي (5 أرغفة)', 500, 3),
      ],
      'totalMinor': 10500,
      'status': 'preparing',
      'createdAt': ago(const Duration(hours: 1, minutes: 10)),
      'deliveryAddress': cairo,
    },
    {
      'id': 'order_demo_3',
      'shopId': 'shop_demo_3',
      'customerUid': customerUid,
      'items': [
        item('p22', 'Apples (1kg)', 'تفاح (1 كجم)', 4000, 1),
        item('p23', 'Strawberries (500g)', 'فراولة (500 جم)', 3500, 2),
      ],
      'totalMinor': 11000,
      'status': 'pending',
      'createdAt': ago(const Duration(hours: 3)),
      'deliveryAddress': cairo,
    },
    {
      'id': 'order_demo_4',
      'shopId': 'shop_demo_1',
      'customerUid': customerUid,
      'items': [
        item('p8', 'Cola 1.5L', 'كولا 1.5 لتر', 2000, 2),
        item('p9', 'Bottled Water 1.5L', 'مياه معدنية 1.5 لتر', 800, 6),
      ],
      'totalMinor': 8800,
      'status': 'delivered',
      'rating': 5,
      'createdAt': ago(const Duration(days: 2)),
      'deliveryAddress': cairo,
    },
    {
      'id': 'order_demo_5',
      'shopId': 'shop_demo_2',
      'customerUid': customerUid,
      'items': [
        item('p17', 'Dish Soap 750ml', 'سائل جلي 750 مل', 4500, 1),
      ],
      'totalMinor': 4500,
      'status': 'delivered',
      'createdAt': ago(const Duration(days: 4)),
      'deliveryAddress': cairo,
    },
    {
      'id': 'order_demo_6',
      'shopId': 'shop_demo_3',
      'customerUid': customerUid,
      'items': [
        item('p25', 'Feta Cheese 250g', 'جبنة فيتا 250 جم', 4800, 1),
      ],
      'totalMinor': 4800,
      'status': 'cancelled',
      'createdAt': ago(const Duration(days: 6)),
      'deliveryAddress': cairo,
    },
    {
      'id': 'order_demo_7',
      'shopId': 'shop_demo_4',
      'customerUid': customerUid,
      'items': [
        item('p29', 'Energy Drink 250ml', 'مشروب طاقة 250 مل', 2500, 4),
      ],
      'totalMinor': 10000,
      'status': 'rejected',
      'createdAt': ago(const Duration(days: 8)),
      'deliveryAddress': cairo,
    },
  ];
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
}) {
  final status = out
      ? 'outOfStock'
      : low
          ? 'lowStock'
          : 'inStock';
  final imageUrl = _servierImage(imageSubject);
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
