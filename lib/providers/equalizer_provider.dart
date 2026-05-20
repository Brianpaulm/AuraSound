import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/eq_preset.dart';
import 'audio_provider.dart';

// ─── Surround Mode ────────────────────────────────────────────────────────────

enum SurroundMode {
  off,
  stereoWide,
  concertHall,
  dolbyAtmos,
  dtsX,
  cinema,
  headphone3d,
}

extension SurroundModeLabel on SurroundMode {
  String get label => switch (this) {
    SurroundMode.off         => 'Off',
    SurroundMode.stereoWide  => 'Stereo Wide',
    SurroundMode.concertHall => 'Concert Hall',
    SurroundMode.dolbyAtmos  => 'Dolby Atmos',
    SurroundMode.dtsX        => 'DTS:X',
    SurroundMode.cinema      => 'Cinema',
    SurroundMode.headphone3d => 'Headphone 3D',
  };

  String get description => switch (this) {
    SurroundMode.off         => 'No spatial processing',
    SurroundMode.stereoWide  => 'Expanded stereo image',
    SurroundMode.concertHall => 'Large hall reverb and depth',
    SurroundMode.dolbyAtmos  => 'Object-based 3D audio simulation',
    SurroundMode.dtsX        => 'Adaptive object audio upmix',
    SurroundMode.cinema      => 'Movie theatre acoustics',
    SurroundMode.headphone3d => 'HRTF binaural 3D for headphones',
  };

  IconData get icon => switch (this) {
    SurroundMode.off         => Icons.surround_sound_outlined,
    SurroundMode.stereoWide  => Icons.spatial_audio_off_rounded,
    SurroundMode.concertHall => Icons.account_balance_rounded,
    SurroundMode.dolbyAtmos  => Icons.surround_sound_rounded,
    SurroundMode.dtsX        => Icons.spatial_audio_rounded,
    SurroundMode.cinema      => Icons.movie_rounded,
    SurroundMode.headphone3d => Icons.headphones_rounded,
  };

  // Simulated effect parameters
  double get virtualizer => switch (this) {
    SurroundMode.off         => 0,
    SurroundMode.stereoWide  => 50,
    SurroundMode.concertHall => 70,
    SurroundMode.dolbyAtmos  => 90,
    SurroundMode.dtsX        => 88,
    SurroundMode.cinema      => 85,
    SurroundMode.headphone3d => 95,
  };

  double get reverb => switch (this) {
    SurroundMode.off         => 0,
    SurroundMode.stereoWide  => 5,
    SurroundMode.concertHall => 65,
    SurroundMode.dolbyAtmos  => 20,
    SurroundMode.dtsX        => 22,
    SurroundMode.cinema      => 40,
    SurroundMode.headphone3d => 15,
  };

  double get stereoWidth => switch (this) {
    SurroundMode.off         => 100,
    SurroundMode.stereoWide  => 185,
    SurroundMode.concertHall => 165,
    SurroundMode.dolbyAtmos  => 180,
    SurroundMode.dtsX        => 175,
    SurroundMode.cinema      => 170,
    SurroundMode.headphone3d => 195,
  };
}

// ─── AI Sound Mode ────────────────────────────────────────────────────────────

enum AIMode {
  off,
  adaptive,    // genre-detects and auto-tunes
  vocal,       // speech enhancement
  nightMode,   // dynamic range compression, quieter late night
  bass,        // bass intelligence — context-aware low end
  clarity,     // detail enhancement for low bitrate files
  live,        // concert feel
}

extension AIModeLabel on AIMode {
  String get label => switch (this) {
    AIMode.off       => 'Off',
    AIMode.adaptive  => 'Adaptive AI',
    AIMode.vocal     => 'Vocal Focus',
    AIMode.nightMode => 'Night Mode',
    AIMode.bass      => 'AI Bass',
    AIMode.clarity   => 'Clarity Boost',
    AIMode.live      => 'Live Feel',
  };

  String get description => switch (this) {
    AIMode.off       => 'No AI processing',
    AIMode.adaptive  => 'Detects genre and tunes EQ automatically',
    AIMode.vocal     => 'Brings vocals to front, reduces muddiness',
    AIMode.nightMode => 'Compresses dynamics, safer for late hours',
    AIMode.bass      => 'Intelligent low-end based on content type',
    AIMode.clarity   => 'Enhances detail in compressed audio',
    AIMode.live      => 'Adds stage presence and air',
  };

