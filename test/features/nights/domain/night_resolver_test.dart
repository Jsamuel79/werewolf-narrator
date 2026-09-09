import 'package:flutter_test/flutter_test.dart';
import 'package:werewolf_narrator/features/games/domain/game_entities.dart';
import 'package:werewolf_narrator/features/games/domain/role.dart';
import 'package:werewolf_narrator/features/nights/domain/night_action_type.dart';
import 'package:werewolf_narrator/features/nights/domain/night_entities.dart';
import 'package:werewolf_narrator/features/nights/domain/night_resolver.dart';

Player player(
  String id, {
  String role = 'villager',
  bool alive = true,
  String? lover,
}) {
  return Player(
    id: id,
    gameId: 'g1',
    name: id.toUpperCase(),
    roleId: role,
    seatOrder: 0,
    isAlive: alive,
    coupledWithPlayerId: lover,
  );
}

int _order = 0;

NightAction action(
  NightActionType type, {
  String? actor,
  String? target,
  String? secondary,
  Map<String, dynamic> details = const {},
}) {
  return NightAction(
    id: 'a${_order++}',
    nightId: 'n1',
    gameId: 'g1',
    typeId: type.id,
    actorPlayerId: actor,
    targetPlayerId: target,
    secondaryTargetPlayerId: secondary,
    details: details,
    orderIndex: _order,
    createdAt: DateTime(2026, 1, 1),
  );
}

NightOutcome resolve(List<Player> players, List<NightAction> actions,
    {int night = 1}) {
  return NightResolver.resolve(
    players: players,
    actions: actions,
    nightNumber: night,
  );
}

