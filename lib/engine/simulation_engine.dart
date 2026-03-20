import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:start_hack_2026/domain/entities/character_stats.dart';
import 'package:start_hack_2026/domain/entities/simulation_event.dart';
import 'package:start_hack_2026/engine/asset_calculation_engine.dart';
import 'package:start_hack_2026/engine/calculation_engine.dart'
    show PortfolioAsset;

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
    required this.holdingsOnlyValue,
    this.event,
    this.lifeEvent,
    this.panicSellEvent,
    this.activeEvents = const [],
    this.finalCash,
    this.finalHoldings,
  });

  final double timestamp;
  final double portfolioValue;

  /// Sum of marked-to-market holdings (return factors applied); excludes cash.
  final double holdingsOnlyValue;
  final SimulationEvent? event;

  /// One-off life event (bills, goals) that may spend cash and liquidate holdings.
  final SimulationEvent? lifeEvent;

  /// Emitted when the player panic-sells an asset during simulation.
  final SimulationEvent? panicSellEvent;

  /// Events currently affecting the market at this timestamp.
  final List<ActiveEvent> activeEvents;

  /// Final cash after simulation (only set on last result).
  final int? finalCash;

  /// Final holdings with updated values (only set on last result).
  final Map<String, PortfolioAsset>? finalHoldings;

  /// Returns the currently active events and their impact.
  List<ActiveEvent> getActiveEvents() => List.unmodifiable(activeEvents);
}

class SimulationScheduledEvent {
  const SimulationScheduledEvent({required this.tick, required this.config});

  final int tick;
  final Map<String, dynamic> config;
}

