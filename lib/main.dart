import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'core/theme/app_theme.dart';
import 'navigation/app_router.dart';
import 'providers/library_provider.dart';
import 'services/storage_scanner.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ONLY initialize on mobile (Android/iOS)
  if (!kIsWeb) {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.aurasound.app.channel.audio',
      androidNotificationChannelName: 'AuraSound Playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: false,
      notificationColor: const Color(0xFF0C0C0E),
    );
  }

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0C0C0E),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const ProviderScope(child: AuraSoundApp()));
}

class AuraSoundApp extends ConsumerStatefulWidget {
  const AuraSoundApp({super.key});

  @override
  ConsumerState<AuraSoundApp> createState() => _AuraSoundAppState();
}

class _AuraSoundAppState extends ConsumerState<AuraSoundApp> {
  @override
  void initState() {
    super.initState();
    // Trigger storage scan after first frame — shows permission dialog naturally
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrapLibrary();
    });
  }

  Future<void> _bootstrapLibrary() async {
    // 1. Scan device storage (requests permission, fills library)
    await ref.read(storageScannerProvider.notifier).scanAndLoad();

    // 2. Merge scanned songs into the library provider
    final scanned = ref.read(storageScannerProvider).songs;
    if (scanned.isNotEmpty) {
      ref.read(libraryProvider.notifier).loadScannedSongs(scanned);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'AuraSound',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeState.themeMode,
      routerConfig: appRouter,
    );
  }
}
