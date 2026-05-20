import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Brand — cool light grey/white
  static const Color primary = Color(0xFFD4D4D8);
  static const Color primaryLight = Color(0xFFF4F4F5);
  static const Color primaryDark = Color(0xFFA1A1AA);

  // Accent — subtle silver/white tones
  static const Color accent = Color(0xFFE4E4E7);
  static const Color accentPurple = Color(0xFFB4B4C0);
  static const Color accentPink = Color(0xFFC8C8D0);

  // Backgrounds — deep dark matte
  static const Color background = Color(0xFF0C0C0E);
  static const Color backgroundSecondary = Color(0xFF111113);
  static const Color backgroundCard = Color(0xFF161618);
  static const Color backgroundElevated = Color(0xFF1C1C1F);

  // Surface — dark neutral
  static const Color surface = Color(0xFF1A1A1D);
  static const Color surfaceVariant = Color(0xFF222226);
  static const Color surfaceHigh = Color(0xFF2A2A2E);

  // Glass — white-tinted frost
  static const Color glassWhite = Color(0x10FFFFFF);
  static const Color glassBorder = Color(0x18FFFFFF);
  static const Color glassHighlight = Color(0x28FFFFFF);

  // Text
  static const Color textPrimary = Color(0xFFF2F2F4);
  static const Color textSecondary = Color(0xFF8C8C96);
  static const Color textTertiary = Color(0xFF48484F);
  static const Color textAccent = Color(0xFFD4D4D8);

  // EQ Colors — cool white/silver bars
  static const Color eqBar = Color(0xFFCCCCD4);
  static const Color eqBarGlow = Color(0x44CCCCCC);
  static const Color eqGrid = Color(0xFF1E1E22);

  // Spectrum Colors — white → grey gradient
  static const List<Color> spectrumColors = [
    Color(0xFFF4F4F5),
    Color(0xFFD4D4D8),
    Color(0xFFB4B4BC),
    Color(0xFF8A8A96),
    Color(0xFF606068),
  ];

  // Gradients — white to grey
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFF0F0F2), Color(0xFFA8A8B0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF0C0C0E), Color(0xFF111113)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1C1C1F), Color(0xFF141416)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient vibrancyGradient = LinearGradient(
    colors: [Color(0xFFE8E8EC), Color(0xFFB8B8C0), Color(0xFF888890)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Now Playing gradients — pure dark, no colour cast
  static const LinearGradient nowPlayingGradient = LinearGradient(
    colors: [Color(0xFF0E0E10), Color(0xFF141416), Color(0xFF0C0C0E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Status colors — keep functional colours subtle
  static const Color success = Color(0xFF4ADE80);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFF87171);
  static const Color info = Color(0xFF60A5FA);

  // Border — near-invisible dark lines
  static const Color border = Color(0xFF28282C);
  static const Color borderLight = Color(0xFF343438);

  // Spotify
  static const Color spotifyGreen = Color(0xFF1DB954);

  // Shadow — neutral dark
  static const Color shadowColor = Color(0x60000000);
}
