import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/games_repository_impl.dart';
import '../../domain/game_entities.dart';
import '../../domain/games_repository.dart';

final Provider<GamesRepository> gamesRepositoryProvider =
    Provider<GamesRepository>((ref) {
      return DriftGamesRepository(
        database: ref.watch(appDatabaseProvider),
        uuid: ref.watch(uuidProvider),
        clock: ref.watch(clockProvider),
      );
    });

final StreamProvider<List<GameSnapshot>> activeGamesProvider =
    StreamProvider<List<GameSnapshot>>((ref) {
      return ref.watch(gamesRepositoryProvider).watchGames(archived: false);
    });

final StreamProvider<List<GameSnapshot>> archivedGamesProvider =
    StreamProvider<List<GameSnapshot>>((ref) {
      return ref.watch(gamesRepositoryProvider).watchGames(archived: true);
    });

/// Roles allowed in a given game, kept live so ticking a box updates the
/// screens that depend on it.
final gameCompositionProvider = StreamProvider.family<Set<String>, String>((
  ref,
  gameId,
) {
  return ref.watch(gamesRepositoryProvider).watchComposition(gameId);
}, isAutoDispose: true);

final gameSnapshotProvider =
    StreamProvider.family<GameSnapshot?, String>((ref, gameId) {
      return ref.watch(gamesRepositoryProvider).watchGame(gameId);
    }, isAutoDispose: true);
