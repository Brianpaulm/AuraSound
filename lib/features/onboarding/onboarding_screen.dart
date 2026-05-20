import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  final List<_OnboardingPage> _pages = const [
    _OnboardingPage(
      title: 'Premium Sound\nLimitless ',
      titleAccent: 'Immersion',
      subtitle:
          'Experience studio-quality sound with intelligent audio tuning and beautiful design.',
      icon: Icons.spatial_audio_off_rounded,
      gradient: [Color(0xFF7C6FFF), Color(0xFF00D4FF)],
    ),
    _OnboardingPage(
      title: 'Advanced EQ &\n',
      titleAccent: 'DSP Engine',
      subtitle:
          'Fine-tune every frequency with 10-band EQ, sound profiles inspired by JBL, Harman Kardon and more.',
      icon: Icons.equalizer_rounded,
      gradient: [Color(0xFFBB6BFF), Color(0xFF7C6FFF)],
    ),
    _OnboardingPage(
      title: 'Local + Spotify\n',
      titleAccent: 'In One Place',
      subtitle:
          'Seamlessly blend your local music collection with Spotify streaming inside a single unified ecosystem.',
      icon: Icons.queue_music_rounded,
      gradient: [Color(0xFF00D4FF), Color(0xFF1DB954)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim =
        Tween<double>(begin: 0, end: 1).animate(_animController);
    _animController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Gradient background
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.4),
                radius: 0.9,
                colors: [
                  _pages[_currentPage].gradient[0].withOpacity(0.2),
                  AppColors.background,
                ],
              ),
            ),
          ),
          FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              children: [
                // Skip button
                SafeArea(
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: GestureDetector(
                        onTap: () => context.go('/home'),
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Page content
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    itemBuilder: (context, index) {
                      return _buildPage(context, _pages[index], size);
                    },
                  ),
                ),
                // Bottom controls
                Padding(
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    bottom: MediaQuery.of(context).padding.bottom + 32,
                  ),
                  child: Column(
                    children: [
                      // Dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_pages.length, (i) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentPage == i ? 24 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              color: _currentPage == i
                                  ? AppColors.primary
                                  : AppColors.textTertiary,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 32),
                      // Button
                      PrimaryButton(
                        label: _currentPage == _pages.length - 1
                            ? 'Get Started'
                            : 'Continue',
                        width: double.infinity,
                        icon: Icon(
                          _currentPage == _pages.length - 1
                              ? Icons.arrow_forward_rounded
                              : Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        onTap: () {
                          if (_currentPage == _pages.length - 1) {
                            context.go('/home');
                          } else {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(BuildContext context, _OnboardingPage page, Size size) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Illustration
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  page.gradient[0].withOpacity(0.15),
                  page.gradient[1].withOpacity(0.05),
                ],
              ),
              border: Border.all(
                color: page.gradient[0].withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Center(
              child: ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: page.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: Icon(
                  page.icon,
                  size: 80,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          // Title
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: page.title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ),
                TextSpan(
                  text: page.titleAccent,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    foreground: Paint()
                      ..shader = LinearGradient(
                        colors: page.gradient,
                      ).createShader(const Rect.fromLTWH(0, 0, 200, 40)),
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            page.subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage {
  final String title;
  final String titleAccent;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;

  const _OnboardingPage({
    required this.title,
    required this.titleAccent,
    required this.subtitle,
    required this.icon,
    required this.gradient,
  });
}
