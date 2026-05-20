import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/song.dart';
import '../providers/audio_provider.dart';

// ─── YouTube search result ────────────────────────────────────────────────────

class YTResult {
  final String videoId;
  final String title;
  final String channel;
  final String? thumbnailUrl;
  final Duration duration;

  const YTResult({
    required this.videoId,
    required this.title,
    required this.channel,
    this.thumbnailUrl,
    required this.duration,
  });

  Song toSong() => Song(
        id: 'yt_$videoId',
        title: title,
        artist: channel,
        album: 'YouTube',
        albumArtUrl: thumbnailUrl,
        duration: duration.inSeconds,
        source: PlaybackSource.youtube,
        // filePath filled in when stream URL is resolved
      );
}

// ─── YT Stream state ──────────────────────────────────────────────────────────

class YouTubeState {
  final List<YTResult> searchResults;
  final bool isSearching;
  final bool isResolving;
  final String? query;
  final String? error;

  const YouTubeState({
    this.searchResults = const [],
    this.isSearching = false,
    this.isResolving = false,
    this.query,
    this.error,
  });

  YouTubeState copyWith({
    List<YTResult>? searchResults,
    bool? isSearching,
    bool? isResolving,
    String? query,
    String? error,
  }) {
    return YouTubeState(
      searchResults: searchResults ?? this.searchResults,
      isSearching: isSearching ?? this.isSearching,
      isResolving: isResolving ?? this.isResolving,
      query: query ?? this.query,
      error: error,
    );
  }
}

// ─── Service ──────────────────────────────────────────────────────────────────

class YouTubeService extends StateNotifier<YouTubeState> {
  final YoutubeExplode _yt = YoutubeExplode();
  final Ref _ref;

  YouTubeService(this._ref) : super(const YouTubeState());

  // ── Search ─────────────────────────────────────────────────────────────────

  Future<void> search(String query) async {
    if (query.trim().isEmpty) return;
    state = state.copyWith(
      isSearching: true,
      query: query,
      error: null,
      searchResults: [],
    );

    try {
      final results = await _yt.search.search(query);
      final ytResults = <YTResult>[];

      for (final item in results) {
        if (item is SearchVideo) {
          ytResults.add(YTResult(
            videoId: item.id.value,
            title: item.title,
            channel: item.author,
            thumbnailUrl: item.thumbnails.highResUrl,
            duration: item.duration ?? Duration.zero,
          ));
        }
        if (ytResults.length >= 20) break;
      }

      state = state.copyWith(
        isSearching: false,
        searchResults: ytResults,
      );
    } catch (e) {
      debugPrint('YT search error: $e');
      state = state.copyWith(
        isSearching: false,
        error: 'Search failed: $e',
      );
    }
  }

  // ── Resolve and play ───────────────────────────────────────────────────────

  /// Resolves a YouTube video's best audio stream URL then plays it.
  Future<void> playResult(YTResult result) async {
    state = state.copyWith(isResolving: true, error: null);
    try {
      final streamUrl = await _resolveAudioStreamUrl(result.videoId);
      if (streamUrl == null) {
        state = state.copyWith(
          isResolving: false,
          error: 'Could not resolve audio stream',
        );
        return;
      }

      final song = result.toSong().copyWith(filePath: streamUrl);
      await _ref.read(playerProvider.notifier).playSong(song);
      state = state.copyWith(isResolving: false);
    } catch (e) {
      debugPrint('YT resolve error: $e');
      state = state.copyWith(
        isResolving: false,
        error: 'Playback failed: $e',
      );
    }
  }

  /// Play a YouTube URL or video ID directly (e.g. pasted by user).
  Future<void> playUrl(String urlOrId) async {
    state = state.copyWith(isResolving: true, error: null);
    try {
      VideoId videoId;
      try {
        videoId = VideoId(urlOrId);
      } catch (_) {
        // Try treating as full URL
        videoId = VideoId.fromString(urlOrId);
      }

      final video = await _yt.videos.get(videoId);
      final streamUrl = await _resolveAudioStreamUrl(videoId.value);
      if (streamUrl == null) {
        state = state.copyWith(isResolving: false, error: 'No audio stream');
        return;
      }

      final song = Song(
        id: 'yt_${videoId.value}',
        title: video.title,
        artist: video.author,
        album: 'YouTube',
        albumArtUrl: video.thumbnails.highResUrl,
        duration: video.duration?.inSeconds ?? 0,
        filePath: streamUrl,
        source: PlaybackSource.youtube,
      );

      await _ref.read(playerProvider.notifier).playSong(song);
      state = state.copyWith(isResolving: false);
    } catch (e) {
      debugPrint('YT playUrl error: $e');
      state = state.copyWith(
        isResolving: false,
        error: 'Could not play: $e',
      );
    }
  }

  // ── Internal: resolve best audio URL ──────────────────────────────────────

  Future<String?> _resolveAudioStreamUrl(String videoId) async {
    try {
      final manifest = await _yt.videos.streamsClient
          .getManifest(VideoId(videoId));

      // Prefer opus/webm audio-only, then aac, then fallback to muxed
      final audioStreams = manifest.audioOnly.toList()
        ..sort((a, b) => b.bitrate.compareTo(a.bitrate));

      if (audioStreams.isNotEmpty) {
        return audioStreams.first.url.toString();
      }

      // Fallback: muxed stream lowest quality
      final muxed = manifest.muxed.toList()
        ..sort((a, b) => a.bitrate.compareTo(b.bitrate));
      if (muxed.isNotEmpty) {
        return muxed.first.url.toString();
      }

      return null;
    } catch (e) {
      debugPrint('_resolveAudioStreamUrl error: $e');
      return null;
    }
  }

  // ── Dispose ────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _yt.close();
    super.dispose();
  }
}

final youTubeServiceProvider =
    StateNotifierProvider<YouTubeService, YouTubeState>((ref) {
  return YouTubeService(ref);
});
