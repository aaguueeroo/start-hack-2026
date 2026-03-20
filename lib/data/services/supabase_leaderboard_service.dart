import 'package:start_hack_2026/core/config/supabase_config.dart';
import 'package:start_hack_2026/domain/entities/leaderboard_entry.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseLeaderboardService {
  /// Only true after a successful [Supabase.initialize]; avoids crashing on bad keys/URL.
  bool get isAvailable => SupabaseConfig.isInitialized;

  Future<void> saveScore({
    required String playerName,
    required String characterType,
    required int score,
  }) async {
    if (!isAvailable) {
      return;
    }

    await Supabase.instance.client.from('leaderboard_scores').insert({
      'username': playerName.trim(),
      'character_type': characterType.toUpperCase(),
      'score': score,
    });
  }

  Future<List<LeaderboardEntry>> fetchTopScores({int limit = 20}) async {
    if (!isAvailable) {
      return const [];
    }

    final dynamic response = await Supabase.instance.client
        .from('leaderboard_scores')
        .select('id, username, character_type, score, created_at')
        .order('score', ascending: false)
        .limit(limit);

    if (response == null) {
      return const [];
    }

    final List<dynamic> rows;
    if (response is List<dynamic>) {
      rows = response;
    } else if (response is List) {
      rows = List<dynamic>.from(response);
    } else {
      return const [];
    }

    final entries = <LeaderboardEntry>[];
    for (final row in rows) {
      if (row is Map<String, dynamic>) {
        entries.add(LeaderboardEntry.fromJson(row));
      } else if (row is Map) {
        entries.add(
          LeaderboardEntry.fromJson(Map<String, dynamic>.from(row)),
        );
      }
    }

    entries.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      return b.createdAt.compareTo(a.createdAt);
    });

    if (entries.length <= limit) {
      return List<LeaderboardEntry>.unmodifiable(entries);
    }
    return List<LeaderboardEntry>.unmodifiable(entries.take(limit).toList());
  }
}
