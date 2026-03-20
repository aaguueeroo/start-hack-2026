import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:start_hack_2026/data/repositories/game_repository.dart';
import 'package:start_hack_2026/data/services/supabase_multiplayer_service.dart';
import 'package:start_hack_2026/domain/entities/multiplayer.dart';
import 'package:start_hack_2026/domain/entities/simulation_event.dart';

class MultiplayerController extends ChangeNotifier {
  MultiplayerController({
    required GameRepository gameRepository,
    required SupabaseMultiplayerService multiplayerService,
  }) : _gameRepository = gameRepository,
       _multiplayerService = multiplayerService;

  final GameRepository _gameRepository;
  final SupabaseMultiplayerService _multiplayerService;

  StreamSubscription<MultiplayerRoom>? _roomSubscription;
  StreamSubscription<List<MultiplayerPlayer>>? _playersSubscription;
  StreamSubscription<List<MultiplayerRoundEvent>>? _roundEventsSubscription;
  StreamSubscription<MultiplayerRoundResult>? _roundResultSubscription;
  Timer? _playersPollTimer;
  Timer? _roomPollTimer;
  Timer? _roundEventsPollTimer;
  Timer? _roundResultPollTimer;

  List<Map<String, dynamic>> _eventsCatalog = [];
  MultiplayerRoom? _room;
  List<MultiplayerPlayer> _players = [];
  List<MultiplayerRoundEvent> _roundEvents = [];
  MultiplayerRoundResult? _roundResult;
  MultiplayerRole? _selectedRole;

  bool _isBusy = false;
  bool _catalogLoaded = false;
  String? _errorMessage;

  bool get isAvailable => _multiplayerService.isAvailable;
  bool get isBusy => _isBusy;
  String? get errorMessage => _errorMessage;
  MultiplayerRoom? get room => _room;
  List<MultiplayerPlayer> get players => List.unmodifiable(_players);
  List<MultiplayerRoundEvent> get roundEvents =>
      List.unmodifiable(_roundEvents);
  MultiplayerRoundResult? get roundResult => _roundResult;
  MultiplayerRole? get selectedRole => _selectedRole;
  List<Map<String, dynamic>> get eventsCatalog =>
      List.unmodifiable(_eventsCatalog);
  String? get currentUserId => _multiplayerService.currentUserId;

  bool get isMarket => _selectedRole == MultiplayerRole.market;

