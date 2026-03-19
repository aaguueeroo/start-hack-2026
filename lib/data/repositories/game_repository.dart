import 'package:start_hack_2026/domain/entities/character.dart';
import 'package:start_hack_2026/domain/entities/stat_schema.dart';
import 'package:start_hack_2026/domain/entities/store_item.dart';

abstract class GameRepository {
  Future<List<Character>> getCharacters();

  Future<List<StatSchema>> getStatsSchema();

  Future<List<StoreItem>> getStoreItems();

  Future<List<StoreItem>> getStoreAssets();

  Future<List<Map<String, dynamic>>> getEvents();

  Future<List<Map<String, dynamic>>> getLifeEvents();

  /// [currentYear] biases knowledge-item (non-asset) card levels: later years
  /// roll higher levels with higher probability (see mock implementation).
  Future<List<StoreItem>> getStoreOffer({
    int itemCount = 4,
    int currentYear = 1,
  });

  Future<StoreItem> getRandomStoreItem();
}
