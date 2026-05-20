import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

// ─── Video State ──────────────────────────────────────────────────────────────

class VideoPlayerState {
  final String? filePath;
  final String? fileName;
  final bool isLoading;
  final String? error;

  const VideoPlayerState({
    this.filePath,
    this.fileName,
    this.isLoading = false,
    this.error,
  });

  VideoPlayerState copyWith({
    String? filePath,
    String? fileName,
    bool? isLoading,
    String? error,
  }) {
    return VideoPlayerState(
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class VideoNotifier extends StateNotifier<VideoPlayerState> {
  VideoNotifier() : super(const VideoPlayerState());

  void setFile(String path, String name) {
    state = VideoPlayerState(filePath: path, fileName: name);
  }

  void setLoading(bool v) => state = state.copyWith(isLoading: v);
  void setError(String e) => state = state.copyWith(error: e, isLoading: false);
  void clear() => state = const VideoPlayerState();
}

final videoProvider =
    StateNotifierProvider<VideoNotifier, VideoPlayerState>((ref) {
  return VideoNotifier();
});

// ─── Video Picker Screen ──────────────────────────────────────────────────────

class VideoScreen extends ConsumerWidget {
  const VideoScreen({super.key});

  static const _videoExts = [
    'mp4', 'mkv', 'mov', 'avi', 'webm', 'm4v', '3gp', 'ts', 'flv',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videoState = ref.watch(videoProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            floating: true,
            expandedHeight: 90,
            flexibleSpace: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Watch anything',
                        style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.textTertiary, letterSpacing: 1)),
                    const SizedBox(height: 4),
                    const Text('Video Player',
                        style: AppTextStyles.headlineMedium),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // ── Import card ────────────────────────────────────────
                  GestureDetector(
                    onTap: videoState.isLoading
                        ? null
                        : () => _pickVideo(context, ref),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 28, horizontal: 20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border, width: 0.5),
                      ),
                      child: Column(
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: videoState.isLoading
                                ? const SizedBox(
                                    width: 36,
                                    height: 36,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primary),
                                  )
                                : const Icon(Icons.video_file_rounded,
                                    size: 38,
                                    color: AppColors.textTertiary),
                          ),
                          const SizedBox(height: 12),
                          const Text('Choose a video file',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              )),
                          const SizedBox(height: 4),
                          Text(
                            _videoExts
                                .map((e) => e.toUpperCase())
                                .take(6)
                                .join(' · '),
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: AppColors.textTertiary,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Error ──────────────────────────────────────────────
                  if (videoState.error != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.error.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: AppColors.error, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(videoState.error!,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: AppColors.error,
                                )),
                          ),
                        ],
                      ),
                    ),

                  // ── Last played ────────────────────────────────────────
                  if (videoState.fileName != null && !videoState.isLoading) ...[
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => _openPlayer(context, videoState.filePath!,
                          videoState.fileName!),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppColors.primary.withOpacity(0.2),
                              width: 0.8),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.play_circle_outline_rounded,
                                color: AppColors.primary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(videoState.fileName!,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  const Text('Tap to play fullscreen',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      )),
                                ],
                              ),
                            ),
                            const Icon(Icons.fullscreen_rounded,
                                color: AppColors.primary, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // ── Supported formats ──────────────────────────────────
                  _FormatsGrid(),
                  const SizedBox(height: 160),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickVideo(BuildContext context, WidgetRef ref) async {
    ref.read(videoProvider.notifier).setLoading(true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _videoExts,
        withData: false,
      );

      if (result == null || result.files.isEmpty) {
        ref.read(videoProvider.notifier).setLoading(false);
        return;
      }

      final file = result.files.first;
      if (file.path == null) {
        ref.read(videoProvider.notifier).setError('Could not read file path');
        return;
      }

      ref.read(videoProvider.notifier).setFile(file.path!, file.name);
      _openPlayer(context, file.path!, file.name);
    } catch (e) {
      ref.read(videoProvider.notifier).setError('Failed to open file: $e');
    }
  }

  void _openPlayer(BuildContext context, String path, String name) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) =>
            FullscreenVideoPlayer(filePath: path, title: name),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: child,
        ),
      ),
    );
  }
}

