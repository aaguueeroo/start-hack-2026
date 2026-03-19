import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:start_hack_2026/core/constants/game_theme_constants.dart';
import 'package:start_hack_2026/core/constants/spacing_constants.dart';
import 'package:start_hack_2026/core/widgets/game_card.dart';
import 'package:start_hack_2026/data/local/achievement_preferences.dart';
import 'package:start_hack_2026/modules/game/controllers/game_controller.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final AchievementPreferences _achievementPreferences =
      AchievementPreferences();

  Set<String> _persistedUnlockedIds = <String>{};
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPersistedAchievements();
  }

  Future<void> _loadPersistedAchievements() async {
    final unlockedIds = await _achievementPreferences.getUnlockedIds();
    if (!mounted) return;
    setState(() {
      _persistedUnlockedIds = unlockedIds;
      _isLoading = false;
    });
  }

  Future<void> _saveUnlockedIdsIfNeeded(Set<String> unlockedIds) async {
    if (_isLoading || _isSaving) return;
    if (_setEquals(_persistedUnlockedIds, unlockedIds)) return;

    _isSaving = true;
    await _achievementPreferences.saveUnlockedIds(unlockedIds);
    _isSaving = false;
    if (!mounted) return;

    setState(() {
      _persistedUnlockedIds = unlockedIds;
    });
  }

  bool _setEquals(Set<String> a, Set<String> b) {
    if (a.length != b.length) return false;
    for (final value in a) {
      if (!b.contains(value)) return false;
    }
    return true;
  }

  Future<void> _unlockPanicSellerForDebug() async {
    final unlockedIds = await _achievementPreferences.getUnlockedIds();
    unlockedIds.add('panic_seller');
    await _achievementPreferences.saveUnlockedIds(unlockedIds);
    await _loadPersistedAchievements();
  }

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

    final achievements = <_AchievementRule>[
      const _AchievementRule(
        id: 'panic_seller',
        title: 'Panic Seller',
        description: 'Sell an asset right before it goes up in value.',
        imageAsset: 'assets/images/achievements/panic.png',
        color: GameThemeConstants.dangerDark,
      ),
      _AchievementRule(
        id: 'bookworm_investor',
        title: 'Bookworm Investor',
        description: 'Buy your first knowledge item.',
        imageAsset: 'assets/images/achievements/bookworm.png',
        color: GameThemeConstants.primaryDark,
        isUnlockedNow: hasKnowledgeItem,
      ),
      _AchievementRule(
        id: 'mba',
        title: 'MBA',
        description: 'Merge knowledge items to reach level 3.',
        imageAsset: 'assets/images/achievements/mba.png',
        color: GameThemeConstants.skyBlueDark,
        isUnlockedNow: hasLevel3Knowledge,
      ),
      _AchievementRule(
        id: 'all_eggs_one_basket',
        title: "Don't Put All Eggs in One Basket",
        description:
            'Reach a diversification score of at least 30 with a balanced portfolio.',
        imageAsset: 'assets/images/achievements/egg.png',
        color: GameThemeConstants.accentDark,
        isUnlockedNow: diversification >= 30,
      ),
      const _AchievementRule(
        id: 'buy_high_cry_later',
        title: 'Buy High, Cry Later',
        description:
            'Purchase an asset and end the same simulation year at a loss.',
        imageAsset: 'assets/images/achievements/cry.png',
        color: GameThemeConstants.orangeDark,
      ),
      const _AchievementRule(
        id: 'hands_in_pockets',
        title: 'Hands in Pockets',
        description: 'Start a store phase and buy absolutely nothing.',
        imageAsset: 'assets/images/achievements/pocket.png',
        color: GameThemeConstants.warningDark,
      ),
      _AchievementRule(
        id: 'instant_noodle_to_ipo',
        title: 'Instant Noodle to IPO',
        description:
            'Finish a simulation with portfolio value at least 2x your starting money.',
        imageAsset: 'assets/images/achievements/noodle.png',
        color: GameThemeConstants.successDark,
        isUnlockedNow: startingCash > 0 && currentCash >= (startingCash * 2),
      ),
      const _AchievementRule(
        id: 'crash_test_investor',
        title: 'Crash Test Investor',
        description:
            'Survive a market crash event and still end the year positive.',
        imageAsset: 'assets/images/achievements/crash.png',
        color: GameThemeConstants.dangerDark,
      ),
      const _AchievementRule(
        id: 'grip_of_steel',
        title: 'Grip of Steel',
        description:
            'Hold a volatile asset through a full simulation without selling.',
        imageAsset: 'assets/images/achievements/steel.png',
        color: GameThemeConstants.primaryDark,
      ),
    ];
    final unlockedIds = <String>{..._persistedUnlockedIds};
    for (final achievement in achievements) {
      if (achievement.isUnlockedNow) {
        unlockedIds.add(achievement.id);
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saveUnlockedIdsIfNeeded(unlockedIds);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        actions: [
          if (kDebugMode)
            IconButton(
              tooltip: 'Unlock Panic Seller',
              icon: const Icon(Icons.bug_report),
              onPressed: _unlockPanicSellerForDebug,
            ),
        ],
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
            colors: [GameThemeConstants.creamBackground, Color(0xFFF5EDE0)],
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
                child: _AchievementCard(
                  achievement: achievement,
                  isUnlocked: unlockedIds.contains(achievement.id),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.achievement, required this.isUnlocked});

  final _AchievementRule achievement;
  final bool isUnlocked;

  @override
  Widget build(BuildContext context) {
    final iconColor = isUnlocked ? achievement.color : Colors.grey.shade500;
    final textColor = isUnlocked
        ? GameThemeConstants.outlineColor
        : Colors.grey.shade700;
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
              border: Border.all(color: iconColor, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(SpacingConstants.radiusMd),
              child: isUnlocked
                  ? Image.asset(
                      achievement.imageAsset,
                      fit: BoxFit.cover,
                      width: 48,
                      height: 48,
                      errorBuilder:
                          (
                            BuildContext context,
                            Object error,
                            StackTrace? stackTrace,
                          ) =>
                              Icon(Icons.image_not_supported, color: iconColor),
                    )
                  : ColorFiltered(
                      colorFilter: const ColorFilter.matrix(<double>[
                        0.2126,
                        0.7152,
                        0.0722,
                        0,
                        0,
                        0.2126,
                        0.7152,
                        0.0722,
                        0,
                        0,
                        0.2126,
                        0.7152,
                        0.0722,
                        0,
                        0,
                        0,
                        0,
                        0,
                        1,
                        0,
                      ]),
                      child: Padding(
                        padding: EdgeInsets.all(4),
                        child: Image.asset(
                          achievement.imageAsset,
                          fit: BoxFit.contain,
                          width: 48,
                          height: 48,
                        ),
                      ),
                    ),
            ),
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
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: subtitleColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: SpacingConstants.sm),
          Icon(
            isUnlocked ? Icons.check_circle : Icons.lock_outline,
            color: isUnlocked
                ? GameThemeConstants.successDark
                : Colors.grey.shade500,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _AchievementRule {
  const _AchievementRule({
    required this.id,
    required this.title,
    required this.description,
    required this.imageAsset,
    required this.color,
    this.isUnlockedNow = false,
  });

  final String id;
  final String title;
  final String description;
  final String imageAsset;
  final Color color;
  final bool isUnlockedNow;
}
