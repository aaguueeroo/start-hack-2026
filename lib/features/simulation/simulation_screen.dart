import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:start_hack_2026/core/constants/game_theme_constants.dart';
import 'package:start_hack_2026/core/constants/spacing_constants.dart';
import 'package:start_hack_2026/core/widgets/game_button.dart';
import 'package:start_hack_2026/core/widgets/game_card.dart';
import 'package:start_hack_2026/core/widgets/game_key_factors_bar.dart';
import 'package:start_hack_2026/domain/entities/simulation_event.dart';
import 'package:start_hack_2026/engine/simulation_engine.dart';
import 'package:start_hack_2026/modules/simulation/controllers/simulation_controller.dart';
import 'package:start_hack_2026/modules/store/controllers/store_controller.dart';

class SimulationScreen extends StatefulWidget {
  const SimulationScreen({super.key});

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SimulationController>().startSimulation();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simulation'),
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
        child: Consumer<SimulationController>(
        builder: (context, controller, _) {
          if (controller.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(SpacingConstants.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      controller.errorMessage!,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: SpacingConstants.md),
                    GameButton(
                      label: 'Back to Store',
                      onPressed: () => context.pop(),
                      variant: GameButtonVariant.primary,
                    ),
                  ],
                ),
              ),
            );
          }
          final storeController = context.watch<StoreController>();
          return SingleChildScrollView(
            padding: const EdgeInsets.all(SpacingConstants.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GameKeyFactorsBar(stats: storeController.stats),
                Text(
                  'Year ${controller.currentYear}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: SpacingConstants.sm),
                if (controller.status == SimulationStatus.running)
                  Text(
                    'Simulation in progress...',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: GameThemeConstants.accentDark,
                        ),
                  )
                else if (controller.status == SimulationStatus.complete)
                  Text(
                    'Simulation Complete',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: GameThemeConstants.successDark,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                if (controller.getActiveEvents().isNotEmpty) ...[
                  const SizedBox(height: SpacingConstants.md),
                  _ActiveEventsChips(events: controller.getActiveEvents()),
                ],
                const SizedBox(height: SpacingConstants.lg),
                SizedBox(
                  height: 250,
                  child: _SimulationChart(
                    dataPoints: controller.dataPoints,
                    events: controller.events,
                  ),
                ),
                const SizedBox(height: SpacingConstants.xl),
                if (controller.status == SimulationStatus.complete)
                  GameButton(
                    label: 'Prepare for Next Year',
                    icon: Icons.store,
                    onPressed: () => context.pop(),
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

class _ActiveEventsChips extends StatelessWidget {
  const _ActiveEventsChips({required this.events});

  final List<ActiveEvent> events;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: SpacingConstants.sm,
      runSpacing: SpacingConstants.xs,
      children: events
          .map(
            (e) => Chip(
              avatar: Icon(
                _iconForType(e.type),
                size: 18,
                color: _colorForImpact(e.marketImpact),
              ),
              label: Text(
                '${e.title} ${e.impactDescription}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              backgroundColor: _colorForImpact(e.marketImpact).withValues(
                alpha: 0.2,
              ),
              side: BorderSide(
                color: _colorForImpact(e.marketImpact),
                width: 1,
              ),
            ),
          )
          .toList(),
    );
  }

  IconData _iconForType(SimulationEventType type) {
    switch (type) {
      case SimulationEventType.market:
        return Icons.trending_up;
      case SimulationEventType.character:
        return Icons.person;
      case SimulationEventType.world:
        return Icons.public;
    }
  }

  Color _colorForImpact(double impact) {
    if (impact > 1) return GameThemeConstants.statPositive;
    if (impact < 1) return GameThemeConstants.statNegative;
    return GameThemeConstants.outlineColor;
  }
}

class _SimulationChart extends StatelessWidget {
  const _SimulationChart({
    required this.dataPoints,
    required this.events,
  });

  final List<SimulationDataPoint> dataPoints;
  final List<SimulationEvent> events;

  /// Maps spot index to the event that occurred at that point (if any).
  Map<int, SimulationEvent> _buildEventSpotMap() {
    final map = <int, SimulationEvent>{};
    for (final event in events) {
      if (dataPoints.isEmpty) continue;
      var bestIdx = 0;
      var bestDist = (dataPoints[0].timestamp - event.timestamp).abs();
      for (var i = 1; i < dataPoints.length; i++) {
        final d = (dataPoints[i].timestamp - event.timestamp).abs();
        if (d < bestDist) {
          bestDist = d;
          bestIdx = i;
        }
      }
      map[bestIdx] = event;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    if (dataPoints.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(SpacingConstants.radiusMd),
        ),
        child: Center(
          child: Text(
            'Waiting for data...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      );
    }
    final spots = dataPoints.map((p) => FlSpot(p.timestamp, p.value)).toList();
    final minVal =
        dataPoints.map((p) => p.value).reduce((a, b) => a < b ? a : b);
    final maxVal =
        dataPoints.map((p) => p.value).reduce((a, b) => a > b ? a : b);
    final minY = (minVal * 0.95).clamp(0.0, double.infinity).toDouble();
    final maxY = (maxVal * 1.05).toDouble();
    final eventSpotMap = _buildEventSpotMap();
    final eventSpotIndices = eventSpotMap.keys.toSet();

    return GameCard(
      child: Padding(
        padding: const EdgeInsets.all(SpacingConstants.sm),
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: 12,
            minY: minY,
            maxY: maxY,
            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    final event = eventSpotMap[spot.spotIndex];
                    if (event != null) {
                      return LineTooltipItem(
                        '${event.title}\n${event.description}\n\n'
                        'Portfolio: \$${event.portfolioValueAtEvent.toStringAsFixed(0)}',
                        TextStyle(
                          color: GameThemeConstants.creamSurface,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    }
                    return LineTooltipItem(
                      'Month ${spot.x.toStringAsFixed(0)}\n'
                      '\$${spot.y.toStringAsFixed(0)}',
                      TextStyle(
                        color: GameThemeConstants.creamSurface,
                        fontSize: 12,
                      ),
                    );
                  }).toList();
                },
                getTooltipColor: (_) => GameThemeConstants.darkNavy,
                maxContentWidth: 180,
                tooltipPadding: const EdgeInsets.symmetric(
                  horizontal: SpacingConstants.sm,
                  vertical: SpacingConstants.xs,
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: GameThemeConstants.primaryDark,
                barWidth: 2,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    final isEvent = eventSpotIndices.contains(index);
                    return FlDotCirclePainter(
                      radius: isEvent ? 5 : 0,
                      color: _eventColor(
                        eventSpotMap[index]?.type ?? SimulationEventType.world,
                      ),
                      strokeWidth: 2,
                      strokeColor: GameThemeConstants.creamSurface,
                    );
                  },
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
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) => Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  getTitlesWidget: (value, meta) => Text(
                    '${value.toInt()}m',
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(show: true),
            borderData: FlBorderData(show: true),
          ),
          duration: const Duration(milliseconds: 150),
        ),
      ),
    );
  }

  Color _eventColor(SimulationEventType type) {
    switch (type) {
      case SimulationEventType.market:
        return GameThemeConstants.primaryDark;
      case SimulationEventType.character:
        return GameThemeConstants.accentDark;
      case SimulationEventType.world:
        return GameThemeConstants.warningDark;
    }
  }
}

