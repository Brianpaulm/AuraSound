import 'package:flutter/material.dart';

class EQPreset {
  final String id;
  final String name;
  final List<double> bands; // gain values in dB
  final bool isBuiltIn;
  final bool isCustom;

  const EQPreset({
    required this.id,
    required this.name,
    required this.bands,
    this.isBuiltIn = false,
    this.isCustom = false,
  });

  EQPreset copyWith({
    String? id,
    String? name,
    List<double>? bands,
    bool? isBuiltIn,
    bool? isCustom,
  }) {
    return EQPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      bands: bands ?? this.bands,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  static final List<EQPreset> builtInPresets = [
    EQPreset(
      id: 'flat',
      name: 'Flat',
      bands: List.filled(10, 0.0),
      isBuiltIn: true,
    ),
    EQPreset(
      id: 'bass_boost',
      name: 'Bass Boost',
      bands: [6, 5, 4, 2, 0, 0, 0, 0, 0, 0],
      isBuiltIn: true,
    ),
    EQPreset(
      id: 'treble_boost',
      name: 'Treble Boost',
      bands: [0, 0, 0, 0, 0, 0, 2, 4, 5, 6],
      isBuiltIn: true,
    ),
    EQPreset(
      id: 'vocal',
      name: 'Vocal Clarity',
      bands: [-2, -1, 0, 1, 3, 4, 3, 1, 0, -1],
      isBuiltIn: true,
    ),
    EQPreset(
      id: 'rock',
      name: 'Rock',
      bands: [4, 3, 2, 0, -1, 0, 2, 3, 3, 2],
      isBuiltIn: true,
    ),
    EQPreset(
      id: 'pop',
      name: 'Pop',
      bands: [-1, 0, 2, 3, 2, 0, -1, 0, 1, 2],
      isBuiltIn: true,
    ),
    EQPreset(
      id: 'jazz',
      name: 'Jazz',
      bands: [2, 1, 0, 2, 0, -2, 0, 1, 2, 3],
      isBuiltIn: true,
    ),
    EQPreset(
      id: 'classical',
      name: 'Classical',
      bands: [4, 3, 2, 0, -2, -2, 0, 2, 3, 4],
      isBuiltIn: true,
    ),
    EQPreset(
      id: 'electronic',
      name: 'Electronic',
      bands: [4, 3, 1, 0, -2, 1, 0, 1, 3, 4],
      isBuiltIn: true,
    ),
    EQPreset(
      id: 'hip_hop',
      name: 'Hip Hop',
      bands: [5, 4, 2, 3, -1, -1, 1, 2, 2, 3],
      isBuiltIn: true,
    ),
  ];
}

class AudioEffect {
  final double bassBoost; // 0-100
  final double virtualizer; // 0-100
  final double loudness; // 0-100
  final double reverb; // 0-100
  final double stereoWidth; // 0-200 (100=normal)
  final bool spatialAudio;
  final bool harmonic;

  const AudioEffect({
    this.bassBoost = 0,
    this.virtualizer = 0,
    this.loudness = 0,
    this.reverb = 0,
    this.stereoWidth = 100,
    this.spatialAudio = false,
    this.harmonic = false,
  });

  AudioEffect copyWith({
    double? bassBoost,
    double? virtualizer,
    double? loudness,
    double? reverb,
    double? stereoWidth,
    bool? spatialAudio,
    bool? harmonic,
  }) {
    return AudioEffect(
      bassBoost: bassBoost ?? this.bassBoost,
      virtualizer: virtualizer ?? this.virtualizer,
      loudness: loudness ?? this.loudness,
      reverb: reverb ?? this.reverb,
      stereoWidth: stereoWidth ?? this.stereoWidth,
      spatialAudio: spatialAudio ?? this.spatialAudio,
      harmonic: harmonic ?? this.harmonic,
    );
  }
}

class SoundProfile {
  final String id;
  final String name;
  final String description;
  final String? icon;
  final EQPreset eqPreset;
  final AudioEffect audioEffect;
  final bool isBuiltIn;
  final bool isActive;
  final Color color;

  const SoundProfile({
    required this.id,
    required this.name,
    required this.description,
    this.icon,
    required this.eqPreset,
    required this.audioEffect,
    this.isBuiltIn = false,
    this.isActive = false,
    required this.color,
  });

