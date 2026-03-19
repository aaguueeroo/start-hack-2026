import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:start_hack_2026/data/repositories/game_repository.dart';
import 'package:start_hack_2026/domain/entities/simulation_event.dart';
import 'package:start_hack_2026/engine/game_engine.dart';
import 'package:start_hack_2026/engine/simulation_engine.dart';
import 'package:start_hack_2026/engine/win_condition_checker.dart';

class SimulationController extends ChangeNotifier {
  SimulationController({
    required GameEngine gameEngine,
    required GameRepository gameRepository,
  }) : _gameEngine = gameEngine,
       _gameRepository = gameRepository;

  final GameEngine _gameEngine;
  final GameRepository _gameRepository;
  StreamSubscription<SimulationResult>? _subscription;
  final ValueNotifier<double> _speedMultiplier = ValueNotifier<double>(1.0);
  final ValueNotifier<bool> _skipToEnd = ValueNotifier<bool>(false);

  static const double _acceleratedSpeedMultiplier = 4.0;

  List<SimulationDataPoint> _dataPoints = [];
  List<SimulationEvent> _events = [];
  List<ActiveEvent> _activeEvents = [];
  SimulationStatus _status = SimulationStatus.idle;
  String? _errorMessage;
  double _lastPortfolioValue = 0;
  bool _hasWon = false;
  SimulationResult? _lastResult;
  List<Map<String, dynamic>>? _forcedEventsForNextSimulation;
  Future<void> Function(
    List<SimulationDataPoint> dataPoints,
    List<SimulationEvent> events,
    bool isComplete,
    double lastPortfolioValue,
  )?
  _multiplayerReporter;

  List<SimulationDataPoint> get dataPoints => _dataPoints;
  bool get hasWon => _hasWon;
  List<SimulationEvent> get events => _events;
  SimulationStatus get status => _status;
  String? get errorMessage => _errorMessage;
  double get lastPortfolioValue => _lastPortfolioValue;
  int get currentYear => _gameEngine.state?.currentYear ?? 1;

  /// Returns the currently active market events and their impact.
  List<ActiveEvent> getActiveEvents() => List.unmodifiable(_activeEvents);

  void setAccelerating(bool isAccelerating) {
    _speedMultiplier.value = isAccelerating ? _acceleratedSpeedMultiplier : 1.0;
  }

  void skipToEnd() {
    if (_status == SimulationStatus.running) {
      _skipToEnd.value = true;
    }
  }

