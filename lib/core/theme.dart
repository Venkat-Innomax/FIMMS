import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// FIMMS design tokens — "Government Official, Modern".
///
/// Distinct from the generic Material-3 purple look. Telangana-flag blue
/// primary, saffron accent, flat 1px-outlined cards, no heavy shadows.
class FimmsColors {
  FimmsColors._();

  // Brand
  static const Color primary = Color(0xFF0B3D91); // deep Telangana blue
  static const Color primaryDark = Color(0xFF082B66);
  static const Color secondary = Color(0xFFE09F3E); // saffron accent

  // Surfaces
  static const Color surface = Color(0xFFF7F8FA);
  static const Color surfaceAlt = Color(0xFFFFFFFF);
  static const Color outline = Color(0xFFD4D7DD);

  // Text
  static const Color textPrimary = Color(0xFF0F1C2E);
  static const Color textMuted = Color(0xFF5A6372);

  // Grade band colours (spec §4.2)
  static const Color gradeExcellent = Color(0xFF1B5E20); // >= 85 Dark Green
  static const Color gradeGood = Color(0xFF1565C0); //      70-84 Blue
  static const Color gradeAverage = Color(0xFFF9A825); //   50-69 Amber
  static const Color gradePoor = Color(0xFFE65100); //      35-49 Orange-Red
  static const Color gradeCritical = Color(0xFFB71C1C); //  < 35  Dark Red

  // Status chips
  static const Color success = Color(0xFF1B5E20);
  static const Color warning = Color(0xFFF9A825);
  static const Color danger = Color(0xFFB71C1C);
}

class FimmsTheme {
  FimmsTheme._();

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: FimmsColors.textPrimary,
      displayColor: FimmsColors.textPrimary,
    );

    return base.copyWith(
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: FimmsColors.primary,
        onPrimary: Colors.white,
        secondary: FimmsColors.secondary,
        onSecondary: Colors.white,
        error: FimmsColors.danger,
        onError: Colors.white,
        surface: FimmsColors.surfaceAlt,
        onSurface: FimmsColors.textPrimary,
        surfaceContainerHighest: FimmsColors.surface,
        outline: FimmsColors.outline,
      ),
      scaffoldBackgroundColor: FimmsColors.surface,
      textTheme: textTheme.copyWith(
        displaySmall: textTheme.displaySmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        headlineMedium: textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        labelLarge: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: FimmsColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
      cardTheme: CardThemeData(
        color: FimmsColors.surfaceAlt,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: FimmsColors.outline, width: 1),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: FimmsColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: FimmsColors.primary,
          side: const BorderSide(color: FimmsColors.outline),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: FimmsColors.surfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: FimmsColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: FimmsColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: FimmsColors.primary,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: FimmsColors.surface,
        side: const BorderSide(color: FimmsColors.outline),
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: FimmsColors.textPrimary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      dividerTheme: const DividerThemeData(
        color: FimmsColors.outline,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
