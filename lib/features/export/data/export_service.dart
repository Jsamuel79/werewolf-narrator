import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/security/crypto_service.dart';
import '../../games/data/game_mappers.dart';
import '../../games/domain/game_entities.dart';
import '../../nights/data/night_mappers.dart';
import '../../nights/domain/night_entities.dart';
import '../domain/game_archive.dart';

class ExportResult {
  const ExportResult({required this.file, required this.fileName});

  final File file;
  final String fileName;
}

/// Reads a game out of the database into a password-protected file, and back.
///
/// The archive never touches the disk in the clear: the JSON is built in
/// memory, encrypted, and only the envelope is written.
class ExportService {
  ExportService({
    required AppDatabase database,
    required CryptoService crypto,
    required Uuid uuid,
    DateTime Function()? clock,
    Directory Function()? outputDirectory,
  }) : _db = database,
       // ignore: prefer_initializing_formals
       _crypto = crypto,
       // ignore: prefer_initializing_formals
       _uuid = uuid,
       _now = clock ?? DateTime.now,
       _outputDirectory = outputDirectory ?? _systemTempDirectory;

  final AppDatabase _db;
  final CryptoService _crypto;
  final Uuid _uuid;
  final DateTime Function() _now;
  final Directory Function() _outputDirectory;

  static Directory _systemTempDirectory() => Directory.systemTemp;

  Future<GameArchive> buildArchive(String gameId) async {
    final gameRow = await (_db.select(
      _db.games,
    )..where((g) => g.id.equals(gameId))).getSingleOrNull();
    if (gameRow == null) {
      throw const ExportException('Cette partie n\'existe plus.');
    }

    final players =
        await (_db.select(_db.players)
              ..where((p) => p.gameId.equals(gameId))
              ..orderBy([(p) => OrderingTerm.asc(p.seatOrder)]))
            .get();
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

    final actionsByNight = <String, List<NightAction>>{};
    for (final action in actions) {
      actionsByNight.putIfAbsent(action.nightId, () => []).add(
        action.toEntity(),
      );
    }

    return GameArchive(
      game: gameRow.toEntity(),
      players: players.map((row) => row.toEntity()).toList(growable: false),
      nights: [
        for (final night in nights)
          NightDetail(
            night: night.toEntity(),
            actions: actionsByNight[night.id] ?? const [],
          ),
      ],
      exportedAt: _now(),
    );
  }

  /// Encrypts the game and writes the envelope next to the app's temp files.
  Future<ExportResult> exportGame({
    required String gameId,
    required String password,
  }) async {
    final archive = await buildArchive(gameId);
    final envelope = _crypto.encrypt(
      plaintext: jsonEncode(archive.toJson()),
      password: password,
    );

    final fileName = _fileNameFor(archive.game);
    try {
      final file = File(p.join(_outputDirectory().path, fileName));
      await file.writeAsString(envelope, flush: true);
      return ExportResult(file: file, fileName: fileName);
    } on Object catch (error) {
      throw ExportException(
        'Impossible d\'écrire le fichier d\'export.',
        cause: error,
      );
    }
  }

