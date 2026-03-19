import 'dart:async';
import 'dart:math';

import 'package:start_hack_2026/domain/entities/character_stats.dart';
import 'package:start_hack_2026/domain/entities/simulation_event.dart';
import 'package:start_hack_2026/engine/calculation_engine.dart';

class SimulationResult {
  const SimulationResult({
    required this.timestamp,
    required this.portfolioValue,
    this.event,
  });

  final double timestamp;
  final double portfolioValue;
  final SimulationEvent? event;
}

class SimulationEngine {
  SimulationEngine({CalculationEngine? calculationEngine})
      : _calculationEngine = calculationEngine ?? CalculationEngine();

  final CalculationEngine _calculationEngine;
  final Random _random = Random();

  static const int monthsPerYear = 12;
  static const int ticksPerMonth = 4;
  static const int totalTicks = monthsPerYear * ticksPerMonth;
  static const Duration tickDuration = Duration(milliseconds: 250);

  Stream<SimulationResult> runSimulation({
    required CharacterStats stats,
    required int cash,
    required Map<String, PortfolioAsset> holdings,
    required List<Map<String, dynamic>> eventsConfig,
  }) async* {
    final returnFactors = <String, double>{};
    for (final entry in holdings.entries) {
      returnFactors[entry.key] = 1.0;
    }
    var currentCash = cash;
    var currentHoldings = Map<String, PortfolioAsset>.from(holdings);
    var portfolioValue = _calculationEngine.calculatePortfolioValue(
      cash: currentCash,
      holdings: currentHoldings,
      returnFactors: returnFactors,
    );
    final riskTolerance = stats.riskTolerance / 100.0;
    final annualIncome = stats.annualIncome;
    final incomePerTick = annualIncome / totalTicks;
    var currentMonth = 0.0;
    final eventPool = List<Map<String, dynamic>>.from(eventsConfig);
    for (var tick = 0; tick < totalTicks; tick++) {
      await Future<void>.delayed(tickDuration);
      currentMonth = (tick / ticksPerMonth).toDouble();
      currentCash += incomePerTick.toInt();
      final marketEvent = _maybeTriggerEvent(eventPool, _random);
      var marketMultiplier = 1.0;
      if (marketEvent != null) {
        final type = marketEvent['type'] as String? ?? 'world';
        if (type == 'market') {
          final title = marketEvent['title'] as String? ?? 'Event';
          if (title.toLowerCase().contains('crash')) {
            marketMultiplier = 0.85;
          } else if (title.toLowerCase().contains('rally')) {
            marketMultiplier = 1.15;
          } else if (title.toLowerCase().contains('boom')) {
            marketMultiplier = 1.1;
          }
        }
      }
      final newHoldings = <String, PortfolioAsset>{};
      for (final entry in currentHoldings.entries) {
        final asset = entry.value;
        final returnFactor = _calculationEngine.generateRandomReturn(
          expectedReturn: asset.expectedReturn,
          volatility: asset.volatility,
          random: _random,
        );
        final newFactor = (returnFactors[entry.key] ?? 1.0) * returnFactor * marketMultiplier;
        returnFactors[entry.key] = newFactor;
        newHoldings[entry.key] = asset;
      }
      final volatility = _averageVolatility(currentHoldings);
      if (volatility > 0.2 && riskTolerance < 0.5 && _random.nextDouble() < 0.3) {
        final toSell = currentHoldings.keys.toList()..shuffle(_random);
        for (final assetId in toSell.take(1)) {
          final asset = currentHoldings[assetId]!;
          currentCash += (asset.totalValue * (returnFactors[assetId] ?? 1.0)).toInt();
          currentHoldings.remove(assetId);
          returnFactors.remove(assetId);
        }
      }
      portfolioValue = _calculationEngine.calculatePortfolioValue(
        cash: currentCash,
        holdings: currentHoldings,
        returnFactors: returnFactors,
      );
      SimulationEvent? event;
      if (marketEvent != null) {
        event = SimulationEvent(
          timestamp: currentMonth,
          type: SimulationEventType.fromString(
            marketEvent['type'] as String? ?? 'world',
          ),
          title: marketEvent['title'] as String? ?? 'Event',
          description: marketEvent['description'] as String? ?? '',
          portfolioValueAtEvent: portfolioValue,
        );
      }
      yield SimulationResult(
        timestamp: currentMonth,
        portfolioValue: portfolioValue,
        event: event,
      );
    }
  }

  Map<String, dynamic>? _maybeTriggerEvent(
    List<Map<String, dynamic>> pool,
    Random random,
  ) {
    if (pool.isEmpty) return null;
    for (final event in pool) {
      final probability = (event['probability'] as num?)?.toDouble() ?? 0.1;
      if (random.nextDouble() < probability) {
        return event;
      }
    }
    return null;
  }

  double _averageVolatility(Map<String, PortfolioAsset> holdings) {
    if (holdings.isEmpty) return 0;
    var sum = 0.0;
    for (final asset in holdings.values) {
      sum += asset.volatility;
    }
    return (sum / holdings.length) / 100;
  }
}
