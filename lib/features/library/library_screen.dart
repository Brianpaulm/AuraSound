import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/library_provider.dart';
import '../../providers/audio_provider.dart';
import '../../models/song.dart';
import '../home/widgets/recently_played_tile.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  final List<_LibTab> _tabs = const [
    _LibTab(icon: Icons.music_note_rounded, label: 'Songs'),
    _LibTab(icon: Icons.person_rounded, label: 'Artists'),
    _LibTab(icon: Icons.album_rounded, label: 'Albums'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(libraryProvider);
    final playerState = ref.watch(playerProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Header
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Your music',
                                style: TextStyle(fontFamily: 'Inter', fontSize: 11,
                                    color: AppColors.textTertiary, letterSpacing: 1,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            const Text('Library', style: AppTextStyles.headlineMedium),
                            const SizedBox(height: 2),
                            Text(
                              '${library.songs.length} tracks · ${library.artists.length} artists',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      _IconBtn(
                          icon: Icons.add_rounded,
                          onTap: () =>
                              ref.read(libraryProvider.notifier).importFiles()),
                      const SizedBox(width: 8),
                      _IconBtn(
                          icon: Icons.sort_rounded,
                          onTap: () => _showSortOptions(context)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _LibrarySearchBar(controller: _searchController, onChanged: (q) {
                    ref.read(libraryProvider.notifier).setSearchQuery(q);
                  }),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),
          // Tab bar
          Container(
            height: 44,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              physics: const BouncingScrollPhysics(),
              itemCount: _tabs.length,
              itemBuilder: (context, i) {
                return AnimatedBuilder(
                  animation: _tabController,
                  builder: (_, __) {
                    final selected = _tabController.index == i;
                    return GestureDetector(
                      onTap: () => _tabController.animateTo(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primary : AppColors.surface,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: selected ? AppColors.primary : AppColors.border,
                            width: 0.5,
                          ),
                          boxShadow: selected
                              ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 10, spreadRadius: -3)]
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(_tabs[i].icon, size: 15, color: selected ? Colors.white : AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              _tabs[i].label,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: selected ? Colors.white : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _SongsTab(
                  songs: library.filteredSongs,
                  currentSongId: playerState.currentSong?.id,
                  isPlaying: playerState.isPlaying,
                  onImport: () =>
                      ref.read(libraryProvider.notifier).importFiles(),
                  onSongTap: (song) {
                    ref.read(playerProvider.notifier).playSong(song);
                    context.push('/now-playing');
                  },
                  onMore: (song) => _showSongOptions(context, song),
                ),
                _ArtistsTab(artists: library.artists),
                _AlbumsTab(albums: library.albums),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSortOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SortSheet(
        onSort: (sortBy) => ref.read(libraryProvider.notifier).setSortBy(sortBy),
      ),
    );
  }

  void _showSongOptions(BuildContext context, Song song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SongActionSheet(song: song),
    );
  }
}

// ─── Songs Tab ─────────────────────────────────────────────────────────────

class _SongsTab extends StatelessWidget {
  final List<Song> songs;
  final String? currentSongId;
  final bool isPlaying;
  final Function(Song) onSongTap;
  final Function(Song) onMore;
  final VoidCallback onImport;

  const _SongsTab({
    required this.songs,
    this.currentSongId,
    required this.isPlaying,
    required this.onSongTap,
    required this.onMore,
    required this.onImport,
  });

  @override
  Widget build(BuildContext context) {
    if (songs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.library_music_rounded,
                    size: 32, color: AppColors.textTertiary),
              ),
              const SizedBox(height: 18),
              const Text('Your library is empty',
                  style: AppTextStyles.titleMedium, textAlign: TextAlign.center),
              const SizedBox(height: 6),
              const Text('Add some music to begin your journey.',
                  style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => onImport(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.upload_file_rounded,
                          color: AppColors.textSecondary, size: 17),
                      SizedBox(width: 8),
                      Text('Import music',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const BouncingScrollPhysics(),
      itemCount: songs.length + 1,
      itemBuilder: (context, i) {
        if (i == songs.length) return const SizedBox(height: 160);
        final song = songs[i];
        return RecentlyPlayedTile(
          song: song,
          isPlaying: currentSongId == song.id && isPlaying,
          onTap: () => onSongTap(song),
          onMore: () => onMore(song),
        );
      },
    );
  }
}

// ─── Artists Tab ────────────────────────────────────────────────────────────

class _ArtistsTab extends StatelessWidget {
  final List<Artist> artists;
  const _ArtistsTab({required this.artists});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.1,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: artists.length,
      itemBuilder: (context, i) {
        final artist = artists[i];
        return GestureDetector(
          onTap: () {},
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceVariant,
                    gradient: LinearGradient(
                      colors: [AppColors.primary.withOpacity(0.3), AppColors.accent.withOpacity(0.2)],
                    ),
                  ),
                  child: ClipOval(
                    child: artist.imageUrl != null
                        ? Image.network(artist.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.person_rounded, color: AppColors.textTertiary, size: 34))
                        : const Icon(Icons.person_rounded, color: AppColors.textTertiary, size: 34),
                  ),
                ),
                const SizedBox(height: 10),
                Text(artist.name, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                const SizedBox(height: 2),
                Text('${artist.songCount} songs', style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Albums Tab ─────────────────────────────────────────────────────────────

class _AlbumsTab extends StatelessWidget {
  final List<Album> albums;
  const _AlbumsTab({required this.albums});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: albums.length,
      itemBuilder: (context, i) {
        final album = albums[i];
        return GestureDetector(
          onTap: () {},
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: album.coverUrl != null
                      ? Image.network(album.coverUrl!, fit: BoxFit.cover, width: double.infinity, errorBuilder: (_, __, ___) => _albumPlaceholder())
                      : _albumPlaceholder(),
                ),
              ),
              const SizedBox(height: 8),
              Text(album.name, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(album.artist, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        );
      },
    );
  }

  Widget _albumPlaceholder() {
    return Container(
      color: AppColors.surfaceVariant,
      child: const Center(child: Icon(Icons.album_rounded, color: AppColors.textTertiary, size: 40)),
    );
  }
}

// ─── Genres Tab ─────────────────────────────────────────────────────────────

class _GenresTab extends StatelessWidget {
  final List<Song> songs;
  const _GenresTab({required this.songs});

  @override
  Widget build(BuildContext context) {
    final genreMap = <String, int>{};
    for (final s in songs) {
      if (s.genre != null) genreMap[s.genre!] = (genreMap[s.genre!] ?? 0) + 1;
    }
    final genres = genreMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final colors = [AppColors.primary, AppColors.accent, AppColors.accentPurple, AppColors.accentPink, const Color(0xFFF59E0B), AppColors.success];

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.6,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: genres.length,
      itemBuilder: (context, i) {
        final genre = genres[i];
        final color = colors[i % colors.length];
        return GestureDetector(
          onTap: () {},
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: [color.withOpacity(0.6), color.withOpacity(0.2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: color.withOpacity(0.3), width: 0.5),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(genre.key, style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 2),
                Text('${genre.value} songs', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Colors.white.withOpacity(0.7))),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Folders Tab ────────────────────────────────────────────────────────────

class _FoldersTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final folders = ['Music', 'Downloads', 'Podcasts', 'Albums', 'Favorites'];
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const BouncingScrollPhysics(),
      itemCount: folders.length,
      itemBuilder: (context, i) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.folder_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(folders[i], style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const Text('Internal Storage', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 20),
            ],
          ),
        );
      },
    );
  }
}

// ─── Helpers ────────────────────────────────────────────────────────────────

class _LibTab {
  final IconData icon;
  final String label;
  const _LibTab({required this.icon, required this.label});
}

class _LibrarySearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _LibrarySearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Icon(Icons.search_rounded, color: AppColors.textTertiary, size: 18),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Search in library',
                hintStyle: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.textTertiary),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                controller.clear();
                onChanged('');
              },
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.close_rounded, color: AppColors.textTertiary, size: 16),
              ),
            ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Icon(icon, color: AppColors.textSecondary, size: 18),
      ),
    );
  }
}

