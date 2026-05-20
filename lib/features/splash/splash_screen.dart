import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/aura_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Logo entrance
  late AnimationController _logoCtrl;
  // Wordmark stagger
  late AnimationController _wordCtrl;
  // Tagline + bar entrance
  late AnimationController _tagCtrl;
  // Background radial glow breathe
  late AnimationController _glowCtrl;
  // Particle float
  late AnimationController _particleCtrl;
  // Fade to app
  late AnimationController _exitCtrl;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _wordSlide;
  late Animation<double> _wordOpacity;
  late Animation<double> _tagOpacity;
  late Animation<double> _glowRadius;
  late Animation<double> _exitFade;
  late Animation<double> _barProgress;

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _wordCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _tagCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200));
    _particleCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 4));
    _exitCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));

    _logoScale = CurvedAnimation(
      parent: _logoCtrl,
      curve: const _SpringCurve(),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _logoCtrl, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
    );

    _wordSlide = Tween<double>(begin: 22.0, end: 0.0).animate(
      CurvedAnimation(parent: _wordCtrl, curve: Curves.easeOutCubic),
    );
    _wordOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _wordCtrl, curve: const Interval(0.0, 0.7)),
    );

    _tagOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _tagCtrl, curve: Curves.easeOut),
    );

    _glowRadius = Tween<double>(begin: 0.5, end: 0.85).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    _barProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _tagCtrl, curve: const Interval(0.3, 1.0)),
    );

    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn),
    );

    _runSequence();
  }

  Future<void> _runSequence() async {
    _glowCtrl.repeat(reverse: true);
    _particleCtrl.repeat();

    // Logo pops in
    await _logoCtrl.forward();
    // Wordmark slides up
    await Future.delayed(const Duration(milliseconds: 80));
    await _wordCtrl.forward();
    // Tagline + loading bar fade in
    await Future.delayed(const Duration(milliseconds: 100));
    _tagCtrl.forward();

    // Hold on screen
    await Future.delayed(const Duration(milliseconds: 1800));

    // Fade out to app
    if (mounted) {
      await _exitCtrl.forward();
      if (mounted) context.go('/onboarding');
    }
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _wordCtrl.dispose();
    _tagCtrl.dispose();
    _glowCtrl.dispose();
    _particleCtrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _exitFade,
      builder: (_, child) => Opacity(opacity: _exitFade.value, child: child),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            // ── Radial glow bg ─────────────────────────────────────────────
            AnimatedBuilder(
              animation: _glowRadius,
              builder: (_, __) => Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.15),
                    radius: _glowRadius.value,
                    colors: [
                      const Color(0xFF1A1A24).withOpacity(0.9),
                      AppColors.background,
                    ],
                  ),
                ),
              ),
            ),

            // ── Floating particles ─────────────────────────────────────────
            AnimatedBuilder(
              animation: _particleCtrl,
              builder: (_, __) => CustomPaint(
                painter: _ParticlePainter(t: _particleCtrl.value),
                child: const SizedBox.expand(),
              ),
            ),

            // ── Centre content ─────────────────────────────────────────────
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  AnimatedBuilder(
                    animation: _logoCtrl,
                    builder: (_, child) => Opacity(
                      opacity: _logoOpacity.value,
                      child: Transform.scale(
                        scale: 0.65 + 0.35 * _logoScale.value,
                        child: child,
                      ),
                    ),
                    child: const AuraLogo(size: 110, animate: true),
                  ),
                  const SizedBox(height: 28),

                  // Wordmark slides up
                  AnimatedBuilder(
                    animation: _wordCtrl,
                    builder: (_, __) => Opacity(
                      opacity: _wordOpacity.value,
                      child: Transform.translate(
                        offset: Offset(0, _wordSlide.value),
                        child: ShaderMask(
                          shaderCallback: (b) => const LinearGradient(
                            colors: [
                              Color(0xFFF5F5F7),
                              Color(0xFFC8C8D0),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(b),
                          child: const Text(
                            'AURASOUND',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 7,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Tagline
                  AnimatedBuilder(
                    animation: _tagCtrl,
                    builder: (_, __) => Opacity(
                      opacity: _tagOpacity.value,
                      child: const Text(
                        'Feel every beat',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textTertiary,
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Bottom loading bar ─────────────────────────────────────────
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _tagCtrl,
                builder: (_, __) => Opacity(
                  opacity: _tagOpacity.value,
                  child: Column(
                    children: [
                      // Progress bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 80),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: _barProgress.value,
                            backgroundColor:
                                AppColors.surfaceVariant.withOpacity(0.5),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.primary),
                            minHeight: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _barProgress.value < 0.4
                            ? 'Initialising audio engine…'
                            : _barProgress.value < 0.8
                                ? 'Loading DSP pipeline…'
                                : 'Ready',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: AppColors.textTertiary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Spring curve for logo pop ────────────────────────────────────────────────

class _SpringCurve extends Curve {
  const _SpringCurve();

  @override
  double transformInternal(double t) {
    // Overshoot spring: goes past 1.0 then settles
    return 1.0 -
        math.pow(math.e, -8 * t) *
            math.cos(12 * t * math.pi / 2).toDouble();
  }
}

// ─── Particle painter ─────────────────────────────────────────────────────────

class _ParticlePainter extends CustomPainter {
  final double t;
  _ParticlePainter({required this.t});

  static final _rand = math.Random(42);
  static final _particles = List.generate(
    22,
    (i) => _Particle(
      x: _rand.nextDouble(),
      y: _rand.nextDouble(),
      r: 1.0 + _rand.nextDouble() * 2.5,
      speed: 0.06 + _rand.nextDouble() * 0.12,
      phase: _rand.nextDouble() * math.pi * 2,
    ),
  );

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final px = p.x * size.width;
      final py = ((p.y + p.speed * t) % 1.0) * size.height;
      final opacity = 0.06 +
          0.12 * math.sin(t * math.pi * 2 * p.speed * 4 + p.phase).abs();
      canvas.drawCircle(
        Offset(px, py),
        p.r,
        Paint()..color = AppColors.primary.withOpacity(opacity),
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.t != t;
}

class _Particle {
  final double x, y, r, speed, phase;
  const _Particle(
      {required this.x,
      required this.y,
      required this.r,
      required this.speed,
      required this.phase});
}
