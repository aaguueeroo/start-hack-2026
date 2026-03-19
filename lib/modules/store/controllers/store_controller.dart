import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:start_hack_2026/data/repositories/game_repository.dart';
import 'package:start_hack_2026/domain/entities/character.dart';
import 'package:start_hack_2026/domain/entities/owned_item.dart';
import 'package:start_hack_2026/domain/entities/stat_schema.dart';
import 'package:start_hack_2026/domain/entities/store_item.dart';
import 'package:start_hack_2026/engine/calculation_engine.dart';
import 'package:start_hack_2026/engine/game_engine.dart';

/// Allocation percentage per asset buy (10% of total capital).
const int _allocationPercentPerBuy = 10;

/// Reshuffle cost progression: 1000 -> 2000 -> 5000, then +2000 per reshuffle
/// (counter resets after each store purchase so typical play stays on the first tier).
const List<int> _reshuffleCosts = [1000, 2000, 5000];
const int _reshuffleCostIncrement = 2000;

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

  /// Max number of different assets this character can hold (from stats).
  int get maxAssetSlots => _gameEngine.assetSlots;

  Future<void> loadStoreData() async {
    _isLoading = true;
    _errorMessage = null;
    _reshuffleCount = 0;
    _syncAllocatedPercent();
    notifyListeners();
    try {
      _statsSchema = await _gameRepository.getStatsSchema();
      _storeOffer = await _gameRepository.getStoreOffer(
        currentYear: currentYear,
      );
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
    if (_reshuffleCount < _reshuffleCosts.length) {
      return _reshuffleCosts[_reshuffleCount];
    }
    final baseCost = _reshuffleCosts.last;
    final extraReshuffles = _reshuffleCount - _reshuffleCosts.length;
    return baseCost + (_reshuffleCostIncrement * extraReshuffles);
  }

  bool get canReshuffle => _gameEngine.currentCash >= reshuffleCost;

  Future<void> reshuffleStoreOffer() async {
    final cost = reshuffleCost;
    if (_gameEngine.currentCash < cost) return;
    try {
      final newOffer = await _gameRepository.getStoreOffer(
        currentYear: currentYear,
      );
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
      _storeOffer = await _gameRepository.getStoreOffer(
        currentYear: currentYear,
      );
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

  int? getKnowledgePurchaseTargetSlot(StoreItemItem item) =>
      _gameEngine.getKnowledgePurchaseTargetSlot(item);

  bool hasExistingAssetHolding(String assetId) =>
      _gameEngine.currentHoldings.containsKey(assetId);

  int get storeAssetAllocationPercentPerBuy => _allocationPercentPerBuy;

  /// Cash deducted when investing in this asset (same quantity as [purchase]).
  int getStoreAssetPurchaseCashCost(StoreItemAsset asset) {
    final double totalCapital = _gameEngine.currentPortfolioValue;
    final double amountToSpend =
        totalCapital * (_allocationPercentPerBuy / 100);
    final int quantity = (amountToSpend / asset.price).floor();
    if (quantity < 1) {
      return asset.price;
    }
    return quantity * asset.price;
  }

  bool _canBuyAsset(StoreItemAsset asset) {
    final hasExisting = _gameEngine.currentHoldings.containsKey(asset.id);
    if (!hasExisting &&
        _gameEngine.holdingsCount >= _gameEngine.assetSlots) {
      return false;
    }
    // Adding to an existing line needs 10% headroom on the global allocation
    // budget. Opening a *new* slot can rebalance existing labels in the engine
    // to free 10%, so we only gate on headroom when stacking the same asset.
    if (hasExisting && remainingAllocationPercent < _allocationPercentPerBuy) {
      return false;
    }
    final totalCapital = _gameEngine.currentPortfolioValue;
    final amountToSpend = totalCapital * (_allocationPercentPerBuy / 100);
    if (_gameEngine.currentCash < amountToSpend) return false;
    final quantity = (amountToSpend / asset.price).floor();
    if (quantity < 1) return false;
    return true;
  }

  /// Returns whether the purchase was applied.
  bool buyItem(StoreItemItem item) {
    if (!canBuy(item)) return false;
    _gameEngine.applyItemPurchase(item, _statsSchema);
    return true;
  }

  bool _slotMatchesItem(int offerIndex, StoreItem item) {
    if (offerIndex < 0 || offerIndex >= _storeOffer.length) return false;
    final slot = _storeOffer[offerIndex];
    if (identical(slot, item)) return true;
    if (slot is StoreItemItem && item is StoreItemItem) {
      return slot.id == item.id && slot.level == item.level;
    }
    if (slot is StoreItemAsset && item is StoreItemAsset) {
      return slot.id == item.id;
    }
    return false;
  }

  bool _applyAssetPurchase(StoreItemAsset asset) {
    if (!_canBuyAsset(asset)) return false;
    final totalCapital = _gameEngine.currentPortfolioValue;
    final amountToSpend = totalCapital * (_allocationPercentPerBuy / 100);
    final quantity = (amountToSpend / asset.price).floor();
    if (quantity < 1) return false;
    _gameEngine.applyAssetPurchase(asset, quantity,
        allocationPercent: _allocationPercentPerBuy);
    _syncAllocatedPercent();
    return true;
  }

  void _removeOfferAt(int offerIndex) {
    if (offerIndex < 0 || offerIndex >= _storeOffer.length) return;
    _storeOffer = List<StoreItem>.from(_storeOffer)..removeAt(offerIndex);
  }

  /// After any purchase, next shuffle uses the first-tier price again. Without
  /// this, the second shuffle in the same visit costs 2000+ while cash is often
  /// already reduced by the first shuffle and purchases.
  void _resetReshuffleCostAfterPurchase() {
    _reshuffleCount = 0;
  }

  /// Returns whether a purchase was completed (card is removed from the offer).
  bool purchase(StoreItem item, {required int offerIndex}) {
    switch (item) {
      case final StoreItemItem i:
        if (!_slotMatchesItem(offerIndex, i)) return false;
        if (!buyItem(i)) return false;
        _removeOfferAt(offerIndex);
        _resetReshuffleCostAfterPurchase();
        HapticFeedback.lightImpact();
        notifyListeners();
        return true;
      case final StoreItemAsset a:
        if (!_slotMatchesItem(offerIndex, a)) return false;
        if (!_applyAssetPurchase(a)) return false;
        _removeOfferAt(offerIndex);
        _resetReshuffleCostAfterPurchase();
        // Card leaves the shelf (no replacement). The same asset can stack
        // when it shows up again after reshuffle or a new round’s store refresh.
        HapticFeedback.lightImpact();
        notifyListeners();
        return true;
    }
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
    _syncAllocatedPercent();
    notifyListeners();
  }

  /// Allocation percent allocated to this asset (fixed at time of investment).
  int getAssetAllocationPercent(String assetId) =>
      _gameEngine.getAssetAllocationPercent(assetId);

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
