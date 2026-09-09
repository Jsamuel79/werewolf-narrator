import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';
import 'package:werewolf_narrator/core/database/app_database.dart';
import 'package:werewolf_narrator/core/errors/app_exception.dart';
import 'package:werewolf_narrator/features/games/data/games_repository_impl.dart';
import 'package:werewolf_narrator/features/games/domain/game_entities.dart';
import 'package:werewolf_narrator/features/games/domain/games_repository.dart';
import 'package:werewolf_narrator/features/nights/data/nights_repository_impl.dart';
import 'package:werewolf_narrator/features/nights/domain/night_action_type.dart';

void main() {
  late AppDatabase db;
  late DriftGamesRepository games;
  late DriftNightsRepository nights;
  late Game game;
  late GameSnapshot snapshot;

  Player playerNamed(String name) =>
      snapshot.players.firstWhere((p) => p.name == name);

  setUp(() async {
    db = AppDatabase.memory();
    games = DriftGamesRepository(database: db, uuid: const Uuid());
    nights = DriftNightsRepository(database: db, uuid: const Uuid());
    game = await games.createGame(
      name: 'Partie test',
      players: const [
        PlayerDraft(name: 'Alice', roleId: 'seer'),
        PlayerDraft(name: 'Bob', roleId: 'werewolf'),
        PlayerDraft(name: 'Chloé', roleId: 'witch'),
        PlayerDraft(name: 'David', roleId: 'cupid'),
      ],
    );
    snapshot = (await games.loadGame(game.id))!;
  });

  tearDown(() => db.close());

  group('startNight', () {
    test('numbers rounds from one', () async {
      final first = await nights.startNight(game.id);
      expect(first.nightNumber, 1);
      expect(first.isResolved, isFalse);
    });

    test('returns the round already open instead of creating another', () async {
      final first = await nights.startNight(game.id);
      final again = await nights.startNight(game.id);
      expect(again.id, first.id);
    });

    test('opens the next number once the previous round is closed', () async {
      final first = await nights.startNight(game.id);
      await nights.resolveNight(first.id);
      final second = await nights.startNight(game.id);
      expect(second.nightNumber, 2);
    });
  });

  group('addAction', () {
    test('records the action in entry order', () async {
      final night = await nights.startNight(game.id);
      await nights.addAction(
        nightId: night.id,
        typeId: NightActionTypes.werewolfVictim.id,
        actorPlayerId: playerNamed('Bob').id,
        targetPlayerId: playerNamed('Alice').id,
      );
      await nights.addAction(
        nightId: night.id,
        typeId: NightActionTypes.seerVision.id,
        actorPlayerId: playerNamed('Alice').id,
        targetPlayerId: playerNamed('Bob').id,
        details: const {'text': 'Loup-Garou'},
      );

      final detail = await nights.loadNight(night.id);
      expect(detail!.actions.map((a) => a.typeId), [
        NightActionTypes.werewolfVictim.id,
        NightActionTypes.seerVision.id,
      ]);
      expect(detail.actions.last.detail, 'Loup-Garou');
      expect(detail.actions.map((a) => a.orderIndex), [0, 1]);
    });

    test('refuses an action without the target it requires', () async {
      final night = await nights.startNight(game.id);
      expect(
        () => nights.addAction(
          nightId: night.id,
          typeId: NightActionTypes.werewolfVictim.id,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('refuses two identical targets for a couple', () async {
      final night = await nights.startNight(game.id);
      final alice = playerNamed('Alice').id;
      expect(
        () => nights.addAction(
          nightId: night.id,
          typeId: NightActionTypes.cupidCouple.id,
          targetPlayerId: alice,
          secondaryTargetPlayerId: alice,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('refuses to write into a closed round', () async {
      final night = await nights.startNight(game.id);
      await nights.resolveNight(night.id);
      expect(
        () => nights.addAction(
          nightId: night.id,
          typeId: NightActionTypes.villageVote.id,
          targetPlayerId: playerNamed('Alice').id,
        ),
        throwsA(isA<GameRuleException>()),
      );
    });

    test('removeAction drops it from the round', () async {
      final night = await nights.startNight(game.id);
      final action = await nights.addAction(
        nightId: night.id,
        typeId: NightActionTypes.villageVote.id,
        targetPlayerId: playerNamed('Alice').id,
      );
      await nights.removeAction(action.id);
      expect((await nights.loadNight(night.id))!.actions, isEmpty);
    });
  });

  group('resolveNight', () {
    test('kills the victim and writes the cause on the board', () async {
      final night = await nights.startNight(game.id);
      await nights.addAction(
        nightId: night.id,
        typeId: NightActionTypes.werewolfVictim.id,
        targetPlayerId: playerNamed('Alice').id,
      );

      final outcome = await nights.resolveNight(night.id);
      expect(outcome.deaths.single.playerId, playerNamed('Alice').id);

      final after = (await games.loadGame(game.id))!;
      final alice = after.players.firstWhere((p) => p.name == 'Alice');
      expect(alice.isAlive, isFalse);
      expect(alice.deathNightNumber, 1);
      expect(alice.deathCause, 'Dévoré par les Loups-Garous');
    });

    test('links both lovers on the board', () async {
      final night = await nights.startNight(game.id);
      await nights.addAction(
        nightId: night.id,
        typeId: NightActionTypes.cupidCouple.id,
        actorPlayerId: playerNamed('David').id,
        targetPlayerId: playerNamed('Alice').id,
        secondaryTargetPlayerId: playerNamed('Bob').id,
      );
      await nights.resolveNight(night.id);

      final after = (await games.loadGame(game.id))!;
      expect(after.couples, hasLength(1));
      expect(
        after.players.firstWhere((p) => p.name == 'Alice').coupledWithPlayerId,
        playerNamed('Bob').id,
      );
    });

    test('freezes the round and stores its summary', () async {
      final night = await nights.startNight(game.id);
      await nights.addAction(
        nightId: night.id,
        typeId: NightActionTypes.werewolfVictim.id,
        targetPlayerId: playerNamed('Alice').id,
      );
      await nights.resolveNight(night.id);

      final stored = (await nights.loadNight(night.id))!.night;
      expect(stored.isResolved, isTrue);
      expect(stored.outcome, isNotNull);
      expect(stored.outcome!.deaths.single.cause,
          'Dévoré par les Loups-Garous');
    });

    test('refuses to close the same round twice', () async {
      final night = await nights.startNight(game.id);
      await nights.resolveNight(night.id);
      expect(
        () => nights.resolveNight(night.id),
        throwsA(isA<GameRuleException>()),
      );
    });

    test('the grief cascade reaches the board', () async {
      final first = await nights.startNight(game.id);
      await nights.addAction(
        nightId: first.id,
        typeId: NightActionTypes.cupidCouple.id,
        targetPlayerId: playerNamed('Alice').id,
        secondaryTargetPlayerId: playerNamed('Chloé').id,
      );
      await nights.resolveNight(first.id);

      final second = await nights.startNight(game.id);
      await nights.addAction(
        nightId: second.id,
        typeId: NightActionTypes.werewolfVictim.id,
        targetPlayerId: playerNamed('Alice').id,
      );
      await nights.resolveNight(second.id);

      final after = (await games.loadGame(game.id))!;
      expect(after.alivePlayers.map((p) => p.name), isNot(contains('Chloé')));
      expect(
        after.players.firstWhere((p) => p.name == 'Chloé').deathCause,
        'Mort de chagrin',
      );
    });
  });

  group('once-per-game actions', () {
    test('a spent potion is reported as used', () async {
      final night = await nights.startNight(game.id);
      expect(await nights.usedOncePerGameActionIds(game.id), isEmpty);

      await nights.addAction(
        nightId: night.id,
        typeId: NightActionTypes.witchHeal.id,
        targetPlayerId: playerNamed('Alice').id,
      );

      expect(
        await nights.usedOncePerGameActionIds(game.id),
        contains(NightActionTypes.witchHeal.id),
      );
      expect(
        await nights.usedOncePerGameActionIds(game.id),
        isNot(contains(NightActionTypes.witchPoison.id)),
      );
    });
  });

  group('history', () {
    test('returns every round with its actions, oldest first', () async {
      final first = await nights.startNight(game.id);
      await nights.addAction(
        nightId: first.id,
        typeId: NightActionTypes.werewolfVictim.id,
        targetPlayerId: playerNamed('Alice').id,
      );
      await nights.resolveNight(first.id);
      final second = await nights.startNight(game.id);
      await nights.addAction(
        nightId: second.id,
        typeId: NightActionTypes.villageVote.id,
        targetPlayerId: playerNamed('Bob').id,
      );
      await nights.resolveNight(second.id);

      final history = await nights.loadHistory(game.id);
      expect(history.map((d) => d.night.nightNumber), [1, 2]);
      expect(history.first.actions, hasLength(1));
      expect(
        history.last.actions.single.typeId,
        NightActionTypes.villageVote.id,
      );
    });

    test('deleting a night removes its actions', () async {
      final night = await nights.startNight(game.id);
      await nights.addAction(
        nightId: night.id,
        typeId: NightActionTypes.villageVote.id,
        targetPlayerId: playerNamed('Alice').id,
      );
      await nights.deleteNight(night.id);

      expect(await nights.loadHistory(game.id), isEmpty);
      expect(await db.select(db.nightActions).get(), isEmpty);
    });
  });
}
