import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/equalizer_provider.dart';
import '../../models/eq_preset.dart';

class SoundProfilesScreen extends ConsumerWidget {
  const SoundProfilesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(soundProfileProvider);
    final profileNotifier = ref.read(soundProfileProvider.notifier);
    final eqNotifier = ref.read(eqProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            leading: null,
            automaticallyImplyLeading: false,
            title: null,
            flexibleSpace: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Tuned for your gear',
                        style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.textTertiary, letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text('Sound Profiles',
                            style: AppTextStyles.headlineMedium),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => _showCreateProfile(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(color: AppColors.border, width: 0.5),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_rounded,
                                    color: AppColors.textSecondary, size: 16),
                                SizedBox(width: 5),
                                Text('Custom',
                                    style: TextStyle(
                                      fontFamily: 'Inter', fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSecondary,
                                    )),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            expandedHeight: 90,
            pinned: true,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          // Profile sections
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Active profile banner
                  if (profileState.activeProfile != null)
                    _ActiveProfileBanner(profile: profileState.activeProfile!),
                  const SizedBox(height: 28),
                  const Text('Headphones & Speakers', style: AppTextStyles.sectionHeader),
                  const SizedBox(height: 4),
                  Text('Tuned by audio experts for premium devices',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary)),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          // Headphone/speaker profiles (first 9)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.1,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final profile = profileState.profiles[i];
                  final isActive = profile.id == profileState.activeProfileId;
                  return _ProfileCard(
                    profile: profile,
                    isActive: isActive,
                    onTap: () {
                      profileNotifier.activateProfile(profile.id);
                      eqNotifier.applySoundProfile(profile);
                    },
                  );
                },
                childCount: 9, // B&O → Audeze → Studio
              ),
            ),
          ),
          // Surround / Spatial section header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Surround & Spatial Audio', style: AppTextStyles.sectionHeader),
                  const SizedBox(height: 4),
                  Text('Immersive 3D and object-based audio modes',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary)),
                ],
              ),
            ),
          ),
          // Surround profiles (Dolby Atmos, Dolby 7.1, DTS:X, Concert Hall, Car)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.1,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final profile = profileState.profiles[9 + i];
                  final isActive = profile.id == profileState.activeProfileId;
                  return _ProfileCard(
                    profile: profile,
                    isActive: isActive,
                    onTap: () {
                      profileNotifier.activateProfile(profile.id);
                      eqNotifier.applySoundProfile(profile);
                    },
                  );
                },
                childCount: profileState.profiles.length - 9,
              ),
            ),
          ),
          // Custom profile section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const Text('Custom Profiles', style: AppTextStyles.sectionHeader),
                  const SizedBox(height: 16),
                  // Add custom
                  GestureDetector(
                    onTap: () => _showCreateProfile(context),
                    child: Container(
                      height: 72,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.border,
                          width: 1.5,
                          style: BorderStyle.solid,
                        ),
                        color: AppColors.surface,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_rounded, color: AppColors.primary, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Create Custom Profile',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
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

  void _showCreateProfile(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _CreateProfileSheet(),
    );
  }
}

class _ActiveProfileBanner extends StatelessWidget {
  final SoundProfile profile;

  const _ActiveProfileBanner({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [profile.color.withOpacity(0.2), profile.color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: profile.color.withOpacity(0.3), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: profile.color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.spatial_audio_off_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Active Profile', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.textSecondary, letterSpacing: 0.5)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('ACTIVE', style: TextStyle(fontFamily: 'Inter', fontSize: 8, fontWeight: FontWeight.w700, color: AppColors.success, letterSpacing: 1)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(profile.name, style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                Text(profile.description, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final SoundProfile profile;
  final bool isActive;
  final VoidCallback onTap;

  const _ProfileCard({required this.profile, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isActive ? AppColors.surfaceVariant : AppColors.surface,
          border: Border.all(
            color: isActive ? AppColors.primary.withOpacity(0.5) : AppColors.border,
            width: isActive ? 1.5 : 0.5,
          ),
          boxShadow: isActive
              ? [BoxShadow(color: AppColors.primary.withOpacity(0.08), blurRadius: 16, spreadRadius: -4)]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Initial avatar
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.primary.withOpacity(0.2)
                          : AppColors.surfaceVariant,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        profile.name[0],
                        style: TextStyle(
                          fontFamily: 'Inter', fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isActive ? AppColors.primary : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (isActive)
                    Container(
                      width: 20, height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded, size: 12, color: AppColors.background),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // Name + description
              Text(profile.name,
                  style: TextStyle(
                    fontFamily: 'Inter', fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isActive ? AppColors.textPrimary : AppColors.textPrimary,
                  ),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(profile.description,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 9,
                      color: AppColors.textTertiary),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 10),
              // Bass / Width / Loud bars — matching web app
              _StatBar(label: 'Bass',
                  value: profile.audioEffect.bassBoost / 100),
              const SizedBox(height: 5),
              _StatBar(label: 'Width',
                  value: (profile.audioEffect.stereoWidth / 200).clamp(0, 1)),
              const SizedBox(height: 5),
              _StatBar(label: 'Loud',
                  value: profile.audioEffect.loudness / 100),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBar extends StatelessWidget {
  final String label;
  final double value; // 0-1

  const _StatBar({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 28,
          child: Text(label,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 8,
                  color: AppColors.textTertiary, fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              backgroundColor: AppColors.surfaceHigh,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 3,
            ),
          ),
        ),
        const SizedBox(width: 5),
        SizedBox(
          width: 24,
          child: Text('${(value * 100).toInt()}%',
              style: const TextStyle(fontFamily: 'Inter', fontSize: 8,
                  color: AppColors.textTertiary),
              textAlign: TextAlign.right),
        ),
      ],
    );
  }
}

  IconData _getProfileIcon(String id) {
    switch (id) {
      case 'bno':         return Icons.radio_rounded;
      case 'bose':        return Icons.headset_rounded;
      case 'jbl':         return Icons.speaker_rounded;
      case 'harman':      return Icons.speaker_group_rounded;
      case 'sennheiser':  return Icons.headphones_rounded;
      case 'sony':        return Icons.noise_control_off_rounded;
      case 'beats':       return Icons.headset_mic_rounded;
      case 'airpods':     return Icons.earbuds_rounded;
      case 'audeze':      return Icons.graphic_eq_rounded;
      case 'studio':      return Icons.equalizer_rounded;
      case 'dolby_atmos': return Icons.surround_sound_rounded;
      case 'dolby_surround': return Icons.spatial_audio_rounded;
      case 'dts_x':       return Icons.spatial_audio_off_rounded;
      case 'concert_hall':return Icons.account_balance_rounded;
      case 'car':         return Icons.directions_car_rounded;
      default:            return Icons.spatial_audio_off_rounded;
    }
  }


class _CreateProfileSheet extends StatelessWidget {
  const _CreateProfileSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 20), decoration: BoxDecoration(color: AppColors.textTertiary, borderRadius: BorderRadius.circular(2))),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(alignment: Alignment.centerLeft, child: Text('Create Profile', style: AppTextStyles.titleLarge)),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const TextField(
                style: TextStyle(fontFamily: 'Inter', color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Profile name',
                  hintStyle: TextStyle(fontFamily: 'Inter', color: AppColors.textTertiary),
                  contentPadding: EdgeInsets.all(14),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Center(child: Text('Cancel', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(child: Text('Create', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white))),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
