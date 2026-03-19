import 'dart:math' show Random, cos, log, pi, sqrt;

import 'package:start_hack_2026/domain/entities/character_stats.dart';
import 'package:start_hack_2026/domain/entities/owned_item.dart';
import 'package:start_hack_2026/domain/entities/stat_schema.dart';
import 'package:start_hack_2026/domain/entities/store_item.dart';

class CalculationEngine {
  double calculatePortfolioValue({
    required int cash,
    required Map<String, PortfolioAsset> holdings,
    required Map<String, double> returnFactors,
  }) {
    double total = cash.toDouble();
    for (final entry in holdings.entries) {
      final asset = entry.value;
      final factor = returnFactors[entry.key] ?? 1.0;
      total += asset.totalValue * factor;
    }
    return total;
  }

  CharacterStats applyItemEffects({
    required CharacterStats currentStats,
    required StoreItemItem item,
    required List<StatSchema> schema,
    int levelMultiplier = 1,
  }) {
    final updates = <String, num>{};
    for (final entry in item.statEffects.entries) {
      updates[entry.key] = entry.value * levelMultiplier;
    }
    var newStats = currentStats.copyWithUpdates(updates);
    for (final stat in schema) {
      final value = newStats.get(stat.id);
      if (stat.min != null && value < stat.min!) {
        final corrected = <String, num>{...newStats.values};
        corrected[stat.id] = stat.min!;
        newStats = CharacterStats(corrected);
      }
      if (stat.max != null && value > stat.max!) {
        final corrected = <String, num>{...newStats.values};
        corrected[stat.id] = stat.max!;
        newStats = CharacterStats(corrected);
      }
    }
    return newStats;
  }

  bool canAfford({required int money, required int price}) {
    return money >= price;
  }

  bool hasAssetSlot({
    required int currentHoldings,
    required int maxSlots,
  }) {
    return currentHoldings < maxSlots;
  }

  Map<String, num> calculatePortfolioStats({
    required Map<String, num> baseStats,
    required Map<String, PortfolioAsset> holdings,
    required List<OwnedItem?> itemSlots,
    required List<StatSchema> schema,
  }) {
    var stats = Map<String, num>.from(baseStats);
    for (final slot in itemSlots) {
      if (slot != null) {
        final owned = slot;
        for (final entry in owned.item.statEffects.entries) {
          final current = stats[entry.key] ?? 0;
          stats[entry.key] = (current.toDouble() + entry.value * owned.level).toDouble();
        }
      }
    }
    final totalValue = holdings.values.fold<double>(
      0,
      (sum, a) => sum + a.totalValue,
    );
    if (totalValue > 0) {
      var weightedReturn = 0.0;
      var weightedVolatility = 0.0;
      var weightedManagementCost = 0.0;
      var weightedLiquidity = 0.0;
      for (final asset in holdings.values) {
        final weight = asset.totalValue / totalValue;
        weightedReturn += asset.expectedReturn * weight;
        weightedVolatility += asset.volatility * weight;
        weightedManagementCost += asset.managementCost * weight;
        weightedLiquidity += asset.liquidity * weight;
      }
      stats['return'] = weightedReturn;
      stats['volatility'] = weightedVolatility;
      final currentMgmt = (stats['managementCostDrag'] ?? 0).toDouble();
      stats['managementCostDrag'] = (currentMgmt + weightedManagementCost).clamp(0, double.infinity);
      stats['liquidityRatio'] = weightedLiquidity;
      final baseDiversification = (stats['diversification'] ?? 0).toDouble();
      final holdingsDiversification = holdings.isEmpty ? 0 : (holdings.length * 10).clamp(0, 100).toDouble();
      stats['diversification'] = (baseDiversification + holdingsDiversification).clamp(0, 100);
      const riskFreeRate = 1.0;
      stats['sharpeRatio'] = weightedVolatility > 0
          ? (weightedReturn - riskFreeRate) / weightedVolatility
          : 0;
      stats['taxDrag'] = stats['taxDrag'] ?? 0;
    }
    for (final stat in schema) {
      final value = stats[stat.id];
      if (value != null && stat.min != null && value < stat.min!) {
        stats[stat.id] = stat.min!;
      }
      if (value != null && stat.max != null && value > stat.max!) {
        stats[stat.id] = stat.max!;
      }
    }
    return stats;
  }

  double generateRandomReturn({
    required double expectedReturn,
    required double volatility,
    required Random random,
  }) {
    final mean = expectedReturn / 100;
    final stdDev = volatility / 100;
    final normal = mean + stdDev * _boxMuller(random);
    return 1 + normal;
  }

  double _boxMuller(Random random) {
    final u1 = random.nextDouble();
    final u2 = random.nextDouble();
    if (u1 <= 0) return _boxMuller(random);
    return sqrt(-2 * log(u1)) * cos(2 * pi * u2);
  }
}

class PortfolioAsset {
  const PortfolioAsset({
    required this.assetId,
    required this.name,
    required this.icon,
    required this.quantity,
    required this.pricePerUnit,
    required this.expectedReturn,
    required this.volatility,
    required this.purchasePrice,
    this.liquidity = 100,
    this.managementCost = 0,
  });

  final String assetId;
  final String name;
  final String icon;
  final int quantity;
  final double pricePerUnit;
  final double expectedReturn;
  final double volatility;
  final double purchasePrice;
  final double liquidity;
  final double managementCost;

  double get totalValue => quantity * pricePerUnit;

  double get gainLossPercent =>
      purchasePrice > 0 ? ((pricePerUnit - purchasePrice) / purchasePrice) * 100 : 0;
}
