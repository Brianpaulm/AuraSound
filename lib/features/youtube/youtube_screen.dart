import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/format_utils.dart';
import '../../services/youtube_service.dart';

class YouTubeScreen extends ConsumerStatefulWidget {
  const YouTubeScreen({super.key});

  @override
  ConsumerState<YouTubeScreen> createState() => _YouTubeScreenState();
}

class _YouTubeScreenState extends ConsumerState<YouTubeScreen> {
  final _searchCtrl = TextEditingController();
  final _urlCtrl    = TextEditingController();
  bool _showUrlInput = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ytState = ref.watch(youTubeServiceProvider);
    final yt      = ref.read(youTubeServiceProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header ─────────────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: Colors.transparent,
            floating: true,
            expandedHeight: 96,
            flexibleSpace: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Stream anything',
                        style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.textTertiary, letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text('YouTube', style: AppTextStyles.headlineMedium),
                        const Spacer(),
                        // Toggle URL paste
                        GestureDetector(
                          onTap: () =>
                              setState(() => _showUrlInput = !_showUrlInput),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _showUrlInput
                                  ? AppColors.primary.withOpacity(0.12)
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(
                                color: _showUrlInput
                                    ? AppColors.primary.withOpacity(0.3)
                                    : AppColors.border,
                                width: 0.5,
                              ),
                            ),
                            child: Text('Paste URL',
                                style: TextStyle(
                                  fontFamily: 'Inter', fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: _showUrlInput
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                )),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                children: [
                  // ── Search bar ──────────────────────────────────────────
                  Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: AppColors.border, width: 0.5),
                    ),
                    child: Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          child: Icon(Icons.search_rounded,
                              color: AppColors.textTertiary, size: 18),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            style: const TextStyle(
                              fontFamily: 'Inter', fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Search songs, artists, albums…',
                              hintStyle: TextStyle(
                                fontFamily: 'Inter', fontSize: 14,
                                color: AppColors.textTertiary,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            textInputAction: TextInputAction.search,
                            onSubmitted: (q) => yt.search(q),
                          ),
                        ),
                        if (ytState.isSearching)
                          const Padding(
                            padding: EdgeInsets.only(right: 14),
                            child: SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: AppColors.primary),
                            ),
                          )
                        else
                          GestureDetector(
                            onTap: () => yt.search(_searchCtrl.text),
                            child: Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 9),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: const Text('Search',
                                  style: TextStyle(
                                    fontFamily: 'Inter', fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.background,
                                  )),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // ── URL paste input ─────────────────────────────────────
                  if (_showUrlInput) ...[
                    const SizedBox(height: 10),
                    Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                            width: 0.8),
                      ),
                      child: Row(
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 14),
                            child: Icon(Icons.link_rounded,
                                color: AppColors.primary, size: 17),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _urlCtrl,
                              style: const TextStyle(
                                fontFamily: 'Inter', fontSize: 13,
                                color: AppColors.textPrimary,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'youtube.com/watch?v=… or video ID',
                                hintStyle: TextStyle(
                                  fontFamily: 'Inter', fontSize: 13,
                                  color: AppColors.textTertiary,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              if (_urlCtrl.text.isNotEmpty) {
                                yt.playUrl(_urlCtrl.text.trim());
                                context.push('/now-playing');
                              }
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 9),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(
                                    color: AppColors.primary.withOpacity(0.3)),
                              ),
                              child: ytState.isResolving
                                  ? const SizedBox(
                                      width: 14, height: 14,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 1.5,
                                          color: AppColors.primary))
                                  : const Text('Play',
                                      style: TextStyle(
                                        fontFamily: 'Inter', fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      )),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ── Error ───────────────────────────────────────────────
                  if (ytState.error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.error.withOpacity(0.25)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: AppColors.error, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(ytState.error!,
                                style: const TextStyle(
                                  fontFamily: 'Inter', fontSize: 12,
                                  color: AppColors.error,
                                )),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // ── Results ────────────────────────────────────────────────────
          if (ytState.searchResults.isEmpty && !ytState.isSearching &&
              ytState.query == null)
            SliverToBoxAdapter(child: _EmptyState())
          else if (ytState.isSearching)
            SliverToBoxAdapter(child: _LoadingShimmer())
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  if (i == ytState.searchResults.length) {
                    return const SizedBox(height: 160);
                  }
                  final result = ytState.searchResults[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 3),
                    child: _YTResultTile(
                      result: result,
                      isResolving: ytState.isResolving,
                      onTap: () async {
                        await yt.playResult(result);
                        if (mounted) context.push('/now-playing');
                      },
                    ),
                  );
                },
                childCount: ytState.searchResults.length + 1,
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Result tile ──────────────────────────────────────────────────────────────

class _YTResultTile extends StatelessWidget {
  final YTResult result;
  final bool isResolving;
  final VoidCallback onTap;

  const _YTResultTile({
    required this.result,
    required this.isResolving,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: result.thumbnailUrl != null
                  ? Image.network(
                      result.thumbnailUrl!,
                      width: 56, height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _thumb(),
                    )
                  : _thumb(),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(result.title,
                      style: const TextStyle(
                        fontFamily: 'Inter', fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(result.channel,
                      style: const TextStyle(
                        fontFamily: 'Inter', fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            // Duration + play
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  FormatUtils.formatDuration(result.duration),
                  style: const TextStyle(
                    fontFamily: 'Inter', fontSize: 11,
                    color: AppColors.textTertiary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withOpacity(0.1),
                    border: Border.all(
                        color: AppColors.primary.withOpacity(0.25)),
                  ),
                  child: isResolving
                      ? const Padding(
                          padding: EdgeInsets.all(7),
                          child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: AppColors.primary))
                      : const Icon(Icons.play_arrow_rounded,
                          color: AppColors.primary, size: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumb() => Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.play_circle_outline_rounded,
            color: AppColors.textTertiary, size: 24),
      );
}

// ─── Empty & loading states ───────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
      child: Column(
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.youtube_searched_for_rounded,
                size: 32, color: AppColors.textTertiary),
          ),
          const SizedBox(height: 16),
          const Text('Search YouTube', style: AppTextStyles.titleMedium),
          const SizedBox(height: 6),
          const Text(
            'Type a song, artist, or paste a YouTube URL.',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _LoadingShimmer extends StatefulWidget {
  @override
  State<_LoadingShimmer> createState() => _LoadingShimmerState();
}

class _LoadingShimmerState extends State<_LoadingShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
    _anim = Tween(begin: -1.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(5, (i) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(13),
          ),
          child: AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                gradient: LinearGradient(
                  begin: Alignment(-1 + _anim.value, 0),
                  end: Alignment(1 + _anim.value, 0),
                  colors: const [
                    AppColors.surface,
                    AppColors.surfaceVariant,
                    AppColors.surface,
                  ],
                ),
              ),
            ),
          ),
        ),
      )),
    );
  }
}
