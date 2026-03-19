import 'package:start_hack_2026/domain/entities/character.dart';
import 'package:start_hack_2026/domain/entities/character_stats.dart';
import 'package:start_hack_2026/domain/entities/owned_item.dart';
import 'package:start_hack_2026/domain/entities/stat_schema.dart';
import 'package:start_hack_2026/domain/entities/store_item.dart';
import 'package:start_hack_2026/engine/calculation_engine.dart';
import 'package:start_hack_2026/engine/simulation_engine.dart';

class PortfolioHistoryPoint {
  const PortfolioHistoryPoint({
    required this.year,
    required this.value,
  });

  final int year;
  final double value;
}

class GameState {
  const GameState({
    required this.character,
    required this.stats,
    required this.cash,
    required this.holdings,
    required this.itemSlots,
    required this.portfolioHistory,
    this.currentYear = 1,
  });

  final Character character;
  final CharacterStats stats;
  final int cash;
  final Map<String, PortfolioAsset> holdings;
  final List<OwnedItem?> itemSlots;
  final List<PortfolioHistoryPoint> portfolioHistory;
  final int currentYear;
}

class GameEngine {
  GameEngine({
    CalculationEngine? calculationEngine,
    SimulationEngine? simulationEngine,
  })  : _calculationEngine = calculationEngine ?? CalculationEngine(),
        _simulationEngine = simulationEngine ?? SimulationEngine();

  final CalculationEngine _calculationEngine;
  final SimulationEngine _simulationEngine;

  GameState? _state;

  GameState? get state => _state;

  static const int _itemSlotsCount = 6;

  void startNewGame(Character character) {
    final initialCash = (character.initialStats['money'] ?? 0).toInt();
    _state = GameState(
      character: character,
      stats: CharacterStats(Map<String, num>.from(character.initialStats)),
      cash: initialCash,
      holdings: {},
      itemSlots: List.filled(_itemSlotsCount, null),
      portfolioHistory: [
        PortfolioHistoryPoint(year: 1, value: initialCash.toDouble()),
      ],
      currentYear: 1,
    );
  }

  int get currentCash => _state?.cash ?? 0;

  CharacterStats get currentStats => _state?.stats ?? const CharacterStats({});

  Map<String, PortfolioAsset> get currentHoldings =>
      Map.from(_state?.holdings ?? {});

  List<OwnedItem?> get itemSlots =>
      List.from(_state?.itemSlots ?? List.filled(_itemSlotsCount, null));

  int get holdingsCount => _state?.holdings.length ?? 0;

  int get assetSlots => currentStats.assetSlots;

  List<PortfolioHistoryPoint> get portfolioHistory =>
      List.from(_state?.portfolioHistory ?? []);

  double get currentPortfolioValue {
    if (_state == null) return 0;
    var total = _state!.cash.toDouble();
    for (final asset in _state!.holdings.values) {
      total += asset.totalValue;
    }
    return total;
  }

  bool validatePurchase(StoreItem item, List<StatSchema> schema) {
    if (_state == null) return false;
    if (item.price > _state!.cash) return false;
    if (item is StoreItemAsset) {
      if (holdingsCount >= assetSlots) return false;
    }
    if (item is StoreItemItem) {
      final freeSlots = _state!.itemSlots.where((s) => s == null).length;
      if (freeSlots > 0) return true;
      final mergeTargetSlot = _findMergeTargetSlotForStoreItem(item);
      if (mergeTargetSlot == null) return false;
    }
    return true;
  }

  int? _findMergeTargetSlotForStoreItem(StoreItemItem item) {
    if (_state == null) return null;
    for (var i = 0; i < _state!.itemSlots.length; i++) {
      final owned = _state!.itemSlots[i];
      if (owned == null) continue;
      if (owned.id != item.id || owned.level != item.level) continue;
      if (owned.level >= 3) continue;
      return i;
    }
    return null;
  }

  void applyItemPurchase(StoreItemItem item, List<StatSchema> schema) {
    if (_state == null) return;
    final slots = List<OwnedItem?>.from(_state!.itemSlots);
    final firstEmpty = slots.indexWhere((s) => s == null);
    if (firstEmpty >= 0) {
      final owned = OwnedItem(
        item: item,
        slotIndex: firstEmpty,
        level: item.level,
      );
      slots[firstEmpty] = owned;
      _state = GameState(
        character: _state!.character,
        stats: _calculationEngine.applyItemEffects(
          currentStats: _state!.stats,
          item: item,
          schema: schema,
          levelMultiplier: item.level,
        ),
        cash: _state!.cash - item.price,
        holdings: _state!.holdings,
        itemSlots: slots,
        portfolioHistory: _state!.portfolioHistory,
        currentYear: _state!.currentYear,
      );
      return;
    }
    final mergeTargetSlot = _findMergeTargetSlotForStoreItem(item);
    if (mergeTargetSlot != null) {
      _applyStoreItemMerge(item, mergeTargetSlot, schema);
    }
  }