// ─── Fullscreen Video Player ──────────────────────────────────────────────────

class FullscreenVideoPlayer extends StatefulWidget {
  final String filePath;
  final String title;

  const FullscreenVideoPlayer({
    super.key,
    required this.filePath,
    required this.title,
  });

  @override
  State<FullscreenVideoPlayer> createState() => _FullscreenVideoPlayerState();
}

class _FullscreenVideoPlayerState extends State<FullscreenVideoPlayer>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _videoCtrl;
  ChewieController? _chewieCtrl;
  bool _initialized = false;
  String? _error;
  late AnimationController _uiCtrl;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();

    // Lock to landscape for fullscreen experience
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _uiCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    _uiCtrl.value = 1.0;

    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      _videoCtrl = VideoPlayerController.file(File(widget.filePath));
      await _videoCtrl.initialize();

      _chewieCtrl = ChewieController(
        videoPlayerController: _videoCtrl,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primary,
          handleColor: Colors.white,
          backgroundColor: AppColors.surfaceVariant,
          bufferedColor: AppColors.primary.withOpacity(0.25),
        ),
        placeholder: Container(color: Colors.black),
        autoInitialize: true,
        customControls: _AuraVideoControls(
          title: widget.title,
          onClose: () => _closePlayer(),
        ),
      );

      if (mounted) setState(() => _initialized = true);
    } catch (e) {
      if (mounted) setState(() => _error = 'Cannot play this file: $e');
    }
  }

  void _closePlayer() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _chewieCtrl?.dispose();
    _videoCtrl.dispose();
    _uiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _error != null
          ? _ErrorState(error: _error!, onClose: _closePlayer)
          : !_initialized
              ? _LoadingState(title: widget.title)
              : Stack(
                  children: [
                    // Chewie player fills the screen
                    Chewie(controller: _chewieCtrl!),
                  ],
                ),
    );
  }
}

// ─── Custom AuraSound video controls overlay ──────────────────────────────────

class _AuraVideoControls extends StatefulWidget {
  final String title;
  final VoidCallback onClose;

  const _AuraVideoControls({required this.title, required this.onClose});

  @override
  State<_AuraVideoControls> createState() => _AuraVideoControlsState();
}

