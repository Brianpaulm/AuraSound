import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/equalizer_provider.dart';
import '../../models/eq_preset.dart';

class EqualizerScreen extends ConsumerWidget {
  const EqualizerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eq    = ref.watch(eqProvider);
    final notif = ref.read(eqProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [

          // ── Header ──────────────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: Colors.transparent,
            floating: true,
            expandedHeight: 82,
            flexibleSpace: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Precision tuning',
                              style: AppTextStyles.labelMedium.copyWith(
                                  color: AppColors.textTertiary, letterSpacing: 1)),
                          const SizedBox(height: 4),
                          const Text('Equalizer', style: AppTextStyles.headlineMedium),
                        ],
                      ),
                    ),
                    // EQ on/off pill
                    GestureDetector(
                      onTap: () => notif.toggleEnabled(),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: eq.isEnabled
                              ? AppColors.primary.withOpacity(0.12)
                              : AppColors.surface,
                          border: Border.all(
                            color: eq.isEnabled
                                ? AppColors.primary.withOpacity(0.4)
                                : AppColors.border,
                          ),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            width: 7, height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: eq.isEnabled ? AppColors.primary : AppColors.textTertiary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            eq.isEnabled ? 'ON' : 'OFF',
                            style: TextStyle(
                              fontFamily: 'Inter', fontSize: 12,
                              fontWeight: FontWeight.w600, letterSpacing: 0.5,
                              color: eq.isEnabled ? AppColors.primary : AppColors.textTertiary,
                            ),
                          ),
                        ]),
                      ),
                    ),
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

                  // ── 10 / 32 band switcher ────────────────────────────────
                  _ModeSwitcher(
                    is32: eq.isAdvancedMode,
                    onToggle: () => notif.toggleAdvancedMode(),
                  ),
                  const SizedBox(height: 18),

                  // ── Preset chips ─────────────────────────────────────────
                  _PresetChips(
                    presets: eq.allPresets,
                    activeId: eq.activePresetId,
                    onSelect: (p) => notif.applyPreset(p),
                  ),
                  const SizedBox(height: 18),

                  // ── EQ Curve ─────────────────────────────────────────────
                  _EQCurve(bands: eq.activeBands),
                  const SizedBox(height: 18),

                  // ── Sliders ──────────────────────────────────────────────
                  eq.isAdvancedMode
                      ? _EQSliders32(
                          bands: eq.bands32,
                          enabled: eq.isEnabled,
                          onBandChange: (i, v) => notif.setBand32(i, v),
                          onReset: () => notif.resetBands(),
                        )
                      : _EQSliders10(
                          bands: eq.bands10,
                          enabled: eq.isEnabled,
                          onBandChange: (i, v) => notif.setBand10(i, v),
                          onReset: () => notif.resetBands(),
                        ),
                  const SizedBox(height: 26),

                  // ── AI Sound Modes ───────────────────────────────────────
                  const Text('AI Sound Modes', style: AppTextStyles.sectionHeader),
                  const SizedBox(height: 4),
                  Text(
                    'Intelligent presets that shape EQ and effects automatically.',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textTertiary),
                  ),
                  const SizedBox(height: 14),
                  _AIModeGrid(
                    active: eq.aiMode,
                    onSelect: (m) => notif.setAIMode(m),
                  ),
                  const SizedBox(height: 26),

                  // ── Surround / Spatial ───────────────────────────────────
                  const Text('Surround & Spatial', style: AppTextStyles.sectionHeader),
                  const SizedBox(height: 4),
                  Text(
                    'Simulate 3D spaces, concert halls and object-based audio.',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textTertiary),
                  ),
                  const SizedBox(height: 14),
                  _SurroundGrid(
                    active: eq.surroundMode,
                    onSelect: (m) => notif.setSurroundMode(m),
                  ),
                  const SizedBox(height: 26),

                  // ── Sound Effects ────────────────────────────────────────
                  Row(children: [
                    const Expanded(
                        child: Text('Sound Effects', style: AppTextStyles.sectionHeader)),
                    _SpatialChip(
                      value: eq.audioEffect.spatialAudio,
                      onTap: () => notif.toggleSpatialAudio(),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _EffectsPanel(
                    effect: eq.audioEffect,
                    enabled: eq.isEnabled,
                    onBass:    (v) => notif.updateBassBoost(v),
                    onVirt:    (v) => notif.updateVirtualizer(v),
                    onLoud:    (v) => notif.updateLoudness(v),
                    onReverb:  (v) => notif.updateReverb(v),
                    onWidth:   (v) => notif.updateStereoWidth(v),
                  ),
                  const SizedBox(height: 160),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Mode Switcher ────────────────────────────────────────────────────────────

class _ModeSwitcher extends StatelessWidget {
  final bool is32;
  final VoidCallback onToggle;
  const _ModeSwitcher({required this.is32, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(children: [
        _ModeBtn(label: '10 Band', selected: !is32, onTap: () { if (is32) onToggle(); }),
        _ModeBtn(label: '32 Band', selected: is32,  onTap: () { if (!is32) onToggle(); }),
      ]),
    );
  }
}

class _ModeBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ModeBtn({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600,
                color: selected ? AppColors.background : AppColors.textSecondary,
              )),
        ),
      ),
    ),
  );
}

