import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/library_provider.dart';
import '../../providers/audio_provider.dart';
import '../../services/storage_scanner.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Playback prefs (backed by audio provider config)
  double _crossfadeDuration = 3.0;

  @override
  Widget build(BuildContext context) {
    final themeState   = ref.watch(themeProvider);
    final theme        = ref.read(themeProvider.notifier);
    final playerState  = ref.watch(playerProvider);
    final player       = ref.read(playerProvider.notifier);
    final libState     = ref.watch(libraryProvider);
    final config       = playerState.config;

    _crossfadeDuration = config.crossfadeDuration;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header ──────────────────────────────────────────────────────
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
                    Text('Preferences',
                        style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.textTertiary, letterSpacing: 1)),
                    const SizedBox(height: 4),
                    const Text('Settings', style: AppTextStyles.headlineMedium),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [

                  // ── Playback ──────────────────────────────────────────────
                  _Section(title: 'Playback', children: [

                    // Gapless toggle
                    _TileSwitch(
                      icon: Icons.skip_next_rounded,
                      label: 'Gapless Playback',
                      subtitle: 'Seamless transitions between tracks',
                      value: config.gapless,
                      onChanged: (v) => player.updateConfig(config.copyWith(gapless: v)),
                    ),

                    // Crossfade toggle
                    _TileSwitch(
                      icon: Icons.swap_horiz_rounded,
                      label: 'Crossfade',
                      subtitle: 'Fade between consecutive tracks',
                      value: config.crossfade,
                      onChanged: (v) => player.updateConfig(config.copyWith(crossfade: v)),
                    ),

                    // Crossfade duration — only visible when crossfade on
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      child: config.crossfade
                          ? _SliderTile(
                              icon: Icons.linear_scale_rounded,
                              label: 'Crossfade Duration',
                              value: config.crossfadeDuration,
                              min: 1.0,
                              max: 12.0,
                              divisions: 22,
                              displayValue: '${config.crossfadeDuration.toStringAsFixed(1)}s',
                              onChangeEnd: (v) {
                                setState(() => _crossfadeDuration = v);
                                player.updateConfig(config.copyWith(crossfadeDuration: v));
                              },
                            )
                          : const SizedBox.shrink(),
                    ),

                    // Normalization
                    _TileSwitch(
                      icon: Icons.compress_rounded,
                      label: 'Audio Normalization',
                      subtitle: 'Balance loudness across tracks',
                      value: config.normalization,
                      onChanged: (v) => player.updateConfig(config.copyWith(normalization: v)),
                    ),

                    // Playback speed
                    _SliderTile(
                      icon: Icons.speed_rounded,
                      label: 'Playback Speed',
                      value: config.speed,
                      min: 0.5,
                      max: 2.0,
                      divisions: 15,
                      displayValue: '${config.speed.toStringAsFixed(2)}×',
                      onChangeEnd: (v) => player.setPlaybackSpeed(v),
                    ),
                  ]),

                  // ── Appearance ─────────────────────────────────────────────
                  _Section(title: 'Appearance', children: [
                    _ThemeTile(
                      mode: themeState.themeMode,
                      onChanged: (m) => theme.setThemeMode(m),
                    ),
                    _AccentTile(
                      color: themeState.accentColor,
                      onChanged: (c) => theme.setAccentColor(c),
                    ),
                    _TileSwitch(
                      icon: Icons.blur_on_rounded,
                      label: 'Glassmorphism Blur',
                      subtitle: 'Frosted glass surfaces',
                      value: themeState.useBlurEffects,
                      onChanged: (_) => theme.toggleBlurEffects(),
                    ),
                    _TileSwitch(
                      icon: Icons.animation_rounded,
                      label: 'Animations',
                      subtitle: 'Motion effects and transitions',
                      value: themeState.showAnimations,
                      onChanged: (_) => theme.toggleAnimations(),
                    ),
                  ]),

                  // ── Library ────────────────────────────────────────────────
                  _Section(title: 'Library', children: [
                    _TileInfo(
                      icon: Icons.library_music_rounded,
                      label: 'Imported tracks',
                      value: '${libState.songs.length}',
                    ),
                    _TileInfo(
                      icon: Icons.person_rounded,
                      label: 'Artists',
                      value: '${libState.artists.length}',
                    ),
                    _TileInfo(
                      icon: Icons.album_rounded,
                      label: 'Albums',
                      value: '${libState.albums.length}',
                    ),
                    _TileButton(
                      icon: Icons.refresh_rounded,
                      label: 'Rescan Storage',
                      subtitle: 'Re-read all audio files from device',
                      color: AppColors.primary,
                      onTap: () async {
                        await ref.read(storageScannerProvider.notifier).rescan();
                        final songs = ref.read(storageScannerProvider).songs;
                        if (songs.isNotEmpty) {
                          ref.read(libraryProvider.notifier).loadScannedSongs(songs);
                        }
                      },
                    ),
                    _TileButton(
                      icon: Icons.delete_outline_rounded,
                      label: 'Clear Library',
                      subtitle: 'Remove all imported tracks',
                      color: AppColors.error,
                      onTap: () => _confirmClearLibrary(context, ref),
                    ),
                  ]),

                  // ── Audio Quality ──────────────────────────────────────────
                  _Section(title: 'Audio Quality', children: [
                    _TileInfo(
                      icon: Icons.high_quality_rounded,
                      label: 'Max supported bit depth',
                      value: '32-bit float',
                    ),
                    _TileInfo(
                      icon: Icons.graphic_eq_rounded,
                      label: 'Max sample rate',
                      value: '192 kHz',
                    ),
                    _TileInfo(
                      icon: Icons.spatial_audio_off_rounded,
                      label: 'Hardware EQ',
                      value: 'AndroidEqualizer',
                    ),
                  ]),

                  // ── Spotify ────────────────────────────────────────────────
                  _Section(title: 'Streaming', children: [
                    _TileButton(
                      icon: Icons.music_note_rounded,
                      label: 'Connect Spotify',
                      subtitle: 'Link your Premium account',
                      color: AppColors.spotifyGreen,
                      onTap: () => context.push('/spotify-auth'),
                    ),
                    _TileButton(
                      icon: Icons.smart_display_rounded,
                      label: 'YouTube Search',
                      subtitle: 'Stream directly from YouTube',
                      color: const Color(0xFFFF0000),
                      onTap: () => context.go('/youtube'),
                    ),
                    _TileInfo(
                      icon: Icons.code_rounded,
                      label: 'Spotify credentials',
                      value: 'In app_constants.dart',
                    ),
                  ]),

                  // ── About ──────────────────────────────────────────────────
                  _Section(title: 'About', children: [
                    _TileInfo(icon: Icons.info_outline_rounded, label: 'Version', value: '1.0.0'),
                    _TileInfo(icon: Icons.build_rounded, label: 'Build', value: 'Release 1'),
                    _TileInfo(icon: Icons.flutter_dash_rounded, label: 'Framework', value: 'Flutter 3.x'),
                  ]),

                  const SizedBox(height: 140),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmClearLibrary(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.backgroundElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Clear Library',
            style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        content: const Text(
            'This will remove all imported tracks from the library. Audio files on your device are not deleted.',
            style: TextStyle(fontFamily: 'Inter', fontSize: 13,
                color: AppColors.textSecondary, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(fontFamily: 'Inter', color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              ref.read(libraryProvider.notifier).loadScannedSongs([]);
              Navigator.pop(context);
            },
            child: const Text('Clear',
                style: TextStyle(fontFamily: 'Inter', color: AppColors.error,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ─── Section wrapper ──────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 24, 4, 10),
          child: Text(title.toUpperCase(),
              style: const TextStyle(fontFamily: 'Inter', fontSize: 10,
                  fontWeight: FontWeight.w600, color: AppColors.textTertiary,
                  letterSpacing: 1.3)),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Column(
            children: List.generate(children.length * 2 - 1, (i) {
              if (i.isOdd) {
                return const Divider(
                    height: 1, color: AppColors.border, indent: 52);
              }
              return children[i ~/ 2];
            }),
          ),
        ),
      ],
    );
  }
}

