enum SimulationEventType {
  market,
  character,
  world,
  panicSell;

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
    this.panicSellAmount,
    this.panicSellLoss,
  });

  final double timestamp;
  final SimulationEventType type;
  final String title;
  final String description;
  final double portfolioValueAtEvent;

  /// Amount received from panic sell (only for type == panicSell).
  final int? panicSellAmount;

  /// Loss locked in by panic selling (cost basis - sale value).
  final double? panicSellLoss;
}

/// A single data point on the simulation portfolio value graph.
class SimulationDataPoint {
  const SimulationDataPoint({
    required this.timestamp,
    required this.value,
  });

  final double timestamp;
  final double value;
}
