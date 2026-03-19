/// Neutral baseline values for character stats.
/// All characters start from these values; only stats that differ
/// due to personality or skill are displayed in character selection.
class CharacterNeutralStats {
  CharacterNeutralStats._();

  static const Map<String, num> values = {
    'money': 10000,
    'riskTolerance': 50,
    'financialKnowledge': 60,
    'assetSlots': 5,
    'annualIncome': 5000,
    'return': 0,
    'volatility': 0,
    'diversification': 0,
    'sharpeRatio': 0,
    'managementCostDrag': 0,
    'liquidityRatio': 100,
    'taxDrag': 0,
    'emotionalReaction': 45,
    'knowledge': 60,
    'investmentHorizonRemaining': 25,
    'savingsRate': 18,
    'behavioralBias': 40,
  };

  static num getNeutral(String statId) => values[statId] ?? 0;

  static bool differsFromNeutral(String statId, num value) {
    final neutral = getNeutral(statId);
    return value != neutral;
  }
}
