import 'package:start_hack_2026/domain/entities/character_win_conditions.dart';

class Character {
  const Character({
    required this.id,
    required this.name,
    required this.icon,
    required this.uniqueSkill,
    required this.initialStats,
    this.winConditions,
  });

  final String id;
  final String name;
  final String icon;
  final String uniqueSkill;
  final Map<String, num> initialStats;
  final CharacterWinConditions? winConditions;

  factory Character.fromJson(Map<String, dynamic> json) {
    final statsJson = json['initialStats'] as Map<String, dynamic>? ?? {};
    final initialStats = <String, num>{};
    for (final entry in statsJson.entries) {
      final value = entry.value;
      if (value is num) {
        initialStats[entry.key] = value;
      } else if (value is int) {
        initialStats[entry.key] = value.toDouble();
      }
    }
    final winConditionsJson = json['winConditions'] as Map<String, dynamic>?;
    return Character(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      uniqueSkill: json['uniqueSkill'] as String,
      initialStats: initialStats,
      winConditions: winConditionsJson != null
          ? CharacterWinConditions.fromJson(winConditionsJson)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'uniqueSkill': uniqueSkill,
      'initialStats': initialStats,
      if (winConditions != null)
        'winConditions': {
          'minPortfolioValue': winConditions!.minPortfolioValue,
          'minYears': winConditions!.minYears,
          'requireSteadyGrowth': winConditions!.requireSteadyGrowth,
          'winMessage': winConditions!.winMessage,
          'winIcon': winConditions!.winIcon,
        },
    };
  }
}
