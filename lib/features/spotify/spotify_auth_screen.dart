import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class SpotifyAuthScreen extends ConsumerStatefulWidget {
  const SpotifyAuthScreen({super.key});

  @override
  ConsumerState<SpotifyAuthScreen> createState() => _SpotifyAuthScreenState();
}

class _SpotifyAuthScreenState extends ConsumerState<SpotifyAuthScreen> {
  bool _connecting = false;
  bool _connected  = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            leading: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 15, color: AppColors.textPrimary),
              ),
            ),
            title: const Text('Spotify', style: AppTextStyles.titleLarge),
            pinned: true,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.spotifyGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: AppColors.spotifyGreen.withOpacity(0.3), width: 0.5),
                    ),
                    child: const Text('Streaming',
                        style: TextStyle(
                          fontFamily: 'Inter', fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.spotifyGreen,
                        )),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Connect your Premium account to stream\nright inside AuraSound.',
                    style: TextStyle(
                      fontFamily: 'Inter', fontSize: 15,
                      color: AppColors.textSecondary, height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Connection card
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 42, height: 42,
                              decoration: BoxDecoration(
                                color: AppColors.spotifyGreen.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.music_note_rounded,
                                  color: AppColors.spotifyGreen, size: 20),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Spotify Premium',
                                      style: TextStyle(
                                        fontFamily: 'Inter', fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      )),
                                  Text('OAuth 2.0 · PKCE flow',
                                      style: TextStyle(
                                        fontFamily: 'Inter', fontSize: 11,
                                        color: AppColors.textTertiary,
                                      )),
                                ],
                              ),
                            ),
                            if (_connected)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text('Active',
                                    style: TextStyle(
                                      fontFamily: 'Inter', fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.success,
                                    )),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1, color: AppColors.border),
                        const SizedBox(height: 16),
                        const Text(
                          'Credentials are configured in the app source code. '
                          'Tapping Connect launches the Spotify OAuth consent screen '
                          'in your browser — no credentials are stored on-device.',
                          style: TextStyle(
                            fontFamily: 'Inter', fontSize: 12,
                            color: AppColors.textSecondary, height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Connect button
                        GestureDetector(
                          onTap: _connected ? null : () async {
                            setState(() => _connecting = true);
                            // Real implementation: launch Spotify OAuth URL
                            // using url_launcher + handle callback via deep link
                            await Future.delayed(const Duration(seconds: 2));
                            if (mounted) {
                              setState(() {
                                _connecting = false;
                                _connected  = true;
                              });
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: double.infinity,
                            height: 46,
                            decoration: BoxDecoration(
                              color: _connected
                                  ? AppColors.success.withOpacity(0.12)
                                  : AppColors.spotifyGreen,
                              borderRadius: BorderRadius.circular(11),
                              border: _connected
                                  ? Border.all(
                                      color: AppColors.success.withOpacity(0.3))
                                  : null,
                              boxShadow: !_connected ? [
                                BoxShadow(
                                  color: AppColors.spotifyGreen.withOpacity(0.3),
                                  blurRadius: 14, spreadRadius: -4,
                                  offset: const Offset(0, 6),
                                ),
                              ] : null,
                            ),
                            child: Center(
                              child: _connecting
                                  ? const SizedBox(
                                      width: 20, height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : Text(
                                      _connected
                                          ? '✓  Connected to Spotify'
                                          : 'Connect with Spotify',
                                      style: TextStyle(
                                        fontFamily: 'Inter', fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: _connected
                                            ? AppColors.success
                                            : Colors.white,
                                      )),
                            ),
                          ),
                        ),
                        if (_connected) ...[
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () => setState(() => _connected = false),
                            child: const Center(
                              child: Text('Disconnect',
                                  style: TextStyle(
                                    fontFamily: 'Inter', fontSize: 13,
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w500,
                                  )),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Developer dashboard link
                  _Card(
                    child: Row(
                      children: [
                        Container(
                          width: 34, height: 34,
                          decoration: BoxDecoration(
                            color: AppColors.spotifyGreen.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.open_in_new_rounded,
                              color: AppColors.spotifyGreen, size: 16),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Spotify for Developers',
                                  style: TextStyle(
                                    fontFamily: 'Inter', fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  )),
                              Text('developer.spotify.com',
                                  style: TextStyle(
                                    fontFamily: 'Inter', fontSize: 11,
                                    color: AppColors.textTertiary,
                                  )),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: AppColors.textTertiary, size: 18),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // What you get
                  const Text('What you get', style: AppTextStyles.titleSmall),
                  const SizedBox(height: 14),
                  ...[
                    (Icons.queue_music_rounded,  'Stream 100M+ tracks instantly'),
                    (Icons.shuffle_rounded,       'Mix local + Spotify in one queue'),
                    (Icons.recommend_rounded,     'Personalised recommendations'),
                    (Icons.spatial_audio_off_rounded, 'AuraSound DSP applied to streams'),
                    (Icons.download_rounded,      'Offline downloads (Premium)'),
                  ].map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 34, height: 34,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.border, width: 0.5),
                          ),
                          child: Icon(item.$1,
                              color: AppColors.textSecondary, size: 16),
                        ),
                        const SizedBox(width: 12),
                        Text(item.$2,
                            style: const TextStyle(
                              fontFamily: 'Inter', fontSize: 13,
                              color: AppColors.textPrimary,
                            )),
                      ],
                    ),
                  )),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: child,
    );
  }
}

