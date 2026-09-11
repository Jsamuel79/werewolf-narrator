import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../../../core/errors/app_exception.dart';
import '../../../core/security/crypto_service.dart';
import '../../games/domain/game_entities.dart';
import '../domain/game_archive.dart';
import 'export_service.dart';

/// One snapshot sitting on the device, already opened far enough to be listed.
class GameBackup {
  const GameBackup({
    required this.file,
    required this.gameName,
    required this.savedAt,
    required this.playerCount,
    required this.roundCount,
    required this.isFinished,
  });

  final File file;
  final String gameName;
  final DateTime savedAt;
  final int playerCount;
  final int roundCount;
  final bool isFinished;
}

/// Keeps an encrypted copy of every game on the device, refreshed on its own
/// after each half-round.
///
/// The narrator never asks for it and never types a password: the snapshot is
/// sealed with the **database key** from the platform keystore, so it is as
/// unreadable off the device as the database itself — and just as lost if the
/// keystore is wiped. It is a safety net against a corrupted database or a
/// misplaced tap, not a backup to carry elsewhere; that is what the
/// password-protected export is for.
class AutoBackupService {
  AutoBackupService({
    required ExportService exportService,
    required CryptoService crypto,
    required Uint8List databaseKey,
    required Future<Directory> Function() directory,
    DateTime Function()? clock,
  }) : _export = exportService,
       // ignore: prefer_initializing_formals
       _crypto = crypto,
       _key = databaseKey,
       // ignore: prefer_initializing_formals
       _directory = directory,
       _now = clock ?? DateTime.now;

  static const String fileExtension = '.wnb';

  final ExportService _export;
  final CryptoService _crypto;
  final Uint8List _key;
  final Future<Directory> Function() _directory;
  final DateTime Function() _now;

  Future<Directory> _backupDirectory() async {
    final root = await _directory();
    final directory = Directory(p.join(root.path, 'backups'));
    if (!directory.existsSync()) await directory.create(recursive: true);
    return directory;
  }

  /// Writes the current state of [gameId] over its previous snapshot.
  ///
  /// One file per game: the point is to be able to go back to the game as it
  /// stood a moment ago, not to keep a history — the game's own history is in
  /// the database, and a pile of snapshots would only grow forever.
  Future<File> backup(String gameId) async {
    final archive = await _export.buildArchive(gameId);
    final envelope = _crypto.encryptWithKey(
      plaintext: jsonEncode(archive.toJson()),
      key: _key,
    );

    final directory = await _backupDirectory();
    final target = File(p.join(directory.path, '$gameId$fileExtension'));
    // Write beside the real file and rename: a crash mid-write then leaves the
    // previous snapshot intact rather than a truncated one.
    final staging = File('${target.path}.tmp');
    try {
      await staging.writeAsString(envelope, flush: true);
      return await staging.rename(target.path);
    } on Object catch (error) {
      if (staging.existsSync()) await staging.delete();
      throw ExportException(
        'La sauvegarde automatique a échoué.',
        cause: error,
      );
    }
  }

  /// Every snapshot on the device, most recently saved first.
  Future<List<GameBackup>> list() async {
    final directory = await _backupDirectory();
    final backups = <GameBackup>[];

    for (final entity in directory.listSync()) {
      if (entity is! File || !entity.path.endsWith(fileExtension)) continue;
      final archive = await _read(entity);
      if (archive == null) continue;
      backups.add(
        GameBackup(
          file: entity,
          gameName: archive.game.name,
          savedAt: archive.exportedAt,
          playerCount: archive.players.length,
          roundCount: archive.nights.length,
          isFinished: archive.game.isFinished,
        ),
      );
    }

    backups.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return backups;
  }

  /// Restores [backup] as a brand new game, exactly like an import does.
  ///
  /// The game already on the board is left alone: restoring is never
  /// destructive, so a mistaken restore costs nothing but a duplicate.
  Future<Game> restore(GameBackup backup) async {
    final archive = await _read(backup.file);
    if (archive == null) {
      throw const ImportException('Cet instantané est illisible.');
    }
    return _export.restoreArchive(archive);
  }

  Future<void> delete(GameBackup backup) async {
    if (backup.file.existsSync()) await backup.file.delete();
  }

  /// Drops the snapshot of a game that no longer exists.
  Future<void> forget(String gameId) async {
    final directory = await _backupDirectory();
    final file = File(p.join(directory.path, '$gameId$fileExtension'));
    if (file.existsSync()) await file.delete();
  }

  /// A file we cannot open — written by another install, or corrupted — is
  /// skipped rather than allowed to break the whole listing.
  Future<GameArchive?> _read(File file) async {
    try {
      final plaintext = _crypto.decryptWithKey(
        envelopeJson: await file.readAsString(),
        key: _key,
      );
      return _export.parseArchive(plaintext);
    } on AppException {
      return null;
    } on Object {
      return null;
    }
  }

  /// Exposed for the tests that need to reason about timing.
  DateTime now() => _now();
}