class _SortSheet extends StatelessWidget {
  final Function(String) onSort;
  const _SortSheet({required this.onSort});

  @override
  Widget build(BuildContext context) {
    final options = ['Title', 'Artist', 'Album', 'Date Added', 'Duration'];
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 16), decoration: BoxDecoration(color: AppColors.textTertiary, borderRadius: BorderRadius.circular(2))),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4), child: Align(alignment: Alignment.centerLeft, child: Text('Sort by', style: AppTextStyles.titleMedium))),
          ...options.map((o) => ListTile(
            title: Text(o, style: AppTextStyles.bodyLarge),
            trailing: const Icon(Icons.check_rounded, color: AppColors.primary, size: 18),
            onTap: () {
              onSort(o.toLowerCase().replaceAll(' ', '_'));
              Navigator.pop(context);
            },
          )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SongActionSheet extends StatelessWidget {
  final Song song;
  const _SongActionSheet({required this.song});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 8), decoration: BoxDecoration(color: AppColors.textTertiary, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: song.albumArtUrl != null
                      ? Image.network(song.albumArtUrl!, width: 48, height: 48, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 48, height: 48, color: AppColors.surfaceVariant))
                      : Container(width: 48, height: 48, color: AppColors.surfaceVariant),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(song.title, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(song.artist, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          ...[
            (Icons.playlist_add_rounded, 'Add to Playlist'),
            (Icons.queue_music_rounded, 'Add to Queue'),
            (Icons.favorite_border_rounded, 'Add to Favorites'),
            (Icons.person_rounded, 'Go to Artist'),
            (Icons.album_rounded, 'Go to Album'),
            (Icons.share_rounded, 'Share'),
            (Icons.info_outline_rounded, 'Song Info'),
          ].map((item) => ListTile(
            leading: Icon(item.$1, color: AppColors.textSecondary, size: 22),
            title: Text(item.$2, style: AppTextStyles.bodyLarge),
            onTap: () => Navigator.pop(context),
          )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
