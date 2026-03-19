import 'package:flutter/foundation.dart';
import 'package:start_hack_2026/data/repositories/game_repository.dart';
import 'package:start_hack_2026/domain/entities/character.dart';
import 'package:start_hack_2026/domain/entities/stat_schema.dart';
import 'package:start_hack_2026/domain/entities/store_item.dart';
import 'package:start_hack_2026/engine/game_engine.dart';

class StoreController extends ChangeNotifier {
  StoreController({
    required GameRepository gameRepository,
    required GameEngine gameEngine,
  })  : _gameRepository = gameRepository,
        _gameEngine = gameEngine;

  final GameRepository _gameRepository;
  final GameEngine _gameEngine;

  List<StatSchema> _statsSchema = [];
  List<StoreItem> _storeOffer = [];
  bool _isLoading = true;
  String? _errorMessage;

  List<StatSchema> get statsSchema => _statsSchema;
  List<StoreItem> get storeOffer => _storeOffer;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Character? get character => _gameEngine.state?.character;
  int get cash => _gameEngine.currentCash;
  Map<String, num> get stats => _gameEngine.currentStats.values;
  int get currentYear => _gameEngine.state?.currentYear ?? 1;

  Future<void> loadStoreData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _statsSchema = await _gameRepository.getStatsSchema();
      _storeOffer = await _gameRepository.getStoreOffer();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load store: $e';
      if (kDebugMode) {
        print(_errorMessage);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshStoreOffer() async {
    try {
      _storeOffer = await _gameRepository.getStoreOffer();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to refresh store: $e');
      }
    }
  }

  bool canBuy(StoreItem item) {
    return _gameEngine.validatePurchase(item, _statsSchema);
  }

  void buyItem(StoreItemItem item) {
    if (!canBuy(item)) return;
    _gameEngine.applyItemPurchase(item, _statsSchema);
    notifyListeners();
  }

  void buyAsset(StoreItemAsset asset, {int quantity = 1}) {
    if (!canBuy(asset)) return;
    _gameEngine.applyAssetPurchase(asset, quantity);
    notifyListeners();
  }

  void purchase(StoreItem item) {
    switch (item) {
      case StoreItemItem():
        buyItem(item);
      case StoreItemAsset():
        buyAsset(item);
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