class SimulationEngine {
  SimulationEngine({AssetCalculationEngine? assetCalculationEngine})
    : _assetCalculationEngine =
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
    List<Map<String, dynamic>> lifeEventsConfig = const [],
    List<SimulationScheduledEvent>? forcedEvents,
    ValueNotifier<double>? speedMultiplier,
    ValueNotifier<bool>? skipToEnd,
  }) async* {
    var returnFactors = <String, double>{};
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
    final monthlySavings = stats.monthlySavings.clamp(0, 1000000000);
    var currentMonth = 0.0;
    final eventPool = List<Map<String, dynamic>>.from(eventsConfig);
    final lifePool = List<Map<String, dynamic>>.from(lifeEventsConfig);
    final useForcedEvents = forcedEvents != null && forcedEvents.isNotEmpty;
    final forcedByTick = <int, List<Map<String, dynamic>>>{};
    if (useForcedEvents) {
      for (final scheduled in forcedEvents) {
        forcedByTick
            .putIfAbsent(scheduled.tick, () => [])
            .add(scheduled.config);
      }
    }

    /// Active events: each entry is (eventConfig, startMonth).
    final activeEvents = <_TrackedActiveEvent>[];
    double? lastEventMonth;
    String? lastTriggeredEventId;
    double? lastLifeEventMonth;
    String? lastLifeEventId;
    var lifeEventsThisYear = 0;

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
      Map<String, dynamic>? newEventConfig;
      if (useForcedEvents) {
        final scheduledAtTick = forcedByTick[tick] ?? const [];
        for (final scheduledConfig in scheduledAtTick) {
          final durationMonths = _resolveDurationMonths(
            scheduledConfig,
            _random,
          );
          activeEvents.add(
            _TrackedActiveEvent(
              config: scheduledConfig,
              startMonth: currentMonth,
              endMonth: currentMonth + durationMonths,
            ),
          );
        }
        if (scheduledAtTick.isNotEmpty) {
          newEventConfig = scheduledAtTick.first;
        }
      } else {
        final canTrigger =
            lastEventMonth == null ||
            (currentMonth - lastEventMonth) >= eventCooldownMonths;
        newEventConfig = canTrigger
            ? _maybeTriggerEvent(
                eventPool,
                _random,
                lastEventId: lastTriggeredEventId,
              )
            : null;
        if (newEventConfig != null) {
          lastEventMonth = currentMonth;
          lastTriggeredEventId = newEventConfig['id'] as String?;
          final durationMonths = _resolveDurationMonths(
            newEventConfig,
            _random,
          );
          activeEvents.add(
            _TrackedActiveEvent(
              config: newEventConfig,
              startMonth: currentMonth,
              endMonth: currentMonth + durationMonths,
            ),
          );
        }
      }

      SimulationEvent? lifeEvent;
      final canTriggerLife =
          lastLifeEventMonth == null ||
          (currentMonth - lastLifeEventMonth) >= _lifeEventCooldownMonths;
      final canStillHaveLifeThisYear =
          lifeEventsThisYear < _maxLifeEventsPerYear;
      if (canTriggerLife && canStillHaveLifeThisYear && lifePool.isNotEmpty) {
        final rollChance = _lifeEventTriggerChanceForCount(lifeEventsThisYear);
        final lifeCfg = _maybeTriggerLifeEvent(
          lifePool,
          _random,
          lastEventId: lastLifeEventId,
          triggerChance: rollChance,
        );
        if (lifeCfg != null) {
          lastLifeEventMonth = currentMonth;
          lastLifeEventId = lifeCfg['id'] as String?;
          lifeEventsThisYear++;
          final pvPreLife = _assetCalculationEngine.portfolioValueWithFactors(
            cash: currentCash,
            holdings: currentHoldings,
            returnFactors: returnFactors,
          );
          final applied = _applyLifeEvent(
            cfg: lifeCfg,
            timestamp: currentMonth,
            startCash: currentCash,
            startHoldings: currentHoldings,
            returnFactors: returnFactors,
            portfolioValue: pvPreLife,
            random: _random,
          );
          currentCash = applied.cash;
          currentHoldings = applied.holdings;
          returnFactors = applied.factors;
          lifeEvent = applied.event;
        }
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
        final newFactor =
            (returnFactors[entry.key] ?? 1.0) * returnFactor * eventMultiplier;
        returnFactors[entry.key] = newFactor;
        newHoldings[entry.key] = asset;
      }

      SimulationEvent? panicSellEvent;
      final volatility = _assetCalculationEngine.averageVolatility(
        currentHoldings,
      );
      if (volatility > 0.2 &&
          riskTolerance < 0.5 &&
          _random.nextDouble() < 0.3) {
        final toSell = currentHoldings.keys.toList()..shuffle(_random);
        for (final assetId in toSell.take(1)) {
          final asset = currentHoldings[assetId]!;
          final costBasis = _assetCalculationEngine.costBasis(asset);
          final saleValue = _assetCalculationEngine.assetValueWithFactor(
            asset,
            returnFactors[assetId] ?? 1.0,
          );
          final loss = costBasis - saleValue;
          currentCash += saleValue.toInt();
          currentHoldings.remove(assetId);
          returnFactors.remove(assetId);
          panicSellEvent = SimulationEvent(
            timestamp: currentMonth,
            type: SimulationEventType.panicSell,
            title: 'Panic Sell',
            description: 'Sold ${asset.name} during market stress',
            portfolioValueAtEvent: 0, // Set after portfolioValue computed
            panicSellAssetName: asset.name,
            panicSellAmount: saleValue.toInt(),
            panicSellLoss: loss,
          );
        }
      }

      // End of each simulated month: add recurring savings to cash (not invested).
      if (tick % ticksPerMonth == ticksPerMonth - 1 && monthlySavings > 0) {
        currentCash += monthlySavings;
      }

      portfolioValue = _assetCalculationEngine.portfolioValueWithFactors(
        cash: currentCash,
        holdings: currentHoldings,
        returnFactors: returnFactors,
      );
      final holdingsOnlyValue = _assetCalculationEngine.holdingsValueWithFactors(
        holdings: currentHoldings,
        returnFactors: returnFactors,
      );

      if (panicSellEvent != null) {
        panicSellEvent = SimulationEvent(
          timestamp: panicSellEvent.timestamp,
          type: panicSellEvent.type,
          title: panicSellEvent.title,
          description: panicSellEvent.description,
          portfolioValueAtEvent: portfolioValue,
          panicSellAssetName: panicSellEvent.panicSellAssetName,
          panicSellAmount: panicSellEvent.panicSellAmount,
          panicSellLoss: panicSellEvent.panicSellLoss,
        );
      }

      SimulationEvent? event;
      if (newEventConfig != null) {
        event = SimulationEvent(
          timestamp: currentMonth,
          type: SimulationEventType.fromString(
            newEventConfig['type'] as String? ?? 'world',
          ),
          title: newEventConfig['title'] as String? ?? 'Event',
          description: _pickDescriptionFromConfig(newEventConfig, _random),
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
        holdingsOnlyValue: holdingsOnlyValue,
        event: event,
        lifeEvent: lifeEvent,
        panicSellEvent: panicSellEvent,
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

  /// Chance per eligible tick (after cooldown) that any market event may start.
  static const double _eventTriggerChance = 0.042;

  /// Prefer a different event than the last one; repeats still occur ~20% of the time.
  static const double _avoidSameEventChance = 0.80;

  Map<String, dynamic>? _maybeTriggerEvent(
    List<Map<String, dynamic>> pool,
    Random random, {
    String? lastEventId,
  }) {
    if (pool.isEmpty) return null;
    if (random.nextDouble() >= _eventTriggerChance) return null;

    var candidates = List<Map<String, dynamic>>.from(pool);
    if (lastEventId != null &&
        lastEventId.isNotEmpty &&
        candidates.length > 1 &&
        random.nextDouble() < _avoidSameEventChance) {
      final filtered = candidates
          .where((e) => (e['id'] as String?) != lastEventId)
          .toList();
      if (filtered.isNotEmpty) {
        candidates = filtered;
      }
    }

    var totalWeight = 0.0;
    for (final e in candidates) {
      final w = (e['probability'] as num?)?.toDouble() ?? 1.0;
      if (w > 0) totalWeight += w;
    }
    if (totalWeight <= 0) return null;

    var roll = random.nextDouble() * totalWeight;
    for (final e in candidates) {
      final w = (e['probability'] as num?)?.toDouble() ?? 1.0;
      if (w <= 0) continue;
      roll -= w;
      if (roll <= 0) return e;
    }
    return candidates.last;
  }

  double _resolveDurationMonths(Map<String, dynamic> config, Random random) {
    final range = config['durationMonthsRange'];
    if (range is List && range.length >= 2) {
      final lo = (range[0] as num).round();
      final hi = (range[1] as num).round();
      if (hi >= lo && lo > 0) {
        return (lo + random.nextInt(hi - lo + 1)).toDouble();
      }
    }
    return (config['durationMonths'] as num?)?.toDouble() ?? 1.0;
  }

  String _pickDescriptionFromConfig(
    Map<String, dynamic> config,
    Random random,
  ) {
    final variants = config['descriptions'];
    if (variants is List && variants.isNotEmpty) {
      final strings = variants.whereType<String>().toList();
      if (strings.isNotEmpty) {
        return strings[random.nextInt(strings.length)];
      }
    }
    return config['description'] as String? ?? '';
  }

  /// At most this many life events in one simulated year (12 months).
  static const int _maxLifeEventsPerYear = 2;

  /// First life event in a year: modest chance (~0–1 typical across runs).
  static const double _lifeEventTriggerChanceFirst = 0.016;

  /// Second life event in the same year: much rarer (cap still enforced).
  static const double _lifeEventTriggerChanceSecond = 0.0055;

  static const double _lifeEventCooldownMonths = 3.0;

  static double _lifeEventTriggerChanceForCount(int alreadyThisYear) {
    if (alreadyThisYear >= _maxLifeEventsPerYear) return 0;
    if (alreadyThisYear == 0) return _lifeEventTriggerChanceFirst;
    return _lifeEventTriggerChanceSecond;
  }

  Map<String, dynamic>? _maybeTriggerLifeEvent(
    List<Map<String, dynamic>> pool,
    Random random, {
    String? lastEventId,
    required double triggerChance,
  }) {
    if (pool.isEmpty || triggerChance <= 0) return null;
    if (random.nextDouble() >= triggerChance) return null;

    var candidates = List<Map<String, dynamic>>.from(pool);
    if (lastEventId != null &&
        lastEventId.isNotEmpty &&
        candidates.length > 1 &&
        random.nextDouble() < _avoidSameEventChance) {
      final filtered = candidates
          .where((e) => (e['id'] as String?) != lastEventId)
          .toList();
      if (filtered.isNotEmpty) {
        candidates = filtered;
      }
    }

    var totalWeight = 0.0;
    for (final e in candidates) {
      final w = (e['probability'] as num?)?.toDouble() ?? 1.0;
      if (w > 0) totalWeight += w;
    }
    if (totalWeight <= 0) return null;

    var roll = random.nextDouble() * totalWeight;
    for (final e in candidates) {
      final w = (e['probability'] as num?)?.toDouble() ?? 1.0;
      if (w <= 0) continue;
      roll -= w;
      if (roll <= 0) return e;
    }
    return candidates.last;
  }

  int _computeLifeBillAmount(
    Map<String, dynamic> c,
    double portfolioValue,
    Random random,
  ) {
    final fixed = c['costFixed'];
    if (fixed is num && fixed.toInt() > 0) {
      return fixed.toInt();
    }
    var minC = (c['costMin'] as num?)?.toInt() ?? 600;
    var maxC = (c['costMax'] as num?)?.toInt() ?? 8000;
    if (maxC < minC) {
      final t = minC;
      minC = maxC;
      maxC = t;
    }
    final pct = (c['costPortfolioPercent'] as num?)?.toDouble();
    final amount = () {
      if (pct != null && pct > 0) {
        return (portfolioValue * pct).round().clamp(minC, maxC);
      }
      final span = maxC - minC;
      return minC + (span > 0 ? random.nextInt(span + 1) : 0);
    }();
    return amount.clamp(0, 2000000000);
  }

  String? _pickHoldingToLiquidate(Map<String, PortfolioAsset> holdings) {
    if (holdings.isEmpty) return null;
    final ids = holdings.keys.toList()
      ..sort((a, b) {
        final la = holdings[a]!.liquidity;
        final lb = holdings[b]!.liquidity;
        final c = lb.compareTo(la);
        if (c != 0) return c;
        return a.compareTo(b);
      });
    return ids.first;
  }

  _LifeEventOutcome _applyLifeEvent({
    required Map<String, dynamic> cfg,
    required double timestamp,
    required int startCash,
    required Map<String, PortfolioAsset> startHoldings,
    required Map<String, double> returnFactors,
    required double portfolioValue,
    required Random random,
  }) {
    var cash = startCash;
    final holdings = Map<String, PortfolioAsset>.from(startHoldings);
    final factors = Map<String, double>.from(returnFactors);
    final bill = _computeLifeBillAmount(cfg, portfolioValue, random);
    final sellIfNeeded = cfg['sellIfNeeded'] as bool? ?? true;
    var due = bill;
    var pay = due < cash ? due : cash;
    cash -= pay;
    due -= pay;

    final liquidatedNames = <String>[];
    final liquidatedAmounts = <int>[];

    while (due > 0 && sellIfNeeded && holdings.isNotEmpty) {
      final pickId = _pickHoldingToLiquidate(holdings);
      if (pickId == null) break;
      final asset = holdings[pickId]!;
      final fv = factors[pickId] ?? 1.0;
      final saleValue = _assetCalculationEngine
          .assetValueWithFactor(asset, fv)
          .toInt();
      holdings.remove(pickId);
      factors.remove(pickId);
      cash += saleValue;
      liquidatedNames.add(asset.name);
      liquidatedAmounts.add(saleValue);
      pay = due < cash ? due : cash;
      cash -= pay;
      due -= pay;
    }

    final shortfall = due;
    final descBase = _pickDescriptionFromConfig(cfg, random);
    final buf = StringBuffer(descBase);
    if (liquidatedNames.isNotEmpty) {
      buf.write('\n\nTo help cover the cost you liquidated: ');
      for (var i = 0; i < liquidatedNames.length; i++) {
        if (i > 0) buf.write('; ');
        buf.write('${liquidatedNames[i]} (\$${liquidatedAmounts[i]})');
      }
      buf.write('.');
    }
    if (shortfall > 0) {
      buf.write(
        '\n\nYou could not fully cover this expense—about \$$shortfall remains unpaid.',
      );
    }

    final portfolioAfter = _assetCalculationEngine.portfolioValueWithFactors(
      cash: cash,
      holdings: holdings,
      returnFactors: factors,
    );

    final summary = liquidatedNames.isEmpty
        ? null
        : () {
            final parts = <String>[];
            for (var i = 0; i < liquidatedNames.length; i++) {
              parts.add('${liquidatedNames[i]} (\$${liquidatedAmounts[i]})');
            }
            return parts.join('; ');
          }();

    final event = SimulationEvent(
      timestamp: timestamp,
      type: SimulationEventType.life,
      title: cfg['title'] as String? ?? 'Life event',
      description: buf.toString(),
      portfolioValueAtEvent: portfolioAfter,
      lifeBillAmount: bill,
      lifeShortfall: shortfall > 0 ? shortfall : null,
      lifeLiquidationSummary: summary,
    );

    return _LifeEventOutcome(
      cash: cash,
      holdings: holdings,
      factors: factors,
      event: event,
    );
  }
}

class _LifeEventOutcome {
  _LifeEventOutcome({
    required this.cash,
    required this.holdings,
    required this.factors,
    required this.event,
  });

  final int cash;
  final Map<String, PortfolioAsset> holdings;
  final Map<String, double> factors;
  final SimulationEvent event;
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
