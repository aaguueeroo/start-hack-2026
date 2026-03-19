import 'package:flutter/foundation.dart';
import 'package:start_hack_2026/data/repositories/game_repository.dart';
import 'package:start_hack_2026/domain/entities/character.dart';
import 'package:start_hack_2026/domain/entities/owned_item.dart';
import 'package:start_hack_2026/domain/entities/stat_schema.dart';
import 'package:start_hack_2026/domain/entities/store_item.dart';
import 'package:start_hack_2026/engine/calculation_engine.dart';
import 'package:start_hack_2026/engine/game_engine.dart';

/// Allocation percentage per asset buy (10% of total capital).
const int _allocationPercentPerBuy = 10;

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
  int _allocatedPercent = 0;

  List<StatSchema> get statsSchema => _statsSchema;
  List<StoreItem> get storeOffer => _storeOffer;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get remainingAllocationPercent => 100 - _allocatedPercent;

  Character? get character => _gameEngine.state?.character;
  int get cash => _gameEngine.currentCash;
  Map<String, num> get stats => _gameEngine.getDisplayStats(_statsSchema);
  List<OwnedItem?> get itemSlots => _gameEngine.itemSlots;
  Map<String, PortfolioAsset> get holdings => _gameEngine.currentHoldings;
  int get currentYear => _gameEngine.state?.currentYear ?? 1;
  List<PortfolioHistoryPoint> get portfolioHistory =>
      _gameEngine.portfolioHistory;
  double get currentPortfolioValue => _gameEngine.currentPortfolioValue;

  Future<void> loadStoreData() async {
    _isLoading = true;
    _errorMessage = null;
    _allocatedPercent = 0;
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
    switch (item) {
      case StoreItemItem():
        return _gameEngine.validatePurchase(item, _statsSchema);
      case StoreItemAsset():
        return _canBuyAsset(item);
    }
  }

  bool _canBuyAsset(StoreItemAsset asset) {
    if (remainingAllocationPercent < _allocationPercentPerBuy) return false;
    final totalCapital = _gameEngine.currentPortfolioValue;
    final amountToSpend = totalCapital * (_allocationPercentPerBuy / 100);
    if (_gameEngine.currentCash < amountToSpend) return false;
    final quantity = (amountToSpend / asset.price).floor();
    if (quantity < 1) return false;
    // Need a free asset slot unless adding to existing holding
    final hasExisting = _gameEngine.currentHoldings.containsKey(asset.id);
    if (!hasExisting &&
        _gameEngine.holdingsCount >= _gameEngine.assetSlots) {
      return false;
    }
    return true;
  }

  void buyItem(StoreItemItem item) {
    if (!canBuy(item)) return;
    _gameEngine.applyItemPurchase(item, _statsSchema);
    notifyListeners();
  }

  void buyAsset(StoreItemAsset asset) {
    if (!_canBuyAsset(asset)) return;
    final totalCapital = _gameEngine.currentPortfolioValue;
    final amountToSpend = totalCapital * (_allocationPercentPerBuy / 100);
    final quantity = (amountToSpend / asset.price).floor();
    if (quantity < 1) return;
    _gameEngine.applyAssetPurchase(asset, quantity);
    _allocatedPercent += _allocationPercentPerBuy;
    notifyListeners();
  }

  void purchase(StoreItem item) {
    switch (item) {
      case StoreItemItem():
        buyItem(item);
      case StoreItemAsset():
        buyAsset(item);
    }
    // Cards do not disappear - no replacement
  }

  bool canCombineItems(int slotA, int slotB) {
    return _gameEngine.canCombineItems(slotA, slotB);
  }

  void combineItems(int slotA, int slotB) {
    _gameEngine.combineItems(slotA, slotB, _statsSchema);
    notifyListeners();
  }

  void sellAsset(String assetId) {
    _gameEngine.sellAsset(assetId);
    notifyListeners();
  }

  /// Current total return for an owned asset (from centralized asset engine).
  double getAssetTotalReturnPercent(PortfolioAsset asset) {
    return _gameEngine.assetCalculationEngine.totalReturnPercent(asset);
  }

  /// Call when game state may have changed externally (e.g. after simulation).
  void refreshFromGameState() {
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
