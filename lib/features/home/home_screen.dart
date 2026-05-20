import '../../core/widgets/aura_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/library_provider.dart';
import '../../providers/audio_provider.dart';
import '../../models/song.dart';
import '../../models/eq_preset.dart';
import '../home/widgets/recently_played_tile.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(libraryProvider);
    final playerState = ref.watch(playerProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Top bar ───────────────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: Colors.transparent,
            floating: true,
            expandedHeight: 70,
            flexibleSpace: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AuraLogoCompact(size: 28),
                        const SizedBox(height: 2),
                        const Text('Feel every beat',
                            style: TextStyle(
                              fontFamily: 'Inter', fontSize: 10,
                              color: AppColors.textTertiary, letterSpacing: 0.5,
                            )),
                      ],
                    ),
                    const Spacer(),
                    _GuestChip(),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  // ── Hero ─────────────────────────────────────────────────
                  const Text('Premium sound.\nLimitless immersion.',
                      style: TextStyle(
                        fontFamily: 'Inter', fontSize: 27,
                        fontWeight: FontWeight.w700, color: AppColors.textPrimary,
                        height: 1.2, letterSpacing: -0.5,
                      )),
                  const SizedBox(height: 10),
                  const Text(
                    'Studio-quality DSP, intelligent tuning,\nand a library that feels alive.',
                    style: TextStyle(
                      fontFamily: 'Inter', fontSize: 14,
                      color: AppColors.textSecondary, height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Import button
                  Consumer(
                    builder: (context, ref, _) {
                      final lib = ref.watch(libraryProvider);
                      return GestureDetector(
                        onTap: lib.isLoading
                            ? null
                            : () => ref
                                .read(libraryProvider.notifier)
                                .importFiles(),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              lib.isLoading
                                  ? const SizedBox(
                                      width: 15,
                                      height: 15,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 1.5,
                                          color: AppColors.primary),
                                    )
                                  : const Icon(Icons.upload_file_rounded,
                                      color: AppColors.textSecondary,
                                      size: 17),
                              const SizedBox(width: 8),
                              Text(
                                lib.isLoading
                                    ? 'Scanning…'
                                    : 'Import music',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // ── Now Spinning ──────────────────────────────────────────
                  _NowSpinningCard(playerState: playerState),
                  const SizedBox(height: 24),

                  // ── Open player / Tune EQ row ─────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _QuickLink(
                          label: 'Open player',
                          icon: Icons.play_circle_outline_rounded,
                          onTap: () => context.push('/now-playing'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _QuickLink(
                          label: 'Tune EQ',
                          icon: Icons.equalizer_rounded,
                          onTap: () => context.go('/equalizer'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Bento Grid ────────────────────────────────────────────
                  _BentoGrid(library: library),
                  const SizedBox(height: 24),

                  // ── Featured Profiles ─────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Featured profiles', style: AppTextStyles.sectionHeader),
                      GestureDetector(
                        onTap: () => context.go('/sound-profiles'),
                        child: const Text('See all',
                            style: TextStyle(
                              fontFamily: 'Inter', fontSize: 13,
                              color: AppColors.primary, fontWeight: FontWeight.w500,
                            )),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),

          // Featured profiles horizontal row — 4 chips
          SliverToBoxAdapter(
            child: SizedBox(
              height: 90,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                physics: const BouncingScrollPhysics(),
                children: SoundProfile.builtInProfiles.take(4).map((p) =>
                    _FeaturedProfileChip(profile: p,
                        onTap: () => context.go('/sound-profiles'))).toList(),
              ),
            ),
          ),

          // ── Recently Played header ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recently played', style: AppTextStyles.sectionHeader),
                  GestureDetector(
                    onTap: () => context.go('/library'),
                    child: const Text('Library',
                        style: TextStyle(
                          fontFamily: 'Inter', fontSize: 13,
                          color: AppColors.primary, fontWeight: FontWeight.w500,
                        )),
                  ),
                ],
              ),
            ),
          ),

          if (library.songs.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _EmptySection(
                  icon: Icons.history_rounded,
                  label: 'Nothing played yet',
                  sub: 'Import music or tap a track to start',
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final songs = library.songs.take(6).toList();
                  if (i == songs.length) return const SizedBox(height: 8);
                  final song = songs[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: RecentlyPlayedTile(
                      song: song,
                      isPlaying: playerState.currentSong?.id == song.id && playerState.isPlaying,
                      onTap: () {
                        ref.read(playerProvider.notifier).playSong(song);
                        context.push('/now-playing');
                      },
                      onMore: () {},
                    ),
                  );
                },
                childCount: library.songs.take(6).length + 1,
              ),
            ),

          // ── Drop Zone ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 160),
              child: _DropZone(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _GuestChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surfaceVariant,
            border: Border.all(color: AppColors.border),
          ),
          child: const Center(
            child: Text('?', style: TextStyle(fontFamily: 'Inter', fontSize: 13,
                fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          ),
        ),
        const SizedBox(width: 7),
        const Text('Guest',
            style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _NowSpinningCard extends ConsumerWidget {
  final PlayerState playerState;
  const _NowSpinningCard({required this.playerState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final song = playerState.currentSong;
    return GestureDetector(
      onTap: () => context.push('/now-playing'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: song?.albumArtUrl != null
                  ? Image.network(song!.albumArtUrl!,
                      width: 48, height: 48, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _art())
                  : _art(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Now spinning',
                      style: TextStyle(
                        fontFamily: 'Inter', fontSize: 9, color: AppColors.textTertiary,
                        letterSpacing: 1.2, fontWeight: FontWeight.w600,
                      )),
                  const SizedBox(height: 2),
                  Text(
                    song?.title ?? 'Your sonic journey awaits',
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 13,
                        fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    song?.artist ?? 'Import tracks or connect Spotify',
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 11,
                        color: AppColors.textSecondary),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                song != null
                    ? ref.read(playerProvider.notifier).togglePlayPause()
                    : context.go('/library');
              },
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.1),
                  border: Border.all(color: AppColors.primary.withOpacity(0.25)),
                ),
                child: Icon(
                  song != null
                      ? (playerState.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded)
                      : Icons.add_rounded,
                  color: AppColors.primary, size: 19,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _art() => Container(width: 48, height: 48,
      color: AppColors.surfaceVariant,
      child: const Icon(Icons.music_note_rounded, color: AppColors.textTertiary, size: 22));
}

class _QuickLink extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _QuickLink({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 7),
            Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 12,
                fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _BentoGrid extends StatelessWidget {
  final LibraryState library;
  const _BentoGrid({required this.library});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(children: [
          Expanded(child: _BentoCell(label: 'Library',
              value: '${library.songs.length} tracks',
              icon: Icons.library_music_rounded, onTap: () => context.go('/library'))),
          const SizedBox(width: 10),
          Expanded(child: _BentoCell(label: 'Equalizer',
              value: '10 / 32 band',
              icon: Icons.equalizer_rounded, onTap: () => context.go('/equalizer'))),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _BentoCell(label: 'Visualizer',
              value: 'FFT live',
              icon: Icons.bar_chart_rounded, onTap: () => context.go('/visualizer'))),
          const SizedBox(width: 10),
          Expanded(child: _BentoCell(label: 'Spotify',
              value: 'Stream',
              icon: Icons.headphones_rounded, onTap: () => context.go('/spotify-auth'))),
        ]),
      ],
    );
  }
}

class _BentoCell extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;
  const _BentoCell({required this.label, required this.value, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: const TextStyle(fontFamily: 'Inter',
                    fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                Text(value, style: const TextStyle(fontFamily: 'Inter',
                    fontSize: 10, color: AppColors.textTertiary)),
              ],
            ),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 14),
          ],
        ),
      ),
    );
  }
}

