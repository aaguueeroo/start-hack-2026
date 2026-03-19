/// Win conditions for a character, evaluated after each simulation year.
class CharacterWinConditions {
  const CharacterWinConditions({
    required this.minPortfolioValue,
    required this.minYears,
    this.requireSteadyGrowth = false,
    required this.winMessage,
    required this.winIcon,
  });

  final double minPortfolioValue;
  final int minYears;
  final bool requireSteadyGrowth;
  final String winMessage;
  final String winIcon;

  factory CharacterWinConditions.fromJson(Map<String, dynamic> json) {
    return CharacterWinConditions(
      minPortfolioValue:
          (json['minPortfolioValue'] as num?)?.toDouble() ?? 50000,
      minYears: (json['minYears'] as num?)?.toInt() ?? 3,
      requireSteadyGrowth: json['requireSteadyGrowth'] as bool? ?? false,
      winMessage: json['winMessage'] as String? ?? 'You won!',
      winIcon: json['winIcon'] as String? ?? 'emoji_events',
    );
  }
}
