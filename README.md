# Syna Smart Home

Syna is a Flutter smart home app prepared for Android and iOS release builds.
It uses Material 3, Riverpod, GoRouter, Dio, secure token storage, localization,
and a feature-first architecture.

## Required Values

- App name: `Syna`
- Android applicationId: `com.syna.smarthome`
- Android namespace: `com.syna.smarthome`
- iOS Bundle Identifier: `com.syna.smarthome`
- Version: `1.0.0+1`
- Replace before production: development, staging, and production API URLs.

## Architecture

`lib/app` contains bootstrap, config, routing, theme, and localization.
`lib/core` contains network, storage, services, errors, utilities, and shared
widgets. `lib/features` is feature-first with `data`, `domain`, and
`presentation` folders.

Current backend integrations are mock repositories behind interfaces. Replace
`MockAuthRepository` and `MockDeviceRepository` with API implementations without
changing widgets.

## Run

```bash
flutter pub get
flutter gen-l10n
flutter run --flavor development --target lib/main_development.dart --dart-define-from-file=config/development.json
flutter run --flavor staging --target lib/main_staging.dart --dart-define-from-file=config/staging.json
flutter run --flavor production --target lib/main_production.dart --dart-define-from-file=config/production.json
```

## Code Quality

```bash
dart format .
flutter analyze
flutter test
```

## Android Release Signing

Create an upload keystore and keep it out of Git:

```bash
keytool -genkeypair -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Create `android/key.properties` locally or in CI:

```properties
storePassword=change-me
keyPassword=change-me
keyAlias=upload
storeFile=upload-keystore.jks
```

Build the Play Store artifact:

```bash
flutter build appbundle --release --flavor production --target lib/main_production.dart --dart-define-from-file=config/production.json
```

## iOS Release

Configure Apple Developer Team ID and provisioning in Xcode before archive.

```bash
flutter build ios --release --flavor production --target lib/main_production.dart --dart-define-from-file=config/production.json
```

Archive in Xcode: choose `production` scheme, select `Any iOS Device`, then
Product -> Archive -> Validate App -> Distribute App.

## Store Checklist

Android: package name correct, release signing works, AAB builds, production API
uses HTTPS, icon and splash verified, minimal permissions, privacy policy ready,
delete account supported, versionCode increased, tested on real devices.

iOS: Bundle ID correct, signing/provisioning works, archive succeeds, permission
descriptions match used features, app icon complete, privacy manifest reviewed,
privacy policy ready, delete account supported, build number increased, tested
on a real iPhone.
