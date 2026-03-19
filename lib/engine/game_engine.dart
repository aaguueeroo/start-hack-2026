import 'package:start_hack_2026/domain/entities/character.dart';
import 'package:start_hack_2026/domain/entities/character_stats.dart';
import 'package:start_hack_2026/domain/entities/stat_schema.dart';
import 'package:start_hack_2026/domain/entities/store_item.dart';
import 'package:start_hack_2026/engine/calculation_engine.dart';
import 'package:start_hack_2026/engine/simulation_engine.dart';

class GameState {
  const GameState({
    required this.character,
    required this.stats,
    required this.cash,
    required this.holdings,
    required this.purchasedItems,
    this.currentYear = 1,
  });

  final Character character;
  final CharacterStats stats;
  final int cash;
  final Map<String, PortfolioAsset> holdings;
  final List<StoreItemItem> purchasedItems;
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

  void startNewGame(Character character) {
    _state = GameState(
      character: character,
      stats: CharacterStats(Map<String, num>.from(character.initialStats)),
      cash: (character.initialStats['money'] ?? 0).toInt(),
      holdings: {},
      purchasedItems: [],
      currentYear: 1,
    );
  }

  int get currentCash => _state?.cash ?? 0;

  CharacterStats get currentStats => _state?.stats ?? const CharacterStats({});

  Map<String, PortfolioAsset> get currentHoldings =>
      Map.from(_state?.holdings ?? {});

  int get holdingsCount => _state?.holdings.length ?? 0;

  int get assetSlots => currentStats.assetSlots;

  bool validatePurchase(StoreItem item, List<StatSchema> schema) {
    if (_state == null) return false;
    if (item.price > _state!.cash) return false;
    if (item is StoreItemAsset) {
      if (holdingsCount >= assetSlots) return false;
    }
    return true;
  }

  void applyItemPurchase(StoreItemItem item, List<StatSchema> schema) {
    if (_state == null) return;
    _state = GameState(
      character: _state!.character,
      stats: _calculationEngine.applyItemEffects(
        currentStats: _state!.stats,
        item: item,
        schema: schema,
      ),
      cash: _state!.cash - item.price,
      holdings: _state!.holdings,
      purchasedItems: [..._state!.purchasedItems, item],
      currentYear: _state!.currentYear,
    );
  }

  void applyAssetPurchase(StoreItemAsset asset, int quantity) {
    if (_state == null) return;
    final holdings = Map<String, PortfolioAsset>.from(_state!.holdings);
    final existing = holdings[asset.id];
    if (existing != null) {
      holdings[asset.id] = PortfolioAsset(
        assetId: asset.id,
        quantity: existing.quantity + quantity,
        pricePerUnit: asset.price.toDouble(),
        expectedReturn: asset.expectedReturn,
        volatility: asset.volatility,
      );
    } else {
      holdings[asset.id] = PortfolioAsset(
        assetId: asset.id,
        quantity: quantity,
        pricePerUnit: asset.price.toDouble(),
        expectedReturn: asset.expectedReturn,
        volatility: asset.volatility,
      );
    }
    final totalCost = asset.price * quantity;
    _state = GameState(
      character: _state!.character,
      stats: _state!.stats,
      cash: _state!.cash - totalCost,
      holdings: holdings,
      purchasedItems: _state!.purchasedItems,
      currentYear: _state!.currentYear,
    );
  }

  Stream<SimulationResult> startSimulation(List<Map<String, dynamic>> events) {
    if (_state == null) {
      return Stream.empty();
    }
    return _simulationEngine.runSimulation(
      stats: _state!.stats,
      cash: _state!.cash,
      holdings: _state!.holdings,
      eventsConfig: events,
    );
  }

  void completeSimulation(double finalPortfolioValue) {
    if (_state == null) return;
    final newCash = finalPortfolioValue.toInt();
    final annualIncome =
        (_state!.character.initialStats['annualIncome'] ?? 0).toInt();
    _state = GameState(
      character: _state!.character,
      stats: CharacterStats({
        ..._state!.stats.values,
        'money': newCash.toDouble(),
        'annualIncome': annualIncome.toDouble(),
      }),
      cash: newCash + annualIncome,
      holdings: {},
      purchasedItems: [],
      currentYear: _state!.currentYear + 1,
    );
  }
}
