import 'game_entities.dart';

/// A player the narrator is about to seat, before the row exists.
class PlayerDraft {
  const PlayerDraft({required this.name, required this.roleId});

  final String name;
  final String roleId;

  PlayerDraft copyWith({String? name, String? roleId}) =>
      PlayerDraft(name: name ?? this.name, roleId: roleId ?? this.roleId);
}

abstract interface class GamesRepository {
  Stream<List<GameSnapshot>> watchGames({required bool archived});

  Stream<GameSnapshot?> watchGame(String gameId);

  Future<GameSnapshot?> loadGame(String gameId);

  Future<Game> createGame({
    required String name,
    required List<PlayerDraft> players,
    Set<String>? allowedRoleIds,
  });

  Future<void> renameGame(String gameId, String name);

  Future<void> setArchived({required String gameId, required bool archived});

  Future<void> setStatus({required String gameId, required GameStatus status});

  Future<void> deleteGame(String gameId);

  Future<void> savePlayers(List<Player> players);

  Future<void> addPlayer({
    required String gameId,
    required String name,
    required String roleId,
  });

  Future<void> removePlayer({required String gameId, required String playerId});

  /// Roles allowed for [gameId]. A game recorded before compositions existed
  /// has none, and gets the whole catalogue.
  Future<Set<String>> loadComposition(String gameId);

  Stream<Set<String>> watchComposition(String gameId);

  Future<void> saveComposition({
    required String gameId,
    required Set<String> roleIds,
  });

  /// Composition of the most recent game that has one — the default proposed
  /// when creating the next game, so the narrator does not tick 26 boxes again.
  Future<Set<String>> loadLastComposition();
}
