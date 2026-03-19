import 'package:shared_preferences/shared_preferences.dart';

class AchievementPreferences {
  static const String _unlockedAchievementsKey = 'unlocked_achievements_v1';

  Future<Set<String>> getUnlockedIds() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_unlockedAchievementsKey) ?? <String>[];
    return ids.toSet();
  }

  Future<void> saveUnlockedIds(Set<String> unlockedIds) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = unlockedIds.toList()..sort();
    await prefs.setStringList(_unlockedAchievementsKey, ids);
  }
}
