enum SimulationEventType {
  market,
  character,
  world,
  panicSell,
  life;

  static SimulationEventType fromString(String value) {
    return SimulationEventType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SimulationEventType.world,
    );
  }
}

class SimulationEvent {
  const SimulationEvent({
    required this.timestamp,
    required this.type,
    required this.title,
    required this.description,
    required this.portfolioValueAtEvent,
    this.panicSellAssetName,
    this.panicSellAmount,
    this.panicSellLoss,
    this.lifeBillAmount,
    this.lifeShortfall,
    this.lifeLiquidationSummary,
  });

  final double timestamp;
  final SimulationEventType type;
  final String title;
  final String description;
  final double portfolioValueAtEvent;

  /// Panic sell: asset name that was sold.
  final String? panicSellAssetName;

  /// Amount received from panic sell (only for type == panicSell).
  final int? panicSellAmount;

  /// Loss locked in by panic selling (cost basis - sale value).
  final double? panicSellLoss;

  /// Life event: total cost that was requested (bill).
  final int? lifeBillAmount;

  /// Life event: portion that could not be paid even after optional liquidation.
  final int? lifeShortfall;

  /// Life event: short note on what was sold (if anything).
  final String? lifeLiquidationSummary;
}

/// A single data point on the simulation portfolio value graph.
class SimulationDataPoint {
  const SimulationDataPoint({
    required this.timestamp,
    required this.value,
    /// Mark-to-market value of holdings only (no cash) — excludes monthly savings.
    this.holdingsOnlyValue,
  });

  final double timestamp;
  final double value;

  /// Null for legacy/cumulative points from older sessions.
  final double? holdingsOnlyValue;
}
