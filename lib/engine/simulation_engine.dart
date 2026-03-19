import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:start_hack_2026/domain/entities/character_stats.dart';
import 'package:start_hack_2026/domain/entities/simulation_event.dart';
import 'package:start_hack_2026/engine/asset_calculation_engine.dart';
import 'package:start_hack_2026/engine/calculation_engine.dart' show PortfolioAsset;

/// Represents an event that is currently affecting the market.
class ActiveEvent {
  const ActiveEvent({
    required this.eventId,
    required this.title,
    required this.type,
    required this.startMonth,
    required this.endMonth,
    required this.marketImpact,
    this.riskyAssetImpact,
    this.safeAssetImpact,
  });

  final String eventId;
  final String title;
  final SimulationEventType type;
  final double startMonth;
  final double endMonth;
  final double marketImpact;
  final double? riskyAssetImpact;
  final double? safeAssetImpact;

  /// Impact applied per tick for risky assets (volatility >= 12).
  double get effectiveRiskyImpact => riskyAssetImpact ?? marketImpact;

  /// Impact applied per tick for safe assets (volatility < 12).
  double get effectiveSafeImpact => safeAssetImpact ?? marketImpact;

  /// Human-readable impact description (e.g. "-18%", "+25%").
  String get impactDescription {
    final pct = ((marketImpact - 1) * 100).round();
    return pct >= 0 ? '+$pct%' : '$pct%';
  }
}

class SimulationResult {
  const SimulationResult({
    required this.timestamp,
    required this.portfolioValue,
    this.event,
    this.activeEvents = const [],
    this.finalCash,
    this.finalHoldings,
  });

  final double timestamp;
  final double portfolioValue;
  final SimulationEvent? event;

  /// Events currently affecting the market at this timestamp.
  final List<ActiveEvent> activeEvents;

  /// Final cash after simulation (only set on last result).
  final int? finalCash;

  /// Final holdings with updated values (only set on last result).
  final Map<String, PortfolioAsset>? finalHoldings;

  /// Returns the currently active events and their impact.
  List<ActiveEvent> getActiveEvents() => List.unmodifiable(activeEvents);
}

class SimulationEngine {
  SimulationEngine({
    AssetCalculationEngine? assetCalculationEngine,
  }) : _assetCalculationEngine =
            assetCalculationEngine ?? AssetCalculationEngine();

  final AssetCalculationEngine _assetCalculationEngine;
  final Random _random = Random();

  static const int monthsPerYear = 12;
  static const int ticksPerMonth = 4;
  static const int totalTicks = monthsPerYear * ticksPerMonth;
  static const Duration tickDuration = Duration(milliseconds: 250);

  /// Volatility threshold: assets with volatility >= this are "risky".
  static const double _riskyVolatilityThreshold = 12.0;

