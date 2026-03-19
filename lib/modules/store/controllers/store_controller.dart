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

/// Reshuffle cost progression: 1000 -> 2000 -> 5000 (capped).
const List<int> _reshuffleCosts = [1000, 2000, 5000];
const int _maxReshuffleCost = 5000;

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
  final Set<String> _purchasedLearningCardIds = {};
  int _reshuffleCount = 0;

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
  int get maxRounds => GameEngine.maxRounds;
  bool get canPlayNextRound => currentYear <= maxRounds;
  bool get hasReachedRoundLimit => !canPlayNextRound;
  List<PortfolioHistoryPoint> get portfolioHistory =>
      _gameEngine.portfolioHistory;
  double get currentPortfolioValue => _gameEngine.currentPortfolioValue;

  Future<void> loadStoreData() async {
    _isLoading = true;
    _errorMessage = null;
    _purchasedLearningCardIds.clear();
    _reshuffleCount = 0;
    _syncAllocatedPercent();
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

  void _syncAllocatedPercent() {
    var total = 0;
    for (final id in _gameEngine.currentHoldings.keys) {
      total += _gameEngine.getAssetAllocationPercent(id);
    }
    _allocatedPercent = total;
  }

  int get reshuffleCost {
    if (_reshuffleCount >= _reshuffleCosts.length) {
      return _maxReshuffleCost;
    }
    return _reshuffleCosts[_reshuffleCount];
  }

  bool get canReshuffle => _gameEngine.currentCash >= reshuffleCost;

  Future<void> reshuffleStoreOffer() async {
    final cost = reshuffleCost;
    if (_gameEngine.currentCash < cost) return;
    try {
      final newOffer = await _gameRepository.getStoreOffer();
      if (!_gameEngine.spendCash(cost)) return;
      _reshuffleCount++;
      _storeOffer = newOffer;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to reshuffle store: $e');
      }
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
        if (isLearningCardPurchased(item)) return false;
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
    _purchasedLearningCardIds.add('${item.id}_${item.level}');
    notifyListeners();
  }

  void buyAsset(StoreItemAsset asset) {
    if (!_canBuyAsset(asset)) return;
    final totalCapital = _gameEngine.currentPortfolioValue;
    final amountToSpend = totalCapital * (_allocationPercentPerBuy / 100);
    final quantity = (amountToSpend / asset.price).floor();
    if (quantity < 1) return;
    _gameEngine.applyAssetPurchase(asset, quantity,
        allocationPercent: _allocationPercentPerBuy);
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
    final allocation = _gameEngine.getAssetAllocationPercent(assetId);
    _gameEngine.sellAsset(assetId);
    _allocatedPercent = (_allocatedPercent - allocation).clamp(0, 100);
    notifyListeners();
  }

  /// Allocation percent allocated to this asset (fixed at time of investment).
  int getAssetAllocationPercent(String assetId) =>
      _gameEngine.getAssetAllocationPercent(assetId);

  bool isLearningCardPurchased(StoreItemItem item) =>
      _purchasedLearningCardIds.contains('${item.id}_${item.level}');

  /// Current total return for an owned asset (from centralized asset engine).
  double getAssetTotalReturnPercent(PortfolioAsset asset) {
    return _gameEngine.assetCalculationEngine.totalReturnPercent(asset);
  }

  /// Call when game state may have changed externally (e.g. after simulation).
  Future<void> refreshFromGameState() async {
    _syncAllocatedPercent();
    _reshuffleCount = 0;
    await refreshStoreOffer();
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