  SoundProfile copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    EQPreset? eqPreset,
    AudioEffect? audioEffect,
    bool? isBuiltIn,
    bool? isActive,
    Color? color,
  }) {
    return SoundProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      eqPreset: eqPreset ?? this.eqPreset,
      audioEffect: audioEffect ?? this.audioEffect,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      isActive: isActive ?? this.isActive,
      color: color ?? this.color,
    );
  }

  static final List<SoundProfile> builtInProfiles = [
    // ── Headphone / Speaker Brands ─────────────────────────────────────────

    SoundProfile(
      id: 'bno',
      name: 'Bang & Olufsen',
      description: 'Scandinavian neutrality — breathtaking detail and silk-smooth highs',
      eqPreset: EQPreset(
        id: 'bno_eq',
        name: 'Bang & Olufsen',
        bands: [1, 1, 0, 0, 1, 2, 3, 4, 4, 3],
        isBuiltIn: true,
      ),
      audioEffect: const AudioEffect(bassBoost: 15, virtualizer: 25, loudness: 20, stereoWidth: 140),
      isBuiltIn: true,
      color: const Color(0xFFF0F0F2),
    ),
    SoundProfile(
      id: 'bose',
      name: 'Bose',
      description: 'TriPort bass technology — warm, rich lows with clear vocals',
      eqPreset: EQPreset(
        id: 'bose_eq',
        name: 'Bose',
        bands: [4, 4, 3, 2, 1, 0, 1, 2, 2, 1],
        isBuiltIn: true,
      ),
      audioEffect: const AudioEffect(bassBoost: 55, virtualizer: 35, loudness: 35, stereoWidth: 115),
      isBuiltIn: true,
      color: const Color(0xFFD8D8DC),
    ),
    SoundProfile(
      id: 'jbl',
      name: 'JBL Signature',
      description: 'Deep bass, crisp highs, powerful live dynamics',
      eqPreset: EQPreset(
        id: 'jbl_eq',
        name: 'JBL Signature',
        bands: [5, 4, 3, 1, 0, 0, 2, 3, 4, 3],
        isBuiltIn: true,
      ),
      audioEffect: const AudioEffect(bassBoost: 60, virtualizer: 40, loudness: 30),
      isBuiltIn: true,
      color: const Color(0xFFD4D4D8),
    ),
    SoundProfile(
      id: 'harman',
      name: 'Harman Kardon',
      description: 'Reference balance — natural, open, studio-grade accuracy',
      eqPreset: EQPreset(
        id: 'harman_eq',
        name: 'Harman Kardon',
        bands: [2, 1, 1, 0, -1, 0, 1, 2, 2, 1],
        isBuiltIn: true,
      ),
      audioEffect: const AudioEffect(bassBoost: 20, virtualizer: 20, loudness: 40, stereoWidth: 120),
      isBuiltIn: true,
      color: const Color(0xFFC8C8CC),
    ),
    SoundProfile(
      id: 'sennheiser',
      name: 'Sennheiser',
      description: 'German precision — expansive stage, neutral mids, audiophile reference',
      eqPreset: EQPreset(
        id: 'sennheiser_eq',
        name: 'Sennheiser',
        bands: [2, 1, 0, 0, 0, 1, 1, 2, 3, 2],
        isBuiltIn: true,
      ),
      audioEffect: const AudioEffect(bassBoost: 10, virtualizer: 15, loudness: 15, stereoWidth: 160),
      isBuiltIn: true,
      color: const Color(0xFFBCBCC4),
    ),
    SoundProfile(
      id: 'sony',
      name: 'Sony Signature',
      description: 'LDAC hi-res tuning — balanced mids, detailed soundstage',
      eqPreset: EQPreset(
        id: 'sony_eq',
        name: 'Sony Signature',
        bands: [3, 2, 1, 0, 0, 1, 2, 2, 1, 0],
        isBuiltIn: true,
      ),
      audioEffect: const AudioEffect(bassBoost: 35, virtualizer: 30, spatialAudio: true),
      isBuiltIn: true,
      color: const Color(0xFFB0B0B8),
    ),
    SoundProfile(
      id: 'beats',
      name: 'Beats',
      description: 'Punchy bass, bright attack, street-ready energy',
      eqPreset: EQPreset(
        id: 'beats_eq',
        name: 'Beats',
        bands: [7, 6, 4, 2, -1, -1, 1, 3, 4, 3],
        isBuiltIn: true,
      ),
      audioEffect: const AudioEffect(bassBoost: 80, virtualizer: 50, loudness: 60),
      isBuiltIn: true,
      color: const Color(0xFF909098),
    ),
    SoundProfile(
      id: 'airpods',
      name: 'AirPods Pro',
      description: 'Apple spatial audio — adaptive transparency, binaural stage',
      eqPreset: EQPreset(
        id: 'airpods_eq',
        name: 'AirPods Pro',
        bands: [1, 1, 2, 3, 2, 1, 2, 3, 2, 1],
        isBuiltIn: true,
      ),
      audioEffect: const AudioEffect(spatialAudio: true, stereoWidth: 150, virtualizer: 45),
      isBuiltIn: true,
      color: const Color(0xFFE8E8EC),
    ),
    SoundProfile(
      id: 'audeze',
      name: 'Audeze Planar',
      description: 'Planar magnetic accuracy — ultra-low distortion, true flat response',
      eqPreset: EQPreset(
        id: 'audeze_eq',
        name: 'Audeze Planar',
        bands: [1, 0, 0, 0, 0, 0, 0, 1, 1, 0],
        isBuiltIn: true,
      ),
      audioEffect: const AudioEffect(bassBoost: 5, virtualizer: 10, stereoWidth: 110, loudness: 10),
      isBuiltIn: true,
      color: const Color(0xFF808088),
    ),

    // ── Studio / Monitor ───────────────────────────────────────────────────

    SoundProfile(
      id: 'studio',
      name: 'Studio Monitor',
      description: 'Flat response — professional mixing, zero coloration',
      eqPreset: EQPreset(
        id: 'studio_eq',
        name: 'Studio Monitor',
        bands: List.filled(10, 0.0),
        isBuiltIn: true,
      ),
      audioEffect: const AudioEffect(stereoWidth: 100),
      isBuiltIn: true,
      color: const Color(0xFF606068),
    ),

    // ── Surround / Spatial ─────────────────────────────────────────────────

    SoundProfile(
      id: 'dolby_atmos',
      name: 'Dolby Atmos',
      description: 'Object-based 3D audio — sound moves all around and above you',
      eqPreset: EQPreset(
        id: 'dolby_atmos_eq',
        name: 'Dolby Atmos',
        bands: [3, 2, 1, 1, 0, 1, 2, 3, 3, 2],
        isBuiltIn: true,
      ),
      audioEffect: const AudioEffect(
        bassBoost: 30,
        virtualizer: 90,
        loudness: 25,
        reverb: 20,
        stereoWidth: 180,
        spatialAudio: true,
      ),
      isBuiltIn: true,
      color: const Color(0xFFF0F0F2),
    ),
    SoundProfile(
      id: 'dolby_surround',
      name: 'Dolby Surround 7.1',
      description: 'Simulated 7.1 surround — front, side, rear and height channels',
      eqPreset: EQPreset(
        id: 'dolby_surround_eq',
        name: 'Dolby Surround 7.1',
        bands: [4, 3, 2, 1, 0, 1, 2, 3, 2, 1],
        isBuiltIn: true,
      ),
      audioEffect: const AudioEffect(
        bassBoost: 25,
        virtualizer: 85,
        loudness: 30,
        reverb: 35,
        stereoWidth: 190,
        spatialAudio: true,
      ),
      isBuiltIn: true,
      color: const Color(0xFFDCDCE0),
    ),
    SoundProfile(
      id: 'dts_x',
      name: 'DTS:X',
      description: 'DTS object audio — adaptive immersive upmix for any headphone',
      eqPreset: EQPreset(
        id: 'dts_x_eq',
        name: 'DTS:X',
        bands: [3, 2, 1, 1, 0, 1, 2, 3, 3, 2],
        isBuiltIn: true,
      ),
      audioEffect: const AudioEffect(
        bassBoost: 28,
        virtualizer: 88,
        loudness: 22,
        reverb: 25,
        stereoWidth: 175,
        spatialAudio: true,
      ),
      isBuiltIn: true,
      color: const Color(0xFFC4C4CC),
    ),
    SoundProfile(
      id: 'concert_hall',
      name: 'Concert Hall',
      description: 'Large orchestral hall acoustics — natural reverb and depth',
      eqPreset: EQPreset(
        id: 'concert_hall_eq',
        name: 'Concert Hall',
        bands: [2, 1, 0, 0, -1, 0, 1, 3, 4, 4],
        isBuiltIn: true,
      ),
      audioEffect: const AudioEffect(
        bassBoost: 10,
        virtualizer: 70,
        loudness: 15,
        reverb: 65,
        stereoWidth: 170,
        spatialAudio: true,
      ),
      isBuiltIn: true,
      color: const Color(0xFFB8B8C0),
    ),

    // ── Environments ───────────────────────────────────────────────────────

    SoundProfile(
      id: 'car',
      name: 'Car Audio',
      description: 'Tuned for vehicle acoustics — boosted bass, compensated reflections',
      eqPreset: EQPreset(
        id: 'car_eq',
        name: 'Car Audio',
        bands: [4, 3, 2, 3, 2, 1, 2, 3, 2, 1],
        isBuiltIn: true,
      ),
      audioEffect: const AudioEffect(bassBoost: 50, loudness: 40, reverb: 10),
      isBuiltIn: true,
      color: const Color(0xFFA0A0A8),
    ),
  ];
}
