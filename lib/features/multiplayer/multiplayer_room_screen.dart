import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:start_hack_2026/core/constants/game_theme_constants.dart';
import 'package:start_hack_2026/core/constants/spacing_constants.dart';
import 'package:start_hack_2026/core/widgets/game_button.dart';
import 'package:start_hack_2026/core/widgets/game_card.dart';
import 'package:start_hack_2026/domain/entities/multiplayer.dart';
import 'package:start_hack_2026/domain/entities/simulation_event.dart';
import 'package:start_hack_2026/modules/game/controllers/game_controller.dart';
import 'package:start_hack_2026/modules/multiplayer/controllers/multiplayer_controller.dart';
import 'package:start_hack_2026/modules/simulation/controllers/simulation_controller.dart';

class MultiplayerRoomScreen extends StatefulWidget {
  const MultiplayerRoomScreen({super.key});

  @override
  State<MultiplayerRoomScreen> createState() => _MultiplayerRoomScreenState();
}

class _MultiplayerRoomScreenState extends State<MultiplayerRoomScreen> {
  final Set<String> _selectedMarketActionKeys = <String>{};
  String? _selectionRoundKey;
  bool _isSubmittingSelectedEvents = false;

  Future<void> _openInvestorStore(
    BuildContext context,
    MultiplayerController multiplayerController,
  ) async {
    final simulationController = context.read<SimulationController>();
    final forcedEvents = multiplayerController.getRoundEventPayloads();
    simulationController.configureForcedEventsForNextSimulation(forcedEvents);
    simulationController.configureMultiplayerReporter((
      dataPoints,
      events,
      isComplete,
      lastPortfolioValue,
    ) {
      return multiplayerController.syncSimulationSnapshot(
        dataPoints: dataPoints,
        events: events,
        isComplete: isComplete,
        lastPortfolioValue: lastPortfolioValue,
      );
    });
    if (context.mounted) {
      context.push('/store');
    }
  }

  String _eventSelectionKey(Map<String, dynamic> event) {
    final title = (event['title'] as String?) ?? '';
    final description = (event['description'] as String?) ?? '';
    final impact = ((event['marketImpact'] as num?)?.toDouble() ?? 1.0)
        .toStringAsFixed(4);
    return '$title|$description|$impact';
  }

  int _stableEventScore(
    Map<String, dynamic> event,
    String roomId,
    int roundNumber,
  ) {
    final title = (event['title'] as String?) ?? '';
    return Object.hash(roomId, roundNumber, title);
  }

  List<Map<String, dynamic>> _pickMarketActionsForRound(
    List<Map<String, dynamic>> catalog,
    String roomId,
    int roundNumber,
  ) {
    final sorted = List<Map<String, dynamic>>.from(catalog)
      ..sort(
        (a, b) => _stableEventScore(
          a,
          roomId,
          roundNumber,
        ).compareTo(_stableEventScore(b, roomId, roundNumber)),
      );
    return sorted.take(2).toList(growable: false);
  }

  void _syncSelectionRound(String roomId, int roundNumber) {
    final roundKey = '$roomId#$roundNumber';
    if (_selectionRoundKey == roundKey) return;
    _selectionRoundKey = roundKey;
    _selectedMarketActionKeys.clear();
  }

  void _toggleMarketActionSelection(String eventKey) {
    setState(() {
      if (_selectedMarketActionKeys.contains(eventKey)) {
        _selectedMarketActionKeys.remove(eventKey);
      } else {
        _selectedMarketActionKeys.add(eventKey);
      }
    });
  }

