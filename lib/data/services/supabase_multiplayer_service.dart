import 'dart:math';

import 'package:start_hack_2026/core/config/supabase_config.dart';
import 'package:start_hack_2026/domain/entities/multiplayer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseMultiplayerService {
  static const _roomsTable = 'multiplayer_rooms';
  static const _playersTable = 'multiplayer_players';
  static const _roundEventsTable = 'multiplayer_round_events';
  static const _roundResultsTable = 'multiplayer_round_results';

  bool get isAvailable => SupabaseConfig.isInitialized;

  SupabaseClient get _client => Supabase.instance.client;

  Future<String?> ensureUser() async {
    if (!isAvailable) return null;
    final currentUser = _client.auth.currentUser;
    if (currentUser != null) {
      return currentUser.id;
    }
    final response = await _client.auth.signInAnonymously();
    return response.user?.id;
  }

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<MultiplayerRoom> createRoom({required MultiplayerRole role}) async {
    final userId = await ensureUser();
    if (userId == null) {
      throw StateError('Supabase user session is not available.');
    }

    for (var attempt = 0; attempt < 5; attempt++) {
      final code = _generateRoomCode();
      try {
        final roomResponse = await _client
            .from(_roomsTable)
            .insert({
              'room_code': code,
              'status': MultiplayerRoomStatus.waiting,
              'current_round': 1,
              'created_by': userId,
            })
            .select('id, room_code, status, current_round')
            .single();
        final room = MultiplayerRoom.fromJson(roomResponse);
        await _client.from(_playersTable).insert({
          'room_id': room.id,
          'user_id': userId,
          'role': role.name,
        });
        return room;
      } on PostgrestException catch (e) {
        final duplicateCode = e.message.toLowerCase().contains(
          'multiplayer_rooms_room_code_key',
        );
        if (!duplicateCode || attempt == 4) {
          rethrow;
        }
      }
    }

    throw StateError('Unable to create a room.');
  }

  Future<JoinedMultiplayerRoom> joinRoom({required String roomCode}) async {
    final userId = await ensureUser();
    if (userId == null) {
      throw StateError('Supabase user session is not available.');
    }

    final normalizedCode = roomCode.trim().toUpperCase();
    final roomResponse = await _client
        .from(_roomsTable)
        .select('id, room_code, status, current_round')
        .eq('room_code', normalizedCode)
        .maybeSingle();

    if (roomResponse == null) {
      throw StateError('Room not found.');
    }

    final room = MultiplayerRoom.fromJson(roomResponse);

    final playerRows =
        await _client
                .from(_playersTable)
                .select('user_id, role')
                .eq('room_id', room.id)
            as List<dynamic>;

    MultiplayerRole? assignedRole;
    final takenRoles = <MultiplayerRole>{};
    for (final row in playerRows) {
      final player = row as Map<String, dynamic>;
      final role = MultiplayerRole.fromString(
        player['role'] as String? ?? MultiplayerRole.investor.name,
      );
      takenRoles.add(role);
      if ((player['user_id'] as String? ?? '') == userId) {
        assignedRole = role;
      }
    }

    assignedRole ??= _chooseRole(takenRoles);
    if (assignedRole == null) {
      throw StateError('Room is full. Both roles are already taken.');
    }

    try {
      await _client.from(_playersTable).upsert({
        'room_id': room.id,
        'user_id': userId,
        'role': assignedRole.name,
      }, onConflict: 'room_id,user_id');
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw StateError('Room role assignment failed. Try joining again.');
      }
      rethrow;
    }

    return JoinedMultiplayerRoom(room: room, assignedRole: assignedRole);
  }

  Stream<MultiplayerRoom> watchRoom(String roomId) {
    return _client
        .from(_roomsTable)
        .stream(primaryKey: ['id'])
        .eq('id', roomId)
        .map((rows) {
          if (rows.isEmpty) {
            throw StateError('Room no longer exists.');
          }
          return MultiplayerRoom.fromJson(rows.first);
        });
  }

  Future<MultiplayerRoom?> fetchRoom(String roomId) async {
    final row = await _client
        .from(_roomsTable)
        .select('id, room_code, status, current_round')
        .eq('id', roomId)
        .maybeSingle();
    if (row == null) return null;
    return MultiplayerRoom.fromJson(row);
  }

  Stream<List<MultiplayerPlayer>> watchPlayers(String roomId) {
    return _client
        .from(_playersTable)
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .map(
          (rows) => rows
              .map((row) => MultiplayerPlayer.fromJson(row))
              .toList(growable: false),
        );
  }

  Future<List<MultiplayerPlayer>> fetchPlayers(String roomId) async {
    final rows =
        await _client
                .from(_playersTable)
                .select('user_id, role, joined_at')
                .eq('room_id', roomId)
            as List<dynamic>;
    return rows
        .map(
          (row) =>
              MultiplayerPlayer.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .toList(growable: false);
  }

  Stream<List<MultiplayerRoundEvent>> watchRoundEvents({
    required String roomId,
    required int roundNumber,
  }) {
    return _client
        .from(_roundEventsTable)
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .map((rows) {
          final events = rows
              .map((row) => MultiplayerRoundEvent.fromJson(row))
              .where((event) => event.roundNumber == roundNumber)
              .toList(growable: false);
          events.sort((a, b) => a.launchOrder.compareTo(b.launchOrder));
          return events;
        });
  }

  Future<List<MultiplayerRoundEvent>> fetchRoundEvents({
    required String roomId,
    required int roundNumber,
  }) async {
    final rows =
        await _client
                .from(_roundEventsTable)
                .select('id, round_number, launch_order, event_payload')
                .eq('room_id', roomId)
                .eq('round_number', roundNumber)
                .order('launch_order', ascending: true)
            as List<dynamic>;
    return rows
        .map(
          (row) => MultiplayerRoundEvent.fromJson(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList(growable: false);
  }

  Future<void> launchEvent({
    required String roomId,
    required int roundNumber,
    required Map<String, dynamic> eventPayload,
  }) async {
    final userId = await ensureUser();
    if (userId == null) {
      throw StateError('Supabase user session is not available.');
    }

    for (var attempt = 0; attempt < 5; attempt++) {
      final rows =
          await _client
                  .from(_roundEventsTable)
                  .select('launch_order')
                  .eq('room_id', roomId)
                  .eq('round_number', roundNumber)
                  .order('launch_order', ascending: false)
                  .limit(1)
              as List<dynamic>;
      final currentMax = rows.isEmpty
          ? 0
          : ((rows.first as Map<String, dynamic>)['launch_order'] as num?)
                    ?.toInt() ??
                0;
      final nextLaunchOrder = currentMax + 1;

      try {
        await _client.from(_roundEventsTable).insert({
          'room_id': roomId,
          'round_number': roundNumber,
          'launch_order': nextLaunchOrder,
          'event_payload': eventPayload,
          'launched_by': userId,
        });
        return;
      } on PostgrestException catch (e) {
        // Concurrent insert took this launch_order; retry with fresh max.
        if (e.code != '23505' || attempt == 4) {
          rethrow;
        }
      }
    }
  }

  Future<void> advanceRound({
    required String roomId,
    required int currentRound,
  }) async {
    await _client
        .from(_roomsTable)
        .update({
          'current_round': currentRound + 1,
          'status': MultiplayerRoomStatus.marketTurn,
        })
        .eq('id', roomId);
  }

  Future<void> ensureMarketTurnStarted({required String roomId}) async {
    await _client
        .from(_roomsTable)
        .update({'status': MultiplayerRoomStatus.marketTurn})
        .eq('id', roomId)
        .eq('status', MultiplayerRoomStatus.waiting);
  }

  Future<void> moveToInvestorTurn({required String roomId}) async {
    await _client
        .from(_roomsTable)
        .update({'status': MultiplayerRoomStatus.investorTurn})
        .eq('id', roomId);
  }

  Future<void> markSimulationRunning({
    required String roomId,
    required int roundNumber,
    required List<Map<String, dynamic>> eventsPayload,
  }) async {
    final userId = await ensureUser();
    if (userId == null) {
      throw StateError('Supabase user session is not available.');
    }
    await _client
        .from(_roomsTable)
        .update({'status': MultiplayerRoomStatus.simulating})
        .eq('id', roomId);
    await _client.from(_roundResultsTable).upsert({
      'room_id': roomId,
      'round_number': roundNumber,
      'status': MultiplayerRoomStatus.simulating,
      'started_by': userId,
      'events_payload': eventsPayload,
      'portfolio_points': const <Map<String, dynamic>>[],
      'last_portfolio_value': 0,
    }, onConflict: 'room_id,round_number');
  }

  Future<void> upsertRoundSimulationSnapshot({
    required String roomId,
    required int roundNumber,
    required List<Map<String, dynamic>> points,
    required List<Map<String, dynamic>> events,
    required double lastPortfolioValue,
    required bool isComplete,
  }) async {
    await _client.from(_roundResultsTable).upsert({
      'room_id': roomId,
      'round_number': roundNumber,
      'status': isComplete
          ? MultiplayerRoomStatus.resultsReady
          : MultiplayerRoomStatus.simulating,
      'portfolio_points': points,
      'events_payload': events,
      'last_portfolio_value': lastPortfolioValue,
    }, onConflict: 'room_id,round_number');
    if (isComplete) {
      await _client
          .from(_roomsTable)
          .update({'status': MultiplayerRoomStatus.resultsReady})
          .eq('id', roomId);
    }
  }

  Stream<MultiplayerRoundResult> watchRoundResult({
    required String roomId,
    required int roundNumber,
  }) {
    return _client
        .from(_roundResultsTable)
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .map((rows) {
          final matching = rows
              .where(
                (row) => (row['round_number'] as num?)?.toInt() == roundNumber,
              )
              .toList(growable: false);
          if (matching.isEmpty) {
            return MultiplayerRoundResult.empty(
              roomId: roomId,
              roundNumber: roundNumber,
            );
          }
          return MultiplayerRoundResult.fromJson(matching.first);
        });
  }

  Future<MultiplayerRoundResult> fetchRoundResult({
    required String roomId,
    required int roundNumber,
  }) async {
    final row = await _client
        .from(_roundResultsTable)
        .select(
          'room_id, round_number, status, portfolio_points, events_payload, last_portfolio_value',
        )
        .eq('room_id', roomId)
        .eq('round_number', roundNumber)
        .maybeSingle();
    if (row == null) {
      return MultiplayerRoundResult.empty(
        roomId: roomId,
        roundNumber: roundNumber,
      );
    }
    return MultiplayerRoundResult.fromJson(row);
  }

  String _generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }

  MultiplayerRole? _chooseRole(Set<MultiplayerRole> takenRoles) {
    if (!takenRoles.contains(MultiplayerRole.investor)) {
      return MultiplayerRole.investor;
    }
    if (!takenRoles.contains(MultiplayerRole.market)) {
      return MultiplayerRole.market;
    }
    return null;
  }
}
