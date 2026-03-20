import 'package:start_hack_2026/domain/entities/simulation_event.dart';

enum MultiplayerRole {
  market,
  investor;

  static MultiplayerRole fromString(String value) {
    return MultiplayerRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => MultiplayerRole.investor,
    );
  }
}

class MultiplayerRoom {
  const MultiplayerRoom({
    required this.id,
    required this.roomCode,
    required this.status,
    required this.currentRound,
  });

  final String id;
  final String roomCode;
  final String status;
  final int currentRound;

  factory MultiplayerRoom.fromJson(Map<String, dynamic> json) {
    return MultiplayerRoom(
      id: (json['id'] as String?) ?? '',
      roomCode: (json['room_code'] as String?) ?? '',
      status: (json['status'] as String?) ?? 'waiting',
      currentRound: (json['current_round'] as num?)?.toInt() ?? 1,
    );
  }
}

class MultiplayerPlayer {
  const MultiplayerPlayer({
    required this.userId,
    required this.role,
    required this.joinedAt,
  });

  final String userId;
  final MultiplayerRole role;
  final DateTime? joinedAt;

  factory MultiplayerPlayer.fromJson(Map<String, dynamic> json) {
    final roleValue =
        (json['role'] as String?) ?? MultiplayerRole.investor.name;
    return MultiplayerPlayer(
      userId: (json['user_id'] as String?) ?? '',
      role: MultiplayerRole.fromString(roleValue),
      joinedAt: DateTime.tryParse((json['joined_at'] as String?) ?? ''),
    );
  }
}

class MultiplayerRoundEvent {
  const MultiplayerRoundEvent({
    required this.id,
    required this.roundNumber,
    required this.launchOrder,
    required this.eventPayload,
  });

  final String id;
  final int roundNumber;
  final int launchOrder;
  final Map<String, dynamic> eventPayload;

  factory MultiplayerRoundEvent.fromJson(Map<String, dynamic> json) {
    final payloadRaw = json['event_payload'];
    return MultiplayerRoundEvent(
      id: (json['id'] as String?) ?? '',
      roundNumber: (json['round_number'] as num?)?.toInt() ?? 1,
      launchOrder: (json['launch_order'] as num?)?.toInt() ?? 0,
      eventPayload: payloadRaw is Map<String, dynamic>
          ? payloadRaw
          : Map<String, dynamic>.from(payloadRaw as Map? ?? const {}),
    );
  }
}

class JoinedMultiplayerRoom {
  const JoinedMultiplayerRoom({required this.room, required this.assignedRole});

  final MultiplayerRoom room;
  final MultiplayerRole assignedRole;
}

abstract final class MultiplayerRoomStatus {
  static const waiting = 'waiting';
  static const marketTurn = 'market_turn';
  static const investorTurn = 'investor_turn';
  static const simulating = 'simulating';
  static const resultsReady = 'results_ready';
}

class MultiplayerRoundResult {
  const MultiplayerRoundResult({
    required this.roomId,
    required this.roundNumber,
    required this.status,
    required this.dataPoints,
    required this.events,
    required this.lastPortfolioValue,
  });

  final String roomId;
  final int roundNumber;
  final String status;
  final List<SimulationDataPoint> dataPoints;
  final List<SimulationEvent> events;
  final double lastPortfolioValue;

  factory MultiplayerRoundResult.empty({
    required String roomId,
    required int roundNumber,
  }) {
    return MultiplayerRoundResult(
      roomId: roomId,
      roundNumber: roundNumber,
      status: MultiplayerRoomStatus.waiting,
      dataPoints: const [],
      events: const [],
      lastPortfolioValue: 0,
    );
  }

  factory MultiplayerRoundResult.fromJson(Map<String, dynamic> json) {
    final pointsRaw = json['portfolio_points'] as List<dynamic>? ?? const [];
    final eventsRaw = json['events_payload'] as List<dynamic>? ?? const [];
    final points = pointsRaw
        .map((point) {
          final p = point as Map<String, dynamic>;
          return SimulationDataPoint(
            timestamp: (p['timestamp'] as num?)?.toDouble() ?? 0,
            value: (p['value'] as num?)?.toDouble() ?? 0,
          );
        })
        .toList(growable: false);
    final events = eventsRaw
        .map((event) {
          final e = event as Map<String, dynamic>;
          return SimulationEvent(
            timestamp: (e['timestamp'] as num?)?.toDouble() ?? 0,
            type: SimulationEventType.fromString(
              e['type'] as String? ?? SimulationEventType.world.name,
            ),
            title: (e['title'] as String?) ?? 'Event',
            description: (e['description'] as String?) ?? '',
            portfolioValueAtEvent:
                (e['portfolioValueAtEvent'] as num?)?.toDouble() ?? 0,
          );
        })
        .toList(growable: false);

    return MultiplayerRoundResult(
      roomId: (json['room_id'] as String?) ?? '',
      roundNumber: (json['round_number'] as num?)?.toInt() ?? 1,
      status: (json['status'] as String?) ?? MultiplayerRoomStatus.waiting,
      dataPoints: points,
      events: events,
      lastPortfolioValue:
          (json['last_portfolio_value'] as num?)?.toDouble() ?? 0,
    );
  }
}
