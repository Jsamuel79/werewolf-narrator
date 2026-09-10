import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../games/presentation/controllers/games_providers.dart';
import '../../data/nights_repository_impl.dart';
import '../../domain/night_entities.dart';
import '../../domain/nights_repository.dart';

typedef NightRef = ({String gameId, String nightId});

final Provider<NightsRepository> nightsRepositoryProvider =
    Provider<NightsRepository>((ref) {
      return DriftNightsRepository(
        database: ref.watch(appDatabaseProvider),
        uuid: ref.watch(uuidProvider),
        clock: ref.watch(clockProvider),
      );
    });

final gameNightsProvider = StreamProvider.family<List<Night>, String>((
  ref,
  gameId,
) {
  return ref.watch(nightsRepositoryProvider).watchNights(gameId);
}, isAutoDispose: true);

/// Everything the night screen needs, recomputed whenever the board or the
/// actions of the round change.
final nightContextProvider = StreamProvider.family<NightContext?, NightRef>((
  ref,
  args,
) async* {
  final snapshotAsync = ref.watch(gameSnapshotProvider(args.gameId));
  if (snapshotAsync.isLoading && !snapshotAsync.hasValue) {
    // Emit nothing: the provider stays in its loading state and rebuilds once
    // the board arrives, instead of flashing "night not found".
    return;
  }
  final snapshot = snapshotAsync.value;
  if (snapshot == null) {
    yield null;
    return;
  }
  final repository = ref.watch(nightsRepositoryProvider);
  await for (final detail in repository.watchNight(args.nightId)) {
    if (detail == null) {
      yield null;
      continue;
    }
    yield NightContext(
      snapshot: snapshot,
      detail: detail,
      usedOncePerGameActionIds: await repository.usedOncePerGameActionIds(
        args.gameId,
      ),
      lastGuardedPlayerId: await repository.lastGuardedPlayerId(
        gameId: args.gameId,
        beforeNightNumber: detail.night.nightNumber,
      ),
    );
  }
}, isAutoDispose: true);

final gameHistoryProvider = FutureProvider.family<List<NightDetail>, String>((
  ref,
  gameId,
) {
  // Depending on the nights stream keeps the history fresh after a round is
  // closed without needing a manual refresh.
  ref.watch(gameNightsProvider(gameId));
  return ref.watch(nightsRepositoryProvider).loadHistory(gameId);
}, isAutoDispose: true);
