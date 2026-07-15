// Dev-only seed entrypoint — thin CLI wrapper around `lib/dev/seed.dart`'s
// `runSeed`. NOT part of the shipping app (nothing under lib/dev is imported
// from lib/main.dart). Firebase plugins need Flutter engine bindings, so this
// can't run as a plain `dart run` — it's a second Flutter entrypoint instead:
//   flutter run -t lib/dev/seed_demo_data.dart -d <device>
//
// See `lib/dev/seed.dart` for the full seed contract (idempotent ids, the
// temporary rules-relax requirement, demo account credentials) — this file
// only wires it to a device run and a tiny on-screen log.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../firebase_options.dart';
import 'seed.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const _SeedApp());

  final log = StringBuffer();
  try {
    await runSeed(FirebaseFirestore.instance, log: log);
    log.writeln('Seed complete. Signed out — log in as your own account.');
  } catch (e) {
    log.writeln('Seed FAILED: $e');
    await FirebaseAuth.instance.signOut();
  }
  _SeedApp.log.value = log.toString();
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
