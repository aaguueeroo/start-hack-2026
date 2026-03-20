import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:start_hack_2026/core/constants/game_theme_constants.dart';
import 'package:start_hack_2026/core/constants/spacing_constants.dart';
import 'package:start_hack_2026/core/widgets/game_button.dart';
import 'package:start_hack_2026/core/widgets/game_card.dart';
import 'package:start_hack_2026/domain/entities/simulation_event.dart'
    show SimulationDataPoint, SimulationEvent, SimulationEventType;
import 'package:start_hack_2026/modules/multiplayer/controllers/multiplayer_controller.dart';
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
          onPressed: () async {
            await context.read<StoreController>().refreshFromGameState();
            if (context.mounted) context.pop();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () => context.push('/simulation-debug'),
            tooltip: 'Debug',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [GameThemeConstants.creamBackground, Color(0xFFF5EDE0)],
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
                        onPressed: () async {
                          await context
                              .read<StoreController>()
                              .refreshFromGameState();
                          if (context.mounted) context.pop();
                        },
                        variant: GameButtonVariant.primary,
                      ),
                    ],
                  ),
                ),
              );
            }
            return Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (_) {
                if (controller.status == SimulationStatus.running) {
                  controller.setAccelerating(true);
                }
              },
              onPointerUp: (_) => controller.setAccelerating(false),
              onPointerCancel: (_) => controller.setAccelerating(false),
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onDoubleTap: () {
                  if (controller.status == SimulationStatus.running) {
                    controller.skipToEnd();
                  }
                },
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(SpacingConstants.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Year ${controller.status == SimulationStatus.complete ? controller.currentYear - 1 : controller.currentYear}',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: SpacingConstants.sm),
                            if (controller.status == SimulationStatus.running)
                              Text(
                                'Simulation in progress...',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: GameThemeConstants.accentDark,
                                    ),
                              )
                            else if (controller.status ==
                                SimulationStatus.complete)
                              Text(
                                'Simulation Complete',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
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
                                currentYear:
                                    controller.status ==
                                        SimulationStatus.complete
                                    ? controller.currentYear - 1
                                    : controller.currentYear,
                              ),
                            ),
                            _YearEventsList(
                              events: controller.events,
                              currentYear:
                                  controller.status == SimulationStatus.complete
                                  ? controller.currentYear - 1
                                  : controller.currentYear,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (controller.status == SimulationStatus.complete)
                      Padding(
                        padding: const EdgeInsets.all(SpacingConstants.md),
                        child: GameButton(
                          label: controller.hasWon
                              ? 'View Victory'
                              : 'Continue',
                          icon: controller.hasWon
                              ? Icons.emoji_events
                              : Icons.store,
                          onPressed: () async {
                            final multiplayerController = context
                                .read<MultiplayerController>();
                            final storeController = context
                                .read<StoreController>();
                            await multiplayerController
                                .continueFromInvestorResults();
                            await storeController.refreshFromGameState();
                            if (!context.mounted) return;
                            if (controller.hasWon) {
                              context.pushReplacement('/game-won');
                            } else {
                              context.pop();
                            }
                          },
                          variant: GameButtonVariant.success,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _YearEventsList extends StatelessWidget {
  const _YearEventsList({required this.events, required this.currentYear});

  final List<SimulationEvent> events;
  final int currentYear;

  static const int _monthsPerYear = 12;

  List<SimulationEvent> _eventsForCurrentYear() {
    final yearStart = (currentYear - 1) * _monthsPerYear;
    final yearEnd = currentYear * _monthsPerYear;
    return events
        .where((e) => e.timestamp >= yearStart && e.timestamp < yearEnd)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  @override
  Widget build(BuildContext context) {
    final yearEvents = _eventsForCurrentYear();
    if (yearEvents.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: SpacingConstants.md),
        Text(
          'Events this year',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: SpacingConstants.sm),
        ...yearEvents.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: SpacingConstants.sm),
            child: _YearEventTile(event: e, currentYear: currentYear),
          ),
        ),
      ],
    );
  }
}

class _YearEventTile extends StatelessWidget {
  const _YearEventTile({required this.event, required this.currentYear});

  final SimulationEvent event;
  final int currentYear;

  static const int _monthsPerYear = 12;

