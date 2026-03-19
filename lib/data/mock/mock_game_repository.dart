import 'package:start_hack_2026/data/loaders/json_data_loader.dart';
import 'package:start_hack_2026/data/repositories/game_repository.dart';
import 'package:start_hack_2026/domain/entities/character.dart';
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
  Future<List<StoreItem>> getStoreOffer({int itemCount = 4}) async {
    final items = await getStoreItems();
    final assets = await getStoreAssets();
    final combined = [...items, ...assets]..shuffle();
    return combined.take(itemCount).toList();
  }
}
