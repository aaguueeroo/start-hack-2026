class Character {
  const Character({
    required this.id,
    required this.name,
    required this.icon,
    required this.uniqueSkill,
    required this.initialStats,
  });

  final String id;
  final String name;
  final String icon;
  final String uniqueSkill;
  final Map<String, num> initialStats;

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
    return Character(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      uniqueSkill: json['uniqueSkill'] as String,
      initialStats: initialStats,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'uniqueSkill': uniqueSkill,
      'initialStats': initialStats,
    };
  }
}