// ─── Tile widgets ─────────────────────────────────────────────────────────────

class _TileSwitch extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _TileSwitch({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        _TileIcon(icon: icon, active: value),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.titleSmall),
            if (subtitle != null)
              Text(subtitle!, style: AppTextStyles.bodySmall),
          ],
        )),
        Switch(value: value, onChanged: onChanged),
      ]),
    );
  }
}

class _TileInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _TileInfo({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(children: [
        _TileIcon(icon: icon),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: AppTextStyles.titleSmall)),
        Text(value, style: AppTextStyles.bodySmall),
      ]),
    );
  }
}

class _TileButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color color;
  final VoidCallback onTap;

  const _TileButton({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          _TileIcon(icon: icon, color: color),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.titleSmall.copyWith(color: color)),
              if (subtitle != null) Text(subtitle!, style: AppTextStyles.bodySmall),
            ],
          )),
          Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 18),
        ]),
      ),
    );
  }
}

class _SliderTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final double value, min, max;
  final int divisions;
  final String displayValue;
  final ValueChanged<double> onChangeEnd;

  const _SliderTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.displayValue,
    required this.onChangeEnd,
  });

  @override
  State<_SliderTile> createState() => _SliderTileState();
}

class _SliderTileState extends State<_SliderTile> {
  late double _local;

