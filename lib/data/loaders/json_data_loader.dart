import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:start_hack_2026/core/constants/app_constants.dart';
import 'package:start_hack_2026/domain/entities/character.dart';
import 'package:start_hack_2026/domain/entities/stat_schema.dart';
import 'package:start_hack_2026/domain/entities/store_item.dart';

class JsonDataLoader {
  Future<List<Character>> loadCharacters() async {
    try {
      final json = await rootBundle.loadString(AppConstants.charactersPath);
      final data = jsonDecode(json) as Map<String, dynamic>;
      final list = data['characters'] as List<dynamic>;
      return list
          .map((e) => Character.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('JsonDataLoader: Failed to load characters: $e');
      return [];
    }
  }

  Future<List<StatSchema>> loadStatsSchema() async {
    try {
      final json = await rootBundle.loadString(AppConstants.statsSchemaPath);
      final data = jsonDecode(json) as Map<String, dynamic>;
      final list = data['stats'] as List<dynamic>;
      return list
          .map((e) => StatSchema.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('JsonDataLoader: Failed to load stats schema: $e');
      return [];
    }
  }

  Future<List<StoreItem>> loadItems() async {
    try {
      final json = await rootBundle.loadString(AppConstants.itemsPath);
      final data = jsonDecode(json) as Map<String, dynamic>;
      final list = data['items'] as List<dynamic>;
      return list
          .map((e) => StoreItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('JsonDataLoader: Failed to load items: $e');
      return [];
    }
  }

  Future<List<StoreItem>> loadAssets() async {
    try {
      final json = await rootBundle.loadString(AppConstants.assetsPath);
      final data = jsonDecode(json) as Map<String, dynamic>;
      final list = data['assets'] as List<dynamic>;
      return list
          .map((e) => StoreItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('JsonDataLoader: Failed to load assets: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> loadEvents() async {
    try {
      final json = await rootBundle.loadString(AppConstants.eventsPath);
      final data = jsonDecode(json) as Map<String, dynamic>;
      final list = data['events'] as List<dynamic>;
      return list.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('JsonDataLoader: Failed to load events: $e');
      return [];
    }
  }
}
