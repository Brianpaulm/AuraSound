import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

// ─── Main Logo Widget ─────────────────────────────────────────────────────────

class AuraLogo extends StatefulWidget {
  final double size;
  final bool animate;
  final bool showWordmark;
  final bool showTagline;

  const AuraLogo({
    super.key,
    this.size = 80,
    this.animate = true,
    this.showWordmark = false,
    this.showTagline = false,
  });

  @override
  State<AuraLogo> createState() => _AuraLogoState();
}

class _AuraLogoState extends State<AuraLogo> with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _ringCtrl;
  late AnimationController _barsCtrl;

  late Animation<double> _pulseAnim;
  late Animation<double> _ringAnim;
  late Animation<double> _barsAnim;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    );
    _barsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _ringAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ringCtrl, curve: Curves.linear),
    );
    _barsAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _barsCtrl, curve: Curves.easeInOut),
    );

    if (widget.animate) {
      _pulseCtrl.repeat(reverse: true);
      _ringCtrl.repeat();
      _barsCtrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _ringCtrl.dispose();
    _barsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: Listenable.merge([_pulseAnim, _ringAnim, _barsAnim]),
          builder: (_, __) => _LogoMark(
            size: widget.size,
            pulse: _pulseAnim.value,
            ring: _ringAnim.value,
            bars: _barsAnim.value,
          ),
        ),
        if (widget.showWordmark) ...[
          SizedBox(height: widget.size * 0.18),
          _AuraWordmark(size: widget.size),
        ],
        if (widget.showTagline) ...[
          SizedBox(height: widget.size * 0.08),
          Text(
            'Feel every beat',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: widget.size * 0.14,
              fontWeight: FontWeight.w400,
              color: AppColors.textTertiary,
              letterSpacing: 2,
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Logo Mark ────────────────────────────────────────────────────────────────

class _LogoMark extends StatelessWidget {
  final double size;
  final double pulse;  // 0-1, glow pulse
  final double ring;   // 0-1, ring rotation
  final double bars;   // 0-1, bar animation

  const _LogoMark({
    required this.size,
    required this.pulse,
    required this.ring,
    required this.bars,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _LogoPainter(
          pulse: pulse,
          ring: ring,
          bars: bars,
        ),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  final double pulse;
  final double ring;
  final double bars;

  const _LogoPainter({
    required this.pulse,
    required this.ring,
    required this.bars,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    // ── Outer glow ───────────────────────────────────────────────────────────
    canvas.drawCircle(
      Offset(cx, cy),
      r * 0.98,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withOpacity(0.07 + pulse * 0.06),
            AppColors.primary.withOpacity(0.04 + pulse * 0.04),
            Colors.transparent,
          ],
          stops: const [0.0, 0.6, 1.0],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r)),
    );

    // ── Background circle ─────────────────────────────────────────────────────
    canvas.drawCircle(
      Offset(cx, cy),
      r * 0.88,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF1E1E24),
            const Color(0xFF111115),
          ],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.88)),
    );

    // ── Rotating outer ring (dashed arc segments) ─────────────────────────────
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.025
      ..strokeCap = StrokeCap.round;

    const segments = 12;
    for (int i = 0; i < segments; i++) {
      final startAngle = (ring * math.pi * 2) + (i / segments) * math.pi * 2;
      final sweepAngle = (math.pi * 2 / segments) * 0.55;
      final opacity = 0.15 + (i / segments) * 0.25;

      ringPaint.color = AppColors.primary.withOpacity(opacity);
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.82),
        startAngle,
        sweepAngle,
        false,
        ringPaint,
      );
    }

    // ── Inner ring — static border ────────────────────────────────────────────
    canvas.drawCircle(
      Offset(cx, cy),
      r * 0.75,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5
        ..color = Colors.white.withOpacity(0.08),
    );

    // ── Audio bars (the core icon) ────────────────────────────────────────────
    const barCount = 5;
    final barHeights = [0.30, 0.55, 0.80, 0.55, 0.30]; // base ratios
    final barW = r * 0.11;
    final maxH = r * 0.58;
    final totalW = barCount * barW + (barCount - 1) * barW * 0.5;
    final startX = cx - totalW / 2;
    final stride = barW * 1.5;

    for (int i = 0; i < barCount; i++) {
      final phase = (i / barCount) * math.pi;
      final animated = barHeights[i] *
          (0.55 + 0.45 * math.sin(bars * math.pi * 2 + phase).abs());
      final h = maxH * animated;
      final x = startX + i * stride;
      final top = cy - h / 2;

      // Bar shadow / glow
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - 1.5, top - 2, barW + 3, h + 4),
          Radius.circular(barW),
        ),
        Paint()
          ..color = AppColors.primary.withOpacity(0.15 * animated)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );

      // Bar body — gradient from bright top to muted bottom
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, top, barW, h),
          Radius.circular(barW),
        ),
        Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.white.withOpacity(0.95),
              AppColors.primary.withOpacity(0.8),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(Rect.fromLTWH(x, top, barW, h)),
      );
    }

    // ── Outer border ──────────────────────────────────────────────────────────
    canvas.drawCircle(
      Offset(cx, cy),
      r * 0.88,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..shader = SweepGradient(
          colors: [
            Colors.white.withOpacity(0.20),
            Colors.white.withOpacity(0.04),
            Colors.white.withOpacity(0.20),
          ],
          transform: GradientRotation(ring * math.pi * 2),
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.88)),
    );
  }

  @override
  bool shouldRepaint(_LogoPainter old) =>
      old.pulse != pulse || old.ring != ring || old.bars != bars;
}

