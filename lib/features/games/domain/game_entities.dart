import 'role.dart';

enum GameStatus {
  setup('setup', 'En préparation'),
  inProgress('inProgress', 'En cours'),
  finished('finished', 'Terminée');

  const GameStatus(this.id, this.label);

  final String id;
  final String label;

  static GameStatus fromId(String id) =>
      GameStatus.values.firstWhere((s) => s.id == id, orElse: () => setup);
}

class Game {
  const Game({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    this.isArchived = false,
    this.notes,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final GameStatus status;
  final bool isArchived;
  final String? notes;

  Game copyWith({
    String? name,
    DateTime? updatedAt,
    GameStatus? status,
    bool? isArchived,
    String? notes,
  }) {
    return Game(
      id: id,
      name: name ?? this.name,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      isArchived: isArchived ?? this.isArchived,
      notes: notes ?? this.notes,
    );
  }
}

class Player {
  const Player({
    required this.id,
    required this.gameId,
    required this.name,
    required this.roleId,
    required this.seatOrder,
    this.isAlive = true,
    this.isCaptain = false,
    this.isCharmed = false,
    this.coupledWithPlayerId,
    this.deathNightNumber,
    this.deathCause,
    this.notes,
  });

  final String id;
  final String gameId;
  final String name;
  final String roleId;
  final int seatOrder;
  final bool isAlive;
  final bool isCaptain;
  final bool isCharmed;
  final String? coupledWithPlayerId;
  final int? deathNightNumber;
  final String? deathCause;
  final String? notes;

  RoleDefinition get role => Roles.byId(roleId);

  bool get isInLove => coupledWithPlayerId != null;

  /// `null` clears a nullable field; the sentinel-free API below is enough for
  /// the few call sites that need it and keeps the class readable.
  Player copyWith({
    String? name,
    String? roleId,
    int? seatOrder,
    bool? isAlive,
    bool? isCaptain,
    bool? isCharmed,
    String? coupledWithPlayerId,
    bool clearCouple = false,
    int? deathNightNumber,
    String? deathCause,
    bool clearDeath = false,
    String? notes,
  }) {
    return Player(
      id: id,
      gameId: gameId,
      name: name ?? this.name,
      roleId: roleId ?? this.roleId,
      seatOrder: seatOrder ?? this.seatOrder,
      isAlive: isAlive ?? this.isAlive,
      isCaptain: isCaptain ?? this.isCaptain,
      isCharmed: isCharmed ?? this.isCharmed,
      coupledWithPlayerId: clearCouple
          ? null
          : coupledWithPlayerId ?? this.coupledWithPlayerId,
      deathNightNumber: clearDeath
          ? null
          : deathNightNumber ?? this.deathNightNumber,
      deathCause: clearDeath ? null : deathCause ?? this.deathCause,
      notes: notes ?? this.notes,
    );
  }
}

/// A game together with its players — what every screen actually needs.
class GameSnapshot {
  const GameSnapshot({required this.game, required this.players});

  final Game game;
  final List<Player> players;

  List<Player> get alivePlayers =>
      players.where((p) => p.isAlive).toList(growable: false);

  List<Player> get deadPlayers =>
      players.where((p) => !p.isAlive).toList(growable: false);

  /// Roles still able to act, deduplicated — drives the night form.
  Set<String> get aliveRoleIds =>
      alivePlayers.map((p) => p.roleId).toSet();

  Player? playerById(String? id) {
    if (id == null) return null;
    for (final player in players) {
      if (player.id == id) return player;
    }
    return null;
  }

  Player? get captain {
    for (final player in players) {
      if (player.isCaptain) return player;
    }
    return null;
  }

  /// Each couple once, as an ordered pair.
  List<(Player, Player)> get couples {
    final seen = <String>{};
    final result = <(Player, Player)>[];
    for (final player in players) {
      final partnerId = player.coupledWithPlayerId;
      if (partnerId == null || seen.contains(player.id)) continue;
      final partner = playerById(partnerId);
      if (partner == null) continue;
      seen
        ..add(player.id)
        ..add(partner.id);
      result.add((player, partner));
    }
    return result;
  }
}
