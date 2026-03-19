import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:start_hack_2026/core/constants/game_theme_constants.dart';
import 'package:start_hack_2026/core/constants/spacing_constants.dart';
import 'package:start_hack_2026/core/widgets/game_card.dart';

/// Skeleton layout matching [LeaderboardScreen] (podium + list) while scores load.
class LeaderboardShimmer extends StatelessWidget {
  const LeaderboardShimmer({super.key});

  static const Color _bone = Color(0xFFE8E0D8);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFD4C8B8),
      highlightColor: const Color(0xFFF8F2EA),
      period: const Duration(milliseconds: 1300),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: SpacingConstants.md,
              right: SpacingConstants.md,
              bottom: SpacingConstants.md,
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 160,
                    height: 26,
                    decoration: BoxDecoration(
                      color: _bone,
                      borderRadius: BorderRadius.circular(
                        GameThemeConstants.radiusSmall,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: SpacingConstants.md * 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: _ShimmerPodiumColumn(
                        blockHeight:
                            GameThemeConstants.leaderboardPodiumSecondHeight,
                      ),
                    ),
                    const SizedBox(width: SpacingConstants.xs),
                    Expanded(
                      child: Transform.scale(
                        scale: 1.08,
                        alignment: Alignment.bottomCenter,
                        child: _ShimmerPodiumColumn(
                          blockHeight:
                              GameThemeConstants.leaderboardPodiumFirstHeight,
                        ),
                      ),
                    ),
                    const SizedBox(width: SpacingConstants.xs),
                    Expanded(
                      child: _ShimmerPodiumColumn(
                        blockHeight:
                            GameThemeConstants.leaderboardPodiumThirdHeight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                SpacingConstants.md,
                0,
                SpacingConstants.md,
                SpacingConstants.md,
              ),
              itemCount: 8,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: SpacingConstants.sm),
              itemBuilder: (BuildContext context, int index) {
                return GameCard(
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 22,
                        decoration: BoxDecoration(
                          color: _bone,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: SpacingConstants.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 16,
                              margin: const EdgeInsets.only(right: 48),
                              decoration: BoxDecoration(
                                color: _bone,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: SpacingConstants.xs),
                            Container(
                              height: 12,
                              width: 120,
                              decoration: BoxDecoration(
                                color: _bone,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 48,
                        height: 22,
                        decoration: BoxDecoration(
                          color: _bone,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerPodiumColumn extends StatelessWidget {
  const _ShimmerPodiumColumn({required this.blockHeight});

  final double blockHeight;

  static const Color _bone = LeaderboardShimmer._bone;

  @override
  Widget build(BuildContext context) {
    final double h = GameThemeConstants.leaderboardPodiumIconSize;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          height: h,
          alignment: Alignment.bottomCenter,
          child: Container(
            width: h * 0.75,
            height: h * 0.85,
            decoration: BoxDecoration(
              color: _bone,
              borderRadius: BorderRadius.circular(h * 0.35),
            ),
          ),
        ),
        const SizedBox(height: SpacingConstants.xs),
        Container(
          height: 14,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: _bone,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          height: 12,
          width: 40,
          decoration: BoxDecoration(
            color: _bone,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: SpacingConstants.sm),
        Container(
          width: double.infinity,
          height: blockHeight,
          decoration: BoxDecoration(
            color: _bone,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(GameThemeConstants.radiusSmall),
            ),
          ),
        ),
      ],
    );
  }
}
