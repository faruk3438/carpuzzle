import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // ── Temel UI ─────────────────────────────────────────────────────────────
  static const Color background = Color(0xFF101820);
  static const Color surface = Color(0xFF172129);
  static const Color surfaceLight = Color(0xFF22303A);
  static const Color gridLine = Color(0xFF40505B);
  static const Color exitGlow = Color(0xFF67D8B5);
  static const Color wallColor = Color(0xFF36424A);

  static const Color accentOrange = Color(0xFFF2B766);
  static const Color accentPink = Color(0xFFE887A8);
  static const Color accentBlue = Color(0xFF7CB7E8);
  static const Color accentGreen = Color(0xFF79D29F);
  static const Color accentRed = Color(0xFFE76F61);
  static const Color accentGold = Color(0xFFE9C46A);

  static const Color textPrimary = Color(0xFFF3EFE3);
  static const Color textSecondary = Color(0xFFB8C2C8);
  static const Color textMuted = Color(0xFF788690);

  // ── Otopark zemini ────────────────────────────────────────────────────────
  static const Color asphalt = Color(0xFF26313A); // otopark zemini
  static const Color asphaltCell = Color(0xFF2B343D); // park alanlari
  static const Color parkLine = Color(0xFFE9D8A6); // sicak park cizgisi
  static const Color concrete = Color(0xFF4B565D); // beton kolon
  static const Color exitLane = Color(0xFF24453F); // cikis seridi

  // ── Araç renkleri ─────────────────────────────────────────────────────────
  static const List<Color> carColors = [
    Color(0xFFE76F61), // soft red
    Color(0xFF7CB7E8), // powder blue
    Color(0xFFE9C46A), // warm yellow
    Color(0xFF79D29F), // soft green
    Color(0xFFF4A261), // orange
    Color(0xFFB28DFF), // lavender
    Color(0xFF5FB3A7), // teal
    Color(0xFFE887A8), // rose
  ];

  static const Color vipColor = Color(0xFFE9C46A);
  static const Color emergencyColor = Color(0xFFE85D75);
  static const Color truckColor = Color(0xFF9AA7AD);
  static const Color spinnerColor = Color(0xFF67D8B5);

  static const Color oneWayColor = Color(0xFF8AD8C1);
  static const Color teleportAColor = Color(0xFFB28DFF);
  static const Color teleportBColor = Color(0xFFE887A8);

  // ── Tema ──────────────────────────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          primary: accentOrange,
          secondary: accentBlue,
          surface: surface,
          error: accentRed,
        ),
        fontFamily: null,
        textTheme: const TextTheme(
          displayLarge: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: textPrimary,
              letterSpacing: -1),
          displayMedium: TextStyle(
              fontSize: 24, fontWeight: FontWeight.w700, color: textPrimary),
          titleLarge: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary),
          titleMedium: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary),
          bodyLarge: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w400, color: textPrimary),
          bodyMedium: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w400, color: textSecondary),
          labelSmall: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: textMuted,
              letterSpacing: 1.5),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentOrange,
            foregroundColor: Colors.black,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            textStyle:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
      );
}
