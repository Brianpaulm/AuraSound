import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/song.dart';
import '../../core/utils/format_utils.dart';

class SongCard extends StatelessWidget {
  final Song song;
  final bool isPlaying;
  final VoidCallback? onTap;
  final VoidCallback? onMore;
  final bool showFormat;

  const SongCard({
    super.key,
    required this.song,
    this.isPlaying = false,
    this.onTap,
    this.onMore,
    this.showFormat = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isPlaying ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: isPlaying
              ? Border.all(color: AppColors.primary.withOpacity(0.2), width: 0.5)
              : null,
        ),
        child: Row(
          children: [
            // Album art with playing indicator
            _AlbumArtWithIndicator(
              url: song.albumArtUrl,
              isPlaying: isPlaying,
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isPlaying ? AppColors.primary : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        song.artist,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (showFormat && song.format != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: _formatColor(song.format!).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            song.format!,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: _formatColor(song.format!),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Duration + more
            Text(
              FormatUtils.formatDurationShort(song.duration),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textTertiary,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onMore,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(Icons.more_vert_rounded, color: AppColors.textTertiary, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _formatColor(String format) {
    switch (format.toUpperCase()) {
      case 'FLAC':
      case 'ALAC':
        return AppColors.primary;
      case 'DSD':
        return AppColors.accentPink;
      case 'WAV':
      case 'AIFF':
        return AppColors.accent;
      default:
        return AppColors.textSecondary;
    }
  }
}

class _AlbumArtWithIndicator extends StatelessWidget {
  final String? url;
  final bool isPlaying;

  const _AlbumArtWithIndicator({this.url, required this.isPlaying});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: AppColors.surfaceVariant,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: url != null
                ? Image.network(url!, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const _Fallback())
                : const _Fallback(),
          ),
        ),
        if (isPlaying)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.black.withOpacity(0.45),
              ),
              child: const _MusicBars(),
            ),
          ),
      ],
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.music_note_rounded, color: AppColors.textTertiary, size: 24),
    );
  }
}

class _MusicBars extends StatefulWidget {
  const _MusicBars();
  @override
  State<_MusicBars> createState() => _MusicBarsState();
}

class _MusicBarsState extends State<_MusicBars> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) => AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 350 + i * 80),
    )..repeat(reverse: true));
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(3, (i) => AnimatedBuilder(
          animation: _controllers[i],
          builder: (_, __) => Container(
            width: 3,
            height: 6 + _controllers[i].value * 12,
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        )),
      ),
    );
  }
}

// ─── Playlist Card ────────────────────────────────────────────────────────────

class PlaylistCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final String? coverUrl;
  final Color? accentColor;
  final VoidCallback? onTap;

  const PlaylistCard({
    super.key,
    required this.name,
    required this.subtitle,
    this.coverUrl,
    this.accentColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.surface,
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: coverUrl != null
                  ? Image.network(
                      coverUrl!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      height: 120,
      color: accentColor ?? AppColors.surfaceVariant,
      child: const Center(child: Icon(Icons.queue_music_rounded, color: AppColors.textTertiary, size: 32)),
    );
  }
}

// ─── Artist Card ──────────────────────────────────────────────────────────────

class ArtistCard extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final String subtitle;
  final VoidCallback? onTap;

  const ArtistCard({
    super.key,
    required this.name,
    this.imageUrl,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceVariant,
              gradient: imageUrl == null
                  ? LinearGradient(colors: [AppColors.primary.withOpacity(0.3), AppColors.accent.withOpacity(0.2)])
                  : null,
            ),
            child: ClipOval(
              child: imageUrl != null
                  ? Image.network(imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.person_rounded, color: AppColors.textTertiary, size: 36))
                  : const Icon(Icons.person_rounded, color: AppColors.textTertiary, size: 36),
            ),
          ),
          const SizedBox(height: 8),
          Text(name, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
          Text(subtitle, style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: AppColors.textSecondary), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
