import 'package:flutter/material.dart';
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
        displayLarge: const TextStyle(
          fontFamily: 'Fredoka',
          fontSize: 32,
          fontWeight: FontWeight.w400,
          color: textColor,
          height: 1.2,
        ),
        displayMedium: const TextStyle(
          fontFamily: 'Fredoka',
          fontSize: 28,
          fontWeight: FontWeight.w400,
          color: textColor,
        ),
        displaySmall: const TextStyle(
          fontFamily: 'Fredoka',
          fontSize: 24,
          fontWeight: FontWeight.w400,
          color: textColor,
        ),
        headlineLarge: const TextStyle(
          fontFamily: 'Fredoka',
          fontSize: 22,
          fontWeight: FontWeight.w400,
          color: textColor,
        ),
        headlineMedium: const TextStyle(
          fontFamily: 'Fredoka',
          fontSize: 20,
          fontWeight: FontWeight.w400,
          color: textColor,
        ),
        headlineSmall: const TextStyle(
          fontFamily: 'Fredoka',
          fontSize: 18,
          fontWeight: FontWeight.w400,
          color: textColor,
        ),
        titleLarge: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
        titleMedium: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        titleSmall: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        bodyLarge: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
        bodyMedium: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
        bodySmall: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
        labelLarge: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontFamily: 'Fredoka',
          fontSize: 22,
          fontWeight: FontWeight.w400,
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
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: const CircleBorder(),
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
            borderRadius: BorderRadius.circular(
              GameThemeConstants.radiusButtonStadium,
            ),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              GameThemeConstants.radiusButtonStadium,
            ),
          ),
        ),
      ),
    );
  }
}