  @override
  Widget build(BuildContext context) {
    final monthInYear = (event.timestamp - (currentYear - 1) * _monthsPerYear)
        .floor()
        .clamp(1, 12);
    return GameCard(
      child: Padding(
        padding: const EdgeInsets.all(SpacingConstants.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              _iconForType(event.type),
              size: 24,
              color: _colorForType(event.type),
            ),
            const SizedBox(width: SpacingConstants.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    event.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (event.description.isNotEmpty) ...[
                    const SizedBox(height: SpacingConstants.xs),
                    Text(
                      event.description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: SpacingConstants.xs),
                  Text(
                    'Month $monthInYear · Portfolio: \$${event.portfolioValueAtEvent.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: GameThemeConstants.accentDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
      case SimulationEventType.panicSell:
        return Icons.sell;
    }
  }

  Color _colorForType(SimulationEventType type) {
    switch (type) {
      case SimulationEventType.market:
        return GameThemeConstants.primaryDark;
      case SimulationEventType.character:
        return GameThemeConstants.accentDark;
      case SimulationEventType.world:
        return GameThemeConstants.warningDark;
      case SimulationEventType.panicSell:
        return GameThemeConstants.statNegative;
    }
  }
}

class _SimulationChart extends StatefulWidget {
  const _SimulationChart({
    required this.dataPoints,
    required this.events,
    required this.currentYear,
  });

  final List<SimulationDataPoint> dataPoints;
  final List<SimulationEvent> events;
  final int currentYear;

  @override
  State<_SimulationChart> createState() => _SimulationChartState();
}

class _SimulationChartState extends State<_SimulationChart> {
  static const int _monthsPerYear = 12;

  final GlobalKey _chartKey = GlobalKey();
  OverlayEntry? _eventOverlayEntry;

  void _showEventOverlay(SimulationEvent event, Offset globalMarkerPosition) {
    _hideEventOverlay();
    _eventOverlayEntry = OverlayEntry(
      builder: (overlayContext) => Positioned.fill(
        child: _EventPopupOverlay(
          event: event,
          markerPosition: globalMarkerPosition,
          onDismiss: _hideEventOverlay,
        ),
      ),
    );
    Overlay.of(context).insert(_eventOverlayEntry!);
  }

  void _hideEventOverlay() {
    _eventOverlayEntry?.remove();
    _eventOverlayEntry = null;
    setState(() {});
  }

  /// Returns data points and events for the current year only, with timestamps
  /// rebased to 0-11 (months within the year).
  ({List<FlSpot> spots, List<SimulationEvent> yearEvents})
  _filterCurrentYear() {
    final yearStart = (widget.currentYear - 1) * _monthsPerYear;
    final yearEnd = widget.currentYear * _monthsPerYear;
    final filteredPoints = widget.dataPoints
        .where((p) => p.timestamp >= yearStart && p.timestamp < yearEnd)
        .toList();
    final spots = filteredPoints
        .map((p) => FlSpot(p.timestamp - yearStart, p.value))
        .toList();
    final yearEvents = widget.events
        .where((e) => e.timestamp >= yearStart && e.timestamp < yearEnd)
        .toList();
    return (spots: spots, yearEvents: yearEvents);
  }

  /// Converts a spot's data coordinates to local pixel position within the
  /// chart's RenderBox. Matches fl_chart's layout (left: 40, bottom: 24).
  Offset _spotToLocalPosition({
    required FlSpot spot,
    required Size chartSize,
    required double minX,
    required double maxX,
    required double minY,
    required double maxY,
  }) {
    const double leftReserved = 40;
    const double bottomReserved = 24;
    final plotWidth = chartSize.width - leftReserved;
    final plotHeight = chartSize.height - bottomReserved;
    final xNorm = (spot.x - minX) / (maxX - minX);
    final yNorm = (spot.y - minY) / (maxY - minY);
    final pixelX = leftReserved + xNorm * plotWidth;
    final pixelY = (1 - yNorm) * plotHeight;
    return Offset(pixelX, pixelY);
  }

  /// Maps spot index to the event that occurred at that point (if any).
  Map<int, SimulationEvent> _buildEventSpotMap(
    List<FlSpot> spots,
    List<SimulationEvent> yearEvents,
  ) {
    final map = <int, SimulationEvent>{};
    final yearStart = (widget.currentYear - 1) * _monthsPerYear;
    for (final event in yearEvents) {
      if (spots.isEmpty) continue;
      final eventMonthInYear = event.timestamp - yearStart;
      var bestIdx = 0;
      var bestDist = (spots[0].x - eventMonthInYear).abs();
      for (var i = 1; i < spots.length; i++) {
        final d = (spots[i].x - eventMonthInYear).abs();
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
    if (widget.dataPoints.isEmpty) {
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
    final filtered = _filterCurrentYear();
    final spots = filtered.spots;
    if (spots.isEmpty) {
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
    final minVal = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxVal = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final minY = (minVal * 0.95).clamp(0.0, double.infinity).toDouble();
    final maxY = (maxVal * 1.05).toDouble();
    final maxX = _monthsPerYear.toDouble();
    final eventSpotMap = _buildEventSpotMap(spots, filtered.yearEvents);
    final eventSpotIndices = eventSpotMap.keys.toSet();

    return GameCard(
      child: Padding(
        padding: const EdgeInsets.all(SpacingConstants.sm),
        child: RepaintBoundary(
          key: _chartKey,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: maxX,
              minY: minY,
              maxY: maxY,
              lineTouchData: LineTouchData(
                enabled: true,
                handleBuiltInTouches: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    if (touchedSpots.isEmpty) return [];
                    final spot = touchedSpots.first;
                    if (eventSpotIndices.contains(spot.spotIndex)) {
                      return [];
                    }
                    return [
                      LineTooltipItem(
                        'Month ${(spot.x.toInt() + 1).clamp(1, 12)}\n'
                        '\$${spot.y.toStringAsFixed(0)}',
                        const TextStyle(
                          color: GameThemeConstants.creamSurface,
                          fontSize: 12,
                        ),
                      ),
                    ];
                  },
                  getTooltipColor: (_) => GameThemeConstants.darkNavy,
                  maxContentWidth: 180,
                  tooltipPadding: const EdgeInsets.symmetric(
                    horizontal: SpacingConstants.sm,
                    vertical: SpacingConstants.xs,
                  ),
                ),
                touchCallback:
                    (FlTouchEvent event, LineTouchResponse? response) {
                      if (response?.lineBarSpots == null ||
                          response!.lineBarSpots!.isEmpty) {
                        if (event is FlTapUpEvent || event is FlPanEndEvent) {
                          _hideEventOverlay();
                        }
                        return;
                      }
                      final spot = response.lineBarSpots!.first;
                      if (!eventSpotIndices.contains(spot.spotIndex)) {
                        if (event is FlTapUpEvent || event is FlPanEndEvent) {
                          _hideEventOverlay();
                        }
                        return;
                      }
                      final simulationEvent = eventSpotMap[spot.spotIndex];
                      if (simulationEvent == null) return;
                      if (event is FlTapDownEvent || event is FlPanDownEvent) {
                        final renderBox =
                            _chartKey.currentContext?.findRenderObject()
                                as RenderBox?;
                        if (renderBox != null) {
                          final localPos = _spotToLocalPosition(
                            spot: FlSpot(spot.x, spot.y),
                            chartSize: renderBox.size,
                            minX: 0,
                            maxX: maxX,
                            minY: minY,
                            maxY: maxY,
                          );
                          final globalPos = renderBox.localToGlobal(localPos);
                          _showEventOverlay(simulationEvent, globalPos);
                        }
                      }
                    },
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
                          eventSpotMap[index]?.type ??
                              SimulationEventType.world,
                        ),
                        strokeWidth: 2,
                        strokeColor: GameThemeConstants.creamSurface,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: GameThemeConstants.primaryDark.withValues(
                      alpha: 0.2,
                    ),
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
                    getTitlesWidget: (value, meta) {
                      final monthInYear = (value.toInt() + 1).clamp(1, 12);
                      return Text(
                        '$monthInYear',
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(show: true),
              borderData: FlBorderData(show: true),
            ),
            duration: const Duration(milliseconds: 150),
          ),
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
      case SimulationEventType.panicSell:
        return GameThemeConstants.statNegative;
    }
  }
}

class _EventPopupOverlay extends StatefulWidget {
  const _EventPopupOverlay({
    required this.event,
    required this.markerPosition,
    required this.onDismiss,
  });

  final SimulationEvent event;
  final Offset markerPosition;
  final VoidCallback onDismiss;

  @override
  State<_EventPopupOverlay> createState() => _EventPopupOverlayState();
}

class _EventPopupOverlayState extends State<_EventPopupOverlay> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Listener(
            onPointerUp: (_) => widget.onDismiss(),
            behavior: HitTestBehavior.translucent,
            child: const SizedBox.expand(),
          ),
        ),
        _EventPopup(event: widget.event, markerPosition: widget.markerPosition),
      ],
    );
  }
}

class _EventPopup extends StatelessWidget {
  const _EventPopup({required this.event, required this.markerPosition});

  final SimulationEvent event;
  final Offset markerPosition;

  static const double _arrowHeight = 12.0;
  static const double _popupWidth = 200.0;
  static const double _spacing = SpacingConstants.sm;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final markerCenterX = markerPosition.dx;
    var popupLeft = markerCenterX - _popupWidth / 2;
    popupLeft = popupLeft.clamp(
      SpacingConstants.md,
      screenWidth - _popupWidth - SpacingConstants.md,
    );
    final arrowCenterX = markerCenterX - popupLeft;
    final showAbove = markerPosition.dy < screenHeight / 2;
    return Positioned(
      left: popupLeft,
      top: showAbove ? null : markerPosition.dy - _spacing - _arrowHeight,
      bottom: showAbove ? screenHeight - markerPosition.dy - _spacing : null,
      width: _popupWidth,
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showAbove) ...[
              _EventPopupContent(event: event),
              SizedBox(
                height: _arrowHeight,
                child: CustomPaint(
                  painter: _EventPopupArrowPainter(
                    color: GameThemeConstants.creamSurface,
                    borderColor: GameThemeConstants.outlineColor,
                    arrowCenterX: arrowCenterX,
                    pointingDown: true,
                  ),
                ),
              ),
            ] else ...[
              SizedBox(
                height: _arrowHeight,
                child: CustomPaint(
                  painter: _EventPopupArrowPainter(
                    color: GameThemeConstants.creamSurface,
                    borderColor: GameThemeConstants.outlineColor,
                    arrowCenterX: arrowCenterX,
                    pointingDown: false,
                  ),
                ),
              ),
              _EventPopupContent(event: event),
            ],
          ],
        ),
      ),
    );
  }
}

