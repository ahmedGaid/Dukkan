# Dukkan — Release runbook (Android)

The build/sign/upload steps below need a real Android build environment (Android
SDK + JDK) and a Google Play Console account, so they run on **your** machine, not
in the agent. The repo is already wired for them: the release signing config in
`android/app/build.gradle.kts` reads `android/key.properties` when present and
falls back to debug signing when it is not.

## 1. One-time: generate the upload keystore

Keep the `.jks` file **outside** the repo (e.g. `C:\keys\`). It is your identity on
the Play Store — losing it means you can never update the app under this listing.

```powershell
keytool -genkey -v -keystore C:\keys\dukkan-release.jks `
  -keyalg RSA -keysize 2048 -validity 10000 -alias dukkan
```

Then copy the template and fill in the passwords you just set:

```powershell
Copy-Item android\key.properties.example android\key.properties
# edit android\key.properties: storePassword, keyPassword, keyAlias, storeFile
```

`android/key.properties`, `*.jks`, and `*.keystore` are all gitignored — never
commit them.

## 2. Bump the version before each release

In `pubspec.yaml`, line `version: 1.0.0+1` → `versionName+versionCode`. The Play
Store rejects a re-used `versionCode`, so bump the number after `+` every upload.

## 3. Build the signed app bundle (AAB — Play requires AAB, not APK)

```powershell
$env:PATH = "$env:PATH;C:\src\flutter\bin"
flutter clean
flutter build appbundle --release
# output: build\app\outputs\bundle\release\app-release.aab
```

If the build fails on a missing Android SDK, install it (Android Studio →
SDK Manager) and enable Windows Developer Mode. If it fails on
`google-services.json`, Crashlytics/native-FCM Gradle config is not yet in place
(see "Still pending" below) — plain release builds do not need it.

## 4. Play Console — internal testing track (R2)

1. Play Console → **Create app** (name "دكان / Dukkan", app, free, Egypt +
   whichever countries).
2. Complete the required declarations (privacy policy URL, data safety, content
   rating, target audience). COD-only, no ads.
3. **Testing → Internal testing → Create new release** → upload
   `app-release.aab`.
4. Add tester emails to the internal tester list, share the opt-in link.
5. Roll out to internal testing.

First upload also asks you to enrol in **Play App Signing** — accept it; Google
holds the app-signing key and your `.jks` becomes the *upload* key.

## Still pending (needs a device to verify)

- **Crashlytics (R2):** wired 2026-07-11 — `firebase_crashlytics` dep, `com.google.gms.google-services`
  + `com.google.firebase.crashlytics` Gradle plugins, `lib/main.dart` routes
  `FlutterError.onError` + `PlatformDispatcher.instance.onError` to Crashlytics
  (skipped on web — no web target). Collection is on in release, off in debug
  builds. Release AAB builds clean with the plugins applied. **Not yet verified
  on-device** — needs a real crash (or `FirebaseCrashlytics.instance.crash()` test
  call) to confirm an event actually reaches the Firebase console.
- **R1 store screenshots:** need the app running on a device/emulator — blocked by
  the same missing Android SDK / Developer Mode.
