import 'package:start_hack_2026/domain/entities/character.dart';
import 'package:start_hack_2026/engine/game_engine.dart';

/// Checks if the player has met their character's win conditions.
class WinConditionChecker {
  /// Returns true if the player has won based on character win conditions.
  static bool checkWin({
    required Character character,
    required List<PortfolioHistoryPoint> portfolioHistory,
  }) {
    final conditions = character.winConditions;
    if (conditions == null || portfolioHistory.isEmpty) return false;
    final lastPoint = portfolioHistory.last;
    final finalValue = lastPoint.value;
    final yearsPlayed = portfolioHistory.length;
    if (finalValue < conditions.minPortfolioValue) return false;
    if (yearsPlayed < conditions.minYears) return false;
    if (conditions.requireSteadyGrowth) {
      for (var i = 1; i < portfolioHistory.length; i++) {
        if (portfolioHistory[i].value < portfolioHistory[i - 1].value) {
          return false;
        }
      }
    }
    return true;
  }
}
