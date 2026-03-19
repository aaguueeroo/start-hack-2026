import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:start_hack_2026/core/constants/game_theme_constants.dart';
import 'package:start_hack_2026/core/constants/spacing_constants.dart';
import 'package:start_hack_2026/core/widgets/game_button.dart';
import 'package:start_hack_2026/core/widgets/game_card.dart';
import 'package:start_hack_2026/engine/game_engine.dart';

class SimulationDebugScreen extends StatelessWidget {
  const SimulationDebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug'),
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
        child: Consumer<GameEngine>(
          builder: (context, gameEngine, _) {
            final portfolioHistory = gameEngine.portfolioHistory;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(SpacingConstants.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Simulation Debug',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: SpacingConstants.lg),
                  Text(
                    'Portfolio Evolution',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: SpacingConstants.md),
                  if (portfolioHistory.isEmpty)
                    GameCard(
                      child: Padding(
                        padding: const EdgeInsets.all(SpacingConstants.lg),
                        child: Text(
                          'No portfolio data yet. Start a game to see evolution.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: GameThemeConstants.outlineColorLight,
                              ),
                        ),
                      ),
                    )
                  else if (portfolioHistory.length < 2)
                    GameCard(
                      child: Padding(
                        padding: const EdgeInsets.all(SpacingConstants.lg),
                        child: Column(
                          children: [
                            Text(
                              'Year ${portfolioHistory.first.year}',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(
                              '\$${portfolioHistory.first.value.toStringAsFixed(0)}',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: GameThemeConstants.primaryDark,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    GameCard(
                      child: Padding(
                        padding: const EdgeInsets.all(SpacingConstants.md),
                        child: _PortfolioChart(dataPoints: portfolioHistory),
                      ),
                    ),
                  const SizedBox(height: SpacingConstants.xl),
                  GameButton(
                    label: 'Show Win Screen',
                    icon: Icons.emoji_events,
                    onPressed: () => context.pushReplacement('/game-won'),
                    variant: GameButtonVariant.success,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PortfolioChart extends StatelessWidget {
  const _PortfolioChart({required this.dataPoints});

  final List<PortfolioHistoryPoint> dataPoints;

  @override
  Widget build(BuildContext context) {
    final spots = dataPoints
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.value))
        .toList();
    final values = dataPoints.map((p) => p.value).toList();
    final minVal = values.reduce((a, b) => a < b ? a : b);
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    var minY = (minVal * 0.95).clamp(0.0, double.infinity).toDouble();
    var maxY = (maxVal * 1.05).toDouble();
    if (maxY <= minY) maxY = minY + 1;
    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (dataPoints.length - 1).toDouble(),
          minY: minY,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: GameThemeConstants.primaryDark,
              barWidth: 2,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                  radius: 3,
                  color: GameThemeConstants.primaryDark,
                  strokeWidth: GameThemeConstants.outlineThicknessSmall,
                  strokeColor: GameThemeConstants.outlineColor,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: GameThemeConstants.primaryDark.withValues(alpha: 0.2),
              ),
            ),
          ],
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    fontSize: 10,
                    color: GameThemeConstants.outlineColor,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 20,
                getTitlesWidget: (value, meta) {
                  final index = value.round();
                  if (index >= 0 && index < dataPoints.length) {
                    return Text(
                      'Y${dataPoints[index].year}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: GameThemeConstants.outlineColor,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: (maxY - minY) / 4,
            getDrawingHorizontalLine: (value) => FlLine(
              color: GameThemeConstants.outlineColor.withValues(alpha: 0.2),
              strokeWidth: 1,
            ),
            getDrawingVerticalLine: (value) => FlLine(
              color: GameThemeConstants.outlineColor.withValues(alpha: 0.2),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(
              color: GameThemeConstants.outlineColor,
              width: GameThemeConstants.outlineThicknessSmall,
            ),
          ),
        ),
        duration: const Duration(milliseconds: 150),
      ),
    );
  }
}
