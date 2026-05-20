import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:aurasound/core/constants/app_constants.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

class SpotifyToken {
  final String accessToken;
  final String? refreshToken;
  final DateTime expiresAt;

  const SpotifyToken({
    required this.accessToken,
    this.refreshToken,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  factory SpotifyToken.fromJson(Map<String, dynamic> json) {
    return SpotifyToken(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String?,
      expiresAt: DateTime.now().add(
        Duration(seconds: (json['expires_in'] as int? ?? 3600)),
      ),
    );
  }
}

class SpotifyProfile {
  final String id;
  final String displayName;
  final String? email;
  final String? avatarUrl;
  final String product; // 'premium' | 'free'

  const SpotifyProfile({
    required this.id,
    required this.displayName,
    this.email,
    this.avatarUrl,
    required this.product,
  });

  bool get isPremium => product == 'premium';

  factory SpotifyProfile.fromJson(Map<String, dynamic> json) {
    final images = json['images'] as List<dynamic>?;
    return SpotifyProfile(
      id: json['id'] as String,
      displayName: json['display_name'] as String? ?? 'Spotify User',
      email: json['email'] as String?,
      avatarUrl: images != null && images.isNotEmpty
          ? (images.first as Map)['url'] as String?
          : null,
      product: json['product'] as String? ?? 'free',
    );
  }
}

// ─── State ────────────────────────────────────────────────────────────────────

class SpotifyState {
  final bool isConnected;
  final bool isConnecting;
  final SpotifyProfile? profile;
  final String? error;

  const SpotifyState({
    this.isConnected = false,
    this.isConnecting = false,
    this.profile,
    this.error,
  });

  SpotifyState copyWith({
    bool? isConnected,
    bool? isConnecting,
    SpotifyProfile? profile,
    String? error,
  }) {
    return SpotifyState(
      isConnected: isConnected ?? this.isConnected,
      isConnecting: isConnecting ?? this.isConnecting,
      profile: profile ?? this.profile,
      error: error,
    );
  }
}

// ─── PKCE Helpers ─────────────────────────────────────────────────────────────

String _generateCodeVerifier() {
  final rand = Random.secure();
  final bytes = Uint8List(64);
  for (var i = 0; i < bytes.length; i++) {
    bytes[i] = rand.nextInt(256);
  }
  return base64UrlEncode(bytes).replaceAll('=', '');
}

String _generateCodeChallenge(String verifier) {
  final bytes = utf8.encode(verifier);
  final digest = sha256.convert(bytes);
  return base64UrlEncode(digest.bytes).replaceAll('=', '');
}

String _generateState() {
  final rand = Random.secure();
  final bytes = Uint8List(16);
  for (var i = 0; i < bytes.length; i++) {
    bytes[i] = rand.nextInt(256);
  }
  return base64UrlEncode(bytes).replaceAll('=', '');
}

// ─── Service ──────────────────────────────────────────────────────────────────

class SpotifyService extends StateNotifier<SpotifyState> {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'spotify_access_token';
  static const _refreshKey = 'spotify_refresh_token';
  static const _expiryKey = 'spotify_token_expiry';

  SpotifyToken? _cachedToken;
  String? _codeVerifier;

  SpotifyService() : super(const SpotifyState()) {
    _restoreSession();
  }

  // Restore saved token on app start
  Future<void> _restoreSession() async {
    try {
      final accessToken = await _storage.read(key: _tokenKey);
      final refreshToken = await _storage.read(key: _refreshKey);
      final expiryStr = await _storage.read(key: _expiryKey);

      if (accessToken == null) return;

      final expiry = expiryStr != null
          ? DateTime.parse(expiryStr)
          : DateTime.now().subtract(const Duration(seconds: 1));

      _cachedToken = SpotifyToken(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresAt: expiry,
      );

      if (_cachedToken!.isExpired && refreshToken != null) {
        await _refreshAccessToken(refreshToken);
      } else if (!_cachedToken!.isExpired) {
        final profile = await fetchProfile();
        if (profile != null) {
          state = state.copyWith(isConnected: true, profile: profile);
        }
      }
    } catch (e) {
      debugPrint('SpotifyService restore error: $e');
    }
  }

  // ── OAuth PKCE ─────────────────────────────────────────────────────────────

  /// Returns the authorization URL to open in a browser.
  /// Call this, then open the URL, intercept the redirect URI callback,
  /// and call [handleCallback] with the full redirect URI.
  String buildAuthUrl() {
    _codeVerifier = _generateCodeVerifier();
    final challenge = _generateCodeChallenge(_codeVerifier!);
    final stateParam = _generateState();

    final params = {
      'client_id': AppConstants.spotifyClientId,
      'response_type': 'code',
      'redirect_uri': AppConstants.spotifyRedirectUri,
      'code_challenge_method': 'S256',
      'code_challenge': challenge,
      'state': stateParam,
      'scope': AppConstants.spotifyScopes.join(' '),
      'show_dialog': 'false',
    };

    final uri = Uri.https(
      'accounts.spotify.com',
      '/authorize',
      params,
    );

    return uri.toString();
  }

  /// Call this with the full redirect URI after Spotify redirects back.
  Future<bool> handleCallback(String redirectUri) async {
    try {
      state = state.copyWith(isConnecting: true, error: null);

      final uri = Uri.parse(redirectUri);
      final code = uri.queryParameters['code'];
      final error = uri.queryParameters['error'];

      if (error != null || code == null) {
        state = state.copyWith(
          isConnecting: false,
          error: error ?? 'Authorization cancelled',
        );
        return false;
      }

      // Exchange code for token
      final response = await http.post(
        Uri.https('accounts.spotify.com', '/api/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': AppConstants.spotifyRedirectUri,
          'client_id': AppConstants.spotifyClientId,
          'code_verifier': _codeVerifier ?? '',
        },
      );

      if (response.statusCode != 200) {
        state = state.copyWith(
          isConnecting: false,
          error: 'Token exchange failed: ${response.statusCode}',
        );
        return false;
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      _cachedToken = SpotifyToken.fromJson(json);

      // Persist tokens securely
      await _storage.write(key: _tokenKey,   value: _cachedToken!.accessToken);
      await _storage.write(key: _expiryKey,  value: _cachedToken!.expiresAt.toIso8601String());
      if (_cachedToken!.refreshToken != null) {
        await _storage.write(key: _refreshKey, value: _cachedToken!.refreshToken!);
      }

      // Fetch profile
      final profile = await fetchProfile();
      state = state.copyWith(
        isConnected: true,
        isConnecting: false,
        profile: profile,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isConnecting: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // ── Token Refresh ──────────────────────────────────────────────────────────

  Future<void> _refreshAccessToken(String refreshToken) async {
    try {
      final response = await http.post(
        Uri.https('accounts.spotify.com', '/api/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
          'client_id': AppConstants.spotifyClientId,
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        _cachedToken = SpotifyToken.fromJson(json);
        await _storage.write(key: _tokenKey,  value: _cachedToken!.accessToken);
        await _storage.write(key: _expiryKey, value: _cachedToken!.expiresAt.toIso8601String());
        if (_cachedToken!.refreshToken != null) {
          await _storage.write(key: _refreshKey, value: _cachedToken!.refreshToken!);
        }
      }
    } catch (e) {
      debugPrint('SpotifyService refresh error: $e');
    }
  }

  // ── Access token getter (auto-refresh) ─────────────────────────────────────

  Future<String?> get accessToken async {
    if (_cachedToken == null) return null;
    if (_cachedToken!.isExpired) {
      final refresh = await _storage.read(key: _refreshKey);
      if (refresh != null) await _refreshAccessToken(refresh);
    }
    return _cachedToken?.accessToken;
  }

  // ── Web API helpers ────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> _apiGet(String path,
      {Map<String, String>? params}) async {
    final token = await accessToken;
    if (token == null) return null;

    final uri = Uri.https('api.spotify.com', '/v1$path', params);
    final response = await http.get(uri,
        headers: {'Authorization': 'Bearer $token'});

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }

  Future<SpotifyProfile?> fetchProfile() async {
    final data = await _apiGet('/me');
    if (data == null) return null;
    return SpotifyProfile.fromJson(data);
  }

  Future<List<Map<String, dynamic>>> fetchPlaylists({int limit = 20}) async {
    final data = await _apiGet('/me/playlists', params: {'limit': '$limit'});
    if (data == null) return [];
    final items = data['items'] as List<dynamic>? ?? [];
    return items.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> fetchLikedTracks({int limit = 50}) async {
    final data = await _apiGet('/me/tracks', params: {'limit': '$limit'});
    if (data == null) return [];
    final items = data['items'] as List<dynamic>? ?? [];
    return items.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> search(String query,
      {String types = 'track,album,artist', int limit = 20}) async {
    final data = await _apiGet('/search', params: {
      'q': query,
      'type': types,
      'limit': '$limit',
    });
    return data != null ? [data] : [];
  }

  Future<List<Map<String, dynamic>>> fetchRecommendations(
      List<String> seedTrackIds) async {
    final data = await _apiGet('/recommendations', params: {
      'seed_tracks': seedTrackIds.take(5).join(','),
      'limit': '20',
    });
    if (data == null) return [];
    final tracks = data['tracks'] as List<dynamic>? ?? [];
    return tracks.cast<Map<String, dynamic>>();
  }

  // ── Playback control (requires Premium + active device) ───────────────────

  Future<void> play({String? uri, String? contextUri}) async {
    final token = await accessToken;
    if (token == null) return;

    final body = <String, dynamic>{};
    if (uri != null) body['uris'] = [uri];
    if (contextUri != null) body['context_uri'] = contextUri;

    await http.put(
      Uri.https('api.spotify.com', '/v1/me/player/play'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
  }

  Future<void> pause() async {
    final token = await accessToken;
    if (token == null) return;
    await http.put(
      Uri.https('api.spotify.com', '/v1/me/player/pause'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  Future<void> next() async {
    final token = await accessToken;
    if (token == null) return;
    await http.post(
      Uri.https('api.spotify.com', '/v1/me/player/next'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  Future<void> previous() async {
    final token = await accessToken;
    if (token == null) return;
    await http.post(
      Uri.https('api.spotify.com', '/v1/me/player/previous'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  Future<void> setVolume(int volumePercent) async {
    final token = await accessToken;
    if (token == null) return;
    await http.put(
      Uri.https('api.spotify.com', '/v1/me/player/volume',
          {'volume_percent': '$volumePercent'}),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  Future<Map<String, dynamic>?> currentlyPlaying() async =>
      _apiGet('/me/player/currently-playing');

  // ── Disconnect ─────────────────────────────────────────────────────────────

  Future<void> disconnect() async {
    _cachedToken = null;
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshKey);
    await _storage.delete(key: _expiryKey);
    state = const SpotifyState();
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final spotifyServiceProvider =
    StateNotifierProvider<SpotifyService, SpotifyState>((ref) {
  return SpotifyService();
});
