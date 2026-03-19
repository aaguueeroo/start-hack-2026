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
            colors: [GameThemeConstants.creamBackground, Color(0xFFF5EDE0)],
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
            final canFinishMarketTurn =
                controller.isMarket &&
                hasBothPlayers &&
                isMarketTurn &&
                hasRoundEvents &&
                !controller.isBusy;
            final canProceedToNextRound =
                controller.isMarket &&
                hasBothPlayers &&
                isResultsReady &&
                !controller.isBusy;
            final canStartMatch =
                isWaiting &&
                hasBothPlayers &&
                !controller.isBusy &&
                controller.isMarket;
            final roundResult = controller.roundResult;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(SpacingConstants.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (controller.errorMessage != null) ...[
                    GameCard(
                      child: Text(
                        controller.errorMessage!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                  if (isWaiting)
                    GameButton(
                      label: 'Start',
                      icon: Icons.play_arrow,
                      variant: GameButtonVariant.success,
                      onPressed: canStartMatch
                          ? () => controller.startMatch()
                          : null,
                    ),
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
                  if (!isWaiting) ...[
                    const SizedBox(height: SpacingConstants.md),
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
                    if (controller.isMarket && isMarketTurn)
                      GameCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Market Controls',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: SpacingConstants.sm),
                            ...controller.eventsCatalog.map(
                              (eventConfig) => Padding(
                                padding: const EdgeInsets.only(
                                  bottom: SpacingConstants.sm,
                                ),
                                child: _MarketEventTile(
                                  eventConfig: eventConfig,
                                  isBusy: controller.isBusy,
                                  onLaunch: () =>
                                      controller.launchEvent(eventConfig),
                                ),
                              ),
                            ),
                            GameButton(
                              label: 'End Market Turn',
                              icon: Icons.skip_next,
                              variant: GameButtonVariant.warning,
                              onPressed: !canFinishMarketTurn
                                  ? null
                                  : () => controller.finishMarketTurn(),
                            ),
                          ],
                        ),
                      ),
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
                    if (controller.isMarket && hasBothPlayers)
                      GameButton(
                        label: 'Back To Action Screen',
                        icon: Icons.skip_next,
                        variant: GameButtonVariant.primary,
                        onPressed: !canProceedToNextRound
                            ? null
                            : () => controller.proceedToNextRound(),
                      ),
                  ],
                ],
              ),
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
        titlesData: const FlTitlesData(
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                final hasEvent = events.any((event) {
                  final dist = (event.timestamp - dataPoints[idx].timestamp)
                      .abs();
                  return dist <= 0.5;
                });
                return FlDotCirclePainter(
                  radius: hasEvent ? 4 : 2.5,
                  color: hasEvent
                      ? GameThemeConstants.warningDark
                      : GameThemeConstants.primaryDark,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketEventTile extends StatelessWidget {
  const _MarketEventTile({
    required this.eventConfig,
    required this.onLaunch,
    required this.isBusy,
  });

  final Map<String, dynamic> eventConfig;
  final VoidCallback onLaunch;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final title = (eventConfig['title'] as String?) ?? 'Event';
    final description = (eventConfig['description'] as String?) ?? '';
    final impact = ((eventConfig['marketImpact'] as num?)?.toDouble() ?? 1.0);
    final impactPct = ((impact - 1) * 100).round();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(SpacingConstants.radiusMd),
        border: Border.all(color: GameThemeConstants.outlineColorLight),
      ),
      padding: const EdgeInsets.all(SpacingConstants.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: SpacingConstants.xs),
          Text(description),
          const SizedBox(height: SpacingConstants.xs),
          Text('Impact: ${impactPct >= 0 ? '+' : ''}$impactPct%'),
          const SizedBox(height: SpacingConstants.xs),
          GameButton(
            label: isBusy ? 'Launching...' : 'Launch Event',
            icon: Icons.bolt,
            variant: GameButtonVariant.accent,
            onPressed: isBusy ? null : onLaunch,
          ),
        ],
      ),
    );
  }
}
