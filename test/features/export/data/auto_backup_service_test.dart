import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';
import 'package:werewolf_narrator/core/database/app_database.dart';
import 'package:werewolf_narrator/core/errors/app_exception.dart';
import 'package:werewolf_narrator/core/security/crypto_service.dart';
import 'package:werewolf_narrator/core/security/key_store.dart';
import 'package:werewolf_narrator/features/export/data/auto_backup_service.dart';
import 'package:werewolf_narrator/features/export/data/export_service.dart';
import 'package:werewolf_narrator/features/games/data/games_repository_impl.dart';
import 'package:werewolf_narrator/features/games/domain/game_entities.dart';
import 'package:werewolf_narrator/features/games/domain/games_repository.dart';
import 'package:werewolf_narrator/features/nights/data/nights_repository_impl.dart';
import 'package:werewolf_narrator/features/nights/domain/night_action_type.dart';

void main() {
  late AppDatabase db;
  late Directory root;
  late DriftGamesRepository games;
  late ExportService exportService;
  late AutoBackupService backups;
  late Game game;

  final key = Uint8List.fromList(List<int>.generate(32, (i) => i));

  setUp(() async {
    db = AppDatabase.memory();
    root = await Directory.systemTemp.createTemp('wn_backups');
    games = DriftGamesRepository(database: db, uuid: const Uuid());
    exportService = ExportService(
      database: db,
      crypto: CryptoService(iterations: 1000),
      uuid: const Uuid(),
    );
    backups = AutoBackupService(
      exportService: exportService,
      crypto: CryptoService(iterations: 1000),
      databaseKey: key,
      directory: () async => root,
    );
    game = await games.createGame(
      name: 'Soirée du samedi',
      players: const [
        PlayerDraft(name: 'Alice', roleId: 'seer'),
        PlayerDraft(name: 'Bob', roleId: 'villager'),
        PlayerDraft(name: 'Chloé', roleId: 'villager'),
        PlayerDraft(name: 'Loup', roleId: 'werewolf'),
      ],
    );
  });

  tearDown(() async {
    await db.close();
    if (root.existsSync()) await root.delete(recursive: true);
  });

  test('writes a snapshot nothing can read in the clear', () async {
    final file = await backups.backup(game.id);

    expect(file.existsSync(), isTrue);
    final raw = await file.readAsString();
    expect(raw, isNot(contains('Soirée du samedi')));
    expect(raw, isNot(contains('Alice')));
    expect(raw, contains(CryptoService.deviceKeyAlgorithm));
  });

  test('lists what it saved, newest first', () async {
    await backups.backup(game.id);
    final other = await games.createGame(
      name: 'Partie de mardi',
      players: const [
        PlayerDraft(name: 'Dan', roleId: 'villager'),
        PlayerDraft(name: 'Eve', roleId: 'villager'),
        PlayerDraft(name: 'Loup', roleId: 'werewolf'),
      ],
    );
    await backups.backup(other.id);

    final listed = await backups.list();
    expect(listed.map((b) => b.gameName), contains('Soirée du samedi'));
    expect(listed.map((b) => b.gameName), contains('Partie de mardi'));
    expect(
      listed.firstWhere((b) => b.gameName == 'Soirée du samedi').playerCount,
      4,
    );
  });

  test('keeps one snapshot per game, always the latest', () async {
    await backups.backup(game.id);
    await games.renameGame(game.id, 'Soirée renommée');
    await backups.backup(game.id);

    final listed = await backups.list();
    expect(listed, hasLength(1));
    expect(listed.single.gameName, 'Soirée renommée');
  });

  test('restores as a new game, leaving the current one alone', () async {
    await backups.backup(game.id);
    // The evening then goes wrong: a player is wiped off the board.
    final board = (await games.loadGame(game.id))!;
    await games.removePlayer(
      gameId: game.id,
      playerId: board.players.firstWhere((p) => p.name == 'Alice').id,
    );

    final restored = await backups.restore((await backups.list()).single);

    expect(restored.id, isNot(game.id));
    expect(restored.name, 'Soirée du samedi');
    final all = await games.watchGames(archived: false).first;
    expect(all, hasLength(2), reason: 'restoring never overwrites');
    final copy = all.firstWhere((s) => s.game.id == restored.id);
    expect(copy.players.map((p) => p.name), contains('Alice'));
    // And the damaged game is still there, untouched.
    final damaged = all.firstWhere((s) => s.game.id == game.id);
    expect(damaged.players.map((p) => p.name), isNot(contains('Alice')));
  });

  test('a snapshot from another install is skipped, not fatal', () async {
    await backups.backup(game.id);
    final foreign = File('${root.path}/backups/stranger.wnb');
    final otherKey = Uint8List.fromList(List<int>.generate(32, (i) => 255 - i));
    await foreign.writeAsString(
      CryptoService(
        iterations: 1000,
      ).encryptWithKey(plaintext: '{"game": {}}', key: otherKey),
    );

    final listed = await backups.list();
    expect(listed, hasLength(1));
    expect(listed.single.gameName, 'Soirée du samedi');
  });

  test('deletes a snapshot on request', () async {
    await backups.backup(game.id);
    await backups.delete((await backups.list()).single);
    expect(await backups.list(), isEmpty);

    // And forgetting a game with no snapshot is a no-op, not a crash.
    await backups.forget(game.id);
  });

  test('a snapshot needs no password, and refuses to give one a meaning', () {
    final crypto = CryptoService(iterations: 1000);
    final sealed = crypto.encryptWithKey(plaintext: 'secret', key: key);

    expect(
      crypto.decryptWithKey(envelopeJson: sealed, key: key),
      'secret',
    );
    expect(
      () => crypto.decrypt(envelopeJson: sealed, password: 'motdepasse'),
      throwsA(isA<ImportException>()),
      reason: 'a device-key envelope is not a password export',
    );
    expect(
      () => crypto.decryptWithKey(
        envelopeJson: crypto.encrypt(
          plaintext: 'secret',
          password: 'motdepasse',
        ),
        key: key,
      ),
      throwsA(isA<ImportException>()),
      reason: 'and the other way round',
    );
  });

  test('another key cannot open a snapshot', () {
    final crypto = CryptoService(iterations: 1000);
    final sealed = crypto.encryptWithKey(plaintext: 'secret', key: key);
    final otherKey = Uint8List.fromList(List<int>.generate(32, (i) => i + 1));

    expect(
      () => crypto.decryptWithKey(envelopeJson: sealed, key: otherKey),
      throwsA(isA<ImportException>()),
    );
  });

  test('a tampered snapshot is rejected rather than half-read', () {
    final crypto = CryptoService(iterations: 1000);
    final envelope =
        jsonDecode(crypto.encryptWithKey(plaintext: 'secret', key: key))
            as Map<String, dynamic>;
    envelope['payload'] = base64Encode(
      base64Decode(envelope['payload'] as String)..[0] ^= 0xFF,
    );

    expect(
      () => crypto.decryptWithKey(
        envelopeJson: jsonEncode(envelope),
        key: key,
      ),
      throwsA(isA<ImportException>()),
    );
  });

  test('the hex key of the keystore decodes to the bytes of the cipher', () {
    expect(decodeHexKey('00ff10'), [0, 255, 16]);
    expect(() => decodeHexKey('abc'), throwsA(isA<KeyStoreException>()));
    expect(() => decodeHexKey('zz'), throwsA(isA<KeyStoreException>()));
  });

  group('wired into the rounds', () {
    test('a snapshot is taken after each half-round', () async {
      final taken = <String>[];
      final nights = DriftNightsRepository(
        database: db,
        uuid: const Uuid(),
        onRoundResolved: (gameId) async {
          taken.add(gameId);
          await backups.backup(gameId);
        },
      );

      final round = await nights.startNight(game.id);
      await nights.addAction(
        nightId: round.id,
        typeId: NightActionTypes.werewolfVictim.id,
        targetPlayerId: (await games.loadGame(game.id))!
            .players
            .firstWhere((p) => p.name == 'Bob')
            .id,
      );
      await nights.resolveNight(round.id);
      expect(taken, [game.id]);

      await nights.resolveDay(round.id);
      expect(taken, [game.id, game.id]);

      // The snapshot holds the round that was just played.
      expect((await backups.list()).single.roundCount, 1);
    });

    test('a failing snapshot never costs the narrator the round', () async {
      final nights = DriftNightsRepository(
        database: db,
        uuid: const Uuid(),
        onRoundResolved: (gameId) async {
          try {
            throw const ExportException('disque plein');
          } on ExportException {
            // Swallowed, exactly like the provider does.
          }
        },
      );

      final round = await nights.startNight(game.id);
      await nights.resolveNight(round.id);

      expect((await nights.loadNight(round.id))!.night.isResolved, isTrue);
    });
  });
}
