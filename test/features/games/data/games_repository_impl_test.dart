import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';
import 'package:werewolf_narrator/core/database/app_database.dart';
import 'package:werewolf_narrator/core/errors/app_exception.dart';
import 'package:werewolf_narrator/features/games/data/games_repository_impl.dart';
import 'package:werewolf_narrator/features/games/domain/game_composition.dart';
import 'package:werewolf_narrator/features/games/domain/game_entities.dart';
import 'package:werewolf_narrator/features/games/domain/games_repository.dart';

void main() {
  late AppDatabase db;
  late DriftGamesRepository repository;

  setUp(() {
    db = AppDatabase.memory();
    repository = DriftGamesRepository(
      database: db,
      uuid: const Uuid(),
      clock: () => DateTime(2026, 5, 1, 20, 30),
    );
  });

  tearDown(() => db.close());

  const drafts = [
    PlayerDraft(name: 'Alice', roleId: 'seer'),
    PlayerDraft(name: 'Bob', roleId: 'werewolf'),
    PlayerDraft(name: 'Chloé', roleId: 'villager'),
  ];

  group('createGame', () {
    test('stores the game and seats the players in order', () async {
      final game = await repository.createGame(
        name: '  Soirée du samedi  ',
        players: drafts,
      );

      expect(game.name, 'Soirée du samedi');
      expect(game.status, GameStatus.inProgress);

      final snapshot = await repository.loadGame(game.id);
      expect(snapshot!.players.map((p) => p.name), [
        'Alice',
        'Bob',
        'Chloé',
      ]);
      expect(snapshot.players.map((p) => p.seatOrder), [0, 1, 2]);
      expect(snapshot.players.every((p) => p.isAlive), isTrue);
    });

    test('rejects an empty name', () {
      expect(
        () => repository.createGame(name: '   ', players: drafts),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects fewer than three players', () {
      expect(
        () => repository.createGame(name: 'Test', players: drafts.take(2).toList()),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects duplicate player names, ignoring case', () {
      expect(
        () => repository.createGame(
          name: 'Test',
          players: const [
            PlayerDraft(name: 'Alice', roleId: 'seer'),
            PlayerDraft(name: 'alice', roleId: 'werewolf'),
            PlayerDraft(name: 'Bob', roleId: 'villager'),
          ],
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('does not leave a half-created game behind on failure', () async {
      await expectLater(
        repository.createGame(name: '', players: drafts),
        throwsA(isA<ValidationException>()),
      );
      expect(await db.select(db.games).get(), isEmpty);
    });
  });

  group('listing', () {
    test('separates active games from archived ones', () async {
      final active = await repository.createGame(name: 'A', players: drafts);
      final archived = await repository.createGame(name: 'B', players: drafts);
      await repository.setArchived(gameId: archived.id, archived: true);

      final activeList = await repository.watchGames(archived: false).first;
      final archivedList = await repository.watchGames(archived: true).first;

      expect(activeList.map((s) => s.game.id), [active.id]);
      expect(archivedList.map((s) => s.game.id), [archived.id]);
    });

    test('a game without players still shows up', () async {
      final game = await repository.createGame(name: 'A', players: drafts);
      final snapshot = await repository.loadGame(game.id);
      for (final player in snapshot!.players) {
        await repository.removePlayer(gameId: game.id, playerId: player.id);
      }

      final list = await repository.watchGames(archived: false).first;
      expect(list, hasLength(1));
      expect(list.single.players, isEmpty);
    });

    test('watchGame emits again when a player changes', () async {
      final game = await repository.createGame(name: 'A', players: drafts);
      final stream = repository.watchGame(game.id);

      final first = await stream.first;
      final alice = first!.players.firstWhere((p) => p.name == 'Alice');
      await repository.savePlayers([alice.copyWith(isAlive: false)]);

      final updated = await stream.first;
      expect(
        updated!.players.firstWhere((p) => p.name == 'Alice').isAlive,
        isFalse,
      );
    });
  });

  group('players', () {
    test('addPlayer appends after the last seat', () async {
      final game = await repository.createGame(name: 'A', players: drafts);
      await repository.addPlayer(
        gameId: game.id,
        name: 'Dimitri',
        roleId: 'hunter',
      );

      final snapshot = await repository.loadGame(game.id);
      expect(snapshot!.players.last.name, 'Dimitri');
      expect(snapshot.players.last.seatOrder, 3);
    });

    test('addPlayer refuses a name already at the table', () async {
      final game = await repository.createGame(name: 'A', players: drafts);
      expect(
        () => repository.addPlayer(
          gameId: game.id,
          name: 'ALICE',
          roleId: 'hunter',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('removing a player also unlinks their lover', () async {
      final game = await repository.createGame(name: 'A', players: drafts);
      final snapshot = (await repository.loadGame(game.id))!;
      final alice = snapshot.players[0];
      final bob = snapshot.players[1];
      await repository.savePlayers([
        alice.copyWith(coupledWithPlayerId: bob.id),
        bob.copyWith(coupledWithPlayerId: alice.id),
      ]);

      await repository.removePlayer(gameId: game.id, playerId: alice.id);

      final after = (await repository.loadGame(game.id))!;
      expect(after.players.map((p) => p.name), isNot(contains('Alice')));
      expect(
        after.players.firstWhere((p) => p.name == 'Bob').coupledWithPlayerId,
        isNull,
      );
    });

    test('couples are exposed once, not twice', () async {
      final game = await repository.createGame(name: 'A', players: drafts);
      final snapshot = (await repository.loadGame(game.id))!;
      await repository.savePlayers([
        snapshot.players[0].copyWith(
          coupledWithPlayerId: snapshot.players[1].id,
        ),
        snapshot.players[1].copyWith(
          coupledWithPlayerId: snapshot.players[0].id,
        ),
      ]);

      final after = (await repository.loadGame(game.id))!;
      expect(after.couples, hasLength(1));
    });
  });

  group('game lifecycle', () {
    test('renameGame trims and refuses an empty name', () async {
      final game = await repository.createGame(name: 'A', players: drafts);
      await repository.renameGame(game.id, '  Nouvelle  ');
      expect((await repository.loadGame(game.id))!.game.name, 'Nouvelle');

      expect(
        () => repository.renameGame(game.id, ' '),
        throwsA(isA<ValidationException>()),
      );
    });

    test('deleteGame removes the game and everything under it', () async {
      final game = await repository.createGame(name: 'A', players: drafts);
      await repository.deleteGame(game.id);

      expect(await repository.loadGame(game.id), isNull);
      expect(await db.select(db.players).get(), isEmpty);
    });

    test('setStatus records the end of the game', () async {
      final game = await repository.createGame(name: 'A', players: drafts);
      await repository.setStatus(gameId: game.id, status: GameStatus.finished);
      expect(
        (await repository.loadGame(game.id))!.game.status,
        GameStatus.finished,
      );
    });
  });

  group('composition', () {
    test('a game created without one gets the whole catalogue', () async {
      final game = await repository.createGame(name: 'A', players: drafts);

      expect(
        await repository.loadComposition(game.id),
        GameComposition.everything,
      );
    });

    test('stores the roles allowed for a game', () async {
      final game = await repository.createGame(
        name: 'A',
        players: drafts,
        allowedRoleIds: const {'seer', 'witch'},
      );

      final stored = await repository.loadComposition(game.id);
      expect(stored, containsAll(<String>['seer', 'witch']));
      // The two foundations are put back in whatever the caller passed.
      expect(stored, containsAll(GameComposition.mandatoryRoleIds));
      expect(stored, isNot(contains('piper')));
    });

    test('saving a composition replaces the previous one', () async {
      final game = await repository.createGame(
        name: 'A',
        players: drafts,
        allowedRoleIds: const {'seer', 'witch', 'cupid'},
      );

      await repository.saveComposition(
        gameId: game.id,
        roleIds: const {'hunter'},
      );

      final stored = await repository.loadComposition(game.id);
      expect(stored, contains('hunter'));
      expect(stored, isNot(contains('cupid')));
    });

    test('watching a composition emits the change', () async {
      final game = await repository.createGame(
        name: 'A',
        players: drafts,
        allowedRoleIds: const {'seer'},
      );

      final stream = repository.watchComposition(game.id);
      await expectLater(
        stream,
        emits(predicate<Set<String>>((set) => set.contains('seer'))),
      );

      await repository.saveComposition(
        gameId: game.id,
        roleIds: const {'guard'},
      );
      await expectLater(
        stream,
        emits(predicate<Set<String>>((set) => set.contains('guard'))),
      );
    });

    test('the last composition is proposed for the next game', () async {
      await repository.createGame(
        name: 'Ancienne',
        players: drafts,
        allowedRoleIds: const {'seer', 'witch'},
      );
      final later = DriftGamesRepository(
        database: db,
        uuid: const Uuid(),
        clock: () => DateTime(2026, 6, 1),
      );
      await later.createGame(
        name: 'Récente',
        players: drafts,
        allowedRoleIds: const {'piper', 'angel'},
      );

      final last = await repository.loadLastComposition();
      expect(last, containsAll(<String>['piper', 'angel']));
      expect(last, isNot(contains('witch')));
    });

    test('with no game at all, the base box is proposed', () async {
      expect(
        await repository.loadLastComposition(),
        GameComposition.defaultRoleIds,
      );
    });

    test('deleting a game drops its composition', () async {
      final game = await repository.createGame(
        name: 'A',
        players: drafts,
        allowedRoleIds: const {'seer'},
      );
      await repository.deleteGame(game.id);

      expect(await db.select(db.gameRoleSelections).get(), isEmpty);
    });
  });
}
