import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/song.dart';

// ─── Scan State ───────────────────────────────────────────────────────────────

enum ScanStatus { idle, requesting, scanning, done, denied }

class ScanState {
  final ScanStatus status;
  final List<Song> songs;
  final int scanned;
  final String? error;

  const ScanState({
    this.status = ScanStatus.idle,
    this.songs = const [],
    this.scanned = 0,
    this.error,
  });

  ScanState copyWith({
    ScanStatus? status,
    List<Song>? songs,
    int? scanned,
    String? error,
  }) {
    return ScanState(
      status: status ?? this.status,
      songs: songs ?? this.songs,
      scanned: scanned ?? this.scanned,
      error: error,
    );
  }

  bool get isLoading =>
      status == ScanStatus.requesting || status == ScanStatus.scanning;
}

// ─── Scanner Service ──────────────────────────────────────────────────────────

class StorageScannerNotifier extends StateNotifier<ScanState> {
  final OnAudioQuery _query = OnAudioQuery();

  StorageScannerNotifier() : super(const ScanState());

  // ── Permissions ────────────────────────────────────────────────────────────

  Future<bool> _requestPermissions() async {
    if (kIsWeb) return true; // Web handles its own file picker

    state = state.copyWith(status: ScanStatus.requesting);

    if (Platform.isAndroid) {
      // Android 13+ uses READ_MEDIA_AUDIO
      // Android < 13 uses READ_EXTERNAL_STORAGE
      final sdkInt = await _androidSdkVersion();
      Permission perm;
      if (sdkInt >= 33) {
        perm = Permission.audio;
      } else {
        perm = Permission.storage;
      }

      var result = await perm.status;
      if (result.isDenied) {
        result = await perm.request();
      }
      if (result.isPermanentlyDenied) {
        state = state.copyWith(
          status: ScanStatus.denied,
          error: 'Storage permission permanently denied. '
              'Enable it in Settings → App Permissions.',
        );
        return false;
      }
      return result.isGranted;
    }

    if (Platform.isIOS) {
      final result = await Permission.mediaLibrary.request();
      return result.isGranted;
    }

    // Windows / Linux / macOS — no permission needed
    return true;
  }

  Future<int> _androidSdkVersion() async {
    try {
      if (Platform.isAndroid) {
        // on_audio_query can tell us
        await _query.permissionsStatus();
        // Rough detection: use platform version string
        final vStr = Platform.operatingSystemVersion;
        // Android 13 = SDK 33
        if (vStr.contains('13') || vStr.contains('14') || vStr.contains('15')) {
          return 33;
        }
      }
    } catch (_) {}
    return 30; // assume SDK 30 if unsure
  }

  // ── Main scan entry point ──────────────────────────────────────────────────

  /// Call this on app startup. Asks for permission then scans.
  Future<void> scanAndLoad() async {
    if (state.isLoading) return;

    final granted = await _requestPermissions();
    if (!granted) return;

    await _doScan();
  }

  Future<void> _doScan() async {
    state = state.copyWith(status: ScanStatus.scanning, scanned: 0);
    try {
      if (kIsWeb) {
        // Web: nothing to auto-scan, files are imported via picker
        state = state.copyWith(status: ScanStatus.done);
        return;
      }

      // Request on_audio_query permission
      final hasPermission = await _query.permissionsRequest();
      if (!hasPermission) {
        state = state.copyWith(
          status: ScanStatus.denied,
          error: 'Permission denied by on_audio_query',
        );
        return;
      }

      // Query all songs from MediaStore (Android) / Music library (iOS)
      final rawSongs = await _query.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      final songs = rawSongs
          .where((s) =>
              s.isMusic == true &&
              s.duration != null &&
              (s.duration ?? 0) > 10000)
          .map(_toSong)
          .toList();

      state = state.copyWith(
        status: ScanStatus.done,
        songs: songs,
        scanned: songs.length,
      );
    } catch (e) {
      debugPrint('StorageScanner error: $e');
      state = state.copyWith(
        status: ScanStatus.done, // done but with error
        error: e.toString(),
      );
    }
  }

  Song _toSong(SongModel m) {
    return Song(
      id: m.id.toString(),
      title: m.title,
      artist: m.artist ?? 'Unknown Artist',
      album: m.album ?? 'Unknown Album',
      genre: m.genre,
      filePath: m.data,
      duration: ((m.duration ?? 0) / 1000).round(),
      bitrate: m.bitrate,
      format: _ext(m.data),
      fileSize: m.size,
      dateAdded: m.dateAdded != null
          ? DateTime.fromMillisecondsSinceEpoch(m.dateAdded! * 1000)
          : null,
    );
  }

  String? _ext(String? path) {
    if (path == null) return null;
    final dot = path.lastIndexOf('.');
    if (dot < 0) return null;
    return path.substring(dot + 1).toUpperCase();
  }

  // ── Re-scan (called from settings) ────────────────────────────────────────

  Future<void> rescan() async {
    state = state.copyWith(status: ScanStatus.idle, error: null);
    await scanAndLoad();
  }
}

extension on SongModel {
  int? get bitrate => null;
}

final storageScannerProvider =
    StateNotifierProvider<StorageScannerNotifier, ScanState>((ref) {
  return StorageScannerNotifier();
});
