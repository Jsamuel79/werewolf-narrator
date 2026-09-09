import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/game_entities.dart';
import '../domain/games_repository.dart';
import 'game_mappers.dart';

class DriftGamesRepository implements GamesRepository {
  DriftGamesRepository({
    required AppDatabase database,
    required Uuid uuid,
    DateTime Function()? clock,
  }) : _db = database,
       // ignore: prefer_initializing_formals
       _uuid = uuid,
       _now = clock ?? DateTime.now;

  final AppDatabase _db;
  final Uuid _uuid;
  final DateTime Function() _now;

  @override
  Stream<List<GameSnapshot>> watchGames({required bool archived}) {
    return _snapshotQuery(
      where: _db.games.isArchived.equals(archived),
    ).watch().map(_groupSnapshots);
  }

  @override
  Stream<GameSnapshot?> watchGame(String gameId) {
    return _snapshotQuery(where: _db.games.id.equals(gameId)).watch().map((
      rows,
    ) {
      final snapshots = _groupSnapshots(rows);
      return snapshots.isEmpty ? null : snapshots.first;
    });
  }

  @override
  Future<GameSnapshot?> loadGame(String gameId) async {
    final rows = await _snapshotQuery(
      where: _db.games.id.equals(gameId),
    ).get();
    final snapshots = _groupSnapshots(rows);
    return snapshots.isEmpty ? null : snapshots.first;
  }

  JoinedSelectStatement<HasResultSet, dynamic> _snapshotQuery({
    required Expression<bool> where,
  }) {
    return _db.select(_db.games).join([
        leftOuterJoin(_db.players, _db.players.gameId.equalsExp(_db.games.id)),
      ])
      ..where(where)
      ..orderBy([
        OrderingTerm.desc(_db.games.updatedAt),
        OrderingTerm.asc(_db.players.seatOrder),
      ]);
  }

  List<GameSnapshot> _groupSnapshots(List<TypedResult> rows) {
    final games = <String, GameRow>{};
    final players = <String, List<Player>>{};
    final order = <String>[];

    for (final row in rows) {
      final game = row.readTable(_db.games);
      if (!games.containsKey(game.id)) {
        games[game.id] = game;
        players[game.id] = [];
        order.add(game.id);
      }
      final player = row.readTableOrNull(_db.players);
      if (player != null) {
        players[game.id]!.add(player.toEntity());
      }
    }

    return [
      for (final id in order)
        GameSnapshot(game: games[id]!.toEntity(), players: players[id]!),
    ];
  }

  @override
  Future<Game> createGame({
    required String name,
    required List<PlayerDraft> players,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw const ValidationException('Le nom de la partie est obligatoire.');
    }
    if (players.length < 3) {
      throw const ValidationException(
        'Il faut au moins 3 joueurs pour lancer une partie.',
      );
    }
    _assertNamesAreUnique(players.map((p) => p.name));

    final now = _now();
    final game = Game(
      id: _uuid.v4(),
      name: trimmed,
      createdAt: now,
      updatedAt: now,
      status: GameStatus.inProgress,
    );

    await _db.transaction(() async {
      await _db.into(_db.games).insert(game.toCompanion());
      for (var i = 0; i < players.length; i++) {
        await _db
            .into(_db.players)
            .insert(
              PlayersCompanion.insert(
                id: _uuid.v4(),
                gameId: game.id,
                name: players[i].name.trim(),
                roleId: players[i].roleId,
                seatOrder: i,
              ),
            );
      }
    });

    return game;
  }

  @override
  Future<void> renameGame(String gameId, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw const ValidationException('Le nom de la partie est obligatoire.');
    }
    await (_db.update(_db.games)..where((g) => g.id.equals(gameId))).write(
      GamesCompanion(name: Value(trimmed), updatedAt: Value(_now())),
    );
  }

  @override
  Future<void> setArchived({
    required String gameId,
    required bool archived,
  }) async {
    await (_db.update(_db.games)..where((g) => g.id.equals(gameId))).write(
      GamesCompanion(isArchived: Value(archived), updatedAt: Value(_now())),
    );
  }

  @override
  Future<void> setStatus({
    required String gameId,
    required GameStatus status,
  }) async {
    await (_db.update(_db.games)..where((g) => g.id.equals(gameId))).write(
      GamesCompanion(status: Value(status.id), updatedAt: Value(_now())),
    );
  }

  @override
  Future<void> deleteGame(String gameId) async {
    await (_db.delete(_db.games)..where((g) => g.id.equals(gameId))).go();
  }

  @override
  Future<void> savePlayers(List<Player> players) async {
    if (players.isEmpty) return;
    await _db.transaction(() async {
      for (final player in players) {
        await (_db.update(
          _db.players,
        )..where((p) => p.id.equals(player.id))).write(
          PlayersCompanion(
            name: Value(player.name),
            roleId: Value(player.roleId),
            seatOrder: Value(player.seatOrder),
            isAlive: Value(player.isAlive),
            isCaptain: Value(player.isCaptain),
            isCharmed: Value(player.isCharmed),
            coupledWithPlayerId: Value(player.coupledWithPlayerId),
            deathNightNumber: Value(player.deathNightNumber),
            deathCause: Value(player.deathCause),
            notes: Value(player.notes),
          ),
        );
      }
      await _touch(players.first.gameId);
    });
  }

  @override
  Future<void> addPlayer({
    required String gameId,
    required String name,
    required String roleId,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw const ValidationException('Le nom du joueur est obligatoire.');
    }
    final existing = await (_db.select(
      _db.players,
    )..where((p) => p.gameId.equals(gameId))).get();
    _assertNamesAreUnique([...existing.map((p) => p.name), trimmed]);

    final nextSeat = existing.isEmpty
        ? 0
        : existing.map((p) => p.seatOrder).reduce((a, b) => a > b ? a : b) + 1;

    await _db.transaction(() async {
      await _db
          .into(_db.players)
          .insert(
            PlayersCompanion.insert(
              id: _uuid.v4(),
              gameId: gameId,
              name: trimmed,
              roleId: roleId,
              seatOrder: nextSeat,
            ),
          );
      await _touch(gameId);
    });
  }

  @override
  Future<void> removePlayer({
    required String gameId,
    required String playerId,
  }) async {
    await _db.transaction(() async {
      // Break the couple first, otherwise the partner keeps pointing at a row
      // that no longer exists.
      await (_db.update(_db.players)
            ..where((p) => p.coupledWithPlayerId.equals(playerId)))
          .write(const PlayersCompanion(coupledWithPlayerId: Value(null)));
      await (_db.delete(_db.players)..where((p) => p.id.equals(playerId))).go();
      await _touch(gameId);
    });
  }

  Future<void> _touch(String gameId) async {
    await (_db.update(_db.games)..where((g) => g.id.equals(gameId))).write(
      GamesCompanion(updatedAt: Value(_now())),
    );
  }

  void _assertNamesAreUnique(Iterable<String> names) {
    final seen = <String>{};
    for (final name in names) {
      final key = name.trim().toLowerCase();
      if (key.isEmpty) {
        throw const ValidationException('Le nom du joueur est obligatoire.');
      }
      if (!seen.add(key)) {
        throw ValidationException(
          'Deux joueurs ne peuvent pas porter le même nom ($name).',
        );
      }
    }
  }
}