// ─── Preset Chips ─────────────────────────────────────────────────────────────

class _PresetChips extends StatelessWidget {
  final List<EQPreset> presets;
  final String activeId;
  final Function(EQPreset) onSelect;
  const _PresetChips({required this.presets, required this.activeId, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: presets.length,
        itemBuilder: (_, i) {
          final p = presets[i];
          final active = p.id == activeId;
          return GestureDetector(
            onTap: () => onSelect(p),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: active ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(
                  color: active ? AppColors.primary : AppColors.border,
                  width: 0.5,
                ),
                boxShadow: active ? [BoxShadow(
                  color: AppColors.primary.withOpacity(0.25), blurRadius: 8, spreadRadius: -2,
                )] : null,
              ),
              child: Text(p.name,
                  style: TextStyle(
                    fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600,
                    color: active ? AppColors.background : AppColors.textSecondary,
                  )),
            ),
          );
        },
      ),
    );
  }
}

// ─── EQ Curve ─────────────────────────────────────────────────────────────────

class _EQCurve extends StatelessWidget {
  final List<double> bands;
  const _EQCurve({required this.bands});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: CustomPaint(
          painter: _CurvePainter(bands: bands),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _CurvePainter extends CustomPainter {
  final List<double> bands;
  const _CurvePainter({required this.bands});

  @override
  void paint(Canvas canvas, Size size) {
    if (bands.isEmpty) return;
    final mid = size.height / 2;

    canvas.drawLine(Offset(0, mid), Offset(size.width, mid),
        Paint()..color = AppColors.border..strokeWidth = 0.5);

    final fill = Path();
    final line = Path();

    for (int i = 0; i < bands.length; i++) {
      final x = (i / (bands.length - 1)) * size.width;
      final y = size.height * (1 - (bands[i] + 12) / 24);

      if (i == 0) {
        line.moveTo(x, y);
        fill..moveTo(x, mid)..lineTo(x, y);
      } else {
        final px = ((i - 1) / (bands.length - 1)) * size.width;
        final py = size.height * (1 - (bands[i - 1] + 12) / 24);
        final cpx = px + (x - px) * 0.5;
        line.cubicTo(cpx, py, cpx, y, x, y);
        fill.cubicTo(cpx, py, cpx, y, x, y);
      }
    }
    fill.lineTo(size.width, mid);
    fill.close();

    canvas.drawPath(fill, Paint()
      ..shader = LinearGradient(
        colors: [AppColors.primary.withOpacity(0.18), AppColors.primary.withOpacity(0.03)],
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)));

    canvas.drawPath(line, Paint()
      ..color = AppColors.primary.withOpacity(0.85)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round);

    for (int i = 0; i < bands.length; i++) {
      final x = (i / (bands.length - 1)) * size.width;
      final y = size.height * (1 - (bands[i] + 12) / 24);
      canvas.drawCircle(Offset(x, y), 3.5,
          Paint()..color = Colors.white..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(_CurvePainter old) => old.bands != bands;
}

// ─── 10-Band Sliders ──────────────────────────────────────────────────────────

class _EQSliders10 extends StatelessWidget {
  final List<double> bands;
  final bool enabled;
  final Function(int, double) onBandChange;
  final VoidCallback onReset;
  const _EQSliders10({required this.bands, required this.enabled,
      required this.onBandChange, required this.onReset});

  @override
  Widget build(BuildContext context) {
    return _SliderContainer(
      onReset: onReset,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.35,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(10, (i) => _BandSlider(
            value: bands[i],
            label: _fmtHz(AppConstants.eq10BandFrequencies[i]),
            onChanged: enabled ? (v) => onBandChange(i, v) : null,
          )),
        ),
      ),
    );
  }
}

// ─── 32-Band Sliders ─────────────────────────────────────────────────────────

class _EQSliders32 extends StatelessWidget {
  final List<double> bands;
  final bool enabled;
  final Function(int, double) onBandChange;
  final VoidCallback onReset;
  const _EQSliders32({required this.bands, required this.enabled,
      required this.onBandChange, required this.onReset});

  @override
  Widget build(BuildContext context) {
    return _SliderContainer(
      onReset: onReset,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.35,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(32, (i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: _BandSlider(
                value: bands[i],
                label: _fmtHz(AppConstants.eq32BandFrequencies[i]),
                width: 22,
                onChanged: enabled ? (v) => onBandChange(i, v) : null,
              ),
            )),
          ),
        ),
      ),
    );
  }
}