void main() {
  setUp(() => _order = 0);

  group('kills', () {
    test('the werewolf victim dies', () {
      final outcome = resolve(
        [player('a'), player('b', role: 'werewolf')],
        [action(NightActionTypes.werewolfVictim, target: 'a')],
      );

      expect(outcome.deaths, hasLength(1));
      expect(outcome.deaths.single.playerId, 'a');
      expect(outcome.deaths.single.cause, 'Dévoré par les Loups-Garous');
    });

    test('the salvator cancels the werewolf attack', () {
      final outcome = resolve(
        [player('a'), player('b', role: 'guard')],
        [
          action(NightActionTypes.werewolfVictim, target: 'a'),
          action(NightActionTypes.guardProtect, actor: 'b', target: 'a'),
        ],
      );

      expect(outcome.deaths, isEmpty);
      expect(outcome.savedPlayerIds, ['a']);
    });

    test('the healing potion cancels the werewolf attack', () {
      final outcome = resolve(
        [player('a'), player('w', role: 'witch')],
        [
          action(NightActionTypes.werewolfVictim, target: 'a'),
          action(NightActionTypes.witchHeal, actor: 'w', target: 'a'),
        ],
      );

      expect(outcome.deaths, isEmpty);
      expect(outcome.savedPlayerIds, ['a']);
    });

    test('protection does not stop the poison', () {
      final outcome = resolve(
        [player('a'), player('w', role: 'witch'), player('g', role: 'guard')],
        [
          action(NightActionTypes.guardProtect, actor: 'g', target: 'a'),
          action(NightActionTypes.witchPoison, actor: 'w', target: 'a'),
        ],
      );

      expect(outcome.deaths.single.playerId, 'a');
      expect(outcome.deaths.single.cause, 'Empoisonné par la Sorcière');
      expect(outcome.savedPlayerIds, isEmpty);
    });

    test('protection does not stop the village vote', () {
      final outcome = resolve(
        [player('a'), player('g', role: 'guard')],
        [
          action(NightActionTypes.guardProtect, actor: 'g', target: 'a'),
          action(NightActionTypes.villageVote, target: 'a'),
        ],
      );

      expect(outcome.deaths.single.cause, 'Éliminé par le vote du village');
    });

    test('an already dead player is not killed twice', () {
      final outcome = resolve(
        [player('a', alive: false)],
        [action(NightActionTypes.villageVote, target: 'a')],
      );

      expect(outcome.deaths, isEmpty);
    });

    test('two different attacks on the same night kill two players', () {
      final outcome = resolve(
        [player('a'), player('b'), player('w', role: 'witch')],
        [
          action(NightActionTypes.werewolfVictim, target: 'a'),
          action(NightActionTypes.witchPoison, actor: 'w', target: 'b'),
        ],
      );

      expect(outcome.deaths.map((d) => d.playerId), ['a', 'b']);
    });
  });

  group('lovers', () {
    test('cupid creates a couple on the first night', () {
      final outcome = resolve(
        [player('a'), player('b'), player('c', role: 'cupid')],
        [
          action(
            NightActionTypes.cupidCouple,
            actor: 'c',
            target: 'a',
            secondary: 'b',
          ),
        ],
      );

      expect(outcome.newCouple, ('a', 'b'));
    });

    test('a lover dies of grief when the other one is killed', () {
      final outcome = resolve(
        [player('a', lover: 'b'), player('b', lover: 'a')],
        [action(NightActionTypes.werewolfVictim, target: 'a')],
      );

      expect(outcome.deaths.map((d) => d.playerId), ['a', 'b']);
      expect(outcome.deaths.last.cause, NightResolver.griefDeathCause);
    });

    test('a couple created this very night already grieves', () {
      final outcome = resolve(
        [player('a'), player('b'), player('c', role: 'cupid')],
        [
          action(
            NightActionTypes.cupidCouple,
            actor: 'c',
            target: 'a',
            secondary: 'b',
          ),
          action(NightActionTypes.werewolfVictim, target: 'b'),
        ],
      );

      expect(outcome.deaths.map((d) => d.playerId), ['b', 'a']);
    });

    test('grief does not resurrect an already dead partner', () {
      final outcome = resolve(
        [player('a', lover: 'b'), player('b', lover: 'a', alive: false)],
        [action(NightActionTypes.villageVote, target: 'a')],
      );

      expect(outcome.deaths.map((d) => d.playerId), ['a']);
    });

    test('a saved lover does not trigger grief', () {
      final outcome = resolve(
        [
          player('a', lover: 'b'),
          player('b', lover: 'a'),
          player('g', role: 'guard'),
        ],
        [
          action(NightActionTypes.werewolfVictim, target: 'a'),
          action(NightActionTypes.guardProtect, actor: 'g', target: 'a'),
        ],
      );

      expect(outcome.deaths, isEmpty);
    });
  });

  group('other effects', () {
    test('the piper charms both targets', () {
      final outcome = resolve(
        [player('a'), player('b'), player('p', role: 'piper')],
        [
          action(
            NightActionTypes.piperCharm,
            actor: 'p',
            target: 'a',
            secondary: 'b',
          ),
        ],
      );

      expect(outcome.charmedPlayerIds, containsAll(['a', 'b']));
    });

    test('infection spares the victim and turns them into a werewolf', () {
      final outcome = resolve(
        [player('a'), player('w', role: 'infectiousWolf')],
        [
          action(NightActionTypes.werewolfVictim, target: 'a'),
          action(NightActionTypes.infectiousWolfInfect, actor: 'w', target: 'a'),
        ],
      );

      expect(outcome.deaths, isEmpty);
      expect(outcome.savedPlayerIds, ['a']);
      expect(outcome.roleChanges.single.playerId, 'a');
      expect(outcome.roleChanges.single.newRoleId, Roles.werewolf.id);
    });

    test('the captain election is recorded', () {
      final outcome = resolve(
        [player('a'), player('b')],
        [action(NightActionTypes.captainElection, target: 'b')],
      );

      expect(outcome.newCaptainId, 'b');
    });

    test('the seer vision becomes a narrator note, not a board change', () {
      final outcome = resolve(
        [player('a'), player('s', role: 'seer')],
        [
          action(
            NightActionTypes.seerVision,
            actor: 's',
            target: 'a',
            details: {'text': 'Loup-Garou'},
          ),
        ],
      );

      expect(outcome.deaths, isEmpty);
      expect(outcome.notes.single, contains('A'));
      expect(outcome.notes.single, contains('Loup-Garou'));
    });

    test('a night with nothing in it is quiet', () {
      expect(resolve([player('a')], []).isQuiet, isTrue);
    });
  });

  group('apply', () {
    test('writes deaths, causes and the night number on the board', () {
      final players = [player('a'), player('b')];
      final outcome = resolve(players, [
        action(NightActionTypes.werewolfVictim, target: 'a'),
      ], night: 3);

      final updated = NightResolver.apply(players: players, outcome: outcome);
      final dead = updated.firstWhere((p) => p.id == 'a');

      expect(dead.isAlive, isFalse);
      expect(dead.deathNightNumber, 3);
      expect(dead.deathCause, 'Dévoré par les Loups-Garous');
      expect(updated.firstWhere((p) => p.id == 'b').isAlive, isTrue);
    });

    test('links both lovers symmetrically', () {
      final players = [player('a'), player('b'), player('c', role: 'cupid')];
      final outcome = resolve(players, [
        action(
          NightActionTypes.cupidCouple,
          actor: 'c',
          target: 'a',
          secondary: 'b',
        ),
      ]);

      final updated = NightResolver.apply(players: players, outcome: outcome);

      expect(updated.firstWhere((p) => p.id == 'a').coupledWithPlayerId, 'b');
      expect(updated.firstWhere((p) => p.id == 'b').coupledWithPlayerId, 'a');
    });

    test('moves the captain badge to the newly elected player', () {
      final players = [
        player('a').copyWith(isCaptain: true),
        player('b'),
      ];
      final outcome = resolve(players, [
        action(NightActionTypes.captainElection, target: 'b'),
      ]);

      final updated = NightResolver.apply(players: players, outcome: outcome);

      expect(updated.firstWhere((p) => p.id == 'a').isCaptain, isFalse);
      expect(updated.firstWhere((p) => p.id == 'b').isCaptain, isTrue);
    });
  });

  group('availableActions', () {
    GameSnapshot snapshotOf(List<Player> players) => GameSnapshot(
      game: Game(
        id: 'g1',
        name: 'test',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        status: GameStatus.inProgress,
      ),
      players: players,
    );

    test('offers only the actions of roles that are still alive', () {
      final available = NightResolver.availableActions(
        snapshot: snapshotOf([
          player('a', role: 'werewolf'),
          player('b', role: 'seer', alive: false),
        ]),
        nightNumber: 2,
        alreadyUsedOncePerGameIds: const {},
      );

      final ids = available.map((t) => t.id);
      expect(ids, contains(NightActionTypes.werewolfVictim.id));
      expect(ids, isNot(contains(NightActionTypes.seerVision.id)));
    });

    test('hides first-night-only actions after night 1', () {
      final snapshot = snapshotOf([player('c', role: 'cupid')]);

      expect(
        NightResolver.availableActions(
          snapshot: snapshot,
          nightNumber: 1,
          alreadyUsedOncePerGameIds: const {},
        ).map((t) => t.id),
        contains(NightActionTypes.cupidCouple.id),
      );
      expect(
        NightResolver.availableActions(
          snapshot: snapshot,
          nightNumber: 2,
          alreadyUsedOncePerGameIds: const {},
        ).map((t) => t.id),
        isNot(contains(NightActionTypes.cupidCouple.id)),
      );
    });

    test('hides a potion that has already been drunk', () {
      final available = NightResolver.availableActions(
        snapshot: snapshotOf([player('w', role: 'witch')]),
        nightNumber: 2,
        alreadyUsedOncePerGameIds: {NightActionTypes.witchHeal.id},
      );

      final ids = available.map((t) => t.id);
      expect(ids, isNot(contains(NightActionTypes.witchHeal.id)));
      expect(ids, contains(NightActionTypes.witchPoison.id));
    });

    test('always offers the village vote and a free note', () {
      final ids = NightResolver.availableActions(
        snapshot: snapshotOf([player('a')]),
        nightNumber: 5,
        alreadyUsedOncePerGameIds: const {},
      ).map((t) => t.id);

      expect(ids, contains(NightActionTypes.villageVote.id));
      expect(ids, contains(NightActionTypes.customNote.id));
    });

    test('offers the hunter shot even once the hunter is dead', () {
      final ids = NightResolver.availableActions(
        snapshot: snapshotOf([player('h', role: 'hunter', alive: false)]),
        nightNumber: 2,
        alreadyUsedOncePerGameIds: const {},
      ).map((t) => t.id);

      expect(ids, contains(NightActionTypes.hunterShot.id));
    });
  });
}
