import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/errors/app_exception.dart';
import '../../games/data/game_mappers.dart';
import '../../games/domain/game_entities.dart';
import '../domain/night_action_type.dart';
import '../domain/night_entities.dart';
import '../domain/night_resolver.dart';
import '../domain/nights_repository.dart';
import 'night_mappers.dart';

class DriftNightsRepository implements NightsRepository {
  DriftNightsRepository({
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
    final open =
        await (_db.select(_db.nights)
              ..where((n) => n.gameId.equals(gameId) & n.resolvedAt.isNull())
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
    if (night.resolvedAt != null) {
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
    final detail = await loadNight(nightId);
    if (detail == null) {
      throw const ValidationException('Cette nuit n\'existe plus.');
    }
    if (detail.night.isResolved) {
      throw const GameRuleException('Cette nuit est déjà close.');
    }

    final playerRows = await (_db.select(
      _db.players,
    )..where((p) => p.gameId.equals(detail.night.gameId))).get();
    final players = playerRows
        .map((row) => row.toEntity())
        .toList(growable: false);

    final outcome = NightResolver.resolve(
      players: players,
      actions: detail.actions,
      nightNumber: detail.night.nightNumber,
    );
    final updated = NightResolver.apply(players: players, outcome: outcome);

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
      await (_db.update(_db.nights)..where((n) => n.id.equals(nightId))).write(
        NightsCompanion(
          resolvedAt: Value(_now()),
          summaryJson: Value(jsonEncode(outcome.toJson())),
        ),
      );
      await (_db.update(
        _db.games,
      )..where((g) => g.id.equals(detail.night.gameId))).write(
        GamesCompanion(updatedAt: Value(_now())),
      );
    });

    return outcome;
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
  });

  final GameSnapshot snapshot;
  final NightDetail detail;
  final Set<String> usedOncePerGameActionIds;

  List<NightActionType> get availableActions => NightResolver.availableActions(
    snapshot: snapshot,
    nightNumber: detail.night.nightNumber,
    alreadyUsedOncePerGameIds: usedOncePerGameActionIds,
  );

  /// What would happen if the narrator closed the round right now.
  NightOutcome get preview => NightResolver.resolve(
    players: snapshot.players,
    actions: detail.actions,
    nightNumber: detail.night.nightNumber,
  );
}
