import 'night_action_type.dart';
import 'night_entities.dart';

abstract interface class NightsRepository {
  /// Rounds of a game, most recent first.
  Stream<List<Night>> watchNights(String gameId);

  Stream<NightDetail?> watchNight(String nightId);

  Future<NightDetail?> loadNight(String nightId);

  /// Full history of a game, oldest round first.
  Future<List<NightDetail>> loadHistory(String gameId);

  /// Opens the next round, or returns the one still open.
  Future<Night> startNight(String gameId);

  Future<NightAction> addAction({
    required String nightId,
    required String typeId,
    ActionPhase phase,
    String? actorPlayerId,
    String? targetPlayerId,
    String? secondaryTargetPlayerId,
    Map<String, dynamic> details,
  });

  Future<void> removeAction(String actionId);

  /// Applies the night half of the round to the board and freezes it.
  Future<NightOutcome> resolveNight(String nightId);

  /// Applies the day half — vote, election, hunter's shot — and closes the
  /// round for good.
  Future<NightOutcome> resolveDay(String nightId);

  /// Who the Salvateur protected during the previous night, so he cannot
  /// protect them twice in a row.
  Future<String?> lastGuardedPlayerId({
    required String gameId,
    required int beforeNightNumber,
  });

  Future<void> deleteNight(String nightId);

  /// Ids of once-per-game actions already spent, so they are not offered twice.
  Future<Set<String>> usedOncePerGameActionIds(String gameId);
}
