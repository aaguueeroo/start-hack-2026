import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:start_hack_2026/core/constants/game_theme_constants.dart';
import 'package:start_hack_2026/core/constants/spacing_constants.dart';
import 'package:start_hack_2026/core/widgets/game_button.dart';
import 'package:start_hack_2026/core/widgets/game_card.dart';
import 'package:start_hack_2026/core/widgets/game_key_factors_bar.dart';
import 'package:start_hack_2026/core/widgets/portfolio_evolution_chart.dart';
import 'package:start_hack_2026/engine/game_engine.dart';
import 'package:start_hack_2026/modules/store/controllers/store_controller.dart';

class GameWonScreen extends StatelessWidget {
  const GameWonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        child: SafeArea(
          child: Consumer2<GameEngine, StoreController>(
            builder: (context, gameEngine, storeController, _) {
              final state = gameEngine.state;
              if (state == null) {
                return Center(
                  child: GameButton(
                    label: 'Back to Home',
                    onPressed: () => context.go('/'),
                    variant: GameButtonVariant.primary,
                  ),
                );
              }
              final character = state.character;
              final winConditions = character.winConditions;
              final portfolioHistory = state.portfolioHistory;
              final finalValue = portfolioHistory.isNotEmpty
                  ? portfolioHistory.last.value
                  : 0.0;
              final startValue = portfolioHistory.isNotEmpty
                  ? portfolioHistory.first.value
                  : 0.0;
              final growthPercent = startValue > 0
                  ? ((finalValue - startValue) / startValue * 100)
                  : 0.0;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _WinHeader(
                      winMessage: winConditions?.winMessage ?? 'You won!',
                      characterName: character.name,
                    ),
                    const SizedBox(height: 24),
                    GameKeyFactorsBar(stats: storeController.stats),
                    const SizedBox(height: 16),
                    _PortfolioEvolutionSection(
                      portfolioHistory: portfolioHistory,
                      finalValue: finalValue,
                      yearsPlayed: portfolioHistory.length,
                      growthPercent: growthPercent,
                    ),
                    const SizedBox(height: 24),
                    GameButton(
                      label: 'Back to Home',
                      icon: Icons.home,
                      onPressed: () => context.go('/'),
                      variant: GameButtonVariant.success,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _WinHeader extends StatelessWidget {
  const _WinHeader({
    required this.winMessage,
    required this.characterName,
  });

  final String winMessage;
  final String characterName;

  static const String _trophyAssetPath = 'assets/images/image.png';

  @override
  Widget build(BuildContext context) {
    return GameCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Image.asset(
              _trophyAssetPath,
              height: 120,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.emoji_events,
                size: 64,
                color: GameThemeConstants.successDark,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Victory!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: GameThemeConstants.successDark,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              winMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: GameThemeConstants.outlineColor,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '— $characterName',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: GameThemeConstants.outlineColorLight,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PortfolioEvolutionSection extends StatelessWidget {
  const _PortfolioEvolutionSection({
    required this.portfolioHistory,
    required this.finalValue,
    required this.yearsPlayed,
    required this.growthPercent,
  });

  final List<PortfolioHistoryPoint> portfolioHistory;
  final double finalValue;
  final int yearsPlayed;
  final double growthPercent;

  @override
  Widget build(BuildContext context) {
    return GameCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Portfolio Evolution',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            PortfolioEvolutionChart(dataPoints: portfolioHistory),
            const SizedBox(height: 16),
            _FinalStatsRow(
              finalValue: finalValue,
              yearsPlayed: yearsPlayed,
              growthPercent: growthPercent,
            ),
          ],
        ),
      ),
    );
  }
}

class _FinalStatsRow extends StatelessWidget {
  const _FinalStatsRow({
    required this.finalValue,
    required this.yearsPlayed,
    required this.growthPercent,
  });

  final double finalValue;
  final int yearsPlayed;
  final double growthPercent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatChip(
            label: 'Final Value',
            value: '\$${finalValue.toStringAsFixed(0)}',
            icon: Icons.account_balance_wallet,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatChip(
            label: 'Years',
            value: '$yearsPlayed',
            icon: Icons.calendar_today,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatChip(
            label: 'Growth',
            value: '${growthPercent >= 0 ? '+' : ''}${growthPercent.toStringAsFixed(1)}%',
            icon: Icons.trending_up,
            isPositive: growthPercent >= 0,
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    this.isPositive,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool? isPositive;

  @override
  Widget build(BuildContext context) {
    final valueColor = isPositive == null
        ? GameThemeConstants.primaryDark
        : isPositive!
            ? GameThemeConstants.statPositive
            : GameThemeConstants.statNegative;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: GameThemeConstants.creamSurface,
        borderRadius: BorderRadius.circular(SpacingConstants.gameRadiusSm),
        border: Border.all(
          color: GameThemeConstants.outlineColor,
          width: GameThemeConstants.outlineThicknessSmall,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: GameThemeConstants.primaryDark),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: GameThemeConstants.outlineColorLight,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                ),
          ),
        ],
      ),
    );
  }
}
