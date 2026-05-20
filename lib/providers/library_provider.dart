import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../models/song.dart';

// ─── Library State ────────────────────────────────────────────────────────────

class LibraryState {
  final List<Song> songs;
  final List<Playlist> playlists;
  final List<Album> albums;
  final List<Artist> artists;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final String sortBy;

  const LibraryState({
    this.songs = const [],
    this.playlists = const [],
    this.albums = const [],
    this.artists = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.sortBy = 'title',
  });

  LibraryState copyWith({
    List<Song>? songs,
    List<Playlist>? playlists,
    List<Album>? albums,
    List<Artist>? artists,
    bool? isLoading,
    String? error,
    String? searchQuery,
    String? sortBy,
  }) {
    return LibraryState(
      songs: songs ?? this.songs,
      playlists: playlists ?? this.playlists,
      albums: albums ?? this.albums,
      artists: artists ?? this.artists,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  List<Song> get filteredSongs {
    if (searchQuery.isEmpty) return _sorted(songs);
    final q = searchQuery.toLowerCase();
    return _sorted(songs.where((s) {
      return s.title.toLowerCase().contains(q) ||
          s.artist.toLowerCase().contains(q) ||
          s.album.toLowerCase().contains(q);
    }).toList());
  }

  List<Song> _sorted(List<Song> list) {
    final copy = List<Song>.from(list);
    switch (sortBy) {
      case 'artist':
        copy.sort((a, b) => a.artist.compareTo(b.artist));
        break;
      case 'album':
        copy.sort((a, b) => a.album.compareTo(b.album));
        break;
      case 'date_added':
        copy.sort((a, b) {
          if (a.dateAdded == null && b.dateAdded == null) return 0;
          if (a.dateAdded == null) return 1;
          if (b.dateAdded == null) return -1;
          return b.dateAdded!.compareTo(a.dateAdded!);
        });
        break;
      case 'duration':
        copy.sort((a, b) => a.duration.compareTo(b.duration));
        break;
      default: // title
        copy.sort((a, b) => a.title.compareTo(b.title));
    }
    return copy;
  }

  List<Song> get favoriteSongs => songs.where((s) => s.isFavorite).toList();

  List<Song> get recentlyPlayed {
    return songs
        .where((s) => s.lastPlayed != null)
        .toList()
      ..sort((a, b) => b.lastPlayed!.compareTo(a.lastPlayed!));
  }
}

// ─── Library Notifier ─────────────────────────────────────────────────────────

class LibraryNotifier extends StateNotifier<LibraryState> {
  // Supported audio extensions
  static const _audioExts = {
    'mp3', 'flac', 'wav', 'aac', 'm4a', 'alac',
    'ogg', 'opus', 'wma', 'dsd', 'dsf', 'dff', 'aiff', 'aif',
  };

  LibraryNotifier() : super(const LibraryState());

  // ── Called from main.dart after StorageScanner finishes ──────────────────

  void loadScannedSongs(List<Song> scanned) {
    if (scanned.isEmpty) return;
    _rebuild(scanned);
  }

  // ── File picker import (user taps "Import music") ─────────────────────────

  Future<void> importFiles() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: _audioExts.toList(),
        withData: false,
        withReadStream: false,
      );

      if (result == null || result.files.isEmpty) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final newSongs = <Song>[];
      for (final file in result.files) {
        final path = file.path;
        if (path == null) continue;

        // Skip duplicates
        if (state.songs.any((s) => s.filePath == path)) continue;

        final song = await _songFromFilePath(path);
        if (song != null) newSongs.add(song);
      }

      if (newSongs.isNotEmpty) {
        _rebuild([...state.songs, ...newSongs]);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      debugPrint('importFiles error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Import failed: $e',
      );
    }
  }

  // ── Import a single folder recursively (desktop/web drag-drop) ───────────

