import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aurasound/main.dart';
import 'package:aurasound/providers/audio_provider.dart';
import 'package:aurasound/providers/library_provider.dart';
import 'package:aurasound/models/song.dart';
import 'package:aurasound/core/theme/app_colors.dart';
import 'package:aurasound/core/utils/format_utils.dart';

void main() {
  group('FormatUtils', () {
    test('formatDuration formats seconds correctly', () {
      expect(FormatUtils.formatDuration(const Duration(seconds: 0)), '00:00');
      expect(FormatUtils.formatDuration(const Duration(seconds: 65)), '01:05');
      expect(FormatUtils.formatDuration(const Duration(minutes: 3, seconds: 42)), '03:42');
    });

    test('formatDurationShort formats int seconds', () {
      expect(FormatUtils.formatDurationShort(0), '0:00');
      expect(FormatUtils.formatDurationShort(90), '1:30');
      expect(FormatUtils.formatDurationShort(3661), '61:01');
    });

    test('formatFileSize returns human-readable sizes', () {
      expect(FormatUtils.formatFileSize(512), '512B');
      expect(FormatUtils.formatFileSize(1024), '1.0KB');
      expect(FormatUtils.formatFileSize(1024 * 1024 * 5), '5.0MB');
    });

    test('formatBitrate formats kbps', () {
      expect(FormatUtils.formatBitrate(320000), '320kbps');
      expect(FormatUtils.formatBitrate(1411000), '1411kbps');
    });

    test('truncate clips long strings', () {
      expect(FormatUtils.truncate('Hello World', 5), 'Hello...');
      expect(FormatUtils.truncate('Hi', 5), 'Hi');
    });
  });

  group('PlayerState', () {
    test('progress returns 0 when duration is zero', () {
      const state = PlayerState();
      expect(state.progress, 0.0);
    });

    test('progress calculates correctly', () {
      const state = PlayerState(
        position: Duration(seconds: 30),
        duration: Duration(seconds: 60),
      );
      expect(state.progress, 0.5);
    });

    test('copyWith updates fields correctly', () {
      const state = PlayerState(isPlaying: false);
      final updated = state.copyWith(isPlaying: true, volume: 0.8);
      expect(updated.isPlaying, true);
      expect(updated.volume, 0.8);
    });

    test('hasPrevious is false when at start of empty queue', () {
      const state = PlayerState(currentIndex: 0);
      expect(state.hasPrevious, false);
    });
  });

  group('Song model', () {
    const song = Song(
      id: 'test-1',
      title: 'Test Song',
      artist: 'Test Artist',
      album: 'Test Album',
      duration: 240,
    );

    test('song equality by id', () {
      const same = Song(id: 'test-1', title: 'Other', artist: 'Other', album: 'Other', duration: 100);
      expect(song, same);
    });

    test('copyWith preserves unchanged fields', () {
      final updated = song.copyWith(isFavorite: true);
      expect(updated.title, 'Test Song');
      expect(updated.isFavorite, true);
    });
  });

  group('LibraryState', () {
    test('filteredSongs returns all when query is empty', () {
      final songs = [
        const Song(id: '1', title: 'Alpha', artist: 'Artist', album: 'Album', duration: 200),
        const Song(id: '2', title: 'Beta', artist: 'Artist', album: 'Album', duration: 180),
      ];
      final state = LibraryState(songs: songs, searchQuery: '');
      expect(state.filteredSongs.length, 2);
    });

    test('filteredSongs filters by title', () {
      final songs = [
        const Song(id: '1', title: 'Blinding Lights', artist: 'The Weeknd', album: 'After Hours', duration: 200),
        const Song(id: '2', title: 'Stay', artist: 'The Kid LAROI', album: 'F*CK LOVE', duration: 141),
      ];
      final state = LibraryState(songs: songs, searchQuery: 'blind');
      expect(state.filteredSongs.length, 1);
      expect(state.filteredSongs.first.title, 'Blinding Lights');
    });

    test('favoriteSongs returns only favorites', () {
      final songs = [
        const Song(id: '1', title: 'A', artist: 'B', album: 'C', duration: 100, isFavorite: true),
        const Song(id: '2', title: 'D', artist: 'E', album: 'F', duration: 100, isFavorite: false),
      ];
      final state = LibraryState(songs: songs);
      expect(state.favoriteSongs.length, 1);
    });
  });

  group('AppColors', () {
    test('glassBorder has correct opacity', () {
      expect(AppColors.glassBorder.alpha, lessThan(255));
    });

    test('primary color is correct', () {
      expect(AppColors.primary.value, 0xFF7C6FFF);
    });
  });

  group('Widget tests', () {
    testWidgets('App renders without crashing', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: AuraSoundApp()),
      );
      // App should render splash screen
      await tester.pump();
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
