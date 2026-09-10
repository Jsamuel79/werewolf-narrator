import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../games/data/game_mappers.dart';
import '../../games/domain/game_entities.dart';
import '../domain/victory_engine.dart';
import '../domain/victory_entities.dart';

/// Watches the board for a finished game, and closes it when one is.
///
/// Both write paths — the night/day resolution and any manual edit of a player
/// — call [refresh] once they are done, so a game can never keep running after
/// a victory condition is met. Deliberately a small class over the database
/// rather than a repository: it owns exactly two columns of `games`.
class VictoryRecorder {
  VictoryRecorder({required AppDatabase database, DateTime Function()? clock})
    : _db = database,
      _now = clock ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _now;

  /// Re-evaluates [gameId] and closes it if a victory rule fires.
  ///
  /// Returns the verdict when the game *just* ended, and `null` when it is
  /// still running or was already closed.
  Future<VictoryResult?> refresh(String gameId) async {
    final gameRow = await (_db.select(
      _db.games,
    )..where((g) => g.id.equals(gameId))).getSingleOrNull();
    if (gameRow == null) return null;
    // A game the narrator already closed by hand is left alone.
    if (GameStatus.fromId(gameRow.status) == GameStatus.finished) return null;

    final players = await (_db.select(
      _db.players,
    )..where((p) => p.gameId.equals(gameId))).get();
    if (players.isEmpty) return null;

    final result = VictoryEngine.evaluate(
      players.map((row) => row.toEntity()).toList(growable: false),
    );
    if (result == null) return null;

    await (_db.update(_db.games)..where((g) => g.id.equals(gameId))).write(
      GamesCompanion(
        status: Value(GameStatus.finished.id),
        winnerCampId: Value(result.camp.id),
        winnerReason: Value(result.reason),
        updatedAt: Value(_now()),
      ),
    );
    return result;
  }

  /// Reopens a game the narrator wants to keep playing, forgetting the winner.
  Future<void> clear(String gameId) async {
    await (_db.update(_db.games)..where((g) => g.id.equals(gameId))).write(
      GamesCompanion(
        winnerCampId: const Value(null),
        winnerReason: const Value(null),
        updatedAt: Value(_now()),
      ),
    );
  }
}