  IconData get icon => switch (this) {
    AIMode.off       => Icons.auto_fix_off_rounded,
    AIMode.adaptive  => Icons.auto_awesome_rounded,
    AIMode.vocal     => Icons.mic_rounded,
    AIMode.nightMode => Icons.nights_stay_rounded,
    AIMode.bass      => Icons.graphic_eq_rounded,
    AIMode.clarity   => Icons.hd_rounded,
    AIMode.live      => Icons.festival_rounded,
  };

  /// Returns the 32-band gain array for this AI mode
  List<double> get bands32 => switch (this) {
    AIMode.off => List.filled(32, 0.0),

    AIMode.adaptive => [
      1, 1, 2, 2, 1, 0, 0, -1, 0, 1,
      1, 2, 2, 1, 0, -1, -1, 0, 1, 2,
      2, 1, 0, -1, 0, 1, 2, 3, 3, 2, 1, 0,
    ],

    AIMode.vocal => [
      -2, -2, -1, 0, 0, 1, 2, 3, 3, 4,
      4, 3, 3, 3, 2, 1, 0, 0, 1, 2,
      2, 1, 0, -1, -1, 0, 1, 1, 0, -1, -1, -2,
    ],

    AIMode.nightMode => [
      2, 2, 1, 0, -1, -1, 0, 0, 1, 1,
      0, 0, 0, 0, 0, 0, 0, 0, -1, -1,
      -2, -2, -2, -3, -3, -3, -4, -4, -4, -3, -2, -1,
    ],

    AIMode.bass => [
      6, 5, 5, 4, 3, 3, 2, 1, 1, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    ],

    AIMode.clarity => [
      0, 0, 0, 0, 0, 0, 0, 1, 1, 1,
      2, 2, 2, 3, 3, 3, 3, 3, 3, 3,
      4, 4, 4, 4, 3, 3, 3, 2, 2, 1, 0, 0,
    ],

    AIMode.live => [
      3, 2, 1, 0, 0, 0, 0, 1, 1, 2,
      2, 2, 1, 0, -1, -1, 0, 0, 1, 2,
      3, 3, 3, 2, 2, 2, 3, 3, 4, 4, 3, 2,
    ],
  };

  AudioEffect get audioEffect => switch (this) {
    AIMode.off      => const AudioEffect(),
    AIMode.adaptive => const AudioEffect(bassBoost: 20, loudness: 20, stereoWidth: 115),
    AIMode.vocal    => const AudioEffect(loudness: 30, stereoWidth: 105, virtualizer: 20),
    AIMode.nightMode => const AudioEffect(loudness: 60, bassBoost: 10, stereoWidth: 100),
    AIMode.bass     => const AudioEffect(bassBoost: 70, virtualizer: 30, loudness: 20),
    AIMode.clarity  => const AudioEffect(loudness: 45, stereoWidth: 110),
    AIMode.live     => const AudioEffect(reverb: 30, virtualizer: 55, stereoWidth: 140, bassBoost: 15),
  };
}

// ─── EQ State ─────────────────────────────────────────────────────────────────

class EQState {
  final List<double> bands10;  // 10-band gains
  final List<double> bands32;  // 32-band gains
  final String activePresetId;
  final bool isEnabled;
  final bool isAdvancedMode;   // true = 32-band
  final AudioEffect audioEffect;
  final List<EQPreset> customPresets;
  final SurroundMode surroundMode;
  final AIMode aiMode;

  const EQState({
    required this.bands10,
    required this.bands32,
    this.activePresetId = 'flat',
    this.isEnabled = true,
    this.isAdvancedMode = false,
    this.audioEffect = const AudioEffect(),
    this.customPresets = const [],
    this.surroundMode = SurroundMode.off,
    this.aiMode = AIMode.off,
  });

  EQState copyWith({
    List<double>? bands10,
    List<double>? bands32,
    String? activePresetId,
    bool? isEnabled,
    bool? isAdvancedMode,
    AudioEffect? audioEffect,
    List<EQPreset>? customPresets,
    SurroundMode? surroundMode,
    AIMode? aiMode,
  }) {
    return EQState(
      bands10: bands10 ?? this.bands10,
      bands32: bands32 ?? this.bands32,
      activePresetId: activePresetId ?? this.activePresetId,
      isEnabled: isEnabled ?? this.isEnabled,
      isAdvancedMode: isAdvancedMode ?? this.isAdvancedMode,
      audioEffect: audioEffect ?? this.audioEffect,
      customPresets: customPresets ?? this.customPresets,
      surroundMode: surroundMode ?? this.surroundMode,
      aiMode: aiMode ?? this.aiMode,
    );
  }

