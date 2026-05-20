import 'dart:ui';
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '/core/theme/app_colors.dart';
import '/core/theme/app_text_styles.dart';
import '/providers/audio_provider.dart';
import '/providers/library_provider.dart';

/// Adaptive scaffold that switches between mobile bottom-nav
/// and a desktop sidebar layout based on screen width.
class AdaptiveScaffold extends ConsumerWidget {
  final Widget body;
  final String currentRoute;

  const AdaptiveScaffold({
    super.key,
    required this.body,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 900) {
      return _DesktopLayout(body: body, currentRoute: currentRoute);
    }
    return body;
  }
}

// ─── Desktop Layout ──────────────────────────────────────────────────────────

class _DesktopLayout extends ConsumerWidget {
  final Widget body;
  final String currentRoute;

  const _DesktopLayout({required this.body, required this.currentRoute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                // Sidebar
                _DesktopSidebar(currentRoute: currentRoute),
                // Vertical divider
                Container(width: 0.5, color: AppColors.border),
                // Main content
                Expanded(child: body),
                // Right panel (now playing info)
                if (playerState.currentSong != null) ...[
                  Container(width: 0.5, color: AppColors.border),
                  _NowPlayingPanel(),
                ],
              ],
            ),
          ),
          // Desktop mini player bar
          if (playerState.currentSong != null)
            _DesktopPlayerBar(),
        ],
      ),
    );
  }
}

class _DesktopSidebar extends ConsumerWidget {
  final String currentRoute;

