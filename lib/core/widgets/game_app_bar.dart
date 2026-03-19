import 'package:flutter/material.dart';
import 'package:start_hack_2026/core/constants/game_theme_constants.dart';

class GameAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GameAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
  });

  final String title;
  final Widget? leading;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: leading,
      actions: actions,
      title: Text(
        title,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: GameThemeConstants.outlineColor,
              shadows: [
                Shadow(
                  color: GameThemeConstants.outlineColor.withValues(alpha: 0.3),
                  offset: const Offset(2, 2),
                  blurRadius: 0,
                ),
              ],
            ),
      ),
    );
  }
}
