class AppConstants {
  AppConstants._();

  static const String appName = 'AuraSound';
  static const String appTagline = 'Feel Every Beat';
  static const String appVersion = '1.0.0';

  // ── Spotify OAuth ──────────────────────────────────────────────────────────
  // Set these before building. Register your app at:
  //   https://developer.spotify.com/dashboard
  //
  // Add   aurasound://callback   as a Redirect URI in your app's settings.
  // Never expose these in client-side JS — Flutter compiles them into the binary.
  //
  static const String spotifyClientId = 'YOUR_SPOTIFY_CLIENT_ID';
  // No client secret needed — we use PKCE (Proof Key for Code Exchange).
  static const String spotifyRedirectUri = 'aurasound://callback';
  static const List<String> spotifyScopes = [
    'user-read-private',
    'user-read-email',
    'user-library-read',
    'user-read-playback-state',
    'user-modify-playback-state',
    'user-read-currently-playing',
    'playlist-read-private',
    'playlist-read-collaborative',
    'streaming',
  ];

  // Audio
  static const int defaultSampleRate = 44100;
  static const int highResSampleRate = 96000;
  static const int defaultBitDepth = 16;
  static const int highResBitDepth = 24;
  static const double defaultCrossfadeDuration = 3.0;
  static const double defaultVolume = 1.0;

  // EQ
  static const List<int> eq10BandFrequencies = [
    31, 62, 125, 250, 500, 1000, 2000, 4000, 8000, 16000
  ];
  static const List<int> eq32BandFrequencies = [
    20, 25, 31, 40, 50, 63, 80, 100, 125, 160,
    200, 250, 315, 400, 500, 630, 800, 1000, 1250, 1600,
    2000, 2500, 3150, 4000, 5000, 6300, 8000, 10000, 12500, 16000,
    20000, 22000,
  ];
  static const double eqMinGain = -12.0;
  static const double eqMaxGain = 12.0;

  // UI
  static const double borderRadius = 16.0;
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusLarge = 24.0;
  static const double borderRadiusXL = 32.0;
  static const double cardPadding = 16.0;
  static const double pageHorizontalPadding = 20.0;
  static const double miniPlayerHeight = 72.0;
  static const double bottomNavHeight = 64.0;
  static const double albumArtSize = 56.0;
  static const double albumArtSizeLarge = 280.0;

  // Animation
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 350);
  static const Duration animationSlow = Duration(milliseconds: 600);
  static const Duration animationVerySlow = Duration(milliseconds: 1000);

  // Storage Keys
  static const String keyThemeMode = 'theme_mode';
  static const String keyAccentColor = 'accent_color';
  static const String keyEqualizerPreset = 'eq_preset';
  static const String keyMusicFolders = 'music_folders';
  static const String keyPlaybackSpeed = 'playback_speed';
  static const String keyCrossfade = 'crossfade_enabled';
  static const String keyCrossfadeDuration = 'crossfade_duration';
  static const String keySpotifyToken = 'spotify_token';
  static const String keyLastPlayed = 'last_played';
  static const String keyVolume = 'volume';
  static const String keyRepeatMode = 'repeat_mode';
  static const String keyShuffleMode = 'shuffle_mode';
}
