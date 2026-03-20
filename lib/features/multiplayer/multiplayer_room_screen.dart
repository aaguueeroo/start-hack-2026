import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

const String _marketRoleAssetPath = 'assets/images/market.png';
const String _investorRoleAssetPath = 'assets/images/investor.png';

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

  MultiplayerPlayer? _playerInRole(
    List<MultiplayerPlayer> players,
    MultiplayerRole role,
  ) {
    for (final MultiplayerPlayer p in players) {
      if (p.role == role) {
        return p;
      }
    }
    return null;
  }

  String _playerSlotLabel(MultiplayerPlayer? player, String? currentUserId) {
    if (player == null) {
      return 'Waiting';
    }
    if (currentUserId != null && player.userId == currentUserId) {
      return 'You';
    }
    return 'Opponent';
  }

  String _statusMessageForGameCard({
    required int playerCount,
    required bool isWaiting,
    required bool isMarketTurn,
    required bool isInvestorTurn,
    required bool isSimulating,
    required bool isResultsReady,
    required MultiplayerController controller,
  }) {
    if (playerCount < 2) {
      return '';
    }
    if (isWaiting) {
      return controller.isMarket
          ? 'Both players are ready. Press Start to begin.'
          : 'Waiting for market to start...';
    }
    if (isMarketTurn) {
      return controller.isMarket
          ? 'Your turn: choose market events, then end turn.'
          : 'The Market is choosing actions... please wait.';
    }
    if (isInvestorTurn) {
      return controller.isMarket
          ? 'Waiting for Investor actions and simulation start.'
          : 'Your turn: open store and then run simulation.';
    }
    if (isSimulating) {
      return controller.isMarket
          ? 'Simulation running... viewing investor live data.'
          : 'Simulation running...';
    }
    if (isResultsReady) {
      return controller.isMarket
          ? 'Results ready. Move to next round when ready.'
          : 'Results ready. Waiting for Market to continue.';
    }
    return 'Waiting for room state...';
  }

  Future<void> _copyRoomCodeToClipboard(
    BuildContext context,
    String roomCode,
  ) async {
    try {
      await Clipboard.setData(ClipboardData(text: roomCode));
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Room code copied')));
    } catch (e, stackTrace) {
      debugPrint('Clipboard copy failed: $e\n$stackTrace');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not copy the room code.')),
      );
    }
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
            final bool showStickyStartButton = isWaiting && controller.isMarket;
            final double bottomSafeInset = MediaQuery.of(
              context,
            ).padding.bottom;
            final EdgeInsets leadingSliverPadding = EdgeInsets.fromLTRB(
              SpacingConstants.md,
              SpacingConstants.md,
              SpacingConstants.md,
              0,
            );
            final double stickyStartVerticalReserve = showStickyStartButton
                ? bottomSafeInset +
                      SpacingConstants.sm +
                      SpacingConstants.multiplayerStickyStartButtonReserve +
                      SpacingConstants.md
                : SpacingConstants.md;
            final EdgeInsets trailingSliverPadding = EdgeInsets.fromLTRB(
              SpacingConstants.md,
              0,
              SpacingConstants.md,
              stickyStartVerticalReserve,
            );

            return Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: leadingSliverPadding,
                      sliver: SliverToBoxAdapter(
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
                            Wrap(
                              spacing: SpacingConstants.xs,
                              runSpacing: SpacingConstants.xs,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  'Room ${room.roomCode}',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                GameButton(
                                  label: '',
                                  icon: Icons.content_copy_rounded,
                                  variant: GameButtonVariant.accent,
                                  isFullWidth: false,
                                  padding: const EdgeInsets.all(
                                    SpacingConstants.sm,
                                  ),
                                  onPressed: () => _copyRoomCodeToClipboard(
                                    context,
                                    room.roomCode,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: SpacingConstants.xs),
                            Text('Round: ${room.currentRound}'),
                            Text('Your role: $activeRoleLabel'),
                            Text('Players connected: $playerCount/2'),
                          ],
                        ),
                      ),
                      const SizedBox(height: SpacingConstants.md),
                      if (playerCount >= 2) ...[
                        GameCard(
                          child: Text(
                            _statusMessageForGameCard(
                              playerCount: playerCount,
                              isWaiting: isWaiting,
                              isMarketTurn: isMarketTurn,
                              isInvestorTurn: isInvestorTurn,
                              isSimulating: isSimulating,
                              isResultsReady: isResultsReady,
                              controller: controller,
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
                              'Players',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: SpacingConstants.sm),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Center(
                                    child: _MultiplayerRoleSlot(
                                      assetPath: _marketRoleAssetPath,
                                      waitingFallbackIcon:
                                          Icons.trending_up_rounded,
                                      waitingFallbackColor:
                                          GameThemeConstants.accentDark,
                                      subtitle: _playerSlotLabel(
                                        _playerInRole(
                                          controller.players,
                                          MultiplayerRole.market,
                                        ),
                                        currentUserId,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: SpacingConstants.sm),
                                Expanded(
                                  child: Center(
                                    child: _MultiplayerRoleSlot(
                                      assetPath: _investorRoleAssetPath,
                                      waitingFallbackIcon: Icons.person_rounded,
                                      waitingFallbackColor:
                                          GameThemeConstants.primaryDark,
                                      subtitle: _playerSlotLabel(
                                        _playerInRole(
                                          controller.players,
                                          MultiplayerRole.investor,
                                        ),
                                        currentUserId,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                    ),
                    if (playerCount < 2)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: EdgeInsets.only(
                            bottom: stickyStartVerticalReserve,
                          ),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: SpacingConstants.sm,
                              ),
                              child: _ShiningWaitingText(
                                text:
                                    'Waiting for second player to join...',
                              ),
                            ),
                          ),
                        ),
                      ),
                    SliverPadding(
                      padding: trailingSliverPadding,
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
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
                    ),
                  ],
                ),
                if (showStickyStartButton)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          SpacingConstants.md,
                          SpacingConstants.sm,
                          SpacingConstants.md,
                          SpacingConstants.md,
                        ),
                        child: GameButton(
                          label: 'Start',
                          icon: Icons.play_arrow,
                          variant: GameButtonVariant.success,
                          onPressed: canStartMatch
                              ? () => controller.startMatch()
                              : null,
                        ),
                      ),
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
      case SimulationEventType.life:
        return GameThemeConstants.dangerDark;
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

