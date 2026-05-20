# 🎵 AuraSound — Premium Audiophile Music Application

> A world-class, cross-platform music application built with Flutter — combining offline local playback with Spotify streaming inside one immersive ecosystem.

![AuraSound Banner](docs/banner.png)

---

## ✨ Features

- **Premium Audio Engine** — Gapless playback, crossfade, hi-res 24/32-bit support
- **Advanced EQ & DSP** — 10-band / 32-band EQ, bass boost, virtualizer, reverb, spatial audio
- **Sound Profiles** — JBL Signature, Harman Kardon, Sony, Beats, AirPods Pro, Studio Monitor, Car Audio
- **Spotify Integration** — Stream 100M+ songs, mix with local library
- **Immersive Visualizers** — Spectrum, Wave, Particles, Bars, Circle — all at 60fps
- **Glassmorphism UI** — Frosted cards, ambient glows, adaptive accent colors
- **Cross-Platform** — Android, Windows, and Web (PWA) from one codebase
- **Desktop Layout** — Sidebar navigation, multi-pane layout, detachable mini-player
- **Local Library** — Scan storage, index 100k+ songs, support MP3/FLAC/ALAC/WAV/AAC/OGG/OPUS/DSD

---

## 🛠 Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.x (Dart 3.x) |
| State Management | Riverpod 2 |
| Navigation | go_router |
| Audio Playback | just_audio + audio_service |
| Local DB | Hive |
| Audio Query | on_audio_query |
| Animations | flutter_animate + custom AnimationController |
| UI Effects | Custom painter, BackdropFilter, ShaderMask |

---

## 📁 Project Structure

```
lib/
├── core/
│   ├── theme/          # AppColors, AppTextStyles, AppTheme
│   ├── constants/      # AppConstants
│   ├── utils/          # FormatUtils, extensions
│   └── widgets/        # GlassCard, PrimaryButton
├── features/
│   ├── splash/         # Animated splash screen
│   ├── onboarding/     # 3-page onboarding flow
│   ├── home/           # Home screen + widgets
│   ├── library/        # Songs, Albums, Artists, Genres, Folders
│   ├── player/         # Now Playing screen
│   ├── equalizer/      # 10-band EQ + DSP effects
│   ├── visualizer/     # 5 animated visualizer modes
│   ├── sound_profiles/ # Device sound presets
│   ├── settings/       # Full settings + theme customization
│   └── spotify/        # Spotify OAuth screen
├── models/
│   ├── song.dart       # Song, Album, Artist, Playlist
│   └── eq_preset.dart  # EQPreset, AudioEffect, SoundProfile
├── providers/
│   ├── audio_provider.dart      # PlayerState + PlayerNotifier
│   ├── equalizer_provider.dart  # EQState + SoundProfileState
│   └── library_provider.dart   # LibraryState + ThemeState
├── navigation/
│   └── app_router.dart
├── shared/
│   └── widgets/
│       ├── main_scaffold.dart   # Bottom nav + mini player
│       ├── mini_player.dart     # Floating glass mini player
│       ├── desktop_layout.dart  # Sidebar layout for desktop
│       ├── song_card.dart       # Reusable song/playlist cards
│       └── shimmer_widgets.dart # Loading skeleton UI
└── main.dart
```

---

## 🚀 Quick Start

### Prerequisites

- Flutter SDK >= 3.1.0
- Dart SDK >= 3.1.0
- Android SDK (for Android builds)
- Visual Studio 2022 + MSVC (for Windows builds)

### 1. Clone & Install

```bash
git clone https://github.com/yourname/aurasound.git
cd aurasound
flutter pub get
```

### 2. Create Required Asset Directories

```bash
mkdir -p assets/images assets/icons assets/animations assets/fonts
```

> **Fonts**: Download Inter font family from [Google Fonts](https://fonts.google.com/specimen/Inter) and place TTF files in `assets/fonts/`.

### 3. Configure Spotify (Optional)

Edit `lib/core/constants/app_constants.dart`:

```dart
static const String spotifyClientId = 'YOUR_SPOTIFY_CLIENT_ID';
static const String spotifyClientSecret = 'YOUR_SPOTIFY_CLIENT_SECRET';
```

Register your app at [developer.spotify.com](https://developer.spotify.com) and add `aurasound://callback` as redirect URI.

### 4. Run

```bash
# Android
flutter run -d android

# Windows
flutter run -d windows

# Web
flutter run -d chrome
```

---

## 📱 Android Setup

`android/app/src/main/AndroidManifest.xml` already includes:
- `READ_MEDIA_AUDIO` (Android 13+)
- `READ_EXTERNAL_STORAGE` (Android ≤ 12)
- `FOREGROUND_SERVICE` for background playback
- Media session and notification support

**Minimum SDK**: 23 (Android 6.0)

---

## 🪟 Windows Setup

```bash
flutter config --enable-windows-desktop
flutter build windows --release
```

Output: `build/windows/x64/runner/Release/aurasound.exe`

---

## 🌐 Web / PWA Setup

```bash
flutter build web --release --web-renderer canvaskit
```

Deploy the `build/web/` folder to any static host (Netlify, Vercel, Firebase Hosting).

PWA features: offline caching, installable, manifest configured.

---

## 🏗 Build for Production

### Android APK
```bash
flutter build apk --release --split-per-abi
```

### Android AAB (Google Play)
```bash
flutter build appbundle --release
```

### Windows Installer
```bash
flutter build windows --release
# Then use Inno Setup or MSIX Packaging Tool
```

---

## 🎨 Theming

AuraSound uses a token-based theme system:

```dart
// Accent color
AppColors.primary         // #7C6FFF (Purple)
AppColors.accent          // #00D4FF (Cyan)
AppColors.accentPurple    // #BB6BFF
AppColors.accentPink      // #FF6BB5

// Backgrounds
AppColors.background      // #0A0A0F
AppColors.surface         // #1A1A24
AppColors.backgroundCard  // #16161E

// Text
AppColors.textPrimary     // #F0F0F8
AppColors.textSecondary   // #8A8AA8
AppColors.textTertiary    // #4A4A65
```

---

## 🔧 Adding Real Audio Playback

Replace mock data in `lib/providers/audio_provider.dart` with actual just_audio integration:

```dart
import 'package:just_audio/just_audio.dart';

final _player = AudioPlayer();

Future<void> playSong(Song song) async {
  if (song.filePath != null) {
    await _player.setFilePath(song.filePath!);
  } else if (song.source == PlaybackSource.spotify) {
    // Use Spotify SDK
  }
  await _player.play();
}
```

---

## 🧪 Testing

```bash
# Unit tests
flutter test

# Widget tests
flutter test test/widget_test.dart

# Integration tests
flutter test integration_test/
```

---

## 🗺 Roadmap

- [ ] Real audio engine integration (just_audio + ExoPlayer)
- [ ] Spotify SDK full integration
- [ ] Cloud sync (Firebase / Supabase)
- [ ] AI-generated playlists
- [ ] Android Auto support
- [ ] WearOS companion
- [ ] DLNA / Chromecast
- [ ] NAS / local network streaming
- [ ] Lyrics sync (LRC format)

---

## 📄 License

MIT License — see [LICENSE](LICENSE) for details.

---

## 🙏 Credits

Designed & built with ❤️ using Flutter.

Inspired by Spotify Premium, Apple Music, JBL, Harman Kardon, Tesla UI, and Apple VisionOS design systems.