  Future<void> initializeCatalog() async {
    if (_catalogLoaded) return;
    _isBusy = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _eventsCatalog = await _gameRepository.getEvents();
      _catalogLoaded = true;
    } catch (e) {
      _errorMessage = 'Failed to load event catalog: $e';
      _eventsCatalog = [];
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<bool> createRoom(MultiplayerRole role) async {
    if (!isAvailable) {
      _errorMessage = 'Supabase is not configured.';
      notifyListeners();
      return false;
    }
    _isBusy = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final createdRoom = await _multiplayerService.createRoom(role: role);
      _selectedRole = role;
      await _subscribeToRoom(createdRoom.id);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create room: $e';
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<bool> joinRoom({required String roomCode}) async {
    if (!isAvailable) {
      _errorMessage = 'Supabase is not configured.';
      notifyListeners();
      return false;
    }
    _isBusy = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final joined = await _multiplayerService.joinRoom(roomCode: roomCode);
      _selectedRole = joined.assignedRole;
      await _subscribeToRoom(joined.room.id);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to join room: $e';
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> launchEvent(Map<String, dynamic> eventConfig) async {
    final currentRoom = _room;
    if (currentRoom == null ||
        !isMarket ||
        currentRoom.status != MultiplayerRoomStatus.marketTurn) {
      return;
    }
    _isBusy = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _multiplayerService
          .launchEvent(
            roomId: currentRoom.id,
            roundNumber: currentRoom.currentRound,
            eventPayload: eventConfig,
          )
          .timeout(const Duration(seconds: 10));
      final latestEvents = await _multiplayerService.fetchRoundEvents(
        roomId: currentRoom.id,
        roundNumber: currentRoom.currentRound,
      );
      _roundEvents = latestEvents;
    } catch (e) {
      _errorMessage = 'Failed to launch event: $e';
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> finishMarketTurn() async {
    final currentRoom = _room;
    if (currentRoom == null ||
        !isMarket ||
        currentRoom.status != MultiplayerRoomStatus.marketTurn) {
      return;
    }
    _isBusy = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _multiplayerService.moveToInvestorTurn(roomId: currentRoom.id);
    } catch (e) {
      _errorMessage = 'Failed to finish market turn: $e';
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> startInvestorSimulation() async {
    final currentRoom = _room;
    if (currentRoom == null ||
        isMarket ||
        currentRoom.status != MultiplayerRoomStatus.investorTurn) {
      return;
    }
    _isBusy = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _multiplayerService.markSimulationRunning(
        roomId: currentRoom.id,
        roundNumber: currentRoom.currentRound,
        eventsPayload: getRoundEventPayloads(),
      );
    } catch (e) {
      _errorMessage = 'Failed to start simulation: $e';
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> syncSimulationSnapshot({
    required List<SimulationDataPoint> dataPoints,
    required List<SimulationEvent> events,
    required bool isComplete,
    required double lastPortfolioValue,
  }) async {
    final currentRoom = _room;
    if (currentRoom == null || isMarket) return;
    final pointPayload = dataPoints
        .map((point) => {'timestamp': point.timestamp, 'value': point.value})
        .toList(growable: false);
    final eventPayload = events
        .map(
          (event) => {
            'timestamp': event.timestamp,
            'type': event.type.name,
            'title': event.title,
            'description': event.description,
            'portfolioValueAtEvent': event.portfolioValueAtEvent,
          },
        )
        .toList(growable: false);
    try {
      await _multiplayerService.upsertRoundSimulationSnapshot(
        roomId: currentRoom.id,
        roundNumber: currentRoom.currentRound,
        points: pointPayload,
        events: eventPayload,
        lastPortfolioValue: lastPortfolioValue,
        isComplete: isComplete,
      );
    } catch (e) {
      _errorMessage = 'Failed to sync simulation snapshot: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> proceedToNextRound() async {
    final currentRoom = _room;
    if (currentRoom == null ||
        !isMarket ||
        currentRoom.status != MultiplayerRoomStatus.resultsReady) {
      return;
    }
    _isBusy = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _multiplayerService.advanceRound(
        roomId: currentRoom.id,
        currentRound: currentRoom.currentRound,
      );
      _roundResult = null;
    } catch (e) {
      _errorMessage = 'Failed to move to next round: $e';
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> continueFromInvestorResults() async {
    final currentRoom = _room;
    if (currentRoom == null ||
        isMarket ||
        currentRoom.status != MultiplayerRoomStatus.resultsReady) {
      return;
    }
    _isBusy = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _multiplayerService.advanceRound(
        roomId: currentRoom.id,
        currentRound: currentRoom.currentRound,
      );
      _roundResult = null;
      _roundEvents = [];
    } catch (e) {
      _errorMessage = 'Failed to continue to next round: $e';
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> startMatch() async {
    final currentRoom = _room;
    if (currentRoom == null ||
        currentRoom.status != MultiplayerRoomStatus.waiting) {
      return;
    }
    if (_players.length < 2) return;
    _isBusy = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _multiplayerService.ensureMarketTurnStarted(roomId: currentRoom.id);
    } catch (e) {
      _errorMessage = 'Failed to start match: $e';
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> getRoundEventPayloads() {
    final events = List<MultiplayerRoundEvent>.from(_roundEvents)
      ..sort((a, b) => a.launchOrder.compareTo(b.launchOrder));
    return events.map((event) => event.eventPayload).toList(growable: false);
  }

  Future<void> _subscribeToRoom(String roomId) async {
    await _roomSubscription?.cancel();
    await _playersSubscription?.cancel();
    await _roundEventsSubscription?.cancel();
    await _roundResultSubscription?.cancel();
    _playersPollTimer?.cancel();
    _roomPollTimer?.cancel();
    _roundEventsPollTimer?.cancel();
    _roundResultPollTimer?.cancel();

    _roomSubscription = _multiplayerService
        .watchRoom(roomId)
        .listen(
          (room) {
            final previousRound = _room?.currentRound;
            _room = room;
            if (previousRound != room.currentRound) {
              _subscribeToRoundEvents(roomId, room.currentRound);
              _subscribeToRoundResult(roomId, room.currentRound);
            }
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = 'Room stream error: $error';
            notifyListeners();
          },
        );

    _roomPollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      try {
        final latestRoom = await _multiplayerService.fetchRoom(roomId);
        if (latestRoom == null) return;
        final current = _room;
        if (current != null &&
            current.status == latestRoom.status &&
            current.currentRound == latestRoom.currentRound &&
            current.roomCode == latestRoom.roomCode) {
          return;
        }
        final previousRound = _room?.currentRound;
        _room = latestRoom;
        if (previousRound != latestRoom.currentRound) {
          _subscribeToRoundEvents(roomId, latestRoom.currentRound);
          _subscribeToRoundResult(roomId, latestRoom.currentRound);
        }
        notifyListeners();
      } catch (_) {
        // Stream remains primary; polling is fallback.
      }
    });

    _playersSubscription = _multiplayerService
        .watchPlayers(roomId)
        .listen(
          (players) {
            _players = players;
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = 'Players stream error: $error';
            notifyListeners();
          },
        );

    _playersPollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      try {
        final latestPlayers = await _multiplayerService.fetchPlayers(roomId);
        if (_samePlayers(_players, latestPlayers)) return;
        _players = latestPlayers;
        notifyListeners();
      } catch (_) {
        // Keep stream-based updates as primary; polling is only fallback.
      }
    });

    final currentRound = _room?.currentRound ?? 1;
    _subscribeToRoundEvents(roomId, currentRound);
    _subscribeToRoundResult(roomId, currentRound);
    _roundEventsPollTimer = Timer.periodic(const Duration(seconds: 2), (
      _,
    ) async {
      final room = _room;
      if (room == null) return;
      try {
        final latest = await _multiplayerService.fetchRoundEvents(
          roomId: room.id,
          roundNumber: room.currentRound,
        );
        if (_sameRoundEvents(_roundEvents, latest)) return;
        _roundEvents = latest;
        notifyListeners();
      } catch (_) {
        // Realtime remains primary; polling is fallback.
      }
    });
    _roundResultPollTimer = Timer.periodic(const Duration(seconds: 2), (
      _,
    ) async {
      final room = _room;
      if (room == null) return;
      try {
        final latest = await _multiplayerService.fetchRoundResult(
          roomId: room.id,
          roundNumber: room.currentRound,
        );
        if (_sameRoundResult(_roundResult, latest)) return;
        _roundResult = latest;
        notifyListeners();
      } catch (_) {
        // Realtime remains primary; polling is fallback.
      }
    });
  }

  void _subscribeToRoundEvents(String roomId, int roundNumber) {
    _roundEventsSubscription?.cancel();
    _roundEventsSubscription = _multiplayerService
        .watchRoundEvents(roomId: roomId, roundNumber: roundNumber)
        .listen(
          (events) {
            _roundEvents = events;
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = 'Round events stream error: $error';
            notifyListeners();
          },
        );
  }

  void _subscribeToRoundResult(String roomId, int roundNumber) {
    _roundResultSubscription?.cancel();
    _roundResult = null;
    _roundResultSubscription = _multiplayerService
        .watchRoundResult(roomId: roomId, roundNumber: roundNumber)
        .listen(
          (result) {
            _roundResult = result;
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = 'Round result stream error: $error';
            notifyListeners();
          },
        );
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _roomSubscription?.cancel();
    _playersSubscription?.cancel();
    _roundEventsSubscription?.cancel();
    _roundResultSubscription?.cancel();
    _playersPollTimer?.cancel();
    _roomPollTimer?.cancel();
    _roundEventsPollTimer?.cancel();
    _roundResultPollTimer?.cancel();
    super.dispose();
  }

  bool _samePlayers(List<MultiplayerPlayer> a, List<MultiplayerPlayer> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    final sa =
        a.map((p) => '${p.userId}:${p.role.name}').toList(growable: false)
          ..sort();
    final sb =
        b.map((p) => '${p.userId}:${p.role.name}').toList(growable: false)
          ..sort();
    for (var i = 0; i < sa.length; i++) {
      if (sa[i] != sb[i]) return false;
    }
    return true;
  }

  bool _sameRoundEvents(
    List<MultiplayerRoundEvent> a,
    List<MultiplayerRoundEvent> b,
  ) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id || a[i].launchOrder != b[i].launchOrder) {
        return false;
      }
    }
    return true;
  }

  bool _sameRoundResult(MultiplayerRoundResult? a, MultiplayerRoundResult b) {
    if (a == null) return false;
    if (a.roomId != b.roomId ||
        a.roundNumber != b.roundNumber ||
        a.status != b.status ||
        a.lastPortfolioValue != b.lastPortfolioValue ||
        a.dataPoints.length != b.dataPoints.length ||
        a.events.length != b.events.length) {
      return false;
    }
    return true;
  }
}