class _FeaturedProfileChip extends StatelessWidget {
  final SoundProfile profile;
  final VoidCallback onTap;
  const _FeaturedProfileChip({required this.profile, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 126,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 26, height: 26,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(child: Text(profile.name[0],
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 12,
                      fontWeight: FontWeight.w700, color: AppColors.primary))),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.name, style: const TextStyle(fontFamily: 'Inter',
                    fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(profile.description, style: const TextStyle(fontFamily: 'Inter',
                    fontSize: 9, color: AppColors.textSecondary),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DropZone extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(libraryProvider).isLoading;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1.0),
        color: AppColors.surface.withOpacity(0.5),
      ),
      child: Column(
        children: [
          Icon(
            isLoading ? Icons.hourglass_top_rounded : Icons.upload_rounded,
            color: AppColors.textTertiary,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            isLoading ? 'Scanning files…' : 'Drop your music',
            style: const TextStyle(
              fontFamily: 'Inter', fontSize: 13,
              fontWeight: FontWeight.w600, color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'MP3 · FLAC · WAV · AAC · OGG · OPUS · ALAC · DSD',
            style: TextStyle(
              fontFamily: 'Inter', fontSize: 10,
              color: AppColors.textTertiary, letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: isLoading
                    ? null
                    : () => ref.read(libraryProvider.notifier).importFiles(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 9),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Text(
                    isLoading ? 'Scanning…' : 'Choose files',
                    style: const TextStyle(
                      fontFamily: 'Inter', fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: isLoading
                    ? null
                    : () =>
                        ref.read(libraryProvider.notifier).importFolder(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 9),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: const Text(
                    'Folder',
                    style: TextStyle(
                      fontFamily: 'Inter', fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  const _EmptySection({required this.icon, required this.label, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textTertiary, size: 18),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 13,
                  fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
              Text(sub, style: const TextStyle(fontFamily: 'Inter', fontSize: 11,
                  color: AppColors.textTertiary)),
            ],
          ),
        ],
      ),
    );
  }
}
