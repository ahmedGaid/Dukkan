// Dev-only E2E verification entrypoint — NOT part of the shipping app (nothing
// under lib/dev is imported from lib/main.dart). Dumps live Firestore state as
// JSON so an E2E run can check the *backend* layer of a journey, per
// Docs/testing/E2E_MASTER_PROMPT.md ("four layers": UI, runtime, backend, rules).
//
// Firebase plugins need Flutter engine bindings, so this is a second Flutter
// entrypoint rather than a plain `dart run`:
//
//   flutter run -t lib/dev/e2e_verify.dart -d <device> \
//     --dart-define=VERIFY_EMAIL=you@example.com \
//     --dart-define=VERIFY_PASSWORD=yourpassword \
//     --dart-define=VERIFY_QUERY=shops
//
// VERIFY_QUERY (comma-separated, any of):
//   shops | products | orders | users | order:<orderId> | user:<uid> | product:<id>
//
// Every result line is prefixed `E2E_VERIFY:` so it can be grepped out of the
// `flutter run` log. Reads only — this script never writes.
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../firebase_options.dart';

const _email = String.fromEnvironment('VERIFY_EMAIL');
const _password = String.fromEnvironment('VERIFY_PASSWORD');
const _query = String.fromEnvironment('VERIFY_QUERY', defaultValue: 'shops');

const _tag = 'E2E_VERIFY:';

void _out(String key, Object? value) {
  // One line per record keeps the log greppable even when it interleaves.
  debugPrint('$_tag$key ${jsonEncode(value)}');
}

/// Firestore hands back Timestamps and nested maps; jsonEncode chokes on both.
Object? _plain(Object? value) {
  if (value is Timestamp) return value.toDate().toIso8601String();
  if (value is DocumentReference) return value.path;
  if (value is Map) {
    return value.map((k, v) => MapEntry(k.toString(), _plain(v)));
  }
  if (value is Iterable) return value.map(_plain).toList();
  return value;
}

Map<String, Object?> _doc(DocumentSnapshot<Map<String, dynamic>> snap) {
  final data = snap.data() ?? <String, dynamic>{};
  return {
    'id': snap.id,
    // Types matter: the money rule is "integer piasters on the wire", so a
    // double priceMinor must be visible here, not silently coerced.
    'types': data.map((k, v) => MapEntry(k, v.runtimeType.toString())),
    'data': _plain(data),
  };
}

Future<void> _dumpCollection(FirebaseFirestore db, String name) async {
  final snap = await db.collection(name).get();
  _out('count.$name', snap.docs.length);
  for (final doc in snap.docs) {
    _out('$name.${doc.id}', _doc(doc));
  }
}

Future<void> _dumpDoc(FirebaseFirestore db, String path, String id) async {
  final snap = await db.collection(path).doc(id).get();
  if (!snap.exists) {
    _out('missing.$path.$id', null);
    return;
  }
  _out('$path.$id', _doc(snap));
}

Future<void> _run() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final auth = FirebaseAuth.instance;
  final db = FirebaseFirestore.instance;

  if (_email.isEmpty || _password.isEmpty) {
    _out('error', 'VERIFY_EMAIL / VERIFY_PASSWORD dart-defines are required');
    return;
  }

  final cred = await auth.signInWithEmailAndPassword(
    email: _email,
    password: _password,
  );
  _out('signedInAs', {'uid': cred.user?.uid, 'email': cred.user?.email});

  for (final part in _query.split(',').map((s) => s.trim())) {
    if (part.isEmpty) continue;
    try {
      if (part.contains(':')) {
        final [name, id] = part.split(':');
        final collection = name.endsWith('s') ? name : '${name}s';
        await _dumpDoc(db, collection, id);
      } else {
        await _dumpCollection(db, part);
      }
    } catch (e) {
      _out('error.$part', e.toString());
    }
  }

  _out('done', _query);
  // Leave no session behind: the next `flutter run` of the real app should open
  // on its own auth state, not this script's.
  await auth.signOut();
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _run().catchError((Object e) => _out('fatal', e.toString()));
  runApp(
    const MaterialApp(
      home: Scaffold(body: Center(child: Text('E2E verify — see logs'))),
    ),
  );
}
