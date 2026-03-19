class CharacterStats {
  const CharacterStats(this.values);

  final Map<String, num> values;

  num get(String statId) => values[statId] ?? 0;

  int get money => get('money').toInt();

  int get riskTolerance => get('riskTolerance').toInt();

  int get financialKnowledge => get('financialKnowledge').toInt();

  int get assetSlots => get('assetSlots').toInt();

  int get annualIncome => get('annualIncome').toInt();

  double get returnStat => get('return').toDouble();

  double get volatility => get('volatility').toDouble();

  double get diversification => get('diversification').toDouble();

  double get sharpeRatio => get('sharpeRatio').toDouble();

  double get managementCostDrag => get('managementCostDrag').toDouble();

  double get liquidityRatio => get('liquidityRatio').toDouble();

  double get taxDrag => get('taxDrag').toDouble();

  double get emotionalReaction => get('emotionalReaction').toDouble();

  double get knowledge => get('knowledge').toDouble();

  int get investmentHorizonRemaining =>
      get('investmentHorizonRemaining').toInt();

  double get savingsRate => get('savingsRate').toDouble();

  double get behavioralBias => get('behavioralBias').toDouble();

  CharacterStats copyWithUpdates(Map<String, num> updates) {
    final newValues = Map<String, num>.from(values);
    for (final entry in updates.entries) {
      final current = newValues[entry.key] ?? 0;
      newValues[entry.key] = (current.toDouble() + entry.value).toDouble();
    }
    return CharacterStats(newValues);
  }

  CharacterStats copyWith(Map<String, num> newValues) {
    return CharacterStats(Map<String, num>.from(newValues));
  }
}
