import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:start_hack_2026/core/constants/game_theme_constants.dart';
import 'package:start_hack_2026/engine/game_engine.dart';

/// Portfolio evolution chart matching the store screen overlay.
/// Shows year-by-year portfolio value from the beginning of the game.
class PortfolioEvolutionChart extends StatelessWidget {
  const PortfolioEvolutionChart({
    super.key,
    required this.dataPoints,
    this.height = 240,
  });

  final List<PortfolioHistoryPoint> dataPoints;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (dataPoints.length < 2) {
      return SizedBox(
        height: height,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.show_chart,
                size: 40,
                color: GameThemeConstants.outlineColorLight,
              ),
              const SizedBox(height: 8),
              Text(
                dataPoints.isEmpty
                    ? 'No portfolio data'
                    : 'Year ${dataPoints.first.year}: \$${dataPoints.first.value.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: GameThemeConstants.outlineColorLight,
                    ),
              ),
            ],
          ),
        ),
      );
    }
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
      height: height,
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
                  style: TextStyle(
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
                      style: TextStyle(
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
