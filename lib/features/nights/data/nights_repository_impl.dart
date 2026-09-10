import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/errors/app_exception.dart';
import '../../games/data/game_mappers.dart';
import '../../games/domain/game_entities.dart';
import '../../victory/data/victory_recorder.dart';
import '../domain/night_action_type.dart';
import '../domain/night_entities.dart';
import '../domain/night_resolver.dart';
import '../domain/night_sequence.dart';
import '../domain/nights_repository.dart';
import 'night_mappers.dart';

class DriftNightsRepository implements NightsRepository {
  DriftNightsRepository({
    required AppDatabase database,
    required Uuid uuid,
    DateTime Function()? clock,
    VictoryRecorder? victoryRecorder,
  }) : _db = database,
       // ignore: prefer_initializing_formals
       _uuid = uuid,
       _now = clock ?? DateTime.now,
       _victory =
           victoryRecorder ??
           VictoryRecorder(database: database, clock: clock);

  final AppDatabase _db;
  final Uuid _uuid;
  final DateTime Function() _now;
  final VictoryRecorder _victory;

  @override
  Stream<List<Night>> watchNights(String gameId) {
    final query = _db.select(_db.nights)
      ..where((n) => n.gameId.equals(gameId))
      ..orderBy([(n) => OrderingTerm.desc(n.nightNumber)]);
    return query.watch().map(
      (rows) => rows.map((row) => row.toEntity()).toList(growable: false),
    );
  }

  @override
  Stream<NightDetail?> watchNight(String nightId) {
    final nightQuery = _db.select(_db.nights)
      ..where((n) => n.id.equals(nightId));
    return nightQuery.watchSingleOrNull().asyncMap((row) async {
      if (row == null) return null;
      return NightDetail(
        night: row.toEntity(),
        actions: await _actionsOf(nightId),
      );
    });
  }

  @override
  Future<NightDetail?> loadNight(String nightId) async {
    final row = await (_db.select(
      _db.nights,
    )..where((n) => n.id.equals(nightId))).getSingleOrNull();
    if (row == null) return null;
    return NightDetail(
      night: row.toEntity(),
      actions: await _actionsOf(nightId),
    );
  }

  @override
  Future<List<NightDetail>> loadHistory(String gameId) async {
    final nights =
        await (_db.select(_db.nights)
              ..where((n) => n.gameId.equals(gameId))
              ..orderBy([(n) => OrderingTerm.asc(n.nightNumber)]))
            .get();
    final actions =
        await (_db.select(_db.nightActions)
              ..where((a) => a.gameId.equals(gameId))
              ..orderBy([(a) => OrderingTerm.asc(a.orderIndex)]))
            .get();

    final byNight = <String, List<NightAction>>{};
    for (final action in actions) {
      byNight.putIfAbsent(action.nightId, () => []).add(action.toEntity());
    }

    return [
      for (final night in nights)
        NightDetail(
          night: night.toEntity(),
          actions: byNight[night.id] ?? const [],
        ),
    ];
  }

  Future<List<NightAction>> _actionsOf(String nightId) async {
    final rows =
        await (_db.select(_db.nightActions)
              ..where((a) => a.nightId.equals(nightId))
              ..orderBy([(a) => OrderingTerm.asc(a.orderIndex)]))
            .get();
    return rows.map((row) => row.toEntity()).toList(growable: false);
  }

  @override
  Future<Night> startNight(String gameId) async {
    final game = await (_db.select(
      _db.games,
    )..where((g) => g.id.equals(gameId))).getSingleOrNull();
    if (game == null) {
      throw const ValidationException('Cette partie n\'existe plus.');
    }
    if (GameStatus.fromId(game.status) == GameStatus.finished) {
      throw const GameRuleException(
        'La partie est terminée : plus aucune nuit ne peut être ouverte.',
      );
    }

    final open =
        await (_db.select(_db.nights)
              ..where(
                (n) => n.gameId.equals(gameId) & n.dayResolvedAt.isNull(),
              )
              ..orderBy([(n) => OrderingTerm.asc(n.nightNumber)])
              ..limit(1))
            .getSingleOrNull();
    if (open != null) return open.toEntity();

    final last =
        await (_db.select(_db.nights)
              ..where((n) => n.gameId.equals(gameId))
              ..orderBy([(n) => OrderingTerm.desc(n.nightNumber)])
              ..limit(1))
            .getSingleOrNull();

    final night = Night(
      id: _uuid.v4(),
      gameId: gameId,
      nightNumber: (last?.nightNumber ?? 0) + 1,
      createdAt: _now(),
    );

    await _db
        .into(_db.nights)
        .insert(
          NightsCompanion.insert(
            id: night.id,
            gameId: night.gameId,
            nightNumber: night.nightNumber,
            createdAt: night.createdAt,
          ),
        );
    return night;
  }

