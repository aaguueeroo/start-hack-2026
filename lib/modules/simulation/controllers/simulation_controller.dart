import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:start_hack_2026/data/repositories/game_repository.dart';
import 'package:start_hack_2026/domain/entities/simulation_event.dart';
import 'package:start_hack_2026/engine/game_engine.dart';
import 'package:start_hack_2026/engine/simulation_engine.dart';

class SimulationController extends ChangeNotifier {
  SimulationController({
    required GameEngine gameEngine,
    required GameRepository gameRepository,
  })  : _gameEngine = gameEngine,
        _gameRepository = gameRepository;

  final GameEngine _gameEngine;
  final GameRepository _gameRepository;
  StreamSubscription<SimulationResult>? _subscription;

  List<SimulationDataPoint> _dataPoints = [];
  List<SimulationEvent> _events = [];
  SimulationStatus _status = SimulationStatus.idle;
  String? _errorMessage;
  double _lastPortfolioValue = 0;

  List<SimulationDataPoint> get dataPoints => _dataPoints;
  List<SimulationEvent> get events => _events;
  SimulationStatus get status => _status;
  String? get errorMessage => _errorMessage;
  double get lastPortfolioValue => _lastPortfolioValue;
  int get currentYear => _gameEngine.state?.currentYear ?? 1;

  Future<void> startSimulation() async {
    _status = SimulationStatus.running;
    _dataPoints = [];
    _events = [];
    _errorMessage = null;
    notifyListeners();
    try {
      final eventsConfig = await _gameRepository.getEvents();
      await _subscription?.cancel();
      _subscription = _gameEngine.startSimulation(eventsConfig).listen(
        (result) {
          _dataPoints.add(SimulationDataPoint(
            timestamp: result.timestamp,
            value: result.portfolioValue,
          ));
          _lastPortfolioValue = result.portfolioValue;
          if (result.event != null) {
            _events.add(result.event!);
          }
          notifyListeners();
        },
        onError: (e) {
          _errorMessage = 'Simulation error: $e';
          _status = SimulationStatus.error;
          if (kDebugMode) {
            print(_errorMessage);
          }
          notifyListeners();
        },
        onDone: () {
          _status = SimulationStatus.complete;
          _gameEngine.completeSimulation(_lastPortfolioValue);
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
    _status = SimulationStatus.idle;
    _errorMessage = null;
    _lastPortfolioValue = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

enum SimulationStatus {
  idle,
  running,
  complete,
  error,
}

class SimulationDataPoint {
  const SimulationDataPoint({
    required this.timestamp,
    required this.value,
  });

  final double timestamp;
  final double value;
}
