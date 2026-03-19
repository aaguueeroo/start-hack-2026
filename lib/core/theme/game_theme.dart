import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:start_hack_2026/core/constants/game_theme_constants.dart';

class GameTheme {
  GameTheme._();

  static ThemeData get light {
    const textColor = GameThemeConstants.outlineColor;
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: GameThemeConstants.primaryDark,
        onPrimary: Colors.white,
        secondary: GameThemeConstants.accentDark,
        onSecondary: Colors.white,
        surface: GameThemeConstants.creamSurface,
        onSurface: GameThemeConstants.outlineColor,
        error: GameThemeConstants.dangerDark,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: GameThemeConstants.creamBackground,
      textTheme: TextTheme(
        displayLarge: GoogleFonts.fredoka(
          fontSize: 32,
          fontWeight: FontWeight.w400,
          color: textColor,
          height: 1.2,
        ),
        displayMedium: GoogleFonts.fredoka(
          fontSize: 28,
          fontWeight: FontWeight.w400,
          color: textColor,
        ),
        displaySmall: GoogleFonts.fredoka(
          fontSize: 24,
          fontWeight: FontWeight.w400,
          color: textColor,
        ),
        headlineLarge: GoogleFonts.fredoka(
          fontSize: 22,
          fontWeight: FontWeight.w400,
          color: textColor,
        ),
        headlineMedium: GoogleFonts.fredoka(
          fontSize: 20,
          fontWeight: FontWeight.w400,
          color: textColor,
        ),
        headlineSmall: GoogleFonts.fredoka(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          color: textColor,
        ),
        titleLarge: GoogleFonts.nunito(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
        titleMedium: GoogleFonts.nunito(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        titleSmall: GoogleFonts.nunito(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        bodyLarge: GoogleFonts.nunito(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
        bodyMedium: GoogleFonts.nunito(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
        bodySmall: GoogleFonts.nunito(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
        labelLarge: GoogleFonts.nunito(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.fredoka(
          fontSize: 22,
          color: textColor,
        ),
        iconTheme: const IconThemeData(
          color: GameThemeConstants.outlineColor,
          size: 28,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: GameThemeConstants.creamSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GameThemeConstants.radiusMedium),
          side: const BorderSide(
            color: GameThemeConstants.outlineColor,
            width: GameThemeConstants.outlineThickness,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GameThemeConstants.radiusMedium),
          ),
        ),
      ),
    );
  }
}
