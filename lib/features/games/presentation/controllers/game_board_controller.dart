import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/game_entities.dart';
import '../../domain/games_repository.dart';
import '../../domain/role_dealer.dart';
import 'games_providers.dart';

/// Manual edits on the player board, outside of the night flow.
///
/// Everything the narrator can do to a player by hand lives here so the widgets
/// stay declarative.
class GameBoardController {
  const GameBoardController(this._repository);

  final GamesRepository _repository;

  Future<void> setAlive({
    required Player player,
    required bool alive,
    int? nightNumber,
  }) {
    final updated = alive
        ? player.copyWith(isAlive: true, clearDeath: true)
        : player.copyWith(
            isAlive: false,
            deathNightNumber: nightNumber,
            deathCause: 'Marqué mort par le narrateur',
          );
    return _repository.savePlayers([updated]);
  }

  Future<void> setRole({required Player player, required String roleId}) {
    return _repository.savePlayers([player.copyWith(roleId: roleId)]);
  }

  /// Redeals every seat at random, before the first night is played.
  ///
  /// A proposal, not a lock: each assignment stays editable afterwards.
  Future<void> randomizeRoles({
    required GameSnapshot snapshot,
    Random? random,
  }) {
    final roleIds = RoleDealer.deal(
      playerCount: snapshot.players.length,
      random: random,
    );
    return _repository.savePlayers([
      for (var i = 0; i < snapshot.players.length; i++)
        snapshot.players[i].copyWith(roleId: roleIds[i]),
    ]);
  }

  /// There is at most one captain, so electing one demotes the previous one.
  Future<void> toggleCaptain({
    required GameSnapshot snapshot,
    required Player player,
  }) {
    final promote = !player.isCaptain;
    final updated = <Player>[];
    for (final current in snapshot.players) {
      final shouldBeCaptain = promote && current.id == player.id;
      if (current.isCaptain != shouldBeCaptain) {
        updated.add(current.copyWith(isCaptain: shouldBeCaptain));
      }
    }
    return _repository.savePlayers(updated);
  }

  Future<void> breakCouple({
    required GameSnapshot snapshot,
    required Player player,
  }) {
    final partner = snapshot.playerById(player.coupledWithPlayerId);
    return _repository.savePlayers([
      player.copyWith(clearCouple: true),
      if (partner != null) partner.copyWith(clearCouple: true),
    ]);
  }

  Future<void> removePlayer({
    required GameSnapshot snapshot,
    required Player player,
  }) {
    return _repository.removePlayer(
      gameId: snapshot.game.id,
      playerId: player.id,
    );
  }

  Future<void> addPlayer({
    required String gameId,
    required String name,
    required String roleId,
  }) {
    return _repository.addPlayer(gameId: gameId, name: name, roleId: roleId);
  }

  Future<void> setStatus({
    required String gameId,
    required GameStatus status,
  }) {
    return _repository.setStatus(gameId: gameId, status: status);
  }

  Future<void> setArchived({
    required String gameId,
    required bool archived,
  }) {
    return _repository.setArchived(gameId: gameId, archived: archived);
  }
}

final Provider<GameBoardController> gameBoardControllerProvider =
    Provider<GameBoardController>(
      (ref) => GameBoardController(ref.watch(gamesRepositoryProvider)),
    );
