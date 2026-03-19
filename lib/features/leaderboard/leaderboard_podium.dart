import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:start_hack_2026/core/constants/game_theme_constants.dart';
import 'package:start_hack_2026/core/constants/leaderboard_image_constants.dart';
import 'package:start_hack_2026/core/constants/spacing_constants.dart';
import 'package:start_hack_2026/domain/entities/leaderboard_entry.dart';

/// Top-three winners in a classic podium layout (2nd – 1st – 3rd).
class LeaderboardPodium extends StatelessWidget {
  const LeaderboardPodium({super.key, required this.topEntries});

  /// Rank order: index 0 = 1st place, 1 = 2nd, 2 = 3rd.
  final List<LeaderboardEntry> topEntries;

  static const Color _silver = Color(0xFFB8B8C8);
  static const Color _silverDeep = Color(0xFF8E8EA0);
  static const Color _bronze = Color(0xFFD4A574);
  static const Color _bronzeDeep = Color(0xFF9A6B3F);

  @override
  Widget build(BuildContext context) {
    if (topEntries.isEmpty) {
      return const SizedBox.shrink();
    }
    final LeaderboardEntry? first = topEntries.isNotEmpty
        ? topEntries[0]
        : null;
    final LeaderboardEntry? second = topEntries.length > 1
        ? topEntries[1]
        : null;
    final LeaderboardEntry? third = topEntries.length > 2
        ? topEntries[2]
        : null;

    return Padding(
      padding: const EdgeInsets.only(
        left: SpacingConstants.md,
        right: SpacingConstants.md,
        bottom: SpacingConstants.md,
      ),
      child: Column(
        children: [
          Text(
            'Top players',
            style: GoogleFonts.fredoka(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: GameThemeConstants.outlineColor,
            ),
          ),
          const SizedBox(height: SpacingConstants.md * 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _PodiumColumn(
                  rankLabel: '2',
                  entry: second,
                  blockHeight: GameThemeConstants.leaderboardPodiumSecondHeight,
                  accent: _silver,
                  accentDeep: _silverDeep,
                  medalAssetPath: LeaderboardImageConstants.silverMedal,
                ),
              ),
              const SizedBox(width: SpacingConstants.xs),
              Expanded(
                child: _PodiumColumn(
                  rankLabel: '1',
                  entry: first,
                  blockHeight: GameThemeConstants.leaderboardPodiumFirstHeight,
                  accent: GameThemeConstants.warningLight,
                  accentDeep: GameThemeConstants.warningDark,
                  medalAssetPath: LeaderboardImageConstants.goldMedal,
                  scale: 1.08,
                ),
              ),
              const SizedBox(width: SpacingConstants.xs),
              Expanded(
                child: _PodiumColumn(
                  rankLabel: '3',
                  entry: third,
                  blockHeight: GameThemeConstants.leaderboardPodiumThirdHeight,
                  accent: _bronze,
                  accentDeep: _bronzeDeep,
                  medalAssetPath: LeaderboardImageConstants.bronzeMedal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  const _PodiumColumn({
    required this.rankLabel,
    required this.entry,
    required this.blockHeight,
    required this.accent,
    required this.accentDeep,
    required this.medalAssetPath,
    this.scale = 1.0,
  });

  final String rankLabel;
  final LeaderboardEntry? entry;
  final double blockHeight;
  final Color accent;
  final Color accentDeep;
  final String medalAssetPath;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final bool hasPlayer = entry != null;
    final String displayName = hasPlayer ? entry!.playerName : '—';
    final String scoreText = hasPlayer ? '${entry!.score}' : '';

    return Transform.scale(
      scale: scale,
      alignment: Alignment.bottomCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PodiumMedalImage(assetPath: medalAssetPath, dimmed: !hasPlayer),
          const SizedBox(height: SpacingConstants.xs),
          Text(
            displayName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.fredoka(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: hasPlayer
                  ? GameThemeConstants.outlineColor
                  : GameThemeConstants.outlineColorLight,
              height: 1.15,
            ),
          ),
          if (hasPlayer && scoreText.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              scoreText,
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: GameThemeConstants.primaryDark,
              ),
            ),
          ],
          const SizedBox(height: SpacingConstants.sm),
          _PodiumBlock(
            rankLabel: rankLabel,
            height: blockHeight,
            accent: accent,
            accentDeep: accentDeep,
            dimmed: !hasPlayer,
          ),
        ],
      ),
    );
  }
}

class _PodiumMedalImage extends StatelessWidget {
  const _PodiumMedalImage({required this.assetPath, required this.dimmed});

  final String assetPath;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final double h = GameThemeConstants.leaderboardPodiumIconSize;
    Widget image = SizedBox(
      width: double.infinity,
      height: h,
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        alignment: Alignment.bottomCenter,
        filterQuality: FilterQuality.medium,
        errorBuilder: (BuildContext context, Object error, StackTrace? stack) {
          debugPrint('Leaderboard medal asset failed: $assetPath $error');
          return SizedBox(height: h, width: h * 0.8);
        },
      ),
    );
    if (dimmed) {
      image = Opacity(opacity: 0.45, child: image);
    }
    return image;
  }
}

class _PodiumBlock extends StatelessWidget {
  const _PodiumBlock({
    required this.rankLabel,
    required this.height,
    required this.accent,
    required this.accentDeep,
    required this.dimmed,
  });

  final String rankLabel;
  final double height;
  final Color accent;
  final Color accentDeep;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final Color top = dimmed ? accent.withValues(alpha: 0.35) : accent;
    final Color bottom = dimmed
        ? accentDeep.withValues(alpha: 0.35)
        : accentDeep;

    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, bottom],
        ),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(GameThemeConstants.radiusSmall),
        ),
        border: Border.all(
          color: GameThemeConstants.outlineColor,
          width: GameThemeConstants.outlineThickness,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44000000),
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 10,
            left: 14,
            right: 14,
            child: Container(
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: dimmed ? 0.12 : 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Positioned(
            bottom: 6,
            left: 6,
            right: 6,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                rankLabel,
                style: GoogleFonts.fredoka(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: GameThemeConstants.outlineColor,
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
