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

const _seedEmail = 'seed-owner@dukkan.dev';
const _seedPassword = 'DukkanSeed123!';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const _SeedApp());

  final log = StringBuffer();
  try {
    final uid = await _signInSeedOwner();
    log.writeln('Signed in as seed owner ($uid).');
    await _seed(uid, log);
    log.writeln('Seed complete.');
  } catch (e) {
    log.writeln('Seed FAILED: $e');
  }
  _SeedApp.log.value = log.toString();
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
  final batch = firestore.batch();

  for (final shop in _demoShops(ownerUid)) {
    batch.set(firestore.collection('shops').doc(shop['id'] as String), shop);
  }
  for (final product in _demoProducts()) {
    batch.set(
      firestore.collection('products').doc(product['id'] as String),
      product,
    );
  }

  await batch.commit();
  log.writeln('Wrote ${_demoShops(ownerUid).length} shops and '
      '${_demoProducts().length} products.');
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
      },
      {
        'id': 'shop_demo_2',
        'ownerUid': ownerUid,
        'name': 'Al Amal Supermarket',
        'nameAr': 'سوبر ماركت الأمل',
        'address': '45 شارع النصر، مدينة نصر، القاهرة',
        'isOpen': true,
        'categories': ['مخبوزات', 'لحوم ودواجن', 'منظفات', 'مشروبات'],
      },
    ];

List<Map<String, dynamic>> _demoProducts() {
  const shop1 = 'shop_demo_1';
  const shop2 = 'shop_demo_2';
  return [
    _product('p1', shop1, 'Tomatoes (1kg)', 'طماطم (1 كجم)', 1500, 'خضروات وفواكه', promo: true),
    _product('p2', shop1, 'Cucumbers (1kg)', 'خيار (1 كجم)', 1200, 'خضروات وفواكه'),
    _product('p3', shop1, 'Bananas (1kg)', 'موز (1 كجم)', 2200, 'خضروات وفواكه'),
    _product('p4', shop1, 'Oranges (1kg)', 'برتقال (1 كجم)', 1800, 'خضروات وفواكه'),
    _product('p5', shop1, 'Milk 1L', 'لبن 1 لتر', 3500, 'ألبان'),
    _product('p6', shop1, 'White Cheese 500g', 'جبنة بيضاء 500 جم', 6500, 'ألبان', low: true),
    _product('p7', shop1, 'Yogurt Cup', 'زبادي كوب', 1200, 'ألبان'),
    _product('p8', shop1, 'Cola 1.5L', 'كولا 1.5 لتر', 2000, 'مشروبات', promo: true),
    _product('p9', shop1, 'Bottled Water 1.5L', 'مياه معدنية 1.5 لتر', 800, 'مشروبات'),
    _product('p10', shop1, 'Canned Fava Beans', 'فول معلب', 1000, 'معلبات', out: true),
    _product('p11', shop2, 'Baladi Bread (5pcs)', 'عيش بلدي (5 أرغفة)', 500, 'مخبوزات'),
    _product('p12', shop2, 'Toast Bread', 'توست', 2500, 'مخبوزات'),
    _product('p13', shop2, 'Croissant', 'كرواسون', 1500, 'مخبوزات', promo: true),
    _product('p14', shop2, 'Chicken (1kg)', 'دجاج (1 كجم)', 9000, 'لحوم ودواجن'),
    _product('p15', shop2, 'Minced Meat (1kg)', 'لحمة مفرومة (1 كجم)', 25000, 'لحوم ودواجن'),
    _product('p16', shop2, 'Frozen Kofta (1kg)', 'كفتة مجمدة (1 كجم)', 18000, 'لحوم ودواجن', low: true),
    _product('p17', shop2, 'Dish Soap 750ml', 'سائل جلي 750 مل', 4500, 'منظفات'),
    _product('p18', shop2, 'Laundry Powder 1kg', 'مسحوق غسيل 1 كجم', 8000, 'منظفات'),
    _product('p19', shop2, 'Iced Tea 500ml', 'شاي مثلج 500 مل', 1500, 'مشروبات'),
    _product('p20', shop2, 'Orange Juice 1L', 'عصير برتقال 1 لتر', 3000, 'مشروبات', out: true),
  ];
}

Map<String, dynamic> _product(
  String id,
  String shopId,
  String name,
  String nameAr,
  int priceMinor,
  String category, {
  bool promo = false,
  bool low = false,
  bool out = false,
}) {
  final status = out
      ? 'outOfStock'
      : low
          ? 'lowStock'
          : 'inStock';
  return {
    'id': id,
    'shopId': shopId,
    'name': name,
    'nameAr': nameAr,
    'priceMinor': priceMinor,
    'category': category,
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
