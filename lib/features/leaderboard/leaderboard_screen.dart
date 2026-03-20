import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:start_hack_2026/core/constants/game_theme_constants.dart';
import 'package:start_hack_2026/core/constants/spacing_constants.dart';
import 'package:start_hack_2026/core/widgets/game_card.dart';
import 'package:start_hack_2026/features/leaderboard/leaderboard_podium.dart';
import 'package:start_hack_2026/features/leaderboard/leaderboard_shimmer.dart';
import 'package:start_hack_2026/modules/leaderboard/controllers/leaderboard_controller.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeaderboardController>().loadTopScores();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
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
        child: Consumer<LeaderboardController>(
          builder: (context, controller, _) {
            if (controller.isLoading) {
              return const LeaderboardShimmer();
            }

            if (controller.entries.isEmpty && controller.errorMessage != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(SpacingConstants.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        controller.errorMessage!,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: SpacingConstants.md),
                      FilledButton(
                        onPressed: () => controller.loadTopScores(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (controller.entries.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(SpacingConstants.lg),
                  child: Text(
                    'No scores yet. Finish a simulation and save your score.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (controller.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      SpacingConstants.md,
                      SpacingConstants.sm,
                      SpacingConstants.md,
                      0,
                    ),
                    child: GameCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.cloud_off_outlined,
                            color: GameThemeConstants.warningDark,
                            size: 22,
                          ),
                          const SizedBox(width: SpacingConstants.sm),
                          Expanded(
                            child: Text(
                              controller.errorMessage!,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: GameThemeConstants.accentDark,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (controller.isShowingDemoData)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      SpacingConstants.md,
                      SpacingConstants.sm,
                      SpacingConstants.md,
                      0,
                    ),
                    child: GameCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.auto_awesome_outlined,
                            color: GameThemeConstants.primaryDark,
                            size: 22,
                          ),
                          const SizedBox(width: SpacingConstants.sm),
                          Expanded(
                            child: Text(
                              'Sample rankings for preview. Save a score after a '
                              'run to see real entries (and sync when Supabase is set up).',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: GameThemeConstants.accentDark,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                LeaderboardPodium(
                  topEntries: controller.entries.take(3).toList(),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      SpacingConstants.md,
                      0,
                      SpacingConstants.md,
                      SpacingConstants.md,
                    ),
                    itemCount: controller.entries.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: SpacingConstants.sm),
                    itemBuilder: (context, index) {
                      final entry = controller.entries[index];
                      return GameCard(
                        child: Row(
                          children: [
                            SizedBox(
                              width: 36,
                              child: Text(
                                '#${index + 1}',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: SpacingConstants.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.playerName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  Text(
                                    'Type: ${entry.characterType}',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${entry.score}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        color: GameThemeConstants.primaryDark,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
