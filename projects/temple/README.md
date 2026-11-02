# Temple — Daily Bible

A sovereign, offline-first Bible app for Android: the complete World
English Bible in a native shell, designed as cream cards on a black
table — the cards are the reading surface and the navigation.

## Release build

- **Version:** 1.0.2 (versionCode 3)
- **Package:** `com.temple.myapp`
- **Android:** API 26+; target API 36
- **Scripture:** 66 books · 1,189 chapters · 31,098 verses
- **Privacy:** no account, no ads, no analytics, no tracking

## Included here

- `app/index.html` — the complete one-file application core
- `android/MainActivity.kt` — native shell, geolocation bridge, secure
  share bridge, and Android 16 back handling
- `android/ShareProvider.kt` — confined provider for user-initiated
  verse-card sharing
- `android/AndroidManifest.xml` — the release manifest
- `android/build.sh` / `build-aab.sh` — the raw-toolchain APK and bundle
  build scripts used to produce the release

## Features

- Verse and prayer of the day
- Full-text search and go-to-reference navigation
- Highlights, favorites, verse notes, and shareable verse cards
- Prayer list, reading plans, hide-a-verse, and cast-a-lot
- Optional weather card — the only network feature, activated only by
  the user's tap

## Verification

The application core passed hostile-storage and navigation batteries;
the Android bundle was verified by package badging, DEX inspection,
target-SDK inspection, and upload-key signature validation.
