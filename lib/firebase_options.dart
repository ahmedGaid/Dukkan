// Firebase config for Dukkan (project dukkan-93042).
//
// Web block hand-written from the console SDK snippet; Android block generated
// 2026-07-10 from `firebase apps:sdkconfig ANDROID` (android/app/google-services.json)
// after the Android app was registered. Firebase web/mobile API keys are public
// identifiers, NOT secrets — access is controlled by Security Rules. (This file
// is gitignored regardless.) iOS is still unregistered and throws until needed.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'FirebaseOptions for iOS are not set up yet. Register the iOS app in '
          'the Firebase console (project dukkan-93042) and add its options here.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for $defaultTargetPlatform.',
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDvdHDTMK9IEZB5bq5eoMxJg_DOahvV6N8',
    appId: '1:179921113250:android:8b5cbaf2a3a23f881387fb',
    messagingSenderId: '179921113250',
    projectId: 'dukkan-93042',
    storageBucket: 'dukkan-93042.firebasestorage.app',
  );
}
