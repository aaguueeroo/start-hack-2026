import 'package:flutter/foundation.dart';
import 'package:start_hack_2026/data/mock/mock_leaderboard_data.dart';
import 'package:start_hack_2026/data/services/local_leaderboard_service.dart';
import 'package:start_hack_2026/data/services/supabase_leaderboard_service.dart';
import 'package:start_hack_2026/domain/entities/leaderboard_entry.dart';

class LeaderboardController extends ChangeNotifier {
  LeaderboardController({
    required LocalLeaderboardService localService,
    required SupabaseLeaderboardService supabaseService,
  }) : _localService = localService,
       _supabaseService = supabaseService;

  final LocalLeaderboardService _localService;
  final SupabaseLeaderboardService _supabaseService;

  List<LeaderboardEntry> _entries = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isDemoData = false;

  List<LeaderboardEntry> get entries => _entries;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isShowingDemoData => _isDemoData;
  bool get isSupabaseAvailable => _supabaseService.isAvailable;

  Future<void> loadTopScores({int limit = 20}) async {
    _isLoading = true;
    _errorMessage = null;
    _isDemoData = false;
    notifyListeners();

    try {
      if (_supabaseService.isAvailable) {
        try {
          _entries = await _supabaseService.fetchTopScores(limit: limit);
        } catch (e) {
          if (kDebugMode) {
            print('LeaderboardController: Supabase fetch failed: $e');
          }
          _entries = await _localService.fetchTopScores(limit: limit);
          if (_entries.isNotEmpty) {
            _errorMessage =
                'Showing device scores (online leaderboard unavailable).';
          }
        }
      } else {
        _entries = await _localService.fetchTopScores(limit: limit);
      }
    } catch (e) {
      _entries = const [];
      _errorMessage = 'Failed to load leaderboard: $e';
      if (kDebugMode) {
        print(_errorMessage);
      }
    }

    if (_entries.isEmpty) {
      _entries = MockLeaderboardData.sampleTopScores.take(limit).toList();
      _isDemoData = true;
      _errorMessage = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveScore({
    required String playerName,
    required String characterType,
    required int score,
  }) async {
    await _localService.savePlayerName(playerName);

    await _localService.saveScore(
      playerName: playerName,
      characterType: characterType,
      score: score,
    );

    if (_supabaseService.isAvailable) {
      try {
        await _supabaseService.saveScore(
          playerName: playerName,
          characterType: characterType,
          score: score,
        );
      } catch (e) {
        if (kDebugMode) {
          print('Failed to sync score to Supabase: $e');
        }
      }
    }
  }

  Future<String?> getSavedPlayerName() {
    return _localService.getSavedPlayerName();
  }

}
