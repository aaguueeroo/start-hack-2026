import 'package:flutter/material.dart';
import 'package:start_hack_2026/core/constants/game_theme_constants.dart';
import 'package:start_hack_2026/core/constants/spacing_constants.dart';

class GameResourceCounter extends StatelessWidget {
  const GameResourceCounter({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.iconColor,
    this.onAddTap,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback? onAddTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingConstants.md,
        vertical: SpacingConstants.sm,
      ),
      decoration: BoxDecoration(
        color: GameThemeConstants.darkNavy,
        borderRadius: BorderRadius.circular(GameThemeConstants.radiusPill),
        border: Border.all(
          color: GameThemeConstants.outlineColor,
          width: GameThemeConstants.outlineThicknessSmall,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: iconColor ?? GameThemeConstants.warningLight,
              size: 24,
            ),
            const SizedBox(width: SpacingConstants.sm),
          ],
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  shadows: [
                    Shadow(
                      color: GameThemeConstants.outlineColor,
                      offset: const Offset(1, 1),
                      blurRadius: 0,
                    ),
                  ],
                ),
          ),
          if (onAddTap != null) ...[
            const SizedBox(width: SpacingConstants.sm),
            GestureDetector(
              onTap: onAddTap,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: GameThemeConstants.successDark,
                  borderRadius: BorderRadius.circular(GameThemeConstants.radiusSmall),
                  border: Border.all(
                    color: GameThemeConstants.outlineColor,
                    width: GameThemeConstants.outlineThicknessSmall,
                  ),
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
