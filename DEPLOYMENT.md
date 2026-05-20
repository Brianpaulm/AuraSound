# AuraSound — Deployment Guide

## Android

### Debug Build
```bash
flutter run -d android
```

### Release APK
```bash
# Split by ABI (smaller size)
flutter build apk --release --split-per-abi

# Universal APK
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/`

### Release AAB (Google Play Store)
```bash
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab`

### Signing
Create `android/key.properties`:
```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=aurasound
storeFile=../aurasound.jks
```

Generate keystore:
```bash
keytool -genkey -v -keystore aurasound.jks -keyalg RSA \
  -keysize 2048 -validity 10000 -alias aurasound
```

Update `android/app/build.gradle` signingConfigs block.

---

## Windows

### Prerequisites
- Visual Studio 2022 with "Desktop development with C++" workload
- CMake 3.14+

### Enable Windows
```bash
flutter config --enable-windows-desktop
```

### Debug
```bash
flutter run -d windows
```

### Release Build
```bash
flutter build windows --release
```
Output: `build/windows/x64/runner/Release/`

### Create Installer (MSIX)
```bash
# Install msix package
flutter pub add msix --dev

# Add to pubspec.yaml:
# msix_config:
#   display_name: AuraSound
#   publisher_display_name: YourName
#   identity_name: com.aurasound.app
#   msix_version: 1.0.0.0
#   logo_path: assets/icons/icon.png

dart run msix:create
```

### WASAPI Support
For exclusive WASAPI mode on Windows, the audio backend
uses BASS library or Windows AudioSession APIs through
platform channels. See `windows/runner/` for native code.

---

## Web / PWA

### Debug
```bash
flutter run -d chrome
```

### Release Build
```bash
# CanvasKit renderer (better quality, larger bundle)
flutter build web --release --web-renderer canvaskit

# HTML renderer (smaller bundle, mobile-friendly)
flutter build web --release --web-renderer html
```
Output: `build/web/`

### Deploy to Firebase Hosting
```bash
npm install -g firebase-tools
firebase login
firebase init hosting
firebase deploy --only hosting
```

### Deploy to Netlify
```bash
# Drop build/web/ folder into Netlify dashboard
# Or use CLI:
npm install -g netlify-cli
netlify deploy --prod --dir=build/web
```

### Deploy to Vercel
```bash
npm install -g vercel
vercel --prod build/web
```

### PWA Configuration
The app includes:
- `web/manifest.json` — PWA manifest
- `web/index.html` — SW registration
- Offline caching via service worker

---

## Environment Variables

Create `.env` (not committed to git):
```env
SPOTIFY_CLIENT_ID=your_client_id
SPOTIFY_CLIENT_SECRET=your_secret
```

Update `lib/core/constants/app_constants.dart` or use
`--dart-define` at build time:
```bash
flutter build apk \
  --dart-define=SPOTIFY_CLIENT_ID=xxx \
  --dart-define=SPOTIFY_CLIENT_SECRET=yyy
```

---

## Performance Tips

- Use `--release` for all production builds
- Enable R8/ProGuard for Android: already configured
- Use `flutter build` with `--analyze-size` to inspect bundle
- For Web, use `--web-renderer canvaskit` for smooth animations

---

## Continuous Integration

### GitHub Actions (example)
```yaml
name: Build AuraSound

on: [push, pull_request]

jobs:
  android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
      - run: flutter pub get
      - run: flutter build apk --release

  windows:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter build windows --release

  web:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter build web --release
```