  @override
  void initState() {
    super.initState();
    _local = widget.value;
  }

  @override
  void didUpdateWidget(_SliderTile old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) _local = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Column(
        children: [
          Row(children: [
            _TileIcon(icon: widget.icon),
            const SizedBox(width: 12),
            Expanded(child: Text(widget.label, style: AppTextStyles.titleSmall)),
            Text(widget.displayValue,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 12,
                    fontWeight: FontWeight.w600, color: AppColors.primary)),
          ]),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.surfaceVariant,
              thumbColor: Colors.white,
              overlayColor: AppColors.primary.withOpacity(0.1),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              value: _local.clamp(widget.min, widget.max),
              min: widget.min,
              max: widget.max,
              divisions: widget.divisions,
              onChanged: (v) => setState(() => _local = v),
              onChangeEnd: widget.onChangeEnd,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${widget.min}', style: const TextStyle(fontFamily: 'Inter', fontSize: 9, color: AppColors.textTertiary)),
              Text('${widget.max}', style: const TextStyle(fontFamily: 'Inter', fontSize: 9, color: AppColors.textTertiary)),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _TileIcon extends StatelessWidget {
  final IconData icon;
  final bool active;
  final Color? color;

  const _TileIcon({required this.icon, this.active = false, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? (active ? AppColors.primary : AppColors.textSecondary);
    return Container(
      width: 34, height: 34,
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(icon, color: c, size: 17),
    );
  }
}

// ─── Theme tile ───────────────────────────────────────────────────────────────

class _ThemeTile extends StatelessWidget {
  final ThemeMode mode;
  final ValueChanged<ThemeMode> onChanged;
  const _ThemeTile({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const _TileIcon(icon: Icons.palette_rounded),
            const SizedBox(width: 12),
            const Text('Theme', style: AppTextStyles.titleSmall),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            _ThemeBtn(label: 'Light',  selected: mode == ThemeMode.light,  onTap: () => onChanged(ThemeMode.light)),
            const SizedBox(width: 8),
            _ThemeBtn(label: 'Dark',   selected: mode == ThemeMode.dark,   onTap: () => onChanged(ThemeMode.dark)),
            const SizedBox(width: 8),
            _ThemeBtn(label: 'System', selected: mode == ThemeMode.system, onTap: () => onChanged(ThemeMode.system)),
          ]),
        ],
      ),
    );
  }
}

class _ThemeBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ThemeBtn({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label,
            style: TextStyle(fontFamily: 'Inter', fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.background : AppColors.textSecondary)),
      ),
    );
  }
}

// ─── Accent color tile ────────────────────────────────────────────────────────

class _AccentTile extends StatelessWidget {
  final Color color;
  final ValueChanged<Color> onChanged;
  const _AccentTile({required this.color, required this.onChanged});

  static const _colors = [
    Color(0xFFF0F0F2), Color(0xFFD4D4D8), Color(0xFFB0B0B8),
    Color(0xFF888890), Color(0xFF606068), Color(0xFFFFFFFF),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const _TileIcon(icon: Icons.color_lens_rounded),
            const SizedBox(width: 12),
            const Text('Accent colour', style: AppTextStyles.titleSmall),
          ]),
          const SizedBox(height: 12),
          Row(
            children: _colors.map((c) => GestureDetector(
              onTap: () => onChanged(c),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 28, height: 28,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color == c ? AppColors.primary : Colors.transparent,
                    width: 2.5,
                  ),
                  boxShadow: color == c
                      ? [BoxShadow(color: c.withOpacity(0.4), blurRadius: 8)]
                      : null,
                ),
                child: color == c
                    ? const Icon(Icons.check_rounded, size: 14, color: AppColors.background)
                    : null,
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}
