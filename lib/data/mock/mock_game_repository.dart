import 'dart:math' show Random;

import 'package:start_hack_2026/data/loaders/json_data_loader.dart';
import 'package:start_hack_2026/data/repositories/game_repository.dart';
import 'package:start_hack_2026/domain/entities/character.dart';
import 'package:start_hack_2026/engine/game_engine.dart';
import 'package:start_hack_2026/domain/entities/stat_schema.dart';
import 'package:start_hack_2026/domain/entities/store_item.dart';

class MockGameRepository implements GameRepository {
  MockGameRepository({required JsonDataLoader jsonDataLoader})
      : _loader = jsonDataLoader;

  final JsonDataLoader _loader;

  List<Character>? _charactersCache;
  List<StatSchema>? _statsSchemaCache;
  List<StoreItem>? _itemsCache;
  List<StoreItem>? _assetsCache;
  List<Map<String, dynamic>>? _eventsCache;
  List<Map<String, dynamic>>? _lifeEventsCache;

  @override
  Future<List<Character>> getCharacters() async {
    _charactersCache ??= await _loader.loadCharacters();
    return _charactersCache!;
  }

  @override
  Future<List<StatSchema>> getStatsSchema() async {
    _statsSchemaCache ??= await _loader.loadStatsSchema();
    return _statsSchemaCache!;
  }

  @override
  Future<List<StoreItem>> getStoreItems() async {
    _itemsCache ??= await _loader.loadItems();
    return _itemsCache!;
  }

  @override
  Future<List<StoreItem>> getStoreAssets() async {
    _assetsCache ??= await _loader.loadAssets();
    return _assetsCache!;
  }

  @override
  Future<List<Map<String, dynamic>>> getEvents() async {
    _eventsCache ??= await _loader.loadEvents();
    return _eventsCache!;
  }

  @override
  Future<List<Map<String, dynamic>>> getLifeEvents() async {
    _lifeEventsCache ??= await _loader.loadLifeEvents();
    return _lifeEventsCache!;
  }

  /// Rolls 1–3 for knowledge cards; weights shift toward 2–3 as [currentYear] increases.
  static int rollKnowledgeItemLevel(int currentYear, Random random) {
    final maxY = GameEngine.maxRounds;
    final rawT = (currentYear.clamp(1, maxY) - 1) / (maxY - 1);
    final t = rawT.clamp(0.0, 1.0);
    final w1 = 0.88 + t * (0.28 - 0.88);
    final w2 = 0.10 + t * (0.37 - 0.10);
    final w3 = 0.02 + t * (0.35 - 0.02);
    final sum = w1 + w2 + w3;
    var roll = random.nextDouble() * sum;
    if (roll < w1) {
      return 1;
    }
    roll -= w1;
    if (roll < w2) {
      return 2;
    }
    return 3;
  }

  static StoreItemItem _withRolledLevel(
    StoreItemItem base,
    int level,
  ) {
    if (level == base.level) {
      return base;
    }
    return StoreItemItem(
      id: base.id,
      name: base.name,
      icon: base.icon,
      price: base.price * level,
      statEffects: base.statEffects,
      flavourText: base.flavourText,
      level: level,
    );
  }

  @override
  Future<List<StoreItem>> getStoreOffer({
    int itemCount = 4,
    int currentYear = 1,
  }) async {
    final items = await getStoreItems();
    final assets = await getStoreAssets();
    final random = Random();
    final combined = [...items, ...assets]..shuffle(random);
    return combined.take(itemCount).map((StoreItem item) {
      if (item is! StoreItemItem) {
        return item;
      }
      final level = rollKnowledgeItemLevel(currentYear, random);
      return _withRolledLevel(item, level);
    }).toList();
  }

  @override
  Future<StoreItem> getRandomStoreItem() async {
    final items = await getStoreItems();
    final assets = await getStoreAssets();
    final combined = [...items, ...assets];
    if (combined.isEmpty) {
      throw StateError('No store items available');
    }
    return combined[Random().nextInt(combined.length)];
  }
}