  // Active bands depending on mode
  List<double> get activeBands => isAdvancedMode ? bands32 : bands10;

  List<EQPreset> get allPresets => [...EQPreset.builtInPresets, ...customPresets];

  EQPreset? get activePreset {
    try { return allPresets.firstWhere((p) => p.id == activePresetId); } catch (_) { return null; }
  }
}

// ─── EQ Notifier ─────────────────────────────────────────────────────────────

class EQNotifier extends StateNotifier<EQState> {
  final Ref _ref;

  EQNotifier(this._ref)
      : super(EQState(
          bands10: List.filled(10, 0.0),
          bands32: List.filled(32, 0.0),
        ));

  PlayerNotifier get _engine => _ref.read(playerProvider.notifier);

  // Pushes currently active bands + all effects to the audio engine
  Future<void> _push() async {
    if (!state.isEnabled) {
      await _engine.disableAllEffects();
      return;
    }
    await _engine.applyEQBands(state.activeBands, enabled: true);
    await _engine.applyBassBoost(state.audioEffect.bassBoost);
    await _engine.applyLoudnessEnhancer(state.audioEffect.loudness);
  }

  // ── Band editing ──────────────────────────────────────────────────────────

  Future<void> setBand10(int index, double value) async {
    final bands = List<double>.from(state.bands10);
    bands[index] = value.clamp(-12.0, 12.0);
    state = state.copyWith(bands10: bands, activePresetId: 'custom', aiMode: AIMode.off);
    if (!state.isAdvancedMode) await _push();
  }

  Future<void> setBand32(int index, double value) async {
    final bands = List<double>.from(state.bands32);
    bands[index] = value.clamp(-12.0, 12.0);
    state = state.copyWith(bands32: bands, activePresetId: 'custom', aiMode: AIMode.off);
    if (state.isAdvancedMode) await _push();
  }

  Future<void> setBand(int index, double value) async =>
      state.isAdvancedMode ? setBand32(index, value) : setBand10(index, value);

  // ── Presets ───────────────────────────────────────────────────────────────

  Future<void> applyPreset(EQPreset preset) async {
    final b10 = List<double>.from(preset.bands.length == 10
        ? preset.bands
        : _downsample32to10(preset.bands));
    final b32 = List<double>.from(preset.bands.length == 32
        ? preset.bands
        : _upsample10to32(b10));
    state = state.copyWith(
      bands10: b10,
      bands32: b32,
      activePresetId: preset.id,
      aiMode: AIMode.off,
    );
    await _push();
  }

  Future<void> resetBands() async {
    state = state.copyWith(
      bands10: List.filled(10, 0.0),
      bands32: List.filled(32, 0.0),
      activePresetId: 'flat',
      aiMode: AIMode.off,
    );
    await _push();
  }

  // ── Toggle enable ─────────────────────────────────────────────────────────

  Future<void> toggleEnabled() async {
    state = state.copyWith(isEnabled: !state.isEnabled);
    await _push();
  }

  void toggleAdvancedMode() =>
      state = state.copyWith(isAdvancedMode: !state.isAdvancedMode);

  // ── Effect sliders ────────────────────────────────────────────────────────

  Future<void> updateBassBoost(double v) async {
    state = state.copyWith(audioEffect: state.audioEffect.copyWith(bassBoost: v));
    await _engine.applyBassBoost(v);
  }

  Future<void> updateVirtualizer(double v) async {
    state = state.copyWith(audioEffect: state.audioEffect.copyWith(virtualizer: v));
    await _push();
  }

  Future<void> updateLoudness(double v) async {
    state = state.copyWith(audioEffect: state.audioEffect.copyWith(loudness: v));
    await _engine.applyLoudnessEnhancer(v);
  }

  Future<void> updateReverb(double v) async {
    state = state.copyWith(audioEffect: state.audioEffect.copyWith(reverb: v));
    await _push();
  }

  Future<void> updateStereoWidth(double v) async {
    state = state.copyWith(audioEffect: state.audioEffect.copyWith(stereoWidth: v));
  }

