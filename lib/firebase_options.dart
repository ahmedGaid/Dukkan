// Firebase config for Dukkan (project dukkan-93042).
//
// Hand-written (not `flutterfire configure`) — the Firebase CLI needs an
// interactive browser login we couldn't run here. Values come from the
// console's Web-app SDK snippet. Firebase web/mobile API keys are public
// identifiers, NOT secrets — access is controlled by Security Rules, so this
// file is safe to commit.
//
// Only the Web app is registered so far. Android/iOS get real options when
// their apps are registered (S1, once the Android SDK is installed) — until
// then those platforms throw a clear error instead of silently misconfiguring.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'FirebaseOptions for ${defaultTargetPlatform.name} are not set up '
          'yet. Register the app in the Firebase console (project '
          'dukkan-93042) and add its options here.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for '
          '$defaultTargetPlatform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCUK3v6U6ExiwyfzERYU_XFUDFspxUPBfI',
    appId: '1:179921113250:web:a55d9d02803e88261387fb',
    messagingSenderId: '179921113250',
    projectId: 'dukkan-93042',
    authDomain: 'dukkan-93042.firebaseapp.com',
    storageBucket: 'dukkan-93042.firebasestorage.app',
    measurementId: 'G-N97H8SC345',
  );
}