  @override
  Future<NightAction> addAction({
    required String nightId,
    required String typeId,
    ActionPhase phase = ActionPhase.night,
    String? actorPlayerId,
    String? targetPlayerId,
    String? secondaryTargetPlayerId,
    Map<String, dynamic> details = const {},
  }) async {
    final night = await (_db.select(
      _db.nights,
    )..where((n) => n.id.equals(nightId))).getSingleOrNull();
    if (night == null) {
      throw const ValidationException('Cette nuit n\'existe plus.');
    }
    // Each half of the round freezes on its own: the day keeps recording after
    // the night has been applied to the board.
    if (phase == ActionPhase.day) {
      if (night.dayResolvedAt != null) {
        throw const GameRuleException(
          'Ce jour est déjà clos : impossible d\'y ajouter une action.',
        );
      }
    } else if (night.resolvedAt != null) {
      throw const GameRuleException(
        'Cette nuit est déjà close : impossible d\'y ajouter une action.',
      );
    }

    final type = NightActionTypes.byId(typeId);
    if (type.requiresTarget && targetPlayerId == null) {
      throw const ValidationException('Cette action demande une cible.');
    }
    if (type.requiresSecondaryTarget && secondaryTargetPlayerId == null) {
      throw const ValidationException(
        'Cette action demande une seconde cible.',
      );
    }
    if (targetPlayerId != null &&
        targetPlayerId == secondaryTargetPlayerId) {
      throw const ValidationException(
        'Les deux cibles doivent être différentes.',
      );
    }

    final existing = await _actionsOf(nightId);
    final action = NightAction(
      id: _uuid.v4(),
      nightId: nightId,
      gameId: night.gameId,
      typeId: typeId,
      phase: phase,
      actorPlayerId: actorPlayerId,
      targetPlayerId: targetPlayerId,
      secondaryTargetPlayerId: secondaryTargetPlayerId,
      details: details,
      orderIndex: existing.length,
      createdAt: _now(),
    );

    await _db
        .into(_db.nightActions)
        .insert(
          NightActionsCompanion.insert(
            id: action.id,
            nightId: action.nightId,
            gameId: action.gameId,
            type: action.typeId,
            orderIndex: action.orderIndex,
            createdAt: action.createdAt,
            phase: Value(NightAction.phaseId(action.phase)),
            actorPlayerId: Value(action.actorPlayerId),
            targetPlayerId: Value(action.targetPlayerId),
            secondaryTargetPlayerId: Value(action.secondaryTargetPlayerId),
            detailsJson: Value(action.detailsJson),
          ),
        );
    return action;
  }

  @override
  Future<void> removeAction(String actionId) async {
    await (_db.delete(
      _db.nightActions,
    )..where((a) => a.id.equals(actionId))).go();
  }

  @override
  Future<NightOutcome> resolveNight(String nightId) async {
    return _resolve(
      nightId: nightId,
      phase: ActionPhase.night,
      alreadyClosed: (row) => row.resolvedAt != null,
      closedMessage: 'Cette nuit est déjà close.',
    );
  }

  @override
  Future<NightOutcome> resolveDay(String nightId) async {
    return _resolve(
      nightId: nightId,
      phase: ActionPhase.day,
      alreadyClosed: (row) => row.dayResolvedAt != null,
      closedMessage: 'Ce jour est déjà clos.',
      requiresNightFirst: true,
    );
  }

  /// Resolves one half of a round: takes the actions recorded in [phase],
  /// applies their consequences to the board, freezes that half, and checks
  /// whether the game just ended.
  Future<NightOutcome> _resolve({
    required String nightId,
    required ActionPhase phase,
    required bool Function(NightRow row) alreadyClosed,
    required String closedMessage,
    bool requiresNightFirst = false,
  }) async {
    final row = await (_db.select(
      _db.nights,
    )..where((n) => n.id.equals(nightId))).getSingleOrNull();
    if (row == null) {
      throw const ValidationException('Cette nuit n\'existe plus.');
    }
    if (alreadyClosed(row)) throw GameRuleException(closedMessage);
    if (requiresNightFirst && row.resolvedAt == null) {
      throw const GameRuleException(
        'Close d\'abord la nuit avant de lever le jour.',
      );
    }

    final actions = (await _actionsOf(nightId))
        .where((action) => action.phase == phase)
        .toList(growable: false);

    final playerRows = await (_db.select(
      _db.players,
    )..where((p) => p.gameId.equals(row.gameId))).get();
    final players = playerRows
        .map((r) => r.toEntity())
        .toList(growable: false);

    final outcome = NightResolver.resolve(
      players: players,
      actions: actions,
      nightNumber: row.nightNumber,
    );
    final updated = NightResolver.apply(players: players, outcome: outcome);
    final now = _now();

    await _db.transaction(() async {
      for (final player in updated) {
        await (_db.update(
          _db.players,
        )..where((p) => p.id.equals(player.id))).write(
          PlayersCompanion(
            roleId: Value(player.roleId),
            isAlive: Value(player.isAlive),
            isCaptain: Value(player.isCaptain),
            isCharmed: Value(player.isCharmed),
            coupledWithPlayerId: Value(player.coupledWithPlayerId),
            deathNightNumber: Value(player.deathNightNumber),
            deathCause: Value(player.deathCause),
          ),
        );
      }
      final summary = jsonEncode(outcome.toJson());
      await (_db.update(_db.nights)..where((n) => n.id.equals(nightId))).write(
        phase == ActionPhase.day
            ? NightsCompanion(
                dayResolvedAt: Value(now),
                daySummaryJson: Value(summary),
              )
            : NightsCompanion(
                resolvedAt: Value(now),
                summaryJson: Value(summary),
              ),
      );
      await (_db.update(
        _db.games,
      )..where((g) => g.id.equals(row.gameId))).write(
        GamesCompanion(updatedAt: Value(now)),
      );
    });

    await _victory.refresh(row.gameId);

    return outcome;
  }