class _AuraVideoControlsState extends State<_AuraVideoControls>
    with SingleTickerProviderStateMixin {
  bool _visible = true;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut));
    _fadeCtrl.value = 1.0;
    _scheduleHide();
  }

  void _scheduleHide() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _visible) _hide();
    });
  }

  void _show() {
    setState(() => _visible = true);
    _fadeCtrl.forward();
    _scheduleHide();
  }

  void _hide() {
    if (!mounted) return;
    setState(() => _visible = false);
    _fadeCtrl.reverse();
  }

  void _toggle() => _visible ? _hide() : _show();

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final videoCtrl = context
        .findAncestorStateOfType<_FullscreenVideoPlayerState>()
        ?._videoCtrl;

    return GestureDetector(
      onTap: _toggle,
      behavior: HitTestBehavior.opaque,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.7),
                Colors.transparent,
                Colors.transparent,
                Colors.black.withOpacity(0.7),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.25, 0.75, 1.0],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // ── Top bar ────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: widget.onClose,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.45),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white.withOpacity(0.15)),
                          ),
                          child: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // ── Centre play/pause ──────────────────────────────────
                if (videoCtrl != null)
                  ValueListenableBuilder<VideoPlayerValue>(
                    valueListenable: videoCtrl,
                    builder: (_, value, __) {
                      return GestureDetector(
                        onTap: () {
                          value.isPlaying
                              ? videoCtrl.pause()
                              : videoCtrl.play();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withOpacity(0.5),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.25),
                                width: 1.5),
                          ),
                          child: Icon(
                            value.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      );
                    },
                  ),

                const Spacer(),

                // ── Bottom progress + controls ─────────────────────────
                if (videoCtrl != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: _VideoBottomBar(videoCtrl: videoCtrl),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VideoBottomBar extends StatefulWidget {
  final VideoPlayerController videoCtrl;
  const _VideoBottomBar({required this.videoCtrl});

  @override
  State<_VideoBottomBar> createState() => _VideoBottomBarState();
}

class _VideoBottomBarState extends State<_VideoBottomBar> {
  double? _dragValue;

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours > 0 ? '${d.inHours}:' : '';
    return '$h$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: widget.videoCtrl,
      builder: (_, value, __) {
        final total = value.duration.inMilliseconds;
        final pos = value.position.inMilliseconds;
        final progress =
            total > 0 ? (_dragValue ?? pos / total).clamp(0.0, 1.0) : 0.0;

        return Column(
          children: [
            // Progress row
            Row(
              children: [
                Text(_fmt(value.position),
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: Colors.white70,
                        fontFeatures: [FontFeature.tabularFigures()])),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 3,
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: Colors.white.withOpacity(0.18),
                      thumbColor: Colors.white,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 7),
                      overlayColor: AppColors.primary.withOpacity(0.15),
                    ),
                    child: Slider(
                      value: progress.toDouble(),
                      onChanged: (v) => setState(() => _dragValue = v),
                      onChangeEnd: (v) {
                        setState(() => _dragValue = null);
                        if (total > 0) {
                          widget.videoCtrl.seekTo(
                              Duration(milliseconds: (v * total).round()));
                        }
                      },
                    ),
                  ),
                ),
                Text(_fmt(value.duration),
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: Colors.white70,
                        fontFeatures: [FontFeature.tabularFigures()])),
              ],
            ),
            // Speed + mute row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ControlBtn(
                  icon: Icons.replay_10_rounded,
                  onTap: () {
                    final newPos = value.position - const Duration(seconds: 10);
                    widget.videoCtrl.seekTo(
                        newPos.isNegative ? Duration.zero : newPos);
                  },
                ),
                const SizedBox(width: 20),
                _ControlBtn(
                  icon: value.volume > 0
                      ? Icons.volume_up_rounded
                      : Icons.volume_off_rounded,
                  onTap: () {
                    widget.videoCtrl
                        .setVolume(value.volume > 0 ? 0.0 : 1.0);
                  },
                ),
                const SizedBox(width: 20),
                _ControlBtn(
                  icon: Icons.forward_10_rounded,
                  onTap: () {
                    final newPos = value.position + const Duration(seconds: 10);
                    widget.videoCtrl.seekTo(
                        newPos > value.duration ? value.duration : newPos);
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ControlBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ControlBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}

// ─── Loading / Error states ───────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  final String title;
  const _LoadingState({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 42,
              height: 42,
              child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: Colors.white70),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onClose;
  const _ErrorState({required this.error, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(28),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.broken_image_rounded,
                color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            const Text('Playback failed',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
            const SizedBox(height: 8),
            Text(error,
                style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: Colors.white54),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onClose,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Text('Close',
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Formats grid ─────────────────────────────────────────────────────────────

class _FormatsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const formats = [
      ('MP4', 'H.264 / H.265'),
      ('MKV', 'Matroska'),
      ('MOV', 'Apple QuickTime'),
      ('AVI', 'Audio Video Interleave'),
      ('WEBM', 'VP8 / VP9'),
      ('M4V', 'iTunes Video'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Supported formats', style: AppTextStyles.titleSmall),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2.4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: formats.length,
          itemBuilder: (_, i) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(formats[i].$1,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      )),
                  Text(formats[i].$2,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9,
                        color: AppColors.textTertiary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
