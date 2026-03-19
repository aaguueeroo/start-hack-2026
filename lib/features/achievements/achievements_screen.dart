import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:start_hack_2026/core/constants/game_theme_constants.dart';
import 'package:start_hack_2026/core/constants/spacing_constants.dart';
import 'package:start_hack_2026/core/widgets/game_card.dart';
import 'package:start_hack_2026/modules/game/controllers/game_controller.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameEngine = context.watch<GameController>().gameEngine;
    final state = gameEngine.state;
    final currentCash = gameEngine.currentCash;
    final hasKnowledgeItem = gameEngine.itemSlots.any((item) => item != null);
    final hasLevel3Knowledge = gameEngine.itemSlots.any(
      (item) => item != null && item.level >= 3,
    );
    final diversification = gameEngine.currentStats.diversification;
    final startingCash =
        state?.character.initialStats['money']?.toDouble() ?? 0.0;

    final achievements = <_AchievementData>[
      const _AchievementData(
        title: 'Panic Seller',
        description: 'Sell an asset right before it goes up in value.',
        icon: Icons.trending_down,
        color: GameThemeConstants.dangerDark,
      ),
      _AchievementData(
        title: 'Bookworm Investor',
        description: 'Buy your first knowledge item.',
        icon: Icons.menu_book,
        color: GameThemeConstants.primaryDark,
        isUnlocked: hasKnowledgeItem,
      ),
      _AchievementData(
        title: 'MBA',
        description: 'Merge knowledge items to reach level 3.',
        icon: Icons.school,
        color: GameThemeConstants.skyBlueDark,
        isUnlocked: hasLevel3Knowledge,
      ),
      _AchievementData(
        title: "Don't Put All Eggs in One Basket",
        description:
            'Reach a diversification score of at least 30 with a balanced portfolio.',
        icon: Icons.pie_chart,
        color: GameThemeConstants.accentDark,
        isUnlocked: diversification >= 30,
      ),
      const _AchievementData(
        title: 'Buy High, Cry Later',
        description:
            'Purchase an asset and end the same simulation year at a loss.',
        icon: Icons.sentiment_very_dissatisfied,
        color: GameThemeConstants.orangeDark,
      ),
      const _AchievementData(
        title: 'Hands in Pockets',
        description: 'Start a store phase and buy absolutely nothing.',
        icon: Icons.do_not_touch,
        color: GameThemeConstants.warningDark,
      ),
      _AchievementData(
        title: 'Instant Noodle to IPO',
        description:
            'Finish a simulation with portfolio value at least 2x your starting money.',
        icon: Icons.rocket_launch,
        color: GameThemeConstants.successDark,
        isUnlocked: startingCash > 0 && currentCash >= (startingCash * 2),
      ),
      const _AchievementData(
        title: 'Crash Test Investor',
        description:
            'Survive a market crash event and still end the year positive.',
        icon: Icons.car_crash,
        color: GameThemeConstants.dangerDark,
      ),
      const _AchievementData(
        title: 'Grip of Steel',
        description:
            'Hold a volatile asset through a full simulation without selling.',
        icon: Icons.fitness_center,
        color: GameThemeConstants.primaryDark,
      ),
    ];

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
        child: ListView(
          padding: const EdgeInsets.all(SpacingConstants.lg),
          children: [
            Text(
              'Every achievement marks a lesson: experiment, adapt, and build your investor instincts one decision at a time.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: GameThemeConstants.outlineColorLight,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: SpacingConstants.lg),
            ...achievements.map(
              (achievement) => Padding(
                padding: const EdgeInsets.only(bottom: SpacingConstants.md),
                child: _AchievementCard(achievement: achievement),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({
    required this.achievement,
  });

  final _AchievementData achievement;

  @override
  Widget build(BuildContext context) {
    final isUnlocked = achievement.isUnlocked;
    final iconColor = isUnlocked ? achievement.color : Colors.grey.shade500;
    final textColor =
        isUnlocked ? GameThemeConstants.outlineColor : Colors.grey.shade700;
    final subtitleColor = isUnlocked
        ? GameThemeConstants.outlineColorLight
        : Colors.grey.shade600;

    return GameCard(
      backgroundColor: isUnlocked
          ? GameThemeConstants.creamSurface
          : const Color(0xFFE7E7E7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(SpacingConstants.radiusMd),
              border: Border.all(
                color: iconColor,
                width: 2,
              ),
            ),
            child: Icon(achievement.icon, color: iconColor),
          ),
          const SizedBox(width: SpacingConstants.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: SpacingConstants.xs),
                Text(
                  achievement.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: subtitleColor,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: SpacingConstants.sm),
          Icon(
            isUnlocked ? Icons.check_circle : Icons.lock_outline,
            color:
                isUnlocked ? GameThemeConstants.successDark : Colors.grey.shade500,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _AchievementData {
  const _AchievementData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.isUnlocked = false,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isUnlocked;
}
