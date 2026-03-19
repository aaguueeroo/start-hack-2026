import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:start_hack_2026/core/constants/game_theme_constants.dart';
import 'package:start_hack_2026/core/constants/spacing_constants.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              GameThemeConstants.creamBackground,
              Color(0xFFF5EDE0),
            ],
          ),
        ),
        child: Center(
          child: Padding(
          padding: const EdgeInsets.all(SpacingConstants.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.emoji_events_outlined,
                size: 80,
                color: GameThemeConstants.warningDark,
              ),
              const SizedBox(height: SpacingConstants.lg),
              Text(
                'Coming Soon',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: SpacingConstants.sm),
              Text(
                'Achievements will be available in a future update.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: GameThemeConstants.outlineColorLight,
                    ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
