import '../../games/domain/game_entities.dart';
import '../../nights/domain/night_entities.dart';

/// A whole game, flattened into something that survives a round trip through
/// JSON: the game, its players, and every round with its actions.
class GameArchive {
  const GameArchive({
    required this.game,
    required this.players,
    required this.nights,
    required this.exportedAt,
  });

  /// Bumped only if the shape below changes in a way older builds cannot read.
  static const int schemaVersion = 1;

  final Game game;
  final List<Player> players;
  final List<NightDetail> nights;
  final DateTime exportedAt;

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'exportedAt': exportedAt.toIso8601String(),
    'game': {
      'id': game.id,
      'name': game.name,
      'createdAt': game.createdAt.toIso8601String(),
      'updatedAt': game.updatedAt.toIso8601String(),
      'status': game.status.id,
      'isArchived': game.isArchived,
      'notes': game.notes,
    },
    'players': [
      for (final player in players)
        {
          'id': player.id,
          'name': player.name,
          'roleId': player.roleId,
          'seatOrder': player.seatOrder,
          'isAlive': player.isAlive,
          'isCaptain': player.isCaptain,
          'isCharmed': player.isCharmed,
          'coupledWithPlayerId': player.coupledWithPlayerId,
          'deathNightNumber': player.deathNightNumber,
          'deathCause': player.deathCause,
          'notes': player.notes,
        },
    ],
    'nights': [
      for (final detail in nights)
        {
          'id': detail.night.id,
          'nightNumber': detail.night.nightNumber,
          'createdAt': detail.night.createdAt.toIso8601String(),
          'resolvedAt': detail.night.resolvedAt?.toIso8601String(),
          'outcome': detail.night.outcome?.toJson(),
          'actions': [
            for (final action in detail.actions)
              {
                'id': action.id,
                'type': action.typeId,
                'actorPlayerId': action.actorPlayerId,
                'targetPlayerId': action.targetPlayerId,
                'secondaryTargetPlayerId': action.secondaryTargetPlayerId,
                'details': action.details,
                'orderIndex': action.orderIndex,
                'createdAt': action.createdAt.toIso8601String(),
              },
          ],
        },
    ],
  };

  static GameArchive fromJson(Map<String, dynamic> json) {
    final gameJson = json['game'] as Map<String, dynamic>;
    final gameId = gameJson['id'] as String;

    final game = Game(
      id: gameId,
      name: gameJson['name'] as String,
      createdAt: DateTime.parse(gameJson['createdAt'] as String),
      updatedAt: DateTime.parse(gameJson['updatedAt'] as String),
      status: GameStatus.fromId(gameJson['status'] as String? ?? 'inProgress'),
      isArchived: gameJson['isArchived'] as bool? ?? false,
      notes: gameJson['notes'] as String?,
    );

    final players = [
      for (final raw in (json['players'] as List<dynamic>? ?? []))
        () {
          final p = raw as Map<String, dynamic>;
          return Player(
            id: p['id'] as String,
            gameId: gameId,
            name: p['name'] as String,
            roleId: p['roleId'] as String,
            seatOrder: p['seatOrder'] as int? ?? 0,
            isAlive: p['isAlive'] as bool? ?? true,
            isCaptain: p['isCaptain'] as bool? ?? false,
            isCharmed: p['isCharmed'] as bool? ?? false,
            coupledWithPlayerId: p['coupledWithPlayerId'] as String?,
            deathNightNumber: p['deathNightNumber'] as int?,
            deathCause: p['deathCause'] as String?,
            notes: p['notes'] as String?,
          );
        }(),
    ];

    final nights = [
      for (final raw in (json['nights'] as List<dynamic>? ?? []))
        () {
          final n = raw as Map<String, dynamic>;
          final nightId = n['id'] as String;
          final outcome = n['outcome'] as Map<String, dynamic>?;
          return NightDetail(
            night: Night(
              id: nightId,
              gameId: gameId,
              nightNumber: n['nightNumber'] as int,
              createdAt: DateTime.parse(n['createdAt'] as String),
              resolvedAt: n['resolvedAt'] == null
                  ? null
                  : DateTime.parse(n['resolvedAt'] as String),
              outcome: outcome == null ? null : NightOutcome.fromJson(outcome),
            ),
            actions: [
              for (final rawAction in (n['actions'] as List<dynamic>? ?? []))
                () {
                  final a = rawAction as Map<String, dynamic>;
                  return NightAction(
                    id: a['id'] as String,
                    nightId: nightId,
                    gameId: gameId,
                    typeId: a['type'] as String,
                    actorPlayerId: a['actorPlayerId'] as String?,
                    targetPlayerId: a['targetPlayerId'] as String?,
                    secondaryTargetPlayerId:
                        a['secondaryTargetPlayerId'] as String?,
                    details: Map<String, dynamic>.from(
                      a['details'] as Map<dynamic, dynamic>? ?? const {},
                    ),
                    orderIndex: a['orderIndex'] as int? ?? 0,
                    createdAt: DateTime.parse(a['createdAt'] as String),
                  );
                }(),
            ],
          );
        }(),
    ];

    return GameArchive(
      game: game,
      players: players,
      nights: nights,
      exportedAt: DateTime.parse(
        json['exportedAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}
