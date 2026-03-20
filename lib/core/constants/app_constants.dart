import 'package:flutter/material.dart';

abstract final class AppConstants {
  static const String appName = 'InvestQuest';
  static const String homeTagline =
      'Stonks school: now with fewer yelling uncles';

  static const Color primaryColor = Color(0xFF6C5CE7);
  static const Color accentColor = Color(0xFF00CEC9);
  static const Color successColor = Color(0xFF00B894);
  static const Color dangerColor = Color(0xFFE17055);
  static const Color warningColor = Color(0xFFFDCB6E);

  static const String charactersPath = 'assets/data/characters.json';
  static const String itemsPath = 'assets/data/items.json';
  static const String assetsPath = 'assets/data/assets.json';
  static const String statsSchemaPath = 'assets/data/stats_schema.json';
  static const String eventsPath = 'assets/data/events.json';
  static const String lifeEventsPath = 'assets/data/life_events.json';
}
