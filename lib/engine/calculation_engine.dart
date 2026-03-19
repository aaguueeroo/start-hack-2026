import 'dart:math' show Random, cos, log, pi, sqrt;

import 'package:start_hack_2026/domain/entities/character_stats.dart';
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
  }) {
    final updates = <String, num>{};
    for (final entry in item.statEffects.entries) {
      updates[entry.key] = entry.value;
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
    required this.quantity,
    required this.pricePerUnit,
    required this.expectedReturn,
    required this.volatility,
  });

  final String assetId;
  final int quantity;
  final double pricePerUnit;
  final double expectedReturn;
  final double volatility;

  double get totalValue => quantity * pricePerUnit;
}