class _EventPopupArrowPainter extends CustomPainter {
  _EventPopupArrowPainter({
    required this.color,
    required this.borderColor,
    required this.arrowCenterX,
    required this.pointingDown,
  });

  final Color color;
  final Color borderColor;
  final double arrowCenterX;
  final bool pointingDown;

  @override
  void paint(Canvas canvas, Size size) {
    const arrowWidth = 16.0;
    final path = Path();
    if (pointingDown) {
      path.moveTo(arrowCenterX - arrowWidth / 2, 0);
      path.lineTo(arrowCenterX + arrowWidth / 2, 0);
      path.lineTo(arrowCenterX, size.height);
      path.close();
    } else {
      path.moveTo(arrowCenterX - arrowWidth / 2, size.height);
      path.lineTo(arrowCenterX + arrowWidth / 2, size.height);
      path.lineTo(arrowCenterX, 0);
      path.close();
    }
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = GameThemeConstants.outlineThickness,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _EventPopupContent extends StatelessWidget {
  const _EventPopupContent({required this.event});

  final SimulationEvent event;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SpacingConstants.sm),
      decoration: BoxDecoration(
        color: GameThemeConstants.creamSurface,
        borderRadius: BorderRadius.circular(GameThemeConstants.radiusMedium),
        border: Border.all(
          color: GameThemeConstants.outlineColor,
          width: GameThemeConstants.outlineThickness,
        ),
        boxShadow: [
          BoxShadow(
            color: GameThemeConstants.outlineColor.withValues(alpha: 0.15),
            offset: const Offset(0, GameThemeConstants.bevelOffset),
            blurRadius: 0,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            event.title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: SpacingConstants.xs),
          Text(event.description, style: Theme.of(context).textTheme.bodySmall),
          if (event.type == SimulationEventType.panicSell &&
              event.panicSellAmount != null &&
              event.panicSellLoss != null) ...[
            const SizedBox(height: SpacingConstants.xs),
            Text(
              'Sold: \$${event.panicSellAmount}\n'
              'Loss: \$${event.panicSellLoss!.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: SpacingConstants.xs),
          Text(
            'Portfolio: \$${event.portfolioValueAtEvent.toStringAsFixed(0)}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
