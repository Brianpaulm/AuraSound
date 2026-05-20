import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/library_provider.dart';
import '../../providers/audio_provider.dart';
import '../home/widgets/recently_played_tile.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(libraryProvider);
    final playerState = ref.watch(playerProvider);
    final favorites = library.favoriteSongs;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            floating: true,
            expandedHeight: 110,
            flexibleSpace: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('The ones you love',
                        style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.textTertiary, letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text('Favorites', style: AppTextStyles.headlineMedium),
                        const Spacer(),
                        Text(
                          '${favorites.length} liked songs',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (favorites.isEmpty)
            SliverFillRemaining(
              child: _EmptyFavorites(),
            )
          else ...[
            // Play all button
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: GestureDetector(
                  onTap: () {
                    ref.read(playerProvider.notifier).playPlaylist(favorites);
                    context.push('/now-playing');
                  },
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.25),
                          blurRadius: 16,
                          spreadRadius: -4,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_arrow_rounded, color: AppColors.background, size: 22),
                        SizedBox(width: 8),
                        Text('Play all',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.background,
                            )),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  if (i == favorites.length) return const SizedBox(height: 160);
                  final song = favorites[i];
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
                childCount: favorites.length + 1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
          ),
          child: const Icon(Icons.favorite_border_rounded,
              size: 36, color: AppColors.textTertiary),
        ),
        const SizedBox(height: 20),
        const Text('No favorites yet', style: AppTextStyles.titleMedium),
        const SizedBox(height: 6),
        const Text(
          'Tap the heart on any track to add it here.',
          style: AppTextStyles.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        GestureDetector(
          onTap: () => context.go('/library'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.library_music_rounded,
                    color: AppColors.textSecondary, size: 18),
                SizedBox(width: 8),
                Text('Go to Library',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    )),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