  Future<void> importFolder() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final path = await FilePicker.platform.getDirectoryPath();
      if (path == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final dir = Directory(path);
      final found = <Song>[];

      await for (final entity in dir.list(recursive: true)) {
        if (entity is! File) continue;
        final ext = p.extension(entity.path).toLowerCase().replaceFirst('.', '');
        if (!_audioExts.contains(ext)) continue;
        if (state.songs.any((s) => s.filePath == entity.path)) continue;

        final song = await _songFromFilePath(entity.path);
        if (song != null) found.add(song);
      }

      if (found.isNotEmpty) {
        _rebuild([...state.songs, ...found]);
      } else {
        state = state.copyWith(isLoading: false,
            error: 'No supported audio files found in that folder.');
      }
    } catch (e) {
      debugPrint('importFolder error: $e');
      state = state.copyWith(isLoading: false, error: 'Import failed: $e');
    }
  }

  // ── Build a Song from a raw file path (no metadata library yet) ──────────

  Future<Song?> _songFromFilePath(String filePath) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) return null;

      final filename = p.basenameWithoutExtension(filePath);
      final ext = p.extension(filePath).toLowerCase().replaceFirst('.', '');

      // Parse "Artist - Title" from filename if present
      String title = filename;
      String artist = 'Unknown Artist';
      if (filename.contains(' - ')) {
        final parts = filename.split(' - ');
        artist = parts[0].trim();
        title = parts.sublist(1).join(' - ').trim();
      }

      final stat = file.statSync();
      final id = '${filePath.hashCode}_${stat.size}';

      return Song(
        id: id,
        title: title,
        artist: artist,
        album: 'Unknown Album',
        filePath: filePath,
        format: ext.toUpperCase(),
        fileSize: stat.size,
        duration: 0, // will be read by just_audio on load
        dateAdded: DateTime.now(),
        source: PlaybackSource.local,
      );
    } catch (e) {
      debugPrint('_songFromFilePath($filePath) error: $e');
      return null;
    }
  }

  // ── Rebuild derived collections from songs ────────────────────────────────

  void _rebuild(List<Song> songs) {
    final albums  = _buildAlbums(songs);
    final artists = _buildArtists(songs, albums);
    state = state.copyWith(
      songs: songs,
      albums: albums,
      artists: artists,
      isLoading: false,
      error: null,
    );
  }

  List<Album> _buildAlbums(List<Song> songs) {
    final map = <String, List<Song>>{};
    for (final s in songs) {
      map.putIfAbsent(s.album, () => []).add(s);
    }
    return map.entries.map((e) {
      final list = e.value;
      return Album(
        id: e.key,
        name: e.key,
        artist: list.first.artist,
        songs: list,
        coverUrl: list.first.albumArtUrl,
        coverPath: list.first.albumArtPath,
        genre: list.first.genre,
      );
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  List<Artist> _buildArtists(List<Song> songs, List<Album> albums) {
    final map = <String, List<Song>>{};
    for (final s in songs) {
      map.putIfAbsent(s.artist, () => []).add(s);
    }
    return map.entries.map((e) {
      final artistAlbums = albums.where((a) => a.artist == e.key).toList();
      return Artist(
        id: e.key,
        name: e.key,
        songs: e.value,
        albums: artistAlbums,
        imageUrl: e.value.first.albumArtUrl,
        imagePath: e.value.first.albumArtPath,
      );
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  // ── Search / sort ─────────────────────────────────────────────────────────

  void setSearchQuery(String query) =>
      state = state.copyWith(searchQuery: query);

  void setSortBy(String sortBy) =>
      state = state.copyWith(sortBy: sortBy);

  // ── Favorites ─────────────────────────────────────────────────────────────

  void toggleFavorite(String songId) {
    final songs = state.songs
        .map((s) => s.id == songId ? s.copyWith(isFavorite: !s.isFavorite) : s)
        .toList();
    _rebuild(songs);
  }

  // ── Remove a song ─────────────────────────────────────────────────────────

  void removeSong(String songId) {
    _rebuild(state.songs.where((s) => s.id != songId).toList());
  }

  // ── Update a song's duration once just_audio resolves it ─────────────────

  void updateSongDuration(String songId, int seconds) {
    final songs = state.songs
        .map((s) => s.id == songId ? s.copyWith(duration: seconds) : s)
        .toList();
    state = state.copyWith(songs: songs);
  }

  // ── Mark as played ────────────────────────────────────────────────────────

  void markPlayed(String songId) {
    final songs = state.songs
        .map((s) => s.id == songId
            ? s.copyWith(
                lastPlayed: DateTime.now(),
                playCount: s.playCount + 1,
              )
            : s)
        .toList();
    state = state.copyWith(songs: songs);
  }
}

final libraryProvider =
    StateNotifierProvider<LibraryNotifier, LibraryState>((ref) {
  return LibraryNotifier();
});

// ─── Theme ────────────────────────────────────────────────────────────────────

class AppThemeState {
  final ThemeMode themeMode;
  final Color accentColor;
  final bool useBlurEffects;
  final bool showAnimations;
  final String backgroundStyle;

  const AppThemeState({
    this.themeMode = ThemeMode.dark,
    this.accentColor = const Color(0xFFD4D4D8),
    this.useBlurEffects = true,
    this.showAnimations = true,
    this.backgroundStyle = 'gradient',
  });

  AppThemeState copyWith({
    ThemeMode? themeMode,
    Color? accentColor,
    bool? useBlurEffects,
    bool? showAnimations,
    String? backgroundStyle,
  }) {
    return AppThemeState(
      themeMode: themeMode ?? this.themeMode,
      accentColor: accentColor ?? this.accentColor,
      useBlurEffects: useBlurEffects ?? this.useBlurEffects,
      showAnimations: showAnimations ?? this.showAnimations,
      backgroundStyle: backgroundStyle ?? this.backgroundStyle,
    );
  }
}

class ThemeNotifier extends StateNotifier<AppThemeState> {
  ThemeNotifier() : super(const AppThemeState());

  void setThemeMode(ThemeMode mode) =>
      state = state.copyWith(themeMode: mode);
  void setAccentColor(Color c) => state = state.copyWith(accentColor: c);
  void toggleBlurEffects() =>
      state = state.copyWith(useBlurEffects: !state.useBlurEffects);
  void toggleAnimations() =>
      state = state.copyWith(showAnimations: !state.showAnimations);
  void setBackgroundStyle(String s) =>
      state = state.copyWith(backgroundStyle: s);
}

final themeProvider =
    StateNotifierProvider<ThemeNotifier, AppThemeState>((ref) {
  return ThemeNotifier();
});

// ─── Navigation ───────────────────────────────────────────────────────────────

final currentTabProvider = StateProvider<int>((ref) => 0);
final showNowPlayingProvider = StateProvider<bool>((ref) => false);
