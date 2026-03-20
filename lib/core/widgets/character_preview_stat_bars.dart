import 'package:flutter/material.dart';
import 'package:start_hack_2026/core/constants/game_theme_constants.dart';
import 'package:start_hack_2026/core/constants/spacing_constants.dart';

/// Stat ids shown in character preview UIs (selection card, store HUD).
const List<String> kCharacterPreviewStatIds = [
  'money',
  'riskTolerance',
  'financialKnowledge',
  'investmentHorizonRemaining',
];

/// RPG-style stat bars shared by character selection and store character panel.
class CharacterPreviewStatBars extends StatelessWidget {
  const CharacterPreviewStatBars({super.key, required this.stats});

  final Map<String, num> stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < kCharacterPreviewStatIds.length; i++) ...[
          if (i > 0) const SizedBox(height: SpacingConstants.xs),
          ComicCharacterStatBar(
            label: _previewStatLabel(kCharacterPreviewStatIds[i]),
            value: (stats[kCharacterPreviewStatIds[i]] ?? 0).toDouble(),
            maxForBar: _previewStatMax(kCharacterPreviewStatIds[i]),
            valueCaption: _previewStatCaption(
              kCharacterPreviewStatIds[i],
              stats,
            ),
            fillLight: _previewStatFillLight(kCharacterPreviewStatIds[i]),
            fillDark: _previewStatFillDark(kCharacterPreviewStatIds[i]),
          ),
        ],
      ],
    );
  }
}

/// Chunky outlined fill bar (comic / RPG character sheet).
class ComicCharacterStatBar extends StatelessWidget {
  const ComicCharacterStatBar({
    super.key,
    required this.label,
    required this.value,
    required this.maxForBar,
    required this.valueCaption,
    required this.fillLight,
    required this.fillDark,
  });

  final String label;
  final double value;
  final double maxForBar;
  final String valueCaption;
  final Color fillLight;
  final Color fillDark;

  @override
  Widget build(BuildContext context) {
    final t = maxForBar <= 0 ? 0.0 : (value / maxForBar).clamp(0.0, 1.0);
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w900,
      letterSpacing: 0.4,
      color: GameThemeConstants.outlineColor,
      fontSize: 10,
    );
    final valueStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w800,
      color: GameThemeConstants.primaryDark,
      fontSize: 10,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: labelStyle)),
            Text(valueCaption, style: valueStyle),
          ],
        ),
        const SizedBox(height: 3),
        SizedBox(
          height: 13,
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: GameThemeConstants.creamBackground.withValues(
                    alpha: 0.45,
                  ),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: GameThemeConstants.outlineColor,
                    width: GameThemeConstants.outlineThicknessSmall,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(2),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: t,
                      heightFactor: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [fillLight, fillDark],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: GameThemeConstants.outlineColor.withValues(
                                alpha: 0.12,
                              ),
                              offset: const Offset(0, 1),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _previewStatLabel(String id) {
  return switch (id) {
    'money' => 'CAPITAL',
    'riskTolerance' => 'RISK',
    'financialKnowledge' => 'FINANCE',
    'investmentHorizonRemaining' => 'RUNWAY',
    _ => id.toUpperCase(),
  };
}

double _previewStatMax(String id) {
  return switch (id) {
    'money' => 80000,
    'riskTolerance' => 100,
    'financialKnowledge' => 100,
    'investmentHorizonRemaining' => 45,
    _ => 100,
  };
}

String _previewStatCaption(String id, Map<String, num> stats) {
  final v = stats[id] ?? 0;
  return switch (id) {
    'money' => '\$${_formatMoney(v)}',
    'investmentHorizonRemaining' => '${v.toStringAsFixed(0)} yrs',
    _ => v.toStringAsFixed(0),
  };
}

String _formatMoney(num value) {
  final n = value.round();
  if (n >= 1000) {
    return '${(n / 1000).round()}k';
  }
  return n.toString();
}

Color _previewStatFillLight(String id) {
  return switch (id) {
    'money' => GameThemeConstants.warningLight,
    'riskTolerance' => GameThemeConstants.orangeLight,
    'financialKnowledge' => GameThemeConstants.primaryLight,
    'investmentHorizonRemaining' => GameThemeConstants.skyBlueLight,
    _ => GameThemeConstants.accentLight,
  };
}

Color _previewStatFillDark(String id) {
  return switch (id) {
    'money' => GameThemeConstants.warningDark,
    'riskTolerance' => GameThemeConstants.orangeDark,
    'financialKnowledge' => GameThemeConstants.primaryDark,
    'investmentHorizonRemaining' => GameThemeConstants.skyBlueDark,
    _ => GameThemeConstants.accentDark,
  };
}