  Future<void> toggleSpatialAudio() async {
    state = state.copyWith(
      audioEffect: state.audioEffect.copyWith(spatialAudio: !state.audioEffect.spatialAudio),
    );
    await _push();
  }

  // ── AI Sound Mode ─────────────────────────────────────────────────────────

  Future<void> setAIMode(AIMode mode) async {
    if (mode == AIMode.off) {
      state = state.copyWith(aiMode: AIMode.off);
      // Don't reset bands — user might have set a preset
      return;
    }

    final bands32 = List<double>.from(mode.bands32);
    final bands10 = _downsample32to10(bands32);
    final effect = mode.audioEffect;

    state = state.copyWith(
      aiMode: mode,
      bands32: bands32,
      bands10: bands10,
      activePresetId: 'ai_${mode.name}',
      audioEffect: effect,
    );
    await _push();
  }

  // ── Surround Mode ─────────────────────────────────────────────────────────

  Future<void> setSurroundMode(SurroundMode mode) async {
    state = state.copyWith(
      surroundMode: mode,
      audioEffect: state.audioEffect.copyWith(
        virtualizer: mode.virtualizer,
        reverb: mode.reverb,
        stereoWidth: mode.stereoWidth,
        spatialAudio: mode != SurroundMode.off,
      ),
    );
    await _push();
  }

  // ── Sound Profile ─────────────────────────────────────────────────────────

  Future<void> applySoundProfile(SoundProfile profile) async {
    final b10 = List<double>.from(profile.eqPreset.bands);
    final b32 = _upsample10to32(b10);
    state = state.copyWith(
      bands10: b10,
      bands32: b32,
      activePresetId: profile.eqPreset.id,
      audioEffect: profile.audioEffect,
      aiMode: AIMode.off,
    );
    await _push();
  }

  // ── Band conversion helpers ───────────────────────────────────────────────

  /// Linearly interpolate 10 points to 32 points
  List<double> _upsample10to32(List<double> b10) {
    final result = List<double>.filled(32, 0.0);
    for (int i = 0; i < 32; i++) {
      final pos = i / 31 * 9;
      final lo = pos.floor().clamp(0, 9);
      final hi = pos.ceil().clamp(0, 9);
      final frac = pos - lo;
      result[i] = b10[lo] * (1 - frac) + b10[hi] * frac;
    }
    return result;
  }

  /// Average 32 points down to 10 points
  List<double> _downsample32to10(List<double> b32) {
    final result = List<double>.filled(10, 0.0);
    final ratio = 32 / 10;
    for (int i = 0; i < 10; i++) {
      final start = (i * ratio).floor();
      final end = ((i + 1) * ratio).floor().clamp(0, 32);
      double sum = 0;
      for (int j = start; j < end; j++) sum += b32[j];
      result[i] = sum / (end - start).clamp(1, 32);
    }
    return result;
  }
}

final eqProvider =
    StateNotifierProvider<EQNotifier, EQState>((ref) => EQNotifier(ref));

// ─── Sound Profile State ──────────────────────────────────────────────────────

class SoundProfileState {
  final List<SoundProfile> profiles;
  final String? activeProfileId;
  const SoundProfileState({this.profiles = const [], this.activeProfileId});

  SoundProfile? get activeProfile {
    if (activeProfileId == null) return null;
    try { return profiles.firstWhere((p) => p.id == activeProfileId); } catch (_) { return null; }
  }

  SoundProfileState copyWith({List<SoundProfile>? profiles, String? activeProfileId}) =>
      SoundProfileState(
        profiles: profiles ?? this.profiles,
        activeProfileId: activeProfileId ?? this.activeProfileId,
      );
}

class SoundProfileNotifier extends StateNotifier<SoundProfileState> {
  final Ref _ref;
  SoundProfileNotifier(this._ref)
      : super(SoundProfileState(profiles: SoundProfile.builtInProfiles));

  Future<void> activateProfile(String id) async {
    state = state.copyWith(activeProfileId: id);
    final profile = state.activeProfile;
    if (profile != null) {
      await _ref.read(eqProvider.notifier).applySoundProfile(profile);
    }
  }

  void deactivate() => state = state.copyWith(activeProfileId: null);
}

final soundProfileProvider =
    StateNotifierProvider<SoundProfileNotifier, SoundProfileState>(
        (ref) => SoundProfileNotifier(ref));
