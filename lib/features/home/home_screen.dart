import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:start_hack_2026/core/constants/app_constants.dart';
import 'package:start_hack_2026/core/constants/game_theme_constants.dart';
import 'package:start_hack_2026/core/constants/spacing_constants.dart';
import 'package:start_hack_2026/core/widgets/game_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [GameThemeConstants.creamBackground, Color(0xFFF5EDE0)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(SpacingConstants.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Image.asset(
                  'assets/images/logo_home.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Text(
                      AppConstants.appName,
                      style: Theme.of(context).textTheme.displayMedium
                          ?.copyWith(
                            color: GameThemeConstants.primaryDark,
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
                            ],
                          ),
                      textAlign: TextAlign.center,
                    );
                  },
                ),
                const Spacer(),
                GameButton(
                  label: 'New Game',
                  icon: Icons.sports_esports,
                  onPressed: () => context.push('/character-selection'),
                  variant: GameButtonVariant.primary,
                ),
                const SizedBox(height: SpacingConstants.md),
                GameButton(
                  label: 'Glossary',
                  icon: Icons.menu_book,
                  onPressed: () => context.push('/glossary'),
                  variant: GameButtonVariant.accent,
                ),
                const SizedBox(height: SpacingConstants.md),
                GameButton(
                  label: 'Achievements',
                  icon: Icons.emoji_events,
                  onPressed: () => context.push('/achievements'),
                  variant: GameButtonVariant.warning,
                ),
                const SizedBox(height: SpacingConstants.md),
                GameButton(
                  label: 'Leaderboard',
                  icon: Icons.leaderboard,
                  onPressed: () => context.push('/leaderboard'),
                  variant: GameButtonVariant.accent,
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
