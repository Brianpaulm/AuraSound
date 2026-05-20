import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/splash/splash_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/home/home_screen.dart';
import '../features/library/library_screen.dart';
import '../features/favorites/favorites_screen.dart';
import '../features/player/now_playing_screen.dart';
import '../features/equalizer/equalizer_screen.dart';
import '../features/visualizer/visualizer_screen.dart';
import '../features/sound_profiles/sound_profiles_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/spotify/spotify_auth_screen.dart';
import '../features/video/video_screen.dart';
import '../features/youtube/youtube_screen.dart';
import '../shared/widgets/main_scaffold.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash',       builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/onboarding',   builder: (_, __) => const OnboardingScreen()),
    GoRoute(path: '/spotify-auth', builder: (_, __) => const SpotifyAuthScreen()),
    ShellRoute(
      builder: (context, state, child) => MainScaffold(child: child),
      routes: [
        GoRoute(path: '/home',          builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/library',       builder: (_, __) => const LibraryScreen()),
        GoRoute(path: '/favorites',     builder: (_, __) => const FavoritesScreen()),
        GoRoute(path: '/equalizer',     builder: (_, __) => const EqualizerScreen()),
        GoRoute(path: '/sound-profiles',builder: (_, __) => const SoundProfilesScreen()),
        GoRoute(path: '/visualizer',    builder: (_, __) => const VisualizerScreen()),
        GoRoute(path: '/settings',      builder: (_, __) => const SettingsScreen()),
        GoRoute(path: '/video',         builder: (_, __) => const VideoScreen()),
        GoRoute(path: '/youtube',       builder: (_, __) => const YouTubeScreen()),
      ],
    ),
    GoRoute(
      path: '/now-playing',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const NowPlayingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                  .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
              child: child,
            ),
      ),
    ),
  ],
);