  Stream<SimulationResult> runSimulation({
    required CharacterStats stats,
    required int cash,
    required Map<String, PortfolioAsset> holdings,
    required List<Map<String, dynamic>> eventsConfig,
    ValueNotifier<double>? speedMultiplier,
    ValueNotifier<bool>? skipToEnd,
  }) async* {
    final returnFactors = <String, double>{};
    for (final entry in holdings.entries) {
      returnFactors[entry.key] = 1.0;
    }
    var currentCash = cash;
    var currentHoldings = Map<String, PortfolioAsset>.from(holdings);
    var portfolioValue = _assetCalculationEngine.portfolioValueWithFactors(
      cash: currentCash,
      holdings: currentHoldings,
      returnFactors: returnFactors,
    );
    final riskTolerance = stats.riskTolerance / 100.0;
    final monthlySavings = stats.monthlySavings;
    var currentMonth = 0.0;
    final eventPool = List<Map<String, dynamic>>.from(eventsConfig);

    /// Active events: each entry is (eventConfig, startMonth).
    final activeEvents = <_TrackedActiveEvent>[];
    double? lastEventMonth;

    /// Cooldown: don't trigger a new event within this many months of the last.
    const eventCooldownMonths = 2.0;

    for (var tick = 0; tick < totalTicks; tick++) {
      final shouldSkip = skipToEnd?.value ?? false;
      final multiplier = (speedMultiplier?.value ?? 1.0).clamp(0.25, 10.0);
      final delay = shouldSkip
          ? Duration.zero
          : Duration(
              milliseconds: (tickDuration.inMilliseconds / multiplier).round(),
            );
      await Future<void>.delayed(delay);
      currentMonth = (tick / ticksPerMonth).toDouble();

      // Remove expired events
      activeEvents.removeWhere((e) => currentMonth >= e.endMonth);

      // Maybe trigger a new event (respect cooldown)
      final canTrigger = lastEventMonth == null ||
          (currentMonth - lastEventMonth) >= eventCooldownMonths;
      final newEventConfig = canTrigger
          ? _maybeTriggerEvent(eventPool, _random)
          : null;
      if (newEventConfig != null) lastEventMonth = currentMonth;
      if (newEventConfig != null) {
        final durationMonths =
            (newEventConfig['durationMonths'] as num?)?.toDouble() ?? 1.0;
        activeEvents.add(_TrackedActiveEvent(
          config: newEventConfig,
          startMonth: currentMonth,
          endMonth: currentMonth + durationMonths,
        ));
      }

      // Monthly savings added at the end of each month
      if ((tick + 1) % ticksPerMonth == 0) {
        currentCash += monthlySavings;
      }

      final newHoldings = <String, PortfolioAsset>{};
      for (final entry in currentHoldings.entries) {
        final asset = entry.value;
        final returnFactor = _assetCalculationEngine.generateRandomReturn(
          expectedReturn: asset.expectedReturn,
          volatility: asset.volatility,
          random: _random,
        );
        final eventMultiplier = _computeAssetEventMultiplier(
          activeEvents: activeEvents,
          asset: asset,
        );
        final newFactor = (returnFactors[entry.key] ?? 1.0) *
            returnFactor *
            eventMultiplier;
        returnFactors[entry.key] = newFactor;
        newHoldings[entry.key] = asset;
      }

      final volatility = _assetCalculationEngine.averageVolatility(currentHoldings);
      if (volatility > 0.2 &&
          riskTolerance < 0.5 &&
          _random.nextDouble() < 0.3) {
        final toSell = currentHoldings.keys.toList()..shuffle(_random);
        for (final assetId in toSell.take(1)) {
          final asset = currentHoldings[assetId]!;
          currentCash += _assetCalculationEngine
              .assetValueWithFactor(asset, returnFactors[assetId] ?? 1.0)
              .toInt();
          currentHoldings.remove(assetId);
          returnFactors.remove(assetId);
        }
      }

      portfolioValue = _assetCalculationEngine.portfolioValueWithFactors(
        cash: currentCash,
        holdings: currentHoldings,
        returnFactors: returnFactors,
      );

      SimulationEvent? event;
      if (newEventConfig != null) {
        event = SimulationEvent(
          timestamp: currentMonth,
          type: SimulationEventType.fromString(
            newEventConfig['type'] as String? ?? 'world',
          ),
          title: newEventConfig['title'] as String? ?? 'Event',
          description: newEventConfig['description'] as String? ?? '',
          portfolioValueAtEvent: portfolioValue,
        );
      }

      final activeList = activeEvents
          .map((e) => _toActiveEvent(e, currentMonth))
          .toList();

      final isLastTick = tick == totalTicks - 1;
      final finalHoldingsMap = isLastTick
          ? _buildFinalHoldings(currentHoldings, returnFactors)
          : null;

      yield SimulationResult(
        timestamp: currentMonth,
        portfolioValue: portfolioValue,
        event: event,
        activeEvents: activeList,
        finalCash: isLastTick ? currentCash : null,
        finalHoldings: finalHoldingsMap,
      );
    }
  }

  /// Builds final holdings with pricePerUnit updated by return factors.
  Map<String, PortfolioAsset> _buildFinalHoldings(
    Map<String, PortfolioAsset> holdings,
    Map<String, double> returnFactors,
  ) {
    return _assetCalculationEngine.applyReturnFactorsToHoldings(
      holdings,
      returnFactors,
    );
  }

  /// Computes the event multiplier for a single asset.
  /// Impact is applied per month and spread over ticks.
  double _computeAssetEventMultiplier({
    required List<_TrackedActiveEvent> activeEvents,
    required PortfolioAsset asset,
  }) {
    if (activeEvents.isEmpty) return 1.0;

    final isRisky = asset.volatility >= _riskyVolatilityThreshold;
    var multiplier = 1.0;

    for (final tracked in activeEvents) {
      final c = tracked.config;
      final marketImpact = (c['marketImpact'] as num?)?.toDouble() ?? 1.0;
      final impact = isRisky
          ? (c['riskyAssetImpact'] as num?)?.toDouble() ?? marketImpact
          : (c['safeAssetImpact'] as num?)?.toDouble() ?? marketImpact;
      // Spread monthly impact over ticks
      multiplier *= pow(impact, 1 / ticksPerMonth);
    }

    return multiplier;
  }

  ActiveEvent _toActiveEvent(_TrackedActiveEvent tracked, double currentMonth) {
    final c = tracked.config;
    return ActiveEvent(
      eventId: c['id'] as String? ?? '',
      title: c['title'] as String? ?? 'Event',
      type: SimulationEventType.fromString(c['type'] as String? ?? 'world'),
      startMonth: tracked.startMonth,
      endMonth: tracked.endMonth,
      marketImpact: (c['marketImpact'] as num?)?.toDouble() ?? 1.0,
      riskyAssetImpact: (c['riskyAssetImpact'] as num?)?.toDouble(),
      safeAssetImpact: (c['safeAssetImpact'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic>? _maybeTriggerEvent(
    List<Map<String, dynamic>> pool,
    Random random,
  ) {
    if (pool.isEmpty) return null;
    for (final event in pool) {
      final probability = (event['probability'] as num?)?.toDouble() ?? 0.006;
      if (random.nextDouble() < probability) {
        return event;
      }
    }
    return null;
  }

}

class _TrackedActiveEvent {
  _TrackedActiveEvent({
    required this.config,
    required this.startMonth,
    required this.endMonth,
  });

  final Map<String, dynamic> config;
  final double startMonth;
  final double endMonth;
}