  Future<void> startSimulation() async {
    _status = SimulationStatus.running;
    // Load cumulative data from previous years (don't reset)
    _dataPoints = List.from(_gameEngine.cumulativeSimulationDataPoints);
    _events = List.from(_gameEngine.cumulativeSimulationEvents);
    _activeEvents = [];
    _errorMessage = null;
    final monthOffset = (currentYear - 1) * 12;
    notifyListeners();
    try {
      _skipToEnd.value = false;
      _speedMultiplier.value = 1.0;
      final eventsConfig = await _gameRepository.getEvents();
      final scheduledForcedEvents = _buildScheduledForcedEvents(
        _forcedEventsForNextSimulation,
      );
      _forcedEventsForNextSimulation = null;
      await _subscription?.cancel();
      _subscription = _gameEngine
          .startSimulation(
            eventsConfig,
            forcedEvents: scheduledForcedEvents,
            speedMultiplier: _speedMultiplier,
            skipToEnd: _skipToEnd,
          )
          .listen(
            (result) {
              _lastResult = result;
              _dataPoints.add(
                SimulationDataPoint(
                  timestamp: monthOffset + result.timestamp,
                  value: result.portfolioValue,
                ),
              );
              _lastPortfolioValue = result.portfolioValue;
              _activeEvents = result.getActiveEvents();
              if (result.event != null) {
                _events.add(
                  SimulationEvent(
                    timestamp: monthOffset + result.event!.timestamp,
                    type: result.event!.type,
                    title: result.event!.title,
                    description: result.event!.description,
                    portfolioValueAtEvent: result.event!.portfolioValueAtEvent,
                  ),
                );
              }
              if (result.panicSellEvent != null) {
                final panic = result.panicSellEvent!;
                _events.add(
                  SimulationEvent(
                    timestamp: monthOffset + panic.timestamp,
                    type: panic.type,
                    title: panic.title,
                    description: panic.description,
                    portfolioValueAtEvent: panic.portfolioValueAtEvent,
                    panicSellAmount: panic.panicSellAmount,
                    panicSellLoss: panic.panicSellLoss,
                  ),
                );
              }
              _reportMultiplayerSnapshot(isComplete: false);
              notifyListeners();
            },
            onError: (e) {
              _errorMessage = 'Simulation error: $e';
              _status = SimulationStatus.error;
              _multiplayerReporter = null;
              if (kDebugMode) {
                print(_errorMessage);
              }
              notifyListeners();
            },
            onDone: () {
              _status = SimulationStatus.complete;
              _gameEngine.completeSimulation(
                _lastPortfolioValue,
                finalCash: _lastResult?.finalCash,
                finalHoldings: _lastResult?.finalHoldings,
                cumulativeDataPoints: _dataPoints,
                cumulativeEvents: _events,
              );
              final state = _gameEngine.state;
              _hasWon =
                  state != null &&
                  WinConditionChecker.checkWin(
                    character: state.character,
                    portfolioHistory: state.portfolioHistory,
                  );
              _reportMultiplayerSnapshot(isComplete: true);
              _multiplayerReporter = null;
              notifyListeners();
            },
          );
    } catch (e) {
      _errorMessage = 'Failed to start simulation: $e';
      _status = SimulationStatus.error;
      if (kDebugMode) {
        print(_errorMessage);
      }
      notifyListeners();
    }
  }

  void reset() {
    _dataPoints = [];
    _events = [];
    _activeEvents = [];
    _status = SimulationStatus.idle;
    _errorMessage = null;
    _lastPortfolioValue = 0;
    _hasWon = false;
    _forcedEventsForNextSimulation = null;
    _multiplayerReporter = null;
    notifyListeners();
  }

  void configureForcedEventsForNextSimulation(
    List<Map<String, dynamic>> events,
  ) {
    _forcedEventsForNextSimulation = List<Map<String, dynamic>>.from(events);
  }

  void configureMultiplayerReporter(
    Future<void> Function(
      List<SimulationDataPoint> dataPoints,
      List<SimulationEvent> events,
      bool isComplete,
      double lastPortfolioValue,
    )?
    reporter,
  ) {
    _multiplayerReporter = reporter;
  }

  void _reportMultiplayerSnapshot({required bool isComplete}) {
    final reporter = _multiplayerReporter;
    if (reporter == null) return;
    unawaited(
      reporter(
        List<SimulationDataPoint>.from(_dataPoints),
        List<SimulationEvent>.from(_events),
        isComplete,
        _lastPortfolioValue,
      ).catchError((e) {
        _errorMessage = 'Failed to sync multiplayer simulation data: $e';
        notifyListeners();
      }),
    );
  }

  List<SimulationScheduledEvent>? _buildScheduledForcedEvents(
    List<Map<String, dynamic>>? forcedEvents,
  ) {
    if (forcedEvents == null || forcedEvents.isEmpty) {
      return null;
    }

    final count = forcedEvents.length;
    return List.generate(count, (index) {
      final month = ((index * SimulationEngine.monthsPerYear) / count).floor();
      final clampedMonth = month.clamp(0, SimulationEngine.monthsPerYear - 1);
      final tick = clampedMonth * SimulationEngine.ticksPerMonth;
      return SimulationScheduledEvent(tick: tick, config: forcedEvents[index]);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _speedMultiplier.dispose();
    _skipToEnd.dispose();
    super.dispose();
  }
}

enum SimulationStatus { idle, running, complete, error }
