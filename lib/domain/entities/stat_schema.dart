class StatSchema {
  const StatSchema({
    required this.id,
    required this.displayName,
    required this.description,
    this.min,
    this.max,
    this.defaultValue,
  });

  final String id;
  final String displayName;
  final String description;
  final num? min;
  final num? max;
  final num? defaultValue;

  factory StatSchema.fromJson(Map<String, dynamic> json) {
    return StatSchema(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      description: json['description'] as String,
      min: json['min'] as num?,
      max: json['max'] as num?,
      defaultValue: json['default'] as num?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'description': description,
      if (min != null) 'min': min,
      if (max != null) 'max': max,
      if (defaultValue != null) 'default': defaultValue,
    };
  }
}
