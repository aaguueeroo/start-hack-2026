import 'package:flutter/material.dart';
import 'package:start_hack_2026/core/constants/game_theme_constants.dart';
import 'package:start_hack_2026/core/constants/spacing_constants.dart';

const _keyFactorIds = {
  'annualIncome',
  'riskTolerance',
  'return',
  'volatility',
};

const _displayNames = {
  'annualIncome': 'Annual Income',
  'riskTolerance': 'Risk Tolerance',
  'return': 'Expected Return',
  'volatility': 'Volatility',
};

const _icons = {
  'annualIncome': Icons.payments,
  'riskTolerance': Icons.psychology,
  'return': Icons.trending_up,
  'volatility': Icons.show_chart,
};

/// Displays key real-world factors that influence portfolio outcomes.
/// Excludes internal/programming factors like incomePerTick, ticksPerMonth.
class GameKeyFactorsBar extends StatelessWidget {
  const GameKeyFactorsBar({
    super.key,
    required this.stats,
  });

  final Map<String, num> stats;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    for (final id in _keyFactorIds) {
      final value = stats[id];
      if (value == null) continue;
      items.add(_FactorChip(
        label: _displayNames[id]!,
        value: _formatValue(id, value),
        icon: _icons[id] ?? Icons.info,
      ));
    }
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: SpacingConstants.md),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: items
              .expand((w) => [w, const SizedBox(width: SpacingConstants.sm)])
              .toList()
            ..removeLast(),
        ),
      ),
    );
  }

  String _formatValue(String id, num value) {
    switch (id) {
      case 'annualIncome':
        return '\$${value.toStringAsFixed(0)}';
      case 'riskTolerance':
        return '${value.toStringAsFixed(0)}%';
      case 'return':
        return '${value >= 0 ? '+' : ''}${value.toStringAsFixed(1)}%';
      case 'volatility':
        return '${value.toStringAsFixed(1)}%';
      default:
        return value.toStringAsFixed(1);
    }
  }
}

class _FactorChip extends StatelessWidget {
  const _FactorChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingConstants.sm,
        vertical: SpacingConstants.xs,
      ),
      decoration: BoxDecoration(
        color: GameThemeConstants.creamSurface,
        borderRadius: BorderRadius.circular(SpacingConstants.gameRadiusSm),
        border: Border.all(
          color: GameThemeConstants.outlineColor,
          width: GameThemeConstants.outlineThicknessSmall,
        ),
        boxShadow: [
          BoxShadow(
            color: GameThemeConstants.outlineColor.withValues(alpha: 0.1),
            offset: const Offset(0, 1),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: GameThemeConstants.primaryDark),
          const SizedBox(width: SpacingConstants.xs),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: GameThemeConstants.outlineColorLight,
                    ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: GameThemeConstants.primaryDark,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
