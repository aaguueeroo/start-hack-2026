import 'package:flutter/material.dart';
import 'package:start_hack_2026/core/constants/game_theme_constants.dart';
import 'package:start_hack_2026/core/extensions/icon_extension.dart';

/// Displays store item art (image or icon fallback). Logs load errors without blocking UI.
class StoreItemArt extends StatelessWidget {
  const StoreItemArt({
    super.key,
    required this.icon,
    this.imagePath,
    this.size = 80,
  });

  final String icon;
  final String? imagePath;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (imagePath == null) {
      return Icon(
        icon.toIconData(),
        size: size,
        color: GameThemeConstants.primaryDark,
      );
    }
    return Image.asset(
      imagePath!,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
        debugPrint('StoreItemArt: failed to load $imagePath: $error');
        return Icon(
          icon.toIconData(),
          size: size,
          color: GameThemeConstants.primaryDark,
        );
      },
    );
  }
}
