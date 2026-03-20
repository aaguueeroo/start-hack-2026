import 'package:start_hack_2026/domain/entities/leaderboard_entry.dart';

/// Shown when Supabase and local storage both have no scores (demo / offline).
abstract final class MockLeaderboardData {
  static final List<LeaderboardEntry> sampleTopScores = _buildSorted();

  static List<LeaderboardEntry> _buildSorted() {
    final base = DateTime.utc(2026, 1, 15);
    final raw = <LeaderboardEntry>[
      LeaderboardEntry(
        id: 'demo-1',
        playerName: 'CompoundCal',
        characterType: 'YOUNG_INVESTOR',
        score: 9420,
        createdAt: base,
      ),
      LeaderboardEntry(
        id: 'demo-2',
        playerName: 'IndexIvy',
        characterType: 'MIDDLE_AGED',
        score: 8890,
        createdAt: base.add(const Duration(hours: 2)),
      ),
      LeaderboardEntry(
        id: 'demo-3',
        playerName: 'BondBuilder',
        characterType: 'PRE_RETIREMENT',
        score: 8310,
        createdAt: base.add(const Duration(hours: 5)),
      ),
      LeaderboardEntry(
        id: 'demo-4',
        playerName: 'RiskRiley',
        characterType: 'ENTREPRENEUR',
        score: 7920,
        createdAt: base.add(const Duration(days: 1)),
      ),
      LeaderboardEntry(
        id: 'demo-5',
        playerName: 'DiversifyDana',
        characterType: 'YOUNG_INVESTOR',
        score: 7650,
        createdAt: base.add(const Duration(days: 1, hours: 3)),
      ),
      LeaderboardEntry(
        id: 'demo-6',
        playerName: 'LongViewLou',
        characterType: 'INHERITOR',
        score: 7010,
        createdAt: base.add(const Duration(days: 2)),
      ),
      LeaderboardEntry(
        id: 'demo-7',
        playerName: 'SteadySam',
        characterType: 'MIDDLE_AGED',
        score: 6540,
        createdAt: base.add(const Duration(days: 2, hours: 8)),
      ),
      LeaderboardEntry(
        id: 'demo-8',
        playerName: 'LearnModeLee',
        characterType: 'YOUNG_INVESTOR',
        score: 5980,
        createdAt: base.add(const Duration(days: 3)),
      ),
    ]..sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      return b.createdAt.compareTo(a.createdAt);
    });
    return List<LeaderboardEntry>.unmodifiable(raw);
  }
}
