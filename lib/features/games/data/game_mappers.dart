import '../../../core/database/app_database.dart';
import '../domain/game_entities.dart';

extension GameRowMapper on GameRow {
  Game toEntity() => Game(
    id: id,
    name: name,
    createdAt: createdAt,
    updatedAt: updatedAt,
    status: GameStatus.fromId(status),
    isArchived: isArchived,
    notes: notes,
    winnerCampId: winnerCampId,
    winnerReason: winnerReason,
  );
}

extension PlayerRowMapper on PlayerRow {
  Player toEntity() => Player(
    id: id,
    gameId: gameId,
    name: name,
    roleId: roleId,
    seatOrder: seatOrder,
    isAlive: isAlive,
    isCaptain: isCaptain,
    isCharmed: isCharmed,
    coupledWithPlayerId: coupledWithPlayerId,
    deathNightNumber: deathNightNumber,
    deathCause: deathCause,
    notes: notes,
  );
}

extension GameEntityMapper on Game {
  GamesCompanion toCompanion() => GamesCompanion.insert(
    id: id,
    name: name,
    createdAt: createdAt,
    updatedAt: updatedAt,
    status: status.id,
  );
}
