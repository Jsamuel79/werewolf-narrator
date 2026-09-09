import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';
import 'package:werewolf_narrator/core/database/app_database.dart';
import 'package:werewolf_narrator/core/errors/app_exception.dart';
import 'package:werewolf_narrator/core/security/crypto_service.dart';
import 'package:werewolf_narrator/features/export/data/export_service.dart';
import 'package:werewolf_narrator/features/games/data/games_repository_impl.dart';
import 'package:werewolf_narrator/features/games/domain/game_entities.dart';
import 'package:werewolf_narrator/features/games/domain/games_repository.dart';
import 'package:werewolf_narrator/features/nights/data/nights_repository_impl.dart';
import 'package:werewolf_narrator/features/nights/domain/night_action_type.dart';

void main() {
  late AppDatabase db;
  late DriftGamesRepository games;
  late DriftNightsRepository nights;
  late ExportService service;
  late Directory tempDir;
  late Game game;
  late GameSnapshot snapshot;

  String idOf(String name) =>
      snapshot.players.firstWhere((p) => p.name == name).id;

  setUp(() async {
    db = AppDatabase.memory();
    tempDir = Directory.systemTemp.createTempSync('wn_export_test');
    games = DriftGamesRepository(database: db, uuid: const Uuid());
    nights = DriftNightsRepository(database: db, uuid: const Uuid());
    service = ExportService(
      database: db,
      crypto: CryptoService(iterations: 1000),
      uuid: const Uuid(),
      outputDirectory: () => tempDir,
    );

    game = await games.createGame(
      name: 'Partie du samedi',
      players: const [
        PlayerDraft(name: 'Alice', roleId: 'villager'),
        PlayerDraft(name: 'Bob', roleId: 'werewolf'),
        PlayerDraft(name: 'Chloé', roleId: 'cupid'),
        PlayerDraft(name: 'David', roleId: 'seer'),
      ],
    );
    snapshot = (await games.loadGame(game.id))!;

    final first = await nights.startNight(game.id);
    await nights.addAction(
      nightId: first.id,
      typeId: NightActionTypes.cupidCouple.id,
      actorPlayerId: idOf('Chloé'),
      targetPlayerId: idOf('Alice'),
      secondaryTargetPlayerId: idOf('Bob'),
    );
    await nights.addAction(
      nightId: first.id,
      typeId: NightActionTypes.seerVision.id,
      actorPlayerId: idOf('David'),
      targetPlayerId: idOf('Bob'),
      details: const {'text': 'Loup-Garou'},
    );
    await nights.resolveNight(first.id);

    final second = await nights.startNight(game.id);
    await nights.addAction(
      nightId: second.id,
      typeId: NightActionTypes.werewolfVictim.id,
      targetPlayerId: idOf('Alice'),
    );
    await nights.resolveNight(second.id);
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('buildArchive', () {
    test('captures the game, its players and every round', () async {
      final archive = await service.buildArchive(game.id);

      expect(archive.game.name, 'Partie du samedi');
      expect(archive.players, hasLength(4));
      expect(archive.nights, hasLength(2));
      expect(archive.nights.first.actions, hasLength(2));
      expect(archive.nights.last.night.outcome, isNotNull);
    });

    test('survives a JSON round trip unchanged', () async {
      final archive = await service.buildArchive(game.id);
      final restored = jsonDecode(jsonEncode(archive.toJson()));
      final again = jsonEncode(archive.toJson());

      expect(jsonEncode(restored), again);
    });

    test('refuses a game that no longer exists', () {
      expect(
        () => service.buildArchive('nope'),
        throwsA(isA<ExportException>()),
      );
    });
  });

  group('exportGame', () {
    test('writes an encrypted file that leaks nothing', () async {
      final result = await service.exportGame(
        gameId: game.id,
        password: 'motdepasse',
      );

      expect(result.file.existsSync(), isTrue);
      final content = await result.file.readAsString();
      expect(content, isNot(contains('Alice')));
      expect(content, isNot(contains('Partie du samedi')));
      expect(content, isNot(contains('motdepasse')));
      expect(content, contains(CryptoService.formatMarker));
    });

    test('names the file after the game', () async {
      final result = await service.exportGame(
        gameId: game.id,
        password: 'motdepasse',
      );
      expect(result.fileName, startsWith('partie-du-samedi-'));
      expect(result.fileName, endsWith('.wnx.json'));
    });
  });

  group('importGame', () {
    Future<String> exported() async {
      final result = await service.exportGame(
        gameId: game.id,
        password: 'motdepasse',
      );
      return result.file.readAsString();
    }

    test('restores the whole game into a fresh copy', () async {
      final envelope = await exported();
      await games.deleteGame(game.id);
      expect(await games.watchGames(archived: false).first, isEmpty);

      final returned = await service.importGame(
        envelopeJson: envelope,
        password: 'motdepasse',
      );

      final restored = (await games.watchGames(archived: false).first).single;
      // The returned game carries the new id, so callers can open it directly.
      expect(returned.id, restored.game.id);
      expect(returned.id, isNot(game.id));
      expect(restored.game.name, 'Partie du samedi');
      expect(restored.players.map((p) => p.name), [
        'Alice',
        'Bob',
        'Chloé',
        'David',
      ]);

      final history = await nights.loadHistory(restored.game.id);
      expect(history, hasLength(2));
      expect(history.first.actions, hasLength(2));
      expect(
        history.first.actions.last.detail,
        'Loup-Garou',
      );
    });

    test('preserves who died, of what, and on which round', () async {
      final envelope = await exported();
      await games.deleteGame(game.id);
      await service.importGame(
        envelopeJson: envelope,
        password: 'motdepasse',
      );

      final restored = (await games.watchGames(archived: false).first).single;
      final alice = restored.players.firstWhere((p) => p.name == 'Alice');
      final bob = restored.players.firstWhere((p) => p.name == 'Bob');

      expect(alice.isAlive, isFalse);
      expect(alice.deathCause, 'Dévoré par les Loups-Garous');
      expect(alice.deathNightNumber, 2);
      // Bob was Alice's lover, so he died of grief the same round.
      expect(bob.isAlive, isFalse);
      expect(bob.deathCause, 'Mort de chagrin');
    });

    test('remaps couples onto the new player ids', () async {
      final envelope = await exported();
      await games.deleteGame(game.id);
      await service.importGame(
        envelopeJson: envelope,
        password: 'motdepasse',
      );

      final restored = (await games.watchGames(archived: false).first).single;
      expect(restored.couples, hasLength(1));
      final couple = restored.couples.single;
      expect({couple.$1.name, couple.$2.name}, {'Alice', 'Bob'});
    });

    test('remaps the stored recap too', () async {
      final envelope = await exported();
      await games.deleteGame(game.id);
      await service.importGame(
        envelopeJson: envelope,
        password: 'motdepasse',
      );

      final restored = (await games.watchGames(archived: false).first).single;
      final history = await nights.loadHistory(restored.game.id);
      final outcome = history.last.night.outcome!;

      expect(
        restored.playerById(outcome.deaths.first.playerId)?.name,
        'Alice',
      );
    });

    test('importing twice yields two independent games', () async {
      final envelope = await exported();
      await service.importGame(
        envelopeJson: envelope,
        password: 'motdepasse',
      );
      await service.importGame(
        envelopeJson: envelope,
        password: 'motdepasse',
      );

      final all = await games.watchGames(archived: false).first;
      // The original plus two copies.
      expect(all, hasLength(3));
      expect(all.map((s) => s.game.id).toSet(), hasLength(3));
    });

    test('a wrong password imports nothing', () async {
      final envelope = await exported();
      await expectLater(
        service.importGame(envelopeJson: envelope, password: 'wrong'),
        throwsA(isA<ImportException>()),
      );
      expect(await games.watchGames(archived: false).first, hasLength(1));
    });
  });
}
