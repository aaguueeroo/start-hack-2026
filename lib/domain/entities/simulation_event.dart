enum SimulationEventType {
  market,
  character,
  world;

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
  });

  final double timestamp;
  final SimulationEventType type;
  final String title;
  final String description;
  final double portfolioValueAtEvent;
}
