import 'dart:async';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../models/song.dart';

enum RepeatMode { none, one, all }

// ─────────────────────────────────────────────────────────────────────────────
// Playback Config
// ─────────────────────────────────────────────────────────────────────────────

class PlaybackConfig {
  final bool gapless;
  final bool crossfade;
  final double crossfadeDuration;
  final double volume;
  final double speed;
  final bool normalization;

  const PlaybackConfig({
    this.gapless = true,
    this.crossfade = false,
    this.crossfadeDuration = 3.0,
    this.volume = 1.0,
    this.speed = 1.0,
    this.normalization = false,
  });

  PlaybackConfig copyWith({
    bool? gapless,
    bool? crossfade,
    double? crossfadeDuration,
    double? volume,
    double? speed,
    bool? normalization,
  }) {
    return PlaybackConfig(
      gapless: gapless ?? this.gapless,
      crossfade: crossfade ?? this.crossfade,
      crossfadeDuration:
          crossfadeDuration ?? this.crossfadeDuration,
      volume: volume ?? this.volume,
      speed: speed ?? this.speed,
      normalization: normalization ?? this.normalization,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Player State
// ─────────────────────────────────────────────────────────────────────────────

class PlayerState {
  final Song? currentSong;
  final List<Song> queue;
  final int currentIndex;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final RepeatMode repeatMode;
  final bool isShuffled;
  final bool isBuffering;
  final bool isSeeking;
  final String? error;
  final PlaybackConfig config;
  final bool isCrossfading;

  const PlayerState({
    this.currentSong,
    this.queue = const [],
    this.currentIndex = 0,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.repeatMode = RepeatMode.none,
    this.isShuffled = false,
    this.isBuffering = false,
    this.isSeeking = false,
    this.error,
    this.config = const PlaybackConfig(),
    this.isCrossfading = false,
  });

  PlayerState copyWith({
    Song? currentSong,
    List<Song>? queue,
    int? currentIndex,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    RepeatMode? repeatMode,
    bool? isShuffled,
    bool? isBuffering,
    bool? isSeeking,
    String? error,
    PlaybackConfig? config,
    bool? isCrossfading, required double volume,
  }) {
    return PlayerState(
      currentSong: currentSong ?? this.currentSong,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      repeatMode: repeatMode ?? this.repeatMode,
      isShuffled: isShuffled ?? this.isShuffled,
      isBuffering: isBuffering ?? this.isBuffering,
      isSeeking: isSeeking ?? this.isSeeking,
      error: error ?? this.error,
      config: config ?? this.config,
      isCrossfading:
          isCrossfading ?? this.isCrossfading,
    );
  }

  double get progress {
    if (duration.inMilliseconds == 0) return 0.0;

    return (position.inMilliseconds /
            duration.inMilliseconds)
        .clamp(0.0, 1.0);
  }

  bool get hasPrevious => currentIndex > 0;

  bool get hasNext =>
      currentIndex < queue.length - 1 ||
      repeatMode == RepeatMode.all;

  dynamic get volume => null;
}

// ─────────────────────────────────────────────────────────────────────────────
// Player Notifier
// ─────────────────────────────────────────────────────────────────────────────

class PlayerNotifier
    extends StateNotifier<PlayerState> {
  late final AudioPlayer _primary;
  late final AudioPlayer _crossfadePlayer;

  AndroidEqualizer? _eq;
  AndroidLoudnessEnhancer? _loudness;

  final List<StreamSubscription> _subs = [];

  bool _disposed = false;

  PlayerNotifier() : super(const PlayerState()) {
    _init();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Init
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> _init() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        _eq = AndroidEqualizer();
        _loudness = AndroidLoudnessEnhancer();

        _primary = AudioPlayer(
          audioPipeline: AudioPipeline(
            androidAudioEffects: [
              _eq!,
              _loudness!,
            ],
          ),
        );
      } catch (e) {
        debugPrint('Audio effects init error: $e');

        _primary = AudioPlayer();
      }
    } else {
      _primary = AudioPlayer();
    }

    _crossfadePlayer = AudioPlayer();

    try {
      final session = await AudioSession.instance;

      await session.configure(
        const AudioSessionConfiguration.music(),
      );
    } catch (e) {
      debugPrint('AudioSession error: $e');
    }

    _attachStreams();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Streams
  // ───────────────────────────────────────────────────────────────────────────

  void _attachStreams() {
    _subs.add(
      _primary.positionStream.listen((pos) {
        if (_disposed || state.isSeeking) return;

        state = state.copyWith(position: pos, volume: state.volume);

        if (state.config.crossfade &&
            state.hasNext &&
            state.duration.inSeconds > 0) {
          final remaining =
              state.duration.inSeconds -
                  pos.inSeconds;

          final fadeIn =
              state.config.crossfadeDuration
                  .clamp(1.0, 12.0)
                  .toInt();

          if (remaining == fadeIn &&
              !state.isCrossfading) {
            _startCrossfade();
          }
        }
      }),
    );

    _subs.add(
      _primary.durationStream.listen((duration) {
        if (_disposed) return;

        state = state.copyWith(
          duration: duration ?? Duration.zero,
          volume: state.volume,
        );
      }),
    );

    _subs.add(
      _primary.playingStream.listen((playing) {
        if (_disposed) return;

        state = state.copyWith(
          isPlaying: playing,
          volume: state.volume,
        );
      }),
    );

    _subs.add(
      _primary.processingStateStream.listen((ps) {
        if (_disposed) return;

        state = state.copyWith(
          isBuffering:
              ps == ProcessingState.loading ||
                  ps ==
                      ProcessingState.buffering, volume: state.volume,
        );

        if (ps == ProcessingState.completed) {
          if (state.repeatMode ==
              RepeatMode.one) {
            _safeSeek(Duration.zero);
            _primary.play();
          } else if (!state.isCrossfading) {
            playNext();
          }
        }
      }),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Seek
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> _safeSeek(Duration target) async {
    if (_disposed) return;

    try {
      final max =
          state.duration.inMilliseconds;

      final clamped = Duration(
        milliseconds: target.inMilliseconds
            .clamp(0, max),
      );

      state = state.copyWith(
        isSeeking: true,
        position: clamped,
        volume: state.volume,
      );

      await _primary.seek(clamped);
    } catch (e) {
      debugPrint('Seek error: $e');
    } finally {
      if (!_disposed) {
        state = state.copyWith(
          isSeeking: false,
          volume: state.volume,
        );
      }
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Audio Source
  // ───────────────────────────────────────────────────────────────────────────

  AudioSource _sourceFor(Song song) {
    final tag = MediaItem(
      id: song.id,
      title: song.title,
      artist: song.artist,
      album: song.album,
      artUri: song.albumArtUrl != null
          ? Uri.parse(song.albumArtUrl!)
          : null,
      duration: Duration(
        seconds: song.duration,
      ),
    );

    if (song.filePath == null) {
      throw Exception('No file path');
    }

    if (song.source ==
            PlaybackSource.youtube ||
        song.filePath!
            .startsWith('http')) {
      return AudioSource.uri(
        Uri.parse(song.filePath!),
        tag: tag,
      );
    }

    return AudioSource.uri(
      Uri.file(song.filePath!),
      tag: tag,
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Queue
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> _loadQueueGapless(
    List<Song> songs,
    int startIndex,
  ) async {
    try {
      final sources = songs
          .map((song) {
            try {
              return _sourceFor(song);
            } catch (_) {
              return null;
            }
          })
          .whereType<AudioSource>()
          .toList();

      if (sources.isEmpty) return;

      final playlist =
          ConcatenatingAudioSource(
        shuffleOrder:
            DefaultShuffleOrder(),
        children: sources,
      );

      await _primary.setAudioSource(
        playlist,
        initialIndex: startIndex.clamp(
          0,
          sources.length - 1,
        ),
        initialPosition: Duration.zero,
      );

      _subs.add(
        _primary.currentIndexStream
            .listen((idx) {
          if (_disposed || idx == null) {
            return;
          }

          if (idx != state.currentIndex &&
              idx < state.queue.length) {
            state = state.copyWith(
              currentIndex: idx,
              currentSong: state.queue[idx],
              position: Duration.zero,
              volume: state.volume,
            );
          }
        }),
      );

      await _primary.setVolume(
        state.config.volume,
      );

      await _primary.setSpeed(
        state.config.speed,
      );

      await _primary.play();
    } catch (e) {
      debugPrint(
        '_loadQueueGapless error: $e',
      );

      state = state.copyWith(
        error: e.toString(),
        isBuffering: false,
        volume: state.volume,
      );
    }
  }

  Future<void> _loadSingle(
    Song song,
  ) async {
    try {
      state = state.copyWith(
        currentSong: song,
        isBuffering: true,
        position: Duration.zero,
        volume: state.volume,
      );

      final source = _sourceFor(song);

      await _primary.setAudioSource(
        source,
      );

      await _primary.setVolume(
        state.config.volume,
      );

      await _primary.setSpeed(
        state.config.speed,
      );

      await _primary.play();
    } catch (e) {
      debugPrint(
        '_loadSingle error: $e',
      );

      if (!_disposed) {
        state = state.copyWith(
          isBuffering: false,
          error: e.toString(),
          volume: state.volume,
        );
      }
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Crossfade
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> _startCrossfade() async {
    if (state.isCrossfading ||
        !state.hasNext) {
      return;
    }

    state = state.copyWith(
      isCrossfading: true,
      volume: state.volume,
    );

    final nextIndex =
        (state.currentIndex + 1) %
            state.queue.length;

    final nextSong =
        state.queue[nextIndex];

    try {
      final nextSource =
          _sourceFor(nextSong);

      await _crossfadePlayer
          .setAudioSource(nextSource);

      await _crossfadePlayer
          .setVolume(0.0);

      await _crossfadePlayer.play();

      final fadeMs =
          (state.config.crossfadeDuration *
                  1000)
              .toInt()
              .clamp(500, 12000);

      const steps = 40;

      final stepDuration = Duration(
        milliseconds: fadeMs ~/ steps,
      );

      for (int i = 1; i <= steps; i++) {
        await Future.delayed(
          stepDuration,
        );

        if (_disposed ||
            !state.isCrossfading) {
          return;
        }

        final t = i / steps;

        await _primary.setVolume(
          ((1.0 - t) *
                  state.config.volume)
              .clamp(0.0, 1.0),
        );

        await _crossfadePlayer
            .setVolume(
          (t * state.config.volume)
              .clamp(0.0, 1.0),
        );
      }

      await _primary.stop();

      await _primary.setVolume(
        state.config.volume,
      );

      state = state.copyWith(
        currentSong: nextSong,
        currentIndex: nextIndex,
        position: Duration.zero,
        isCrossfading: false,
        volume: state.volume,
      );

      await _loadSingle(nextSong);

      await _crossfadePlayer.stop();
    } catch (e) {
      debugPrint(
        'Crossfade error: $e',
      );

      state = state.copyWith(
        isCrossfading: false,
        volume: state.volume,
      );
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Controls
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> play() async {
    try {
      await _primary.play();
    } catch (e) {
      debugPrint('play error: $e');
    }
  }

  Future<void> pause() async {
    try {
      await _primary.pause();

      if (state.isCrossfading) {
        await _crossfadePlayer.pause();
      }
    } catch (e) {
      debugPrint('pause error: $e');
    }
  }

  Future<void> togglePlayPause() async {
    if (state.isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> seekTo(Duration pos) async {
    await _safeSeek(pos);
  }

  Future<void> seekToRelative(
    double value,
  ) async {
    if (state.duration.inMilliseconds ==
        0) {
      return;
    }

    final target = Duration(
      milliseconds:
          (value.clamp(0.0, 1.0) *
                  state.duration
                      .inMilliseconds)
              .round(),
    );

    state = state.copyWith(
      position: target,
      volume: state.volume,
    );

    await _safeSeek(target);
  }

  Future<void> playNext() async {
    if (state.queue.isEmpty) return;

    final next =
        (state.currentIndex + 1) %
            state.queue.length;

    if (state.config.gapless) {
      try {
        await _primary.seekToNext();
      } catch (_) {
        await _playAtIndex(next);
      }
    } else {
      await _playAtIndex(next);
    }
  }

  Future<void> playPrevious() async {
    if (state.position.inSeconds > 3) {
      await _safeSeek(Duration.zero);
      return;
    }

    if (state.queue.isEmpty) return;

    final prev = state.currentIndex > 0
        ? state.currentIndex - 1
        : state.queue.length - 1;

    if (state.config.gapless) {
      try {
        await _primary.seekToPrevious();
      } catch (_) {
        await _playAtIndex(prev);
      }
    } else {
      await _playAtIndex(prev);
    }
  }

  Future<void> _playAtIndex(
    int index,
  ) async {
    if (index < 0 ||
        index >= state.queue.length) {
      return;
    }

    final song = state.queue[index];

    state = state.copyWith(
      currentIndex: index,
      currentSong: song, volume: state.volume,
    );

    await _loadSingle(song);
  }

  Future<void> playSong(
    Song song,
  ) async {
    final idx = state.queue.indexWhere(
      (s) => s.id == song.id,
    );

    if (idx >= 0) {
      state = state.copyWith(
        currentIndex: idx,
        volume: state.volume,
      );

      if (state.config.gapless) {
        try {
          await _primary.seek(
            Duration.zero,
            index: idx,
          );

          await _primary.play();

          return;
        } catch (_) {}
      }

      await _loadSingle(song);
    } else {
      final newQueue = [
        song,
        ...state.queue,
      ];

      state = state.copyWith(
        queue: newQueue,
        currentIndex: 0,
        currentSong: song,
        volume: state.volume,
      );

      if (state.config.gapless) {
        await _loadQueueGapless(
          newQueue,
          0,
        );
      } else {
        await _loadSingle(song);
      }
    }
  }

  Future<void> playPlaylist(
    List<Song> songs, {
    int startIndex = 0,
  }) async {
    if (songs.isEmpty) return;

    final idx = startIndex.clamp(
      0,
      songs.length - 1,
    );

    state = state.copyWith(
      queue: songs,
      currentIndex: idx,
      currentSong: songs[idx],
      volume: state.volume,
    );

    if (state.config.gapless) {
      await _loadQueueGapless(
        songs,
        idx,
      );
    } else {
      await _loadSingle(songs[idx]);
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Config
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> updateConfig(
    PlaybackConfig config,
  ) async {
    state = state.copyWith(
      config: config,
      volume: state.volume,
    );

    try {
      await _primary.setVolume(
        config.volume,
      );

      await _primary.setSpeed(
        config.speed,
      );

      await _primary.setLoopMode(
        switch (state.repeatMode) {
          RepeatMode.one =>
            LoopMode.one,
          RepeatMode.all =>
            LoopMode.all,
          RepeatMode.none =>
            LoopMode.off,
        },
      );
    } catch (_) {}
  }

  Future<void> setVolume(
    double v,
  ) async {
    final clamped =
        v.clamp(0.0, 1.0);

    state = state.copyWith(
      config: state.config.copyWith(
        volume: clamped,
      ), volume: clamped,
    );

    try {
      await _primary.setVolume(
        clamped,
      );
    } catch (_) {}
  }

  Future<void> setPlaybackSpeed(
    double s,
  ) async {
    state = state.copyWith(
      config: state.config.copyWith(
        speed: s,
      ),
      volume: state.volume,
    );

    try {
      await _primary.setSpeed(s);
    } catch (_) {}
  }

  void toggleRepeat() {
    final next =
        switch (state.repeatMode) {
      RepeatMode.none =>
        RepeatMode.all,
      RepeatMode.all =>
        RepeatMode.one,
      RepeatMode.one =>
        RepeatMode.none,
    };

    state = state.copyWith(
      repeatMode: next,
      volume: state.volume,
    );

    try {
      _primary.setLoopMode(
        switch (next) {
          RepeatMode.one =>
            LoopMode.one,
          RepeatMode.all =>
            LoopMode.all,
          RepeatMode.none =>
            LoopMode.off,
        },
      );
    } catch (_) {}
  }

  void toggleShuffle() {
    final shuffled =
        !state.isShuffled;

    state = state.copyWith(
      isShuffled: shuffled,
      volume: state.volume,
    );

    try {
      _primary.setShuffleModeEnabled(
        shuffled,
      );
    } catch (_) {}
  }

  void toggleFavorite() {
    if (state.currentSong == null) {
      return;
    }

    final updated =
        state.currentSong!.copyWith(
      isFavorite:
          !state.currentSong!
              .isFavorite,
    );

    final updatedQueue = state.queue
        .map(
          (song) => song.id == updated.id
              ? updated
              : song,
        )
        .toList();

    state = state.copyWith(
      currentSong: updated,
      queue: updatedQueue,
      volume: state.volume,
    );
  }

  void addToQueue(Song song) {
    state = state.copyWith(
      queue: [
        ...state.queue,
        song,
      ],
      volume: state.volume,
    );
  }

  void clearQueue() {
    try {
      _primary.stop();
    } catch (_) {}

    state = state.copyWith(
      queue: [],
      currentIndex: 0,
      volume: state.volume,
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Audio Effects
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> applyEQBands(
    List<double> bands, {
    bool enabled = true,
  }) async {
    if (_eq == null) return;

    try {
      await _eq!.setEnabled(
        enabled,
      );

      if (!enabled) return;

      final params =
          await _eq!.parameters;

      final eqBands = params.bands;

      for (
        int i = 0;
        i < eqBands.length &&
            i < bands.length;
        i++
      ) {
        await eqBands[i]
            .setGain(bands[i]);
      }
    } catch (e) {
      debugPrint(
        'EQ bands error: $e',
      );
    }
  }

  Future<void> applyBassBoost(
    double level,
  ) async {
    if (_eq == null) return;

    try {
      final params =
          await _eq!.parameters;

      final bands = params.bands;

      final gain =
          (level / 100) * 9.0;

      for (
        int i = 0;
        i < 3 && i < bands.length;
        i++
      ) {
        await bands[i].setGain(
          gain * (1.0 - i * 0.25),
        );
      }
    } catch (e) {
      debugPrint(
        'Bass boost error: $e',
      );
    }
  }

  Future<void>
      applyLoudnessEnhancer(
    double level,
  ) async {
    if (_loudness == null) return;

    try {
      await _loudness!.setEnabled(
        level > 0,
      );

      if (level > 0) {
        await _loudness!
            .setTargetGain(
          (level * 6).round() as double,
        );
      }
    } catch (e) {
      debugPrint(
        'Loudness error: $e',
      );
    }
  }

  Future<void>
      disableAllEffects() async {
    try {
      await _eq?.setEnabled(false);
      await _loudness?.setEnabled(
        false,
      );
    } catch (_) {}
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Dispose
  // ───────────────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _disposed = true;

    for (final sub in _subs) {
      sub.cancel();
    }

    _primary.dispose();
    _crossfadePlayer.dispose();

    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final playerProvider =
    StateNotifierProvider<
        PlayerNotifier,
        PlayerState>(
  (ref) => PlayerNotifier(),
);