import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/format_utils.dart';
import '../../providers/audio_provider.dart' hide RepeatMode;
import '../../models/song.dart';

class NowPlayingScreen extends ConsumerStatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  ConsumerState<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends ConsumerState<NowPlayingScreen>
    with TickerProviderStateMixin {
  late AnimationController _spin;
  late AnimationController _wave;
  late AnimationController _glow;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
    _wave = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat();
    _glow = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _spin.dispose();
    _wave.dispose();
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ps = ref.watch(playerProvider);
    final player = ref.read(playerProvider.notifier);
    final song = ps.currentSong;

    // Sync vinyl to playback
    if (ps.isPlaying && !_spin.isAnimating) _spin.repeat();
    if (!ps.isPlaying && _spin.isAnimating) _spin.stop();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Blurred background art
          if (song?.albumArtUrl != null)
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
                child: Image.network(song!.albumArtUrl!, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox()),
              ),
            ),
          // Dark overlay
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xF00C0C0E), Color(0xF5111113), Color(0xFA0C0C0E)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                _TopBar(song: song),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        // Album art / vinyl
                        _AlbumArt(song: song, spin: _spin, glow: _glow, isPlaying: ps.isPlaying),
                        const SizedBox(height: 28),
                        // Song info + like
                        _SongInfo(song: song, isFavorite: song?.isFavorite ?? false,
                            onLike: () => player.toggleFavorite()),
                        const SizedBox(height: 20),
                        // Waveform
                        _Waveform(controller: _wave, isPlaying: ps.isPlaying),
                        const SizedBox(height: 16),
                        // Progress
                        _ProgressBar(ps: ps, player: player),
                        const SizedBox(height: 24),
                        // Playback controls
                        _Controls(ps: ps, player: player),
                        const SizedBox(height: 28),
                        // Bottom action strip
                        _ActionStrip(),
                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Top Bar ──────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final Song? song;
  const _TopBar({this.song});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: AppColors.glassWhite,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textPrimary, size: 22),
            ),
          ),
          const Expanded(
            child: Column(
              children: [
                Text('Now playing',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 10,
                        color: AppColors.textTertiary, letterSpacing: 1.5,
                        fontWeight: FontWeight.w600)),
                Text('AuraSound',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 13,
                        color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: AppColors.glassWhite,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: const Icon(Icons.more_horiz_rounded, color: AppColors.textPrimary, size: 18),
          ),
        ],
      ),
    );
  }
}

// ─── Album Art ────────────────────────────────────────────────────────────────

class _AlbumArt extends StatelessWidget {
  final Song? song;
  final AnimationController spin;
  final AnimationController glow;
  final bool isPlaying;

  const _AlbumArt({this.song, required this.spin, required this.glow, required this.isPlaying});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: glow,
      builder: (_, child) => Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary
                  .withOpacity(isPlaying ? 0.12 + glow.value * 0.1 : 0.05),
              blurRadius: 50,
              spreadRadius: 8,
            ),
          ],
        ),
        child: child,
      ),
      child: RotationTransition(
        turns: spin,
        child: Container(
          width: 240, height: 240,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surfaceVariant,
            border: Border.all(color: AppColors.glassBorder, width: 1),
          ),
          child: ClipOval(
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (song?.albumArtUrl != null)
                  Image.network(song!.albumArtUrl!, width: 240, height: 240,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const _ArtFallback())
                else
                  const _ArtFallback(),
                // Vinyl overlay
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.15),
                        Colors.transparent,
                        Colors.black.withOpacity(0.2),
                      ],
                      stops: const [0.0, 0.28, 0.5, 1.0],
                    ),
                  ),
                ),
                // Center hole
                Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.background,
                    border: Border.all(color: AppColors.border, width: 2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ArtFallback extends StatelessWidget {
  const _ArtFallback();
  @override
  Widget build(BuildContext context) =>
      const Icon(Icons.music_note_rounded, size: 72, color: AppColors.textTertiary);
}

// ─── Song Info ────────────────────────────────────────────────────────────────

class _SongInfo extends StatelessWidget {
  final Song? song;
  final bool isFavorite;
  final VoidCallback onLike;

  const _SongInfo({this.song, required this.isFavorite, required this.onLike});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                song?.title ?? 'Nothing playing',
                style: const TextStyle(fontFamily: 'Inter', fontSize: 22,
                    fontWeight: FontWeight.w700, color: AppColors.textPrimary,
                    letterSpacing: -0.4),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                song?.artist ?? 'Import music to get started',
                style: const TextStyle(fontFamily: 'Inter', fontSize: 14,
                    color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        // Like button
        GestureDetector(
          onTap: onLike,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 42, height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isFavorite ? AppColors.primary.withOpacity(0.12) : AppColors.glassWhite,
              border: Border.all(
                color: isFavorite ? AppColors.primary.withOpacity(0.3) : AppColors.glassBorder,
              ),
            ),
            child: Icon(
              isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isFavorite ? AppColors.primary : AppColors.textSecondary,
              size: 19,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Waveform ─────────────────────────────────────────────────────────────────

class _Waveform extends StatelessWidget {
  final AnimationController controller;
  final bool isPlaying;
  const _Waveform({required this.controller, required this.isPlaying});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => SizedBox(
        height: 40,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(38, (i) {
            final phase = (i / 38) * math.pi * 4;
            final h = isPlaying
                ? 4 + 32 * math.sin(phase + controller.value * math.pi * 2).abs()
                : 4.0;
            final frac = i / 38;
            final col = Color.lerp(
                const Color(0xFFD0D0D8), const Color(0xFF505058), frac)!;
            return Container(
              width: 2.8,
              height: h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(1.5),
                gradient: LinearGradient(
                  colors: [col, col.withOpacity(0.2)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ─── Progress Bar — stateful to prevent snap-back during drag ────────────────

class _ProgressBar extends StatefulWidget {
  final PlayerState ps;
  final PlayerNotifier player;
  const _ProgressBar({required this.ps, required this.player});

  @override
  State<_ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<_ProgressBar> {
  double? _dragValue; // not null while user is dragging

  @override
  Widget build(BuildContext context) {
    // While dragging use the local value; otherwise use player progress
    final displayValue =
        (_dragValue ?? widget.ps.progress).clamp(0.0, 1.0);

    final position = _dragValue != null
        ? Duration(
            milliseconds:
                (_dragValue! * widget.ps.duration.inMilliseconds).round())
        : widget.ps.position;

    final remaining = widget.ps.duration - position;

    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.surfaceVariant,
            thumbColor: Colors.white,
            overlayColor: AppColors.primary.withOpacity(0.12),
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            value: displayValue,
            // While dragging: update local value only — never touch the engine
            onChanged: (v) => setState(() => _dragValue = v),
            // On release: commit the seek to the engine once
            onChangeEnd: (v) {
              setState(() => _dragValue = null);
              widget.player.seekToRelative(v);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                FormatUtils.formatDuration(position),
                style: const TextStyle(
                  fontFamily: 'Inter', fontSize: 11,
                  color: AppColors.textSecondary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                '-${FormatUtils.formatDuration(remaining.isNegative ? Duration.zero : remaining)}',
                style: const TextStyle(
                  fontFamily: 'Inter', fontSize: 11,
                  color: AppColors.textSecondary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


// ─── Controls ─────────────────────────────────────────────────────────────────

class _Controls extends StatelessWidget {
  final PlayerState ps;
  final PlayerNotifier player;
  const _Controls({required this.ps, required this.player});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Shuffle
        GestureDetector(
          onTap: () => player.toggleShuffle(),
          child: Icon(Icons.shuffle_rounded, size: 22,
              color: ps.isShuffled ? AppColors.primary : AppColors.textTertiary),
        ),
        // Previous
        GestureDetector(
          onTap: () => player.playPrevious(),
          child: const Icon(Icons.skip_previous_rounded,
              color: AppColors.textPrimary, size: 36),
        ),
        // Play / Pause
        GestureDetector(
          onTap: () => player.togglePlayPause(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 66, height: 66,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(ps.isPlaying ? 0.35 : 0.15),
                  blurRadius: 20, spreadRadius: -4,
                ),
              ],
            ),
            child: Icon(
              ps.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: AppColors.background, size: 32,
            ),
          ),
        ),
        // Next
        GestureDetector(
          onTap: () => player.playNext(),
          child: const Icon(Icons.skip_next_rounded,
              color: AppColors.textPrimary, size: 36),
        ),
        // Repeat
        GestureDetector(
          onTap: () => player.toggleRepeat(),
          child: Icon(
            ps.repeatMode == RepeatMode.one
                ? Icons.repeat_one_rounded
                : Icons.repeat_rounded,
            size: 22,
            color: ps.repeatMode != RepeatMode.none
                ? AppColors.primary
                : AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}

// ─── Action Strip ─────────────────────────────────────────────────────────────

class _ActionStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ActionBtn(icon: Icons.queue_music_rounded,   label: 'Queue',    onTap: () => _showQueue(context)),
        _ActionBtn(icon: Icons.equalizer_rounded,     label: 'EQ',       onTap: () => context.go('/equalizer')),
        _ActionBtn(icon: Icons.spatial_audio_off_rounded, label: 'Profiles', onTap: () => context.go('/sound-profiles')),
        _ActionBtn(icon: Icons.bar_chart_rounded,     label: 'Visual',   onTap: () => context.go('/visualizer')),
      ],
    );
  }

  void _showQueue(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _QueueSheet(),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64, height: 56,
        decoration: BoxDecoration(
          color: AppColors.glassWhite,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 18),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 9,
                    color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ─── Queue Sheet ──────────────────────────────────────────────────────────────

class _QueueSheet extends ConsumerWidget {
  const _QueueSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ps = ref.watch(playerProvider);
    final player = ref.read(playerProvider.notifier);

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      maxChildSize: 0.88,
      minChildSize: 0.35,
      builder: (_, sc) => Container(
        decoration: const BoxDecoration(
          color: AppColors.backgroundElevated,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: Column(
          children: [
            Container(width: 40, height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 14),
                decoration: BoxDecoration(color: AppColors.textTertiary,
                    borderRadius: BorderRadius.circular(2))),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(alignment: Alignment.centerLeft,
                  child: Text('Queue',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 17,
                          fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ps.queue.isEmpty
                  ? const Center(child: Text('No tracks in queue',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 13,
                          color: AppColors.textTertiary)))
                  : ListView.builder(
                      controller: sc,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      itemCount: ps.queue.length,
                      itemBuilder: (_, i) {
                        final s = ps.queue[i];
                        final active = i == ps.currentIndex;
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(7),
                            child: s.albumArtUrl != null
                                ? Image.network(s.albumArtUrl!, width: 40, height: 40,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                        width: 40, height: 40, color: AppColors.surfaceVariant))
                                : Container(width: 40, height: 40, color: AppColors.surfaceVariant),
                          ),
                          title: Text(s.title,
                              style: TextStyle(fontFamily: 'Inter', fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: active ? AppColors.primary : AppColors.textPrimary),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(s.artist,
                              style: const TextStyle(fontFamily: 'Inter', fontSize: 11,
                                  color: AppColors.textSecondary)),
                          onTap: () {
                            player.playPlaylist(ps.queue, startIndex: i);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
