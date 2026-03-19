import 'package:flutter/material.dart';
import 'package:start_hack_2026/core/constants/game_theme_constants.dart';
import 'package:start_hack_2026/core/constants/spacing_constants.dart';

enum GameButtonVariant { primary, success, accent, danger, warning }

class GameButton extends StatelessWidget {
  const GameButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailing,
    this.variant = GameButtonVariant.primary,
    this.isFullWidth = true,
    this.padding,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Widget? trailing;
  final GameButtonVariant variant;
  final bool isFullWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final (gradient, bevelColor) = _variantColors;
    final isEnabled = onPressed != null;
    return GestureDetector(
      onTap: isEnabled ? onPressed : null,
      child: Container(
        width: isFullWidth ? double.infinity : null,
        padding:
            padding ??
            const EdgeInsets.symmetric(
              horizontal: SpacingConstants.lg,
              vertical: SpacingConstants.md,
            ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isEnabled
                ? gradient
                : [Colors.grey.shade400, Colors.grey.shade600],
          ),
          borderRadius: BorderRadius.circular(GameThemeConstants.radiusMedium),
          border: Border.all(
            color: GameThemeConstants.outlineColor,
            width: GameThemeConstants.outlineThickness,
          ),
          boxShadow: [
            BoxShadow(
              color: isEnabled ? bevelColor : Colors.grey.shade800,
              offset: const Offset(0, GameThemeConstants.bevelOffset),
              blurRadius: 0,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: trailing != null
              ? MainAxisAlignment.spaceBetween
              : MainAxisAlignment.center,
          mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: 24),
                  const SizedBox(width: SpacingConstants.sm),
                ],
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    shadows: [
                      Shadow(
                        color: GameThemeConstants.outlineColor,
                        offset: const Offset(2, 2),
                        blurRadius: 0,
                      ),
                      Shadow(
                        color: GameThemeConstants.outlineColor,
                        offset: const Offset(-1, -1),
                        blurRadius: 0,
                      ),
                      Shadow(
                        color: GameThemeConstants.outlineColor,
                        offset: const Offset(1, -1),
                        blurRadius: 0,
                      ),
                      Shadow(
                        color: GameThemeConstants.outlineColor,
                        offset: const Offset(-1, 1),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }

  (List<Color>, Color) get _variantColors {
    switch (variant) {
      case GameButtonVariant.primary:
        return (
          [GameThemeConstants.primaryLight, GameThemeConstants.primaryDark],
          const Color(0xFF3D2E8C),
        );
      case GameButtonVariant.success:
        return (
          [GameThemeConstants.successLight, GameThemeConstants.successDark],
          const Color(0xFF15803D),
        );
      case GameButtonVariant.accent:
        return (
          [GameThemeConstants.accentLight, GameThemeConstants.accentDark],
          const Color(0xFF008F82),
        );
      case GameButtonVariant.danger:
        return (
          [GameThemeConstants.dangerLight, GameThemeConstants.dangerDark],
          const Color(0xFF991B1B),
        );
      case GameButtonVariant.warning:
        return (
          [GameThemeConstants.warningLight, GameThemeConstants.warningDark],
          const Color(0xFFCA8A04),
        );
    }
  }
}