  void _applyStoreItemMerge(
    StoreItemItem storeItem,
    int targetSlotIndex,
    List<StatSchema> schema,
  ) {
    if (_state == null) return;
    final existing = _state!.itemSlots[targetSlotIndex];
    if (existing == null) return;
    if (existing.id != storeItem.id || existing.level != storeItem.level) return;
    if (existing.level >= 3) return;
    final slots = List<OwnedItem?>.from(_state!.itemSlots);
    final newLevel = existing.level + 1;
    final combinedItem = existing.item.copyWithLevel(newLevel);
    final combined = OwnedItem(
      item: combinedItem,
      slotIndex: targetSlotIndex,
      level: newLevel,
    );
    var newStats = _state!.stats;
    final subtractEffects = <String, num>{};
    for (final entry in existing.item.statEffects.entries) {
      subtractEffects[entry.key] = -(entry.value * existing.level);
    }
    for (final entry in storeItem.statEffects.entries) {
      final current = subtractEffects[entry.key] ?? 0;
      subtractEffects[entry.key] = current - (entry.value * storeItem.level);
    }
    newStats = newStats.copyWithUpdates(subtractEffects);
    newStats = _calculationEngine.applyItemEffects(
      currentStats: newStats,
      item: combinedItem,
      schema: schema,
      levelMultiplier: newLevel,
    );
    slots[targetSlotIndex] = combined;
    _state = GameState(
      character: _state!.character,
      stats: newStats,
      cash: _state!.cash - storeItem.price,
      holdings: _state!.holdings,
      itemSlots: slots,
      portfolioHistory: _state!.portfolioHistory,
      currentYear: _state!.currentYear,
    );
  }

  bool canCombineItems(int slotA, int slotB) {
    if (_state == null) return false;
    if (slotA == slotB) return false;
    if (slotA < 0 || slotA >= _state!.itemSlots.length) return false;
    if (slotB < 0 || slotB >= _state!.itemSlots.length) return false;
    final a = _state!.itemSlots[slotA];
    final b = _state!.itemSlots[slotB];
    if (a == null || b == null) return false;
    if (a.id != b.id || a.level != b.level) return false;
    if (a.level >= 3) return false;
    return true;
  }

  void combineItems(int slotA, int slotB, List<StatSchema> schema) {
    if (!canCombineItems(slotA, slotB) || _state == null) return;
    final slots = List<OwnedItem?>.from(_state!.itemSlots);
    final a = slots[slotA]!;
    final b = slots[slotB]!;
    final newLevel = a.level + 1;
    final combinedItem = a.item.copyWithLevel(newLevel);
    final combined = OwnedItem(
      item: combinedItem,
      slotIndex: slotB,
      level: newLevel,
    );
    var newStats = _state!.stats;
    final subtractEffects = <String, num>{};
    for (final entry in a.item.statEffects.entries) {
      subtractEffects[entry.key] = -(entry.value * a.level);
    }
    for (final entry in b.item.statEffects.entries) {
      final current = subtractEffects[entry.key] ?? 0;
      subtractEffects[entry.key] = current - (entry.value * b.level);
    }
    newStats = newStats.copyWithUpdates(subtractEffects);
    newStats = _calculationEngine.applyItemEffects(
      currentStats: newStats,
      item: combinedItem,
      schema: schema,
      levelMultiplier: newLevel,
    );
    slots[slotA] = null;
    slots[slotB] = combined;
    _state = GameState(
      character: _state!.character,
      stats: newStats,
      cash: _state!.cash,
      holdings: _state!.holdings,
      itemSlots: slots,
      portfolioHistory: _state!.portfolioHistory,
      currentYear: _state!.currentYear,
    );
  }