// ─── Wordmark ─────────────────────────────────────────────────────────────────

class _AuraWordmark extends StatelessWidget {
  final double size;
  const _AuraWordmark({required this.size});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [
          Color(0xFFF5F5F7),
          Color(0xFFD4D4D8),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      child: Text(
        'AURASOUND',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: size * 0.26,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: size * 0.06,
        ),
      ),
    );
  }
}

// ─── Compact logo for app bar / nav ──────────────────────────────────────────

class AuraLogoCompact extends StatelessWidget {
  final double size;
  const AuraLogoCompact({super.key, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(painter: _StaticLogoPainter()),
        ),
        SizedBox(width: size * 0.28),
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [Color(0xFFF0F0F2), Color(0xFFB0B0B8)],
          ).createShader(b),
          child: Text(
            'AURASOUND',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: size * 0.42,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: size * 0.07,
            ),
          ),
        ),
      ],
    );
  }
}

class _StaticLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    // Background
    canvas.drawCircle(
      Offset(cx, cy),
      r * 0.9,
      Paint()
        ..shader = RadialGradient(
          colors: [const Color(0xFF1E1E24), const Color(0xFF0E0E12)],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.9)),
    );

    // Bars
    const barCount = 5;
    final barHeights = [0.30, 0.55, 0.80, 0.55, 0.30];
    final barW = r * 0.12;
    final maxH = r * 0.56;
    final totalW = barCount * barW + (barCount - 1) * barW * 0.5;
    final startX = cx - totalW / 2;
    final stride = barW * 1.5;

    for (int i = 0; i < barCount; i++) {
      final h = maxH * barHeights[i];
      final x = startX + i * stride;
      final top = cy - h / 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, top, barW, h),
          Radius.circular(barW),
        ),
        Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.white.withOpacity(0.92),
              AppColors.primary.withOpacity(0.75),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(Rect.fromLTWH(x, top, barW, h)),
      );
    }

    // Border
    canvas.drawCircle(
      Offset(cx, cy),
      r * 0.9,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6
        ..color = Colors.white.withOpacity(0.12),
    );
  }

  @override
  bool shouldRepaint(_) => false;
}
