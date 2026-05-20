import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '/providers/audio_provider.dart';
import '/providers/library_provider.dart';
import '/core/theme/app_colors.dart';
import 'mini_player.dart';

class MainScaffold extends ConsumerWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(currentTabProvider);
    final playerState = ref.watch(playerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          child,
          if (playerState.currentSong != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 64,
              child: const MiniPlayer(),
            ),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: currentTab,
        onTap: (index) {
          ref.read(currentTabProvider.notifier).state = index;
          switch (index) {
            case 0: context.go('/home'); break;
            case 1: context.go('/library'); break;
            case 2: context.go('/equalizer'); break;
            case 3: context.go('/sound-profiles'); break;
            case 4: context.go('/visualizer'); break;
            case 5: context.go('/video'); break;
          }
        },
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const items = [
      _NavItem(Icons.home_rounded, 'Home'),
      _NavItem(Icons.library_music_rounded, 'Library'),
      _NavItem(Icons.equalizer_rounded, 'EQ'),
      _NavItem(Icons.spatial_audio_off_rounded, 'Profiles'),
      _NavItem(Icons.bar_chart_rounded, 'Visual'),
      _NavItem(Icons.video_library_rounded, 'Video'),
    ];

    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: AppColors.backgroundSecondary,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final item = items[i];
          final selected = currentIndex == i;
          return GestureDetector(
            onTap: () => onTap(i),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.all(selected ? 6 : 0),
                    decoration: selected
                        ? BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          )
                        : null,
                    child: Icon(item.icon,
                        color: selected ? AppColors.primary : AppColors.textTertiary,
                        size: 20),
                  ),
                  const SizedBox(height: 2),
                  Text(item.label,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                        color: selected ? AppColors.primary : AppColors.textTertiary,
                      )),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}