  void applyAssetPurchase(StoreItemAsset asset, int quantity) {
    if (_state == null) return;
    final holdings = Map<String, PortfolioAsset>.from(_state!.holdings);
    final existing = holdings[asset.id];
    final newQuantity = quantity;
    final newPrice = asset.price.toDouble();
    if (existing != null) {
      final totalCost = existing.totalValue + (newQuantity * newPrice);
      final totalQty = existing.quantity + newQuantity;
      final avgPrice = totalCost / totalQty;
      holdings[asset.id] = PortfolioAsset(
        assetId: asset.id,
        name: asset.name,
        icon: asset.icon,
        quantity: totalQty,
        pricePerUnit: avgPrice,
        expectedReturn: asset.expectedReturn,
        volatility: asset.volatility,
        purchasePrice: avgPrice,
        liquidity: asset.liquidity,
        managementCost: asset.managementCost,
      );
    } else {
      holdings[asset.id] = PortfolioAsset(
        assetId: asset.id,
        name: asset.name,
        icon: asset.icon,
        quantity: newQuantity,
        pricePerUnit: newPrice,
        expectedReturn: asset.expectedReturn,
        volatility: asset.volatility,
        purchasePrice: newPrice,
        liquidity: asset.liquidity,
        managementCost: asset.managementCost,
      );
    }
    final totalCost = asset.price * quantity;
    _state = GameState(
      character: _state!.character,
      stats: _state!.stats,
      cash: _state!.cash - totalCost,
      holdings: holdings,
      itemSlots: _state!.itemSlots,
      portfolioHistory: _state!.portfolioHistory,
      currentYear: _state!.currentYear,
    );
  }

  int getAssetSaleValue(String assetId) {
    final asset = _state?.holdings[assetId];
    if (asset == null) return 0;
    return (asset.totalValue).toInt();
  }

  void sellAsset(String assetId) {
    if (_state == null) return;
    final asset = _state!.holdings[assetId];
    if (asset == null) return;
    final holdings = Map<String, PortfolioAsset>.from(_state!.holdings);
    holdings.remove(assetId);
    final saleValue = asset.totalValue.toInt();
    _state = GameState(
      character: _state!.character,
      stats: _state!.stats,
      cash: _state!.cash + saleValue,
      holdings: holdings,
      itemSlots: _state!.itemSlots,
      portfolioHistory: _state!.portfolioHistory,
      currentYear: _state!.currentYear,
    );
  }

  Stream<SimulationResult> startSimulation(List<Map<String, dynamic>> events) {
    if (_state == null) {
      return Stream.empty();
    }
    var statsToPass = _state!.stats;
    final charMonthly = _state!.character.initialStats['monthlySavings'];
    if ((statsToPass.get('monthlySavings') == 0) && charMonthly != null) {
      final merged = Map<String, num>.from(statsToPass.values);
      merged['monthlySavings'] = charMonthly;
      statsToPass = CharacterStats(merged);
    }
    return _simulationEngine.runSimulation(
      stats: statsToPass,
      cash: _state!.cash,
      holdings: _state!.holdings,
      eventsConfig: events,
    );
  }

  Map<String, num> getDisplayStats(List<StatSchema> schema) {
    if (_state == null) return {};
    final baseStats = Map<String, num>.from(_state!.character.initialStats);
    baseStats['money'] = _state!.cash.toDouble();
    final stats = _calculationEngine.calculatePortfolioStats(
      baseStats: baseStats,
      holdings: _state!.holdings,
      itemSlots: _state!.itemSlots,
      schema: schema,
    );
    // Ensure monthlySavings is always present for display
    if (!stats.containsKey('monthlySavings')) {
      stats['monthlySavings'] =
          (_state!.character.initialStats['monthlySavings'] ?? 0).toDouble();
    }
    return stats;
  }

  void completeSimulation(double finalPortfolioValue) {
    if (_state == null) return;
    final cashAfterSim = finalPortfolioValue.toInt();
    final monthlySavings =
        (_state!.character.initialStats['monthlySavings'] ?? 0).toInt();
    final nextYear = _state!.currentYear + 1;
    final baseStats = Map<String, num>.from(_state!.character.initialStats);
    baseStats['money'] = cashAfterSim.toDouble();
    baseStats['monthlySavings'] = monthlySavings.toDouble();
    _state = GameState(
      character: _state!.character,
      stats: CharacterStats(baseStats),
      cash: cashAfterSim,
      holdings: {},
      itemSlots: List.filled(_itemSlotsCount, null),
      portfolioHistory: [
        ..._state!.portfolioHistory,
        PortfolioHistoryPoint(year: nextYear, value: cashAfterSim.toDouble()),
      ],
      currentYear: nextYear,
    );
  }
}