class _MultiplayerRoleSlot extends StatelessWidget {
  const _MultiplayerRoleSlot({
    required this.assetPath,
    required this.waitingFallbackIcon,
    required this.waitingFallbackColor,
    required this.subtitle,
  });

  final String assetPath;
  final IconData waitingFallbackIcon;
  final Color waitingFallbackColor;
  final String subtitle;

  static const double _imageSize = 120.0;

  @override
  Widget build(BuildContext context) {
    final bool isWaiting = subtitle == 'Waiting';
    final Widget artwork = SizedBox(
      width: _imageSize,
      height: _imageSize,
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        errorBuilder:
            (BuildContext context, Object error, StackTrace? stackTrace) {
              debugPrint('Role image failed: $assetPath — $error');
              return Icon(
                waitingFallbackIcon,
                size: 52,
                color: isWaiting
                    ? GameThemeConstants.outlineColorLight
                    : waitingFallbackColor,
              );
            },
      ),
    );
    final Widget slotVisual = isWaiting
        ? Opacity(
            opacity: 0.42,
            child: ColorFiltered(
              colorFilter: const ColorFilter.matrix(<double>[
                0.2126, 0.7152, 0.0722, 0, 0, //
                0.2126, 0.7152, 0.0722, 0, 0, //
                0.2126, 0.7152, 0.0722, 0, 0, //
                0, 0, 0, 1, 0, //
              ]),
              child: artwork,
            ),
          )
        : artwork;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(SpacingConstants.md),
          decoration: BoxDecoration(
            color: GameThemeConstants.creamSurface,
            shape: BoxShape.circle,
            border: Border.all(
              color: GameThemeConstants.outlineColor,
              width: GameThemeConstants.outlineThickness,
            ),
            boxShadow: [
              BoxShadow(
                color: GameThemeConstants.outlineColor.withValues(alpha: 0.12),
                offset: const Offset(0, GameThemeConstants.bevelOffset),
                blurRadius: 0,
                spreadRadius: 0,
              ),
            ],
          ),
          child: slotVisual,
        ),
        const SizedBox(height: SpacingConstants.sm),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: isWaiting
                ? GameThemeConstants.statNeutral
                : GameThemeConstants.darkNavy,
          ),
        ),
      ],
    );
  }
}

class _ShiningWaitingText extends StatefulWidget {
  const _ShiningWaitingText({required this.text});

  final String text;

  @override
  State<_ShiningWaitingText> createState() => _ShiningWaitingTextState();
}

class _ShiningWaitingTextState extends State<_ShiningWaitingText>
    with SingleTickerProviderStateMixin {
  static const Duration _shineDuration = Duration(milliseconds: 2200);

  late AnimationController _shineController;

  @override
  void initState() {
    super.initState();
    _shineController = AnimationController(
      vsync: this,
      duration: _shineDuration,
    )..repeat();
  }

  @override
  void dispose() {
    _shineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle style =
        Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ) ??
        const TextStyle(fontWeight: FontWeight.w600, color: Colors.white);
    return AnimatedBuilder(
      animation: _shineController,
      builder: (BuildContext context, Widget? child) {
        final double t = _shineController.value;
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              begin: Alignment(-2.6 + 5.2 * t, 0),
              end: Alignment(-1.4 + 5.2 * t, 0),
              tileMode: TileMode.clamp,
              colors: [
                GameThemeConstants.statNeutral,
                GameThemeConstants.creamSurface,
                GameThemeConstants.statNeutral,
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          child: Text(widget.text, style: style, textAlign: TextAlign.center),
        );
      },
    );
  }
}
