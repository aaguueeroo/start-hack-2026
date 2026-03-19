import 'package:flutter/foundation.dart';
import 'package:start_hack_2026/data/repositories/game_repository.dart';
import 'package:start_hack_2026/domain/entities/character.dart';
import 'package:start_hack_2026/engine/game_engine.dart';

class GameController extends ChangeNotifier {
  GameController({
    required GameRepository gameRepository,
    required GameEngine gameEngine,
  })  : _gameRepository = gameRepository,
        _gameEngine = gameEngine;

  final GameRepository _gameRepository;
  final GameEngine _gameEngine;

  List<Character> _characters = [];
  bool _isLoading = true;
  String? _errorMessage;

  List<Character> get characters => _characters;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  GameEngine get gameEngine => _gameEngine;

  Future<void> loadCharacters() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _characters = await _gameRepository.getCharacters();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load characters: $e';
      _characters = [];
      if (kDebugMode) {
        debugPrint(_errorMessage);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void startNewGame(Character character) {
    _gameEngine.startNewGame(character);
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
