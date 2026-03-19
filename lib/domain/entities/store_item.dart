sealed class StoreItem {
  const StoreItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.price,
    this.flavourText,
  });

  final String id;
  final String name;
  final String icon;
  final int price;
  final String? flavourText;

  factory StoreItem.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('statEffects')) {
      return StoreItemItem.fromJson(json);
    }
    if (json.containsKey('expectedReturn') && json.containsKey('volatility')) {
      return StoreItemAsset.fromJson(json);
    }
    throw ArgumentError('Unknown store item type: $json');
  }
}

class StoreItemItem extends StoreItem {
  const StoreItemItem({
    required super.id,
    required super.name,
    required super.icon,
    required super.price,
    required this.statEffects,
    super.flavourText,
    this.level = 1,
  });

  final Map<String, double> statEffects;
  final int level;

  StoreItemItem copyWithLevel(int newLevel) {
    return StoreItemItem(
      id: id,
      name: name,
      icon: icon,
      price: price,
      statEffects: statEffects,
      flavourText: flavourText,
      level: newLevel,
    );
  }

  Map<String, double> getScaledStatEffects() {
    final scaled = <String, double>{};
    for (final entry in statEffects.entries) {
      scaled[entry.key] = entry.value * level;
    }
    return scaled;
  }

  factory StoreItemItem.fromJson(Map<String, dynamic> json) {
    final effectsJson = json['statEffects'] as Map<String, dynamic>? ?? {};
    final statEffects = <String, double>{};
    for (final entry in effectsJson.entries) {
      final value = entry.value;
      if (value is int) {
        statEffects[entry.key] = value.toDouble();
      } else if (value is num) {
        statEffects[entry.key] = value.toDouble();
      }
    }
    return StoreItemItem(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      price: (json['price'] as num).toInt(),
      statEffects: statEffects,
      flavourText: json['flavourText'] as String?,
      level: (json['level'] as num?)?.toInt() ?? 1,
    );
  }
}

class StoreItemAsset extends StoreItem {
  const StoreItemAsset({
    required super.id,
    required super.name,
    required super.icon,
    required super.price,
    required this.expectedReturn,
    required this.volatility,
    super.flavourText,
    this.liquidity = 100,
    this.managementCost = 0,
    this.creditRisk = 0,
    this.currencyRisk = 0,
    this.specialMechanic,
    this.category,
  });

  final double expectedReturn;
  final double volatility;
  final double liquidity;
  final double managementCost;
  final double creditRisk;
  final double currencyRisk;
  final String? specialMechanic;
  final String? category;

  factory StoreItemAsset.fromJson(Map<String, dynamic> json) {
    return StoreItemAsset(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      price: (json['price'] as num).toInt(),
      expectedReturn: (json['expectedReturn'] as num).toDouble(),
      volatility: (json['volatility'] as num).toDouble(),
      flavourText: json['flavourText'] as String?,
      liquidity: (json['liquidity'] as num?)?.toDouble() ?? 100,
      managementCost: (json['managementCost'] as num?)?.toDouble() ?? 0,
      creditRisk: (json['creditRisk'] as num?)?.toDouble() ?? 0,
      currencyRisk: (json['currencyRisk'] as num?)?.toDouble() ?? 0,
      specialMechanic: json['specialMechanic'] as String?,
      category: json['category'] as String?,
    );
  }
}