  @override
  Future<String?> lastGuardedPlayerId({
    required String gameId,
    required int beforeNightNumber,
  }) async {
    final rows =
        await (_db.select(_db.nightActions).join([
              innerJoin(
                _db.nights,
                _db.nights.id.equalsExp(_db.nightActions.nightId),
              ),
            ])
              ..where(
                _db.nightActions.gameId.equals(gameId) &
                    _db.nightActions.type.equals(
                      NightActionTypes.guardProtect.id,
                    ) &
                    _db.nights.nightNumber.isSmallerThanValue(
                      beforeNightNumber,
                    ),
              )
              ..orderBy([OrderingTerm.desc(_db.nights.nightNumber)])
              ..limit(1))
            .getSingleOrNull();
    return rows?.readTable(_db.nightActions).targetPlayerId;
  }

  @override
  Future<void> deleteNight(String nightId) async {
    await (_db.delete(_db.nights)..where((n) => n.id.equals(nightId))).go();
  }

  @override
  Future<Set<String>> usedOncePerGameActionIds(String gameId) async {
    final rows = await (_db.selectOnly(_db.nightActions)
          ..addColumns([_db.nightActions.type])
          ..where(_db.nightActions.gameId.equals(gameId))
          ..groupBy([_db.nightActions.type]))
        .get();
    return rows
        .map((row) => row.read(_db.nightActions.type))
        .whereType<String>()
        .where((id) => NightActionTypes.byId(id).oncePerGame)
        .toSet();
  }
}

/// Convenience view used by the night screen: the board plus the round in
/// progress, so the form knows which roles are still alive.
class NightContext {
  const NightContext({
    required this.snapshot,
    required this.detail,
    required this.usedOncePerGameActionIds,
    this.lastGuardedPlayerId,
  });

  final GameSnapshot snapshot;
  final NightDetail detail;
  final Set<String> usedOncePerGameActionIds;

  /// Protected during the previous night — the Salvateur may not repeat.
  final String? lastGuardedPlayerId;

  List<NightActionType> get availableActions => NightResolver.availableActions(
    snapshot: snapshot,
    nightNumber: detail.night.nightNumber,
    alreadyUsedOncePerGameIds: usedOncePerGameActionIds,
  );

  /// The ordered stack of cards the narrator walks through tonight.
  List<NightCardSpec> get cards => NightSequenceBuilder.build(
    snapshot: snapshot,
    nightNumber: detail.night.nightNumber,
    usedOncePerGameActionIds: usedOncePerGameActionIds,
    lastGuardedPlayerId: lastGuardedPlayerId,
  );

  /// Actions recorded during the night half of this round.
  List<NightAction> get nightActions => detail.actions
      .where((action) => action.phase == ActionPhase.night)
      .toList(growable: false);

  /// Actions recorded during the day half.
  List<NightAction> get dayActions => detail.actions
      .where((action) => action.phase == ActionPhase.day)
      .toList(growable: false);

  /// The action already recorded for a card, if the narrator went back.
  NightAction? actionOf(String typeId) {
    for (final action in detail.actions) {
      if (action.typeId == typeId) return action;
    }
    return null;
  }

  /// What would happen if the narrator closed the night right now.
  NightOutcome get preview => NightResolver.resolve(
    players: snapshot.players,
    actions: nightActions,
    nightNumber: detail.night.nightNumber,
  );

  /// What would happen if the narrator closed the day right now.
  NightOutcome get dayPreview => NightResolver.resolve(
    players: snapshot.players,
    actions: dayActions,
    nightNumber: detail.night.nightNumber,
  );
}
