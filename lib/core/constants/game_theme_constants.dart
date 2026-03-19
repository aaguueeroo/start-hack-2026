import 'package:flutter/material.dart';

/// Game-style theme constants for cartoonish, playful UI.
abstract final class GameThemeConstants {
  static const Color outlineColor = Color(0xFF2D1B0E);
  static const Color outlineColorLight = Color(0xFF5A3E2B);

  static const Color creamBackground = Color.fromARGB(255, 232, 188, 117);
  static const Color creamSurface = Color(0xFFFFFBF0);
  static const Color darkNavy = Color(0xFF1E2A3A);

  static const Color primaryLight = Color(0xFF7B6BFF);
  static const Color primaryDark = Color(0xFF5A4BD9);
  static const Color accentLight = Color(0xFF00E5D4);
  static const Color accentDark = Color(0xFF00B8A9);
  static const Color successLight = Color(0xFF4ADE80);
  static const Color successDark = Color(0xFF22C55E);
  static const Color dangerLight = Color(0xFFF87171);
  static const Color dangerDark = Color(0xFFDC2626);
  static const Color warningLight = Color(0xFFFDE047);
  static const Color warningDark = Color(0xFFFACC15);
  static const Color orangeLight = Color(0xFFFB923C);
  static const Color orangeDark = Color(0xFFEA580C);
  static const Color skyBlueLight = Color(0xFF7DD3FC);
  static const Color skyBlueDark = Color(0xFF0EA5E9);

  /// Stat colors tuned for visibility on cream background.
  static const Color statPositive = Color(0xFF1A6B2E);
  static const Color statNegative = Color(0xFF991B1B);
  static const Color statNeutral = Color(0xFF5A3E2B);

  /// Item level card background colors.
  static const Color itemLevel1Color = Color(0xFFFDE047); // yellow
  static const Color itemLevel2Color = Color(0xFF93C5FD); // blue
  static const Color itemLevel3Color = Color(0xFFC4B5FD); // purple

  static Color getItemLevelColor(int level) {
    return switch (level) {
      1 => itemLevel1Color,
      2 => itemLevel2Color,
      3 => itemLevel3Color,
      _ => itemLevel1Color,
    };
  }

  static const double outlineThickness = 3.0;
  static const double outlineThicknessSmall = 2.0;
  static const double bevelOffset = 4.0;
  static const double radiusPill = 24.0;
  static const double radiusLarge = 20.0;
  static const double radiusMedium = 16.0;
  static const double radiusSmall = 12.0;
}