class _SliderContainer extends StatelessWidget {
  final Widget child;
  final VoidCallback onReset;
  const _SliderContainer({required this.child, required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: onReset,
              child: const Text('Reset',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 12,
                      color: AppColors.primary, fontWeight: FontWeight.w500)),
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _BandSlider extends StatelessWidget {
  final double value;
  final String label;
  final double width;
  final ValueChanged<double>? onChanged;
  const _BandSlider({required this.value, required this.label,
      this.width = 26, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(children: [
        Text(
          value >= 0 ? '+${value.toStringAsFixed(0)}' : value.toStringAsFixed(0),
          style: const TextStyle(fontFamily: 'Inter', fontSize: 7,
              color: AppColors.textTertiary,
              fontFeatures: [FontFeature.tabularFigures()]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 140,
          child: RotatedBox(
            quarterTurns: 3,
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: AppColors.surfaceVariant,
                thumbColor: Colors.white,
                overlayColor: AppColors.primary.withOpacity(0.1),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              ),
              child: Slider(
                value: value.clamp(-12.0, 12.0),
                min: -12.0, max: 12.0,
                onChanged: onChanged,
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(label,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 7,
                color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center),
      ]),
    );
  }
}

String _fmtHz(int hz) => hz >= 1000 ? '${(hz / 1000).toStringAsFixed(hz % 1000 == 0 ? 0 : 1)}K' : '$hz';

// ─── AI Mode Grid ─────────────────────────────────────────────────────────────

class _AIModeGrid extends StatelessWidget {
  final AIMode active;
  final Function(AIMode) onSelect;
  const _AIModeGrid({required this.active, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final modes = AIMode.values;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.35,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: modes.length,
      itemBuilder: (_, i) {
        final mode = modes[i];
        final isActive = mode == active;
        return GestureDetector(
          onTap: () => onSelect(mode),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary.withOpacity(0.12) : AppColors.surface,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: isActive ? AppColors.primary.withOpacity(0.5) : AppColors.border,
                width: isActive ? 1.2 : 0.5,
              ),
              boxShadow: isActive ? [BoxShadow(
                color: AppColors.primary.withOpacity(0.12), blurRadius: 12, spreadRadius: -3,
              )] : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(mode.icon,
                    size: 18,
                    color: isActive ? AppColors.primary : AppColors.textSecondary),
                const Spacer(),
                Text(mode.label,
                    style: TextStyle(
                      fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700,
                      color: isActive ? AppColors.primary : AppColors.textPrimary,
                    ),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(mode.description,
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 8,
                        color: AppColors.textTertiary),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Surround Grid ────────────────────────────────────────────────────────────

class _SurroundGrid extends StatelessWidget {
  final SurroundMode active;
  final Function(SurroundMode) onSelect;
  const _SurroundGrid({required this.active, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final modes = SurroundMode.values;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.35,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: modes.length,
      itemBuilder: (_, i) {
        final mode = modes[i];
        final isActive = mode == active;
        return GestureDetector(
          onTap: () => onSelect(mode),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary.withOpacity(0.12) : AppColors.surface,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: isActive ? AppColors.primary.withOpacity(0.5) : AppColors.border,
                width: isActive ? 1.2 : 0.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(mode.icon, size: 18,
                    color: isActive ? AppColors.primary : AppColors.textSecondary),
                const Spacer(),
                Text(mode.label,
                    style: TextStyle(
                      fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700,
                      color: isActive ? AppColors.primary : AppColors.textPrimary,
                    ),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(mode.description,
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 8,
                        color: AppColors.textTertiary),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Spatial chip ─────────────────────────────────────────────────────────────

class _SpatialChip extends StatelessWidget {
  final bool value;
  final VoidCallback onTap;
  const _SpatialChip({required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: value ? AppColors.primary.withOpacity(0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: value ? AppColors.primary.withOpacity(0.4) : AppColors.border,
            width: 0.5,
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.surround_sound_rounded, size: 13,
              color: value ? AppColors.primary : AppColors.textTertiary),
          const SizedBox(width: 5),
          Text('Spatial',
              style: TextStyle(fontFamily: 'Inter', fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: value ? AppColors.primary : AppColors.textTertiary)),
        ]),
      ),
    );
  }
}

// ─── Effects Panel ────────────────────────────────────────────────────────────

class _EffectsPanel extends StatelessWidget {
  final AudioEffect effect;
  final bool enabled;
  final Function(double) onBass, onVirt, onLoud, onReverb, onWidth;
  const _EffectsPanel({
    required this.effect, required this.enabled,
    required this.onBass, required this.onVirt,
    required this.onLoud, required this.onReverb, required this.onWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          // Knobs row
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _Knob(label: 'Bass',       value: effect.bassBoost,   onChanged: enabled ? onBass : null),
            _Knob(label: 'Virtualizer',value: effect.virtualizer, onChanged: enabled ? onVirt : null),
            _Knob(label: 'Loudness',   value: effect.loudness,    onChanged: enabled ? onLoud : null),
            _Knob(label: 'Reverb',     value: effect.reverb,      onChanged: enabled ? onReverb : null),
          ]),
          const SizedBox(height: 18),
          // Stereo width slider
          _WidthSlider(value: effect.stereoWidth, enabled: enabled, onChange: onWidth),
        ],
      ),
    );
  }
}

class _Knob extends StatelessWidget {
  final String label;
  final double value;
  final Function(double)? onChanged;
  const _Knob({required this.label, required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: onChanged == null
          ? null
          : (d) => onChanged!((value - d.delta.dy).clamp(0.0, 100.0)),
      child: Column(children: [
        SizedBox(
          width: 62, height: 62,
          child: CustomPaint(
            painter: _KnobPainter(value: value / 100),
            child: Center(child: Text('${value.toInt()}%',
                style: const TextStyle(fontFamily: 'Inter', fontSize: 10,
                    fontWeight: FontWeight.w700, color: AppColors.primary))),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 9,
            color: AppColors.textSecondary), textAlign: TextAlign.center),
      ]),
    );
  }
}

class _KnobPainter extends CustomPainter {
  final double value;
  const _KnobPainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 5;

    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      math.pi * 0.75, math.pi * 1.5, false,
      Paint()..color = AppColors.surfaceVariant..strokeWidth = 5
          ..style = PaintingStyle.stroke..strokeCap = StrokeCap.round,
    );

    if (value > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        math.pi * 0.75, math.pi * 1.5 * value, false,
        Paint()..color = AppColors.primary.withOpacity(0.85)..strokeWidth = 5
            ..style = PaintingStyle.stroke..strokeCap = StrokeCap.round,
      );
    }

    canvas.drawCircle(c, r - 9,
        Paint()..color = AppColors.backgroundCard..style = PaintingStyle.fill);

    final angle = math.pi * 0.75 + math.pi * 1.5 * value;
    canvas.drawLine(
      Offset(c.dx + (r - 16) * math.cos(angle), c.dy + (r - 16) * math.sin(angle)),
      Offset(c.dx + (r - 9)  * math.cos(angle), c.dy + (r - 9)  * math.sin(angle)),
      Paint()..color = AppColors.primary..strokeWidth = 1.8..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_KnobPainter old) => old.value != value;
}

class _WidthSlider extends StatefulWidget {
  final double value;
  final bool enabled;
  final Function(double) onChange;
  const _WidthSlider({required this.value, required this.enabled, required this.onChange});

  @override
  State<_WidthSlider> createState() => _WidthSliderState();
}

class _WidthSliderState extends State<_WidthSlider> {
  late double _local;

  @override
  void initState() {
    super.initState();
    _local = widget.value;
  }

  @override
  void didUpdateWidget(_WidthSlider old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) _local = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(children: [
        const Text('Stereo Width',
            style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textSecondary)),
        const Spacer(),
        Text('${_local.toInt()}%',
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
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        ),
        child: Slider(
          value: (_local / 200).clamp(0.0, 1.0),
          onChanged: widget.enabled ? (v) => setState(() => _local = v * 200) : null,
          onChangeEnd: widget.enabled ? (v) => widget.onChange(v * 200) : null,
        ),
      ),
      const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Mono', style: TextStyle(fontFamily: 'Inter', fontSize: 9, color: AppColors.textTertiary)),
          Text('Normal', style: TextStyle(fontFamily: 'Inter', fontSize: 9, color: AppColors.textTertiary)),
          Text('Wide', style: TextStyle(fontFamily: 'Inter', fontSize: 9, color: AppColors.textTertiary)),
        ],
      ),
    ]);
  }
}