  const _DesktopSidebar({required this.currentRoute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navItems = [
      _NavItem(Icons.home_rounded, 'Home', '/home'),
      _NavItem(Icons.library_music_rounded, 'Library', '/library'),
      _NavItem(Icons.queue_music_rounded, 'Playlists', '/library'),
      _NavItem(Icons.person_rounded, 'Artists', '/library'),
      _NavItem(Icons.album_rounded, 'Albums', '/library'),
      _NavItem(Icons.folder_rounded, 'Folders', '/library'),
    ];
    final bottomItems = [
      _NavItem(Icons.equalizer_rounded, 'Equalizer', '/equalizer'),
      _NavItem(Icons.spatial_audio_off_rounded, 'Sound Profiles', '/sound-profiles'),
      _NavItem(Icons.settings_rounded, 'Settings', '/settings'),
    ];

    return Container(
      width: 220,
      decoration: const BoxDecoration(color: AppColors.backgroundSecondary),
      child: Column(
        children: [
          // Logo
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.primaryGradient,
                    ),
                    child: const Icon(Icons.spatial_audio_off_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  ShaderMask(
                    shaderCallback: (b) => AppColors.primaryGradient.createShader(b),
                    child: const Text(
                      'AURASOUND',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Nav items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                ...navItems.map((item) => _SidebarNavTile(
                  item: item,
                  isActive: currentRoute == item.route,
                  onTap: () => context.go(item.route),
                )),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    'LIBRARY',
                    style: AppTextStyles.labelSmall.copyWith(letterSpacing: 1.5),
                  ),
                ),
                // Playlists preview
                ..._buildPlaylistItems(context, ref),
              ],
            ),
          ),
          // Bottom items
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Column(
              children: bottomItems.map((item) => _SidebarNavTile(
                item: item,
                isActive: currentRoute == item.route,
                onTap: () => context.push(item.route),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPlaylistItems(BuildContext context, WidgetRef ref) {
    final library = ref.read(libraryProvider);
    return library.playlists.take(4).map((pl) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: GestureDetector(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: pl.coverUrl != null
                    ? Image.network(pl.coverUrl!, width: 28, height: 28, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 28, height: 28, color: AppColors.surfaceVariant))
                    : Container(width: 28, height: 28, color: AppColors.surfaceVariant),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  pl.name,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    )).toList();
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String route;
  const _NavItem(this.icon, this.label, this.route);
}

class _SidebarNavTile extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _SidebarNavTile({required this.item, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(item.icon, size: 18, color: isActive ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 10),
            Text(
              item.label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Now Playing Side Panel ───────────────────────────────────────────────────

class _NowPlayingPanel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final song = playerState.currentSong;
    if (song == null) return const SizedBox(width: 260);

    return Container(
      width: 260,
      color: AppColors.backgroundSecondary,
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Album art
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: song.albumArtUrl != null
                  ? Image.network(song.albumArtUrl!, width: double.infinity, height: 220, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(height: 220, color: AppColors.surfaceVariant))
                  : Container(height: 220, color: AppColors.surfaceVariant),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(song.title, style: AppTextStyles.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(song.artist, style: AppTextStyles.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 16),
                // Format info
                if (song.format != null || song.bitrate != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (song.format != null) ...[
                          Text(song.format!, style: const TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 0.5)),
                          if (song.bitrate != null) ...[
                            Container(width: 1, height: 10, color: AppColors.border, margin: const EdgeInsets.symmetric(horizontal: 6)),
                          ],
                        ],
                        if (song.bitrate != null)
                          Text('${(song.bitrate! >= 1000) ? '${song.bitrate! ~/ 1000}' : song.bitrate}${song.bitrate! >= 1000 ? 'k' : ''} kbps', style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const Spacer(),
          // Quick links
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _PanelAction(icon: Icons.equalizer_rounded, label: 'Open Equalizer', onTap: () => context.push('/equalizer')),
                const SizedBox(height: 8),
                _PanelAction(icon: Icons.spatial_audio_off_rounded, label: 'Sound Profiles', onTap: () => context.push('/sound-profiles')),
                const SizedBox(height: 8),
                _PanelAction(icon: Icons.fullscreen_rounded, label: 'Visualizer', onTap: () => context.push('/visualizer')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PanelAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

// ─── Desktop Player Bar ───────────────────────────────────────────────────────

class _DesktopPlayerBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final player = ref.read(playerProvider.notifier);
    final song = playerState.currentSong;
    if (song == null) return const SizedBox.shrink();

    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: AppColors.backgroundSecondary,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Song info
          SizedBox(
            width: 220,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: song.albumArtUrl != null
                      ? Image.network(song.albumArtUrl!, width: 44, height: 44, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 44, height: 44, color: AppColors.surfaceVariant))
                      : Container(width: 44, height: 44, color: AppColors.surfaceVariant),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(song.title, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(song.artist, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => player.toggleFavorite(),
                  child: Icon(
                    song.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: song.isFavorite ? AppColors.primary : AppColors.textTertiary,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Controls + progress
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(onTap: () => player.toggleShuffle(), child: Icon(Icons.shuffle_rounded, size: 18, color: playerState.isShuffled ? AppColors.primary : AppColors.textTertiary)),
                    const SizedBox(width: 20),
                    GestureDetector(onTap: () => player.playPrevious(), child: const Icon(Icons.skip_previous_rounded, size: 26, color: AppColors.textPrimary)),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => player.togglePlayPause(),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppColors.primaryGradient, boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 12)]),
                        child: Icon(playerState.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 22),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(onTap: () => player.playNext(), child: const Icon(Icons.skip_next_rounded, size: 26, color: AppColors.textPrimary)),
                    const SizedBox(width: 20),
                    GestureDetector(onTap: () => player.toggleRepeat(), child: Icon(Icons.repeat_rounded, size: 18, color: playerState.repeatMode != RepeatMode.none ? AppColors.primary : AppColors.textTertiary)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(_fmt(playerState.position), style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: AppColors.textTertiary)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 2,
                          activeTrackColor: AppColors.primary,
                          inactiveTrackColor: AppColors.surfaceVariant,
                          thumbColor: Colors.white,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                          overlayShape: SliderComponentShape.noOverlay,
                        ),
                        child: Slider(
                          value: playerState.progress.clamp(0.0, 1.0),
                          onChanged: (v) {
                            // Update UI immediately without calling engine
                            // (engine seek happens on release via onChangeEnd)
                          },
                          onChangeEnd: (v) => player.seekToRelative(v),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(_fmt(playerState.duration), style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: AppColors.textTertiary)),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          // Right controls
          SizedBox(
            width: 220,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(onTap: () => context.push('/visualizer'), child: const Icon(Icons.equalizer_rounded, size: 18, color: AppColors.textTertiary)),
                const SizedBox(width: 16),
                const Icon(Icons.volume_up_rounded, size: 18, color: AppColors.textTertiary),
                const SizedBox(width: 8),
                SizedBox(
                  width: 80,
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 2,
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: AppColors.surfaceVariant,
                      thumbColor: Colors.white,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                      overlayShape: SliderComponentShape.noOverlay,
                    ),
                    child: Slider(
                      value: playerState.config.volume,
                      onChanged: (v) => player.setVolume(v),
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

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
