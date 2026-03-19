import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:start_hack_2026/core/constants/game_theme_constants.dart';
import 'package:start_hack_2026/core/constants/spacing_constants.dart';
import 'package:start_hack_2026/core/widgets/game_button.dart';
import 'package:start_hack_2026/core/widgets/game_card.dart';
import 'package:start_hack_2026/domain/entities/simulation_event.dart';
import 'package:start_hack_2026/modules/simulation/controllers/simulation_controller.dart';

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
          return SingleChildScrollView(
            padding: const EdgeInsets.all(SpacingConstants.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                const SizedBox(height: SpacingConstants.lg),
                SizedBox(
                  height: 250,
                  child: _SimulationChart(
                    dataPoints: controller.dataPoints,
                    events: controller.events,
                  ),
                ),
                if (controller.events.isNotEmpty) ...[
                  const SizedBox(height: SpacingConstants.lg),
                  Text(
                    'Events',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: SpacingConstants.sm),
                  ...controller.events.map(
                    (e) => _EventMarker(
                      event: e,
                      maxTimestamp: 12,
                    ),
                  ),
                ],
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

class _SimulationChart extends StatelessWidget {
  const _SimulationChart({
    required this.dataPoints,
    required this.events,
  });

  final List<SimulationDataPoint> dataPoints;
  final List<SimulationEvent> events;

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
    final spots = dataPoints
        .map((p) => FlSpot(p.timestamp, p.value))
        .toList();
    final minVal = dataPoints.map((p) => p.value).reduce((a, b) => a < b ? a : b);
    final maxVal = dataPoints.map((p) => p.value).reduce((a, b) => a > b ? a : b);
    final minY = (minVal * 0.95).clamp(0.0, double.infinity).toDouble();
    final maxY = (maxVal * 1.05).toDouble();
    return GameCard(
      child: Padding(
        padding: const EdgeInsets.all(SpacingConstants.sm),
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: 12,
            minY: minY,
            maxY: maxY,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: GameThemeConstants.primaryDark,
                barWidth: 2,
                dotData: const FlDotData(show: false),
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
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(show: true),
            borderData: FlBorderData(show: true),
          ),
          duration: const Duration(milliseconds: 150),
        ),
      ),
    );
  }
}

class _EventMarker extends StatelessWidget {
  const _EventMarker({
    required this.event,
    required this.maxTimestamp,
  });

  final SimulationEvent event;
  final double maxTimestamp;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SpacingConstants.sm),
      child: GameCard(
        onTap: () {
          showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(event.title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.description),
                  const SizedBox(height: SpacingConstants.sm),
                  Text(
                    'Portfolio: \$${event.portfolioValueAtEvent.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        },
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: _eventColor(event.type),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: SpacingConstants.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    'Month ${event.timestamp.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: GameThemeConstants.outlineColorLight,
                        ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.info_outline, size: 20),
          ],
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
