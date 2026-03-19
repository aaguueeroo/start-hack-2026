import 'dart:math' show Random, cos, log, pi, sqrt;

import 'package:start_hack_2026/engine/calculation_engine.dart';

/// Single source of truth for all asset-related calculations.
/// Each asset is calculated independently; values are derived from
/// the asset's stored state (quantity, pricePerUnit, purchasePrice).
class AssetCalculationEngine {
  AssetCalculationEngine();

  // ─────────────────────────────────────────────────────────────────────────
  // Per-asset calculations (each asset computed independently)
  // ─────────────────────────────────────────────────────────────────────────

  /// Current market value of the asset: quantity × current price per unit.
  double totalValue(PortfolioAsset asset) {
    return asset.quantity * asset.pricePerUnit;
  }

  /// Total cost basis (what was paid): quantity × purchase price per unit.
  double costBasis(PortfolioAsset asset) {
    return asset.quantity * asset.purchasePrice;
  }

  /// Total return since purchase, in percent.
  /// Formula: ((currentValue - costBasis) / costBasis) × 100
  double totalReturnPercent(PortfolioAsset asset) {
    final basis = costBasis(asset);
    if (basis <= 0) return 0;
    final value = totalValue(asset);
    return ((value - basis) / basis) * 100;
  }

  /// Creates a new asset with pricePerUnit updated by the given return factor.
  /// Used when applying simulation results; purchasePrice stays unchanged.
  PortfolioAsset applyReturnFactor(PortfolioAsset asset, double factor) {
    return PortfolioAsset(
      assetId: asset.assetId,
      name: asset.name,
      icon: asset.icon,
      quantity: asset.quantity,
      pricePerUnit: asset.pricePerUnit * factor,
      expectedReturn: asset.expectedReturn,
      volatility: asset.volatility,
      purchasePrice: asset.purchasePrice,
      liquidity: asset.liquidity,
      managementCost: asset.managementCost,
    );
  }

  /// Sale value of the asset (same as totalValue, for clarity at point of sale).
  int saleValue(PortfolioAsset asset) {
    return totalValue(asset).round();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Portfolio-level calculations (aggregate across assets)
  // ─────────────────────────────────────────────────────────────────────────

  /// Total portfolio value: cash + sum of each asset's totalValue.
  double portfolioValue({
    required int cash,
    required Map<String, PortfolioAsset> holdings,
  }) {
    var total = cash.toDouble();
    for (final asset in holdings.values) {
      total += totalValue(asset);
    }
    return total;
  }

  /// Portfolio value with per-asset return factors (for simulation).
  /// Each asset's value is multiplied by its factor before summing.
  double portfolioValueWithFactors({
    required int cash,
    required Map<String, PortfolioAsset> holdings,
    required Map<String, double> returnFactors,
  }) {
    var total = cash.toDouble();
    for (final entry in holdings.entries) {
      final asset = entry.value;
      final factor = returnFactors[entry.key] ?? 1.0;
      total += totalValue(asset) * factor;
    }
    return total;
  }

  /// Builds updated holdings with each asset's pricePerUnit multiplied by its factor.
  Map<String, PortfolioAsset> applyReturnFactorsToHoldings(
    Map<String, PortfolioAsset> holdings,
    Map<String, double> returnFactors,
  ) {
    final result = <String, PortfolioAsset>{};
    for (final entry in holdings.entries) {
      final factor = returnFactors[entry.key] ?? 1.0;
      result[entry.key] = applyReturnFactor(entry.value, factor);
    }
    return result;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Random return generation (for simulation)
  // ─────────────────────────────────────────────────────────────────────────

  /// Generates a random one-period return factor from expected return and volatility.
  /// Uses log-normal: mean = expectedReturn/100, stdDev = volatility/100.
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

  // ─────────────────────────────────────────────────────────────────────────
  // Aggregation helpers (for portfolio stats, simulation)
  // ─────────────────────────────────────────────────────────────────────────

  /// Average volatility across holdings (0–1 scale for simulation logic).
  double averageVolatility(Map<String, PortfolioAsset> holdings) {
    if (holdings.isEmpty) return 0;
    var sum = 0.0;
    for (final asset in holdings.values) {
      sum += asset.volatility;
    }
    return (sum / holdings.length) / 100;
  }

  /// Total value of holdings for a given return factor map (used in panic sell).
  double assetValueWithFactor(PortfolioAsset asset, double factor) {
    return totalValue(asset) * factor;
  }
}