  Future<void> _submitSelectedEventsAndFinishTurn({
    required MultiplayerController controller,
    required List<Map<String, dynamic>> selectedEvents,
  }) async {
    if (_isSubmittingSelectedEvents) return;
    setState(() => _isSubmittingSelectedEvents = true);
    controller.clearError();
    try {
      for (final event in selectedEvents) {
        await controller.launchEvent(event);
        if (controller.errorMessage != null) return;
      }
      await controller.finishMarketTurn();
      if (controller.errorMessage != null) return;
      if (!mounted) return;
      setState(() => _selectedMarketActionKeys.clear());
    } finally {
      if (mounted) {
        setState(() => _isSubmittingSelectedEvents = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomCode =
        context.watch<MultiplayerController>().room?.roomCode ??
        'Multiplayer Room';
    return Scaffold(
      appBar: AppBar(title: Text(roomCode)),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              GameThemeConstants.creamBackground,
              GameThemeConstants.creamBackground,
            ],
          ),
        ),
        child: Consumer2<MultiplayerController, GameController>(
          builder: (context, controller, gameController, _) {
            final room = controller.room;
            if (room == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(SpacingConstants.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('No room is currently active.'),
                      const SizedBox(height: SpacingConstants.md),
                      GameButton(
                        label: 'Back',
                        onPressed: context.pop,
                        variant: GameButtonVariant.primary,
                      ),
                    ],
                  ),
                ),
              );
            }

            final currentUserId = controller.currentUserId;
            final activeRoleLabel = controller.selectedRole?.name ?? '-';
            final roundEvents = controller.roundEvents;
            final hasRoundEvents = roundEvents.isNotEmpty;
            final hasLocalGame = gameController.gameEngine.state != null;
            final playerCount = controller.players.length;
            final hasBothPlayers = playerCount == 2;
            final status = room.status;
            final isMarketTurn = status == MultiplayerRoomStatus.marketTurn;
            final isInvestorTurn = status == MultiplayerRoomStatus.investorTurn;
            final isSimulating = status == MultiplayerRoomStatus.simulating;
            final isResultsReady = status == MultiplayerRoomStatus.resultsReady;
            final isWaiting = status == MultiplayerRoomStatus.waiting;
            final isInvestorBlockedWaiting =
                !controller.isMarket && isMarketTurn;
            final canFinishMarketTurn =
                controller.isMarket &&
                hasBothPlayers &&
                isMarketTurn &&
                !_isSubmittingSelectedEvents &&
                !controller.isBusy;
            final canStartMatch =
                isWaiting &&
                hasBothPlayers &&
                !controller.isBusy &&
                controller.isMarket;
            final marketActionCards = _pickMarketActionsForRound(
              controller.eventsCatalog,
              room.id,
              room.currentRound,
            );
            _syncSelectionRound(room.id, room.currentRound);
            final selectedMarketActions = marketActionCards
                .where(
                  (event) => _selectedMarketActionKeys.contains(
                    _eventSelectionKey(event),
                  ),
                )
                .toList(growable: false);
            final hasAtLeastOneActionSelected =
                selectedMarketActions.isNotEmpty;
            final roundResult = controller.roundResult;

            return Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(SpacingConstants.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (controller.errorMessage != null) ...[
                        GameCard(
                          child: Text(
                            controller.errorMessage!,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: GameThemeConstants.dangerDark,
                                ),
                          ),
                        ),
                        const SizedBox(height: SpacingConstants.md),
                      ],
                      GameCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Room ${room.roomCode}',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: SpacingConstants.xs),
                            Text('Round: ${room.currentRound}'),
                            Text('Your role: $activeRoleLabel'),
                            Text('Players connected: $playerCount/2'),
                          ],
                        ),
                      ),
                      const SizedBox(height: SpacingConstants.md),
                      GameCard(
                        child: Text(
                          isWaiting
                              ? (playerCount < 2
                                    ? 'Waiting for second player to join...'
                                    : controller.isMarket
                                    ? 'Both players are ready. Press Start to begin.'
                                    : 'Waiting for market to start...')
                              : playerCount < 2
                              ? 'Waiting for second player to join...'
                              : isMarketTurn
                              ? (controller.isMarket
                                    ? 'Your turn: choose market events, then end turn.'
                                    : 'The Market is choosing actions... please wait.')
                              : isInvestorTurn
                              ? (controller.isMarket
                                    ? 'Waiting for Investor actions and simulation start.'
                                    : 'Your turn: open store and then run simulation.')
                              : isSimulating
                              ? (controller.isMarket
                                    ? 'Simulation running... viewing investor live data.'
                                    : 'Simulation running...')
                              : isResultsReady
                              ? (controller.isMarket
                                    ? 'Results ready. Move to next round when ready.'
                                    : 'Results ready. Waiting for Market to continue.')
                              : 'Waiting for room state...',
                        ),
                      ),
                      const SizedBox(height: SpacingConstants.md),
                      GameCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Players',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: SpacingConstants.sm),
                            ...controller.players.map(
                              (player) => Padding(
                                padding: const EdgeInsets.only(
                                  bottom: SpacingConstants.xs,
                                ),
                                child: Text(
                                  '${player.role.name.toUpperCase()} '
                                  '${player.userId == currentUserId ? '(You)' : ''}',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: SpacingConstants.md),
                      if (isWaiting && !controller.isMarket && !hasLocalGame)
                        GameCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Investor must choose a character type before starting.',
                              ),
                              const SizedBox(height: SpacingConstants.sm),
                              GameButton(
                                label: 'Choose Character Type',
                                icon: Icons.person_add,
                                variant: GameButtonVariant.primary,
                                onPressed: () => context.push(
                                  '/character-selection?from=multiplayer',
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (isWaiting && controller.isMarket)
                        GameButton(
                          label: 'Start',
                          icon: Icons.play_arrow,
                          variant: GameButtonVariant.success,
                          onPressed: canStartMatch
                              ? () => controller.startMatch()
                              : null,
                        ),
                      if (!isWaiting) ...[
                        const SizedBox(height: SpacingConstants.md),
                        if (controller.isMarket) ...[
                          GameCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Round Events',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: SpacingConstants.sm),
                                if (!hasRoundEvents)
                                  const Text(
                                    'No events launched for this round yet.',
                                  ),
                                ...roundEvents.map(
                                  (event) => Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: SpacingConstants.xs,
                                    ),
                                    child: Text(
                                      '${event.launchOrder}. '
                                      '${event.eventPayload['title'] ?? 'Event'}',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: SpacingConstants.md),
                        ],
                        if (controller.isMarket && isMarketTurn) ...[
                          Text(
                            'Market Controls',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: SpacingConstants.sm),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: marketActionCards.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: SpacingConstants.sm,
                                  mainAxisSpacing: SpacingConstants.sm,
                                  childAspectRatio: 0.72,
                                ),
                            itemBuilder: (context, index) {
                              final eventConfig = marketActionCards[index];
                              final eventKey = _eventSelectionKey(eventConfig);
                              return _MarketEventTile(
                                eventConfig: eventConfig,
                                isBusy:
                                    controller.isBusy ||
                                    _isSubmittingSelectedEvents,
                                isSelected: _selectedMarketActionKeys.contains(
                                  eventKey,
                                ),
                                onToggleSelected: () =>
                                    _toggleMarketActionSelection(eventKey),
                              );
                            },
                          ),
                          const SizedBox(height: SpacingConstants.sm),
                          GameButton(
                            label: 'Send Events & End Turn',
                            icon: Icons.skip_next,
                            variant: GameButtonVariant.warning,
                            onPressed:
                                !canFinishMarketTurn ||
                                    !hasAtLeastOneActionSelected
                                ? null
                                : () => _submitSelectedEventsAndFinishTurn(
                                    controller: controller,
                                    selectedEvents: selectedMarketActions,
                                  ),
                          ),
                        ],
                        const SizedBox(height: SpacingConstants.md),
                        if (!controller.isMarket && !hasLocalGame)
                          GameCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'No local character selected. This device needs a '
                                  'portfolio profile before simulation.',
                                ),
                                const SizedBox(height: SpacingConstants.sm),
                                GameButton(
                                  label: 'Choose Character',
                                  icon: Icons.person_add,
                                  variant: GameButtonVariant.primary,
                                  onPressed: () => context.push(
                                    '/character-selection?from=multiplayer',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (!controller.isMarket &&
                            isInvestorTurn &&
                            hasRoundEvents &&
                            hasLocalGame)
                          GameButton(
                            label: 'Go To Store',
                            icon: Icons.store,
                            variant: GameButtonVariant.success,
                            onPressed: () =>
                                _openInvestorStore(context, controller),
                          ),
                        if (!hasRoundEvents)
                          GameCard(
                            child: Text(
                              controller.isMarket && isMarketTurn
                                  ? 'Launch at least one event before ending market turn.'
                                  : 'Waiting for Market to launch events for this round.',
                            ),
                          ),
                        if (controller.isMarket &&
                            (isInvestorTurn || isSimulating || isResultsReady))
                          const GameCard(
                            child: Text('Waiting for investor data graph...'),
                          ),
                        if (controller.isMarket &&
                            (isInvestorTurn || isSimulating || isResultsReady))
                          GameCard(
                            child: SizedBox(
                              height: 250,
                              child: _SharedSimulationChart(
                                dataPoints: roundResult?.dataPoints ?? const [],
                                events: roundResult?.events ?? const [],
                              ),
                            ),
                          ),
                        const SizedBox(height: SpacingConstants.md),
                      ],
                    ],
                  ),
                ),
                if (isInvestorBlockedWaiting)
                  Positioned.fill(
                    child: AbsorbPointer(
                      absorbing: true,
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.35),
                        alignment: Alignment.center,
                        child: GameCard(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              CircularProgressIndicator(),
                              SizedBox(height: SpacingConstants.sm),
                              Text('Waiting for Market to choose actions...'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SharedSimulationChart extends StatelessWidget {
  const _SharedSimulationChart({
    required this.dataPoints,
    required this.events,
  });

  final List<SimulationDataPoint> dataPoints;
  final List<SimulationEvent> events;

  @override
  Widget build(BuildContext context) {
    if (dataPoints.isEmpty) {
      return const Center(child: Text('Waiting for simulation data...'));
    }

    final spots = dataPoints.map((p) => FlSpot(p.timestamp, p.value)).toList();
    final eventSpotMap = <int, SimulationEvent>{};
    for (final event in events) {
      if (spots.isEmpty) continue;
      var bestIdx = 0;
      var bestDist = (spots[0].x - event.timestamp).abs();
      for (var i = 1; i < spots.length; i++) {
        final dist = (spots[i].x - event.timestamp).abs();
        if (dist < bestDist) {
          bestDist = dist;
          bestIdx = i;
        }
      }
      eventSpotMap[bestIdx] = event;
    }
    final eventSpotIndices = eventSpotMap.keys.toSet();
    final minVal = dataPoints
        .map((p) => p.value)
        .reduce((a, b) => a < b ? a : b);
    final maxVal = dataPoints
        .map((p) => p.value)
        .reduce((a, b) => a > b ? a : b);
    final minY = (minVal * 0.95).clamp(0.0, double.infinity).toDouble();
    final maxY = (maxVal * 1.05).toDouble();
    final maxTimestamp = dataPoints
        .map((p) => p.timestamp)
        .reduce((a, b) => a > b ? a : b);
    final maxX = (maxTimestamp + 1).clamp(12.0, double.infinity);

    return LineChart(
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
        ),
        gridData: FlGridData(
          show: true,
          getDrawingHorizontalLine: (_) => FlLine(
            color: GameThemeConstants.outlineColorLight.withValues(alpha: 0.2),
            strokeWidth: 1,
          ),
          getDrawingVerticalLine: (_) => FlLine(
            color: GameThemeConstants.outlineColorLight.withValues(alpha: 0.2),
            strokeWidth: 1,
          ),
        ),
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
                final month = (value.toInt() + 1).clamp(1, 12);
                return Text('$month', style: const TextStyle(fontSize: 10));
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
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: GameThemeConstants.primaryDark,
            barWidth: 2,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, idx) {
                final hasEvent = eventSpotIndices.contains(idx);
                return FlDotCirclePainter(
                  radius: hasEvent ? 5 : 0,
                  color: _eventColor(
                    eventSpotMap[idx]?.type ?? SimulationEventType.world,
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
        borderData: FlBorderData(show: true),
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

class _MarketEventTile extends StatelessWidget {
  const _MarketEventTile({
    required this.eventConfig,
    required this.onToggleSelected,
    required this.isSelected,
    required this.isBusy,
  });

  final Map<String, dynamic> eventConfig;
  final VoidCallback onToggleSelected;
  final bool isSelected;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final title = (eventConfig['title'] as String?) ?? 'Event';
    final description = (eventConfig['description'] as String?) ?? '';
    final impact = ((eventConfig['marketImpact'] as num?)?.toDouble() ?? 1.0);
    final impactPct = ((impact - 1) * 100).round();
    final impactIcon = impactPct >= 0 ? Icons.trending_up : Icons.trending_down;

    return GameCard(
      backgroundColor: GameThemeConstants.creamSurface,
      padding: const EdgeInsets.all(SpacingConstants.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.8,
            child: Center(
              child: Icon(
                impactIcon,
                size: 34,
                color: GameThemeConstants.primaryDark,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: SpacingConstants.xs),
                Expanded(
                  child: Text(
                    description,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: SpacingConstants.xs),
                Text(
                  'Impact: ${impactPct >= 0 ? '+' : ''}$impactPct%',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: impactPct >= 0
                        ? GameThemeConstants.statPositive
                        : GameThemeConstants.statNegative,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: SpacingConstants.sm),
          GameButton(
            label: isSelected ? 'Selected' : 'Select',
            icon: Icons.bolt,
            variant: isSelected
                ? GameButtonVariant.success
                : GameButtonVariant.accent,
            onPressed: isBusy ? null : onToggleSelected,
            isFullWidth: true,
            padding: const EdgeInsets.symmetric(
              horizontal: SpacingConstants.sm,
              vertical: SpacingConstants.xs,
            ),
          ),
        ],
      ),
    );
  }
}