  /// Restores an encrypted archive as a brand new game.
  ///
  /// Every id is regenerated so the same file can be imported twice, and so an
  /// import never overwrites a game already on the device.
  Future<Game> importGame({
    required String envelopeJson,
    required String password,
  }) async {
    final plaintext = _crypto.decrypt(
      envelopeJson: envelopeJson,
      password: password,
    );

    final GameArchive archive;
    try {
      archive = GameArchive.fromJson(
        jsonDecode(plaintext) as Map<String, dynamic>,
      );
    } on Object catch (error) {
      throw ImportException(
        'Le contenu de cet export est illisible.',
        cause: error,
      );
    }

    final newGameId = _uuid.v4();
    final playerIds = {
      for (final player in archive.players) player.id: _uuid.v4(),
    };
    final now = _now();

    await _db.transaction(() async {
      await _db
          .into(_db.games)
          .insert(
            GamesCompanion.insert(
              id: newGameId,
              name: archive.game.name,
              createdAt: archive.game.createdAt,
              updatedAt: now,
              status: archive.game.status.id,
              isArchived: Value(archive.game.isArchived),
              notes: Value(archive.game.notes),
            ),
          );

      for (final player in archive.players) {
        await _db
            .into(_db.players)
            .insert(
              PlayersCompanion.insert(
                id: playerIds[player.id]!,
                gameId: newGameId,
                name: player.name,
                roleId: player.roleId,
                seatOrder: player.seatOrder,
                isAlive: Value(player.isAlive),
                isCaptain: Value(player.isCaptain),
                isCharmed: Value(player.isCharmed),
                coupledWithPlayerId: Value(
                  playerIds[player.coupledWithPlayerId],
                ),
                deathNightNumber: Value(player.deathNightNumber),
                deathCause: Value(player.deathCause),
                notes: Value(player.notes),
              ),
            );
      }

      for (final detail in archive.nights) {
        final nightId = _uuid.v4();
        await _db
            .into(_db.nights)
            .insert(
              NightsCompanion.insert(
                id: nightId,
                gameId: newGameId,
                nightNumber: detail.night.nightNumber,
                createdAt: detail.night.createdAt,
                resolvedAt: Value(detail.night.resolvedAt),
                summaryJson: Value(
                  _remapOutcome(detail.night.outcome, playerIds),
                ),
              ),
            );

        for (final action in detail.actions) {
          await _db
              .into(_db.nightActions)
              .insert(
                NightActionsCompanion.insert(
                  id: _uuid.v4(),
                  nightId: nightId,
                  gameId: newGameId,
                  type: action.typeId,
                  orderIndex: action.orderIndex,
                  createdAt: action.createdAt,
                  actorPlayerId: Value(playerIds[action.actorPlayerId]),
                  targetPlayerId: Value(playerIds[action.targetPlayerId]),
                  secondaryTargetPlayerId: Value(
                    playerIds[action.secondaryTargetPlayerId],
                  ),
                  detailsJson: Value(action.detailsJson),
                ),
              );
        }
      }
    });

    return archive.game.copyWith(updatedAt: now);
  }

  /// The stored recap references player ids too, so it needs the same remap.
  String? _remapOutcome(NightOutcome? outcome, Map<String, String> playerIds) {
    if (outcome == null) return null;
    String? remap(String? id) => playerIds[id];
    final couple = outcome.newCouple;

    final remapped = NightOutcome(
      nightNumber: outcome.nightNumber,
      deaths: [
        for (final death in outcome.deaths)
          PlayerDeath(
            playerId: remap(death.playerId) ?? death.playerId,
            cause: death.cause,
          ),
      ],
      savedPlayerIds: [
        for (final id in outcome.savedPlayerIds) remap(id) ?? id,
      ],
      newCouple: couple == null
          ? null
          : (remap(couple.$1) ?? couple.$1, remap(couple.$2) ?? couple.$2),
      charmedPlayerIds: [
        for (final id in outcome.charmedPlayerIds) remap(id) ?? id,
      ],
      roleChanges: [
        for (final change in outcome.roleChanges)
          RoleChange(
            playerId: remap(change.playerId) ?? change.playerId,
            newRoleId: change.newRoleId,
          ),
      ],
      newCaptainId: remap(outcome.newCaptainId),
      notes: outcome.notes,
    );
    return jsonEncode(remapped.toJson());
  }

  String _fileNameFor(Game game) {
    final slug = game.name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final stamp = _now()
        .toIso8601String()
        .substring(0, 16)
        .replaceAll(RegExp(r'[:\-]'), '');
    return '${slug.isEmpty ? 'partie' : slug}-$stamp.wnx.json';
  }
}
