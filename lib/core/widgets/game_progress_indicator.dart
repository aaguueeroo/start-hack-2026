import 'package:flutter/material.dart';
import 'package:start_hack_2026/core/constants/game_theme_constants.dart';

class GameProgressIndicator extends StatelessWidget {
  const GameProgressIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: CircularProgressIndicator(
        strokeWidth: 4,
        valueColor: const AlwaysStoppedAnimation<Color>(
          GameThemeConstants.primaryDark,
        ),
        backgroundColor: GameThemeConstants.primaryLight.withValues(alpha: 0.3),
      ),
    );
  }
}
