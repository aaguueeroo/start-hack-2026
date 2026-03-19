class LeaderboardEntry {
  const LeaderboardEntry({
    required this.id,
    required this.playerName,
    required this.characterType,
    required this.score,
    required this.createdAt,
  });

  final String id;
  final String playerName;
  final String characterType;
  final int score;
  final DateTime createdAt;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    final createdAtValue = json['created_at'] ?? json['createdAt'];
    final createdAt =
        DateTime.tryParse(createdAtValue?.toString() ?? '') ?? DateTime.now();

    return LeaderboardEntry(
      id: (json['id'] ?? '').toString(),
      playerName: (json['username'] ?? json['playerName'] ?? '').toString(),
      characterType:
          (json['character_type'] ?? json['characterType'] ?? '').toString(),
      score: _toInt(json['score']),
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': playerName,
      'character_type': characterType,
      'score': score,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
