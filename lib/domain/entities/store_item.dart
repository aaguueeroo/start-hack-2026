sealed class StoreItem {
  const StoreItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.price,
  });

  final String id;
  final String name;
  final String icon;
  final int price;

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
  });

  final Map<String, int> statEffects;

  factory StoreItemItem.fromJson(Map<String, dynamic> json) {
    final effectsJson = json['statEffects'] as Map<String, dynamic>? ?? {};
    final statEffects = <String, int>{};
    for (final entry in effectsJson.entries) {
      final value = entry.value;
      if (value is int) {
        statEffects[entry.key] = value;
      } else if (value is num) {
        statEffects[entry.key] = value.toInt();
      }
    }
    return StoreItemItem(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      price: (json['price'] as num).toInt(),
      statEffects: statEffects,
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
  });

  final double expectedReturn;
  final double volatility;

  factory StoreItemAsset.fromJson(Map<String, dynamic> json) {
    return StoreItemAsset(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      price: (json['price'] as num).toInt(),
      expectedReturn: (json['expectedReturn'] as num).toDouble(),
      volatility: (json['volatility'] as num).toDouble(),
    );
  }
}
