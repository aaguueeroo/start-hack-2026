import 'package:start_hack_2026/domain/entities/character.dart';
import 'package:start_hack_2026/domain/entities/stat_schema.dart';
import 'package:start_hack_2026/domain/entities/store_item.dart';

abstract class GameRepository {
  Future<List<Character>> getCharacters();

  Future<List<StatSchema>> getStatsSchema();

  Future<List<StoreItem>> getStoreItems();

  Future<List<StoreItem>> getStoreAssets();

  Future<List<Map<String, dynamic>>> getEvents();

  Future<List<StoreItem>> getStoreOffer({int itemCount = 4});

  Future<StoreItem> getRandomStoreItem();
}
