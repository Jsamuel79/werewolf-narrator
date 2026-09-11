import 'package:flutter_test/flutter_test.dart';
import 'package:werewolf_narrator/features/games/domain/game_entities.dart';
import 'package:werewolf_narrator/features/games/domain/role.dart';
import 'package:werewolf_narrator/features/nights/domain/night_action_type.dart';
import 'package:werewolf_narrator/features/nights/domain/night_entities.dart';
import 'package:werewolf_narrator/features/nights/domain/night_sequence.dart';

Player player(
  String id,
  String roleId, {
  bool alive = true,
  bool charmed = false,
}) => Player(
  id: id,
  gameId: 'g',
  name: id,
  roleId: roleId,
  seatOrder: 0,
  isAlive: alive,
  isCharmed: charmed,
);

GameSnapshot snapshotOf(List<Player> players) => GameSnapshot(
  game: Game(
    id: 'g',
    name: 'Partie',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    status: GameStatus.inProgress,
  ),
  players: players,
);

List<String> idsOf(
  List<Player> players, {
  int nightNumber = 1,
  Set<String> used = const {},
  String? lastGuarded,
  List<NightAction> actions = const [],
}) {
  return NightSequenceBuilder.build(
    snapshot: snapshotOf(players),
    nightNumber: nightNumber,
    usedOncePerGameActionIds: used,
    lastGuardedPlayerId: lastGuarded,
    actions: actions,
  ).map((card) => card.id).toList();
}

int _order = 0;

NightAction charmOf(String first, [String? second]) => NightAction(
  id: 'a${_order++}',
  nightId: 'n',
  gameId: 'g',
  typeId: NightActionTypes.piperCharm.id,
  targetPlayerId: first,
  secondaryTargetPlayerId: second,
  orderIndex: _order,
  createdAt: DateTime(2026),
);

void main() {
  final classicTable = [
    player('alice', Roles.seer.id),
    player('bob', Roles.witch.id),
    player('carl', Roles.cupid.id),
    player('dan', Roles.villager.id),
    player('wolf', Roles.werewolf.id),
  ];

  test('every night-acting role of the catalogue has a card', () {
    final everyone = [
      for (final role in Roles.all.where((r) => r.actsAtNight))
        player(role.id, role.id),
    ];

    // Night 1 carries the one-shot roles, night 2 the White Werewolf: between
    // the two, every night action of the catalogue must have been offered.
    final covered = {
      for (final nightNumber in [1, 2])
        ...NightSequenceBuilder.build(
          snapshot: snapshotOf(everyone),
          nightNumber: nightNumber,
          usedOncePerGameActionIds: const {},
        ).map((card) => card.id),
    };

    for (final type in NightActionTypes.all) {
      if (type.phase != ActionPhase.night) continue;
      if (type.id == NightActionTypes.unknown.id) continue;
      // Both potions live on the single witch card, keyed by the heal action.
      final expected = type.id == NightActionTypes.witchPoison.id
          ? NightActionTypes.witchHeal.id
          : type.id;
      expect(
        covered,
        contains(expected),
        reason: '${type.label} has no card',
      );
    }
  });

  test('follows the wake-up order of the rulebook', () {
    final ids = idsOf(classicTable);

    expect(
      ids,
      containsAllInOrder([
        NightActionTypes.cupidCouple.id,
        NightActionTypes.seerVision.id,
        NightActionTypes.werewolfVictim.id,
        NightActionTypes.witchHeal.id,
      ]),
    );
    expect(ids.last, 'summary', reason: 'the recap always closes the night');
  });

  test('only offers the roles still alive', () {
    final ids = idsOf([
      player('alice', Roles.seer.id, alive: false),
      player('bob', Roles.witch.id),
      player('wolf', Roles.werewolf.id),
      player('dan', Roles.villager.id),
    ]);

    expect(ids, isNot(contains(NightActionTypes.seerVision.id)));
    expect(ids, contains(NightActionTypes.witchHeal.id));
  });

  test('first-night roles only show up on the first night', () {
    expect(idsOf(classicTable), contains(NightActionTypes.cupidCouple.id));
    expect(
      idsOf(classicTable, nightNumber: 2),
      isNot(contains(NightActionTypes.cupidCouple.id)),
    );
  });

  test('the witch card disappears once both potions are spent', () {
    expect(
      idsOf(
        classicTable,
        used: {NightActionTypes.witchHeal.id},
      ),
      contains(NightActionTypes.witchHeal.id),
      reason: 'the death potion is still available',
    );
    expect(
      idsOf(
        classicTable,
        used: {
          NightActionTypes.witchHeal.id,
          NightActionTypes.witchPoison.id,
        },
      ),
      isNot(contains(NightActionTypes.witchHeal.id)),
    );
  });

  test('a spent once-per-game power is not offered again', () {
    final table = [
      player('inf', Roles.infectiousWolf.id),
      player('dan', Roles.villager.id),
      player('eve', Roles.villager.id),
    ];

    expect(
      idsOf(table, nightNumber: 2),
      contains(NightActionTypes.infectiousWolfInfect.id),
    );
    expect(
      idsOf(
        table,
        nightNumber: 2,
        used: {NightActionTypes.infectiousWolfInfect.id},
      ),
      isNot(contains(NightActionTypes.infectiousWolfInfect.id)),
    );
  });

  test('the White Werewolf only feeds every other night', () {
    final table = [
      player('white', Roles.whiteWerewolf.id),
      player('wolf', Roles.werewolf.id),
      player('dan', Roles.villager.id),
    ];

    expect(
      idsOf(table, nightNumber: 1),
      isNot(contains(NightActionTypes.whiteWerewolfVictim.id)),
    );
    expect(
      idsOf(table, nightNumber: 2),
      contains(NightActionTypes.whiteWerewolfVictim.id),
    );
  });


  /// Point 5: the ritual the rulebook asks for every single night — all the
  /// charmed players, old and new together, wake up and recognise each other.
  group('the roll call of the charmed', () {
    final table = [
      player('piper', Roles.piper.id),
      player('dan', Roles.villager.id),
      player('eve', Roles.villager.id),
      player('flo', Roles.villager.id),
      player('wolf', Roles.werewolf.id),
    ];

    NightCardSpec? rollCallOf(
      List<Player> players, {
      int nightNumber = 1,
      List<NightAction> actions = const [],
    }) {
      final cards = NightSequenceBuilder.build(
        snapshot: snapshotOf(players),
        nightNumber: nightNumber,
        usedOncePerGameActionIds: const {},
        actions: actions,
      );
      for (final card in cards) {
        if (card.kind == NightCardKind.charmedRollCall) return card;
      }
      return null;
    }

    test('never shows up on a night where nobody is charmed', () {
      expect(rollCallOf(table), isNull);
      expect(idsOf(table), isNot(contains(NightCardSpec.charmedRollCallId)));
    });

    test('appears as soon as the Piper has designated somebody tonight', () {
      final ids = idsOf(table, actions: [charmOf('dan', 'eve')]);

      expect(
        ids,
        containsAllInOrder([
          NightActionTypes.piperCharm.id,
          NightCardSpec.charmedRollCallId,
          NightCardSpec.summaryId,
        ]),
        reason: 'the ritual follows the designation, before the recap',
      );
    });

    test('lists tonight\'s charmed players', () {
      final card = rollCallOf(table, actions: [charmOf('dan', 'eve')])!;
      expect(card.listedPlayerIds, {'dan', 'eve'});
    });

    test('lists the charms of every past night together with tonight\'s', () {
      final secondNight = [
        player('piper', Roles.piper.id),
        player('dan', Roles.villager.id, charmed: true),
        player('eve', Roles.villager.id, charmed: true),
        player('flo', Roles.villager.id),
        player('wolf', Roles.werewolf.id),
      ];

      final card = rollCallOf(
        secondNight,
        nightNumber: 2,
        actions: [charmOf('flo')],
      )!;

      expect(card.listedPlayerIds, {'dan', 'eve', 'flo'});
      expect(card.prompt, contains('tous'));
    });

    test('shows up on a later night even before the Piper has acted', () {
      final secondNight = [
        player('piper', Roles.piper.id),
        player('dan', Roles.villager.id, charmed: true),
        player('eve', Roles.villager.id),
      ];

      expect(rollCallOf(secondNight, nightNumber: 2)?.listedPlayerIds, {'dan'});
    });

    test('leaves the dead out of the roll call', () {
      final board = [
        player('piper', Roles.piper.id),
        player('dan', Roles.villager.id, charmed: true, alive: false),
        player('eve', Roles.villager.id, charmed: true),
        player('wolf', Roles.werewolf.id),
      ];

      expect(rollCallOf(board, nightNumber: 2)!.listedPlayerIds, {'eve'});
    });

    test('goes away with the Piper', () {
      final board = [
        player('piper', Roles.piper.id, alive: false),
        player('dan', Roles.villager.id, charmed: true),
        player('eve', Roles.villager.id),
        player('wolf', Roles.werewolf.id),
      ];

      expect(rollCallOf(board, nightNumber: 2), isNull);
    });
  });

  group('targets', () {
    test('the pack may not eat one of its own', () {
      final snapshot = snapshotOf([
        player('wolf', Roles.werewolf.id),
        player('white', Roles.whiteWerewolf.id),
        player('dan', Roles.villager.id),
        player('eve', Roles.seer.id),
      ]);
      final card = NightSequenceBuilder.build(
        snapshot: snapshot,
        nightNumber: 1,
        usedOncePerGameActionIds: const {},
      ).firstWhere((c) => c.id == NightActionTypes.werewolfVictim.id);

      final names = NightSequenceBuilder.candidates(
        spec: card,
        snapshot: snapshot,
      ).map((p) => p.id);

      expect(names, containsAll(['dan', 'eve']));
      expect(names, isNot(contains('wolf')));
      expect(names, isNot(contains('white')));
    });

    group('the Piper never charms the same player twice', () {
      NightCardSpec piperCardOf(GameSnapshot snapshot, {int nightNumber = 2}) =>
          NightSequenceBuilder.build(
            snapshot: snapshot,
            nightNumber: nightNumber,
            usedOncePerGameActionIds: const {},
          ).firstWhere((c) => c.id == NightActionTypes.piperCharm.id);

      test('drops the players charmed on an earlier night', () {
        final snapshot = snapshotOf([
          player('piper', Roles.piper.id),
          player('dan', Roles.villager.id, charmed: true),
          player('eve', Roles.seer.id, charmed: true),
          player('flo', Roles.villager.id),
          player('wolf', Roles.werewolf.id),
        ]);

        final ids = NightSequenceBuilder.candidates(
          spec: piperCardOf(snapshot),
          snapshot: snapshot,
        ).map((p) => p.id);

        expect(ids, ['flo', 'wolf']);
        expect(ids, isNot(contains('dan')));
        expect(ids, isNot(contains('eve')));
      });

      test('never offers the Piper his own tune', () {
        final snapshot = snapshotOf([
          player('piper', Roles.piper.id),
          player('dan', Roles.villager.id),
        ]);

        expect(
          NightSequenceBuilder.candidates(
            spec: piperCardOf(snapshot),
            snapshot: snapshot,
          ).map((p) => p.id),
          ['dan'],
        );
      });

      test('says on the card why a name is missing', () {
        final snapshot = snapshotOf([
          player('piper', Roles.piper.id),
          player('dan', Roles.villager.id, charmed: true),
          player('eve', Roles.villager.id),
        ]);

        expect(piperCardOf(snapshot).hint, contains('déjà charmé'));
      });

      test('keeps a quiet card when nobody is charmed yet', () {
        final snapshot = snapshotOf([
          player('piper', Roles.piper.id),
          player('dan', Roles.villager.id),
        ]);

        expect(piperCardOf(snapshot, nightNumber: 1).hint, isNull);
      });

      test('a charmed player who died changes nothing', () {
        final snapshot = snapshotOf([
          player('piper', Roles.piper.id),
          player('dan', Roles.villager.id, charmed: true, alive: false),
          player('eve', Roles.villager.id),
        ]);

        expect(
          NightSequenceBuilder.candidates(
            spec: piperCardOf(snapshot),
            snapshot: snapshot,
          ).map((p) => p.id),
          ['eve'],
        );
      });
    });

    test('the seer does not look at herself', () {
      final snapshot = snapshotOf([
        player('alice', Roles.seer.id),
        player('dan', Roles.villager.id),
        player('wolf', Roles.werewolf.id),
      ]);
      final card = NightSequenceBuilder.build(
        snapshot: snapshot,
        nightNumber: 1,
        usedOncePerGameActionIds: const {},
      ).firstWhere((c) => c.id == NightActionTypes.seerVision.id);

      expect(
        NightSequenceBuilder.candidates(spec: card, snapshot: snapshot)
            .map((p) => p.id),
        isNot(contains('alice')),
      );
    });

    test('the guard may not protect the same player twice in a row', () {
      final snapshot = snapshotOf([
        player('guard', Roles.guard.id),
        player('dan', Roles.villager.id),
        player('eve', Roles.villager.id),
        player('wolf', Roles.werewolf.id),
      ]);
      final card = NightSequenceBuilder.build(
        snapshot: snapshot,
        nightNumber: 2,
        usedOncePerGameActionIds: const {},
        lastGuardedPlayerId: 'dan',
      ).firstWhere((c) => c.id == NightActionTypes.guardProtect.id);

      expect(card.hint, contains('deux nuits de suite'));
      expect(
        NightSequenceBuilder.candidates(spec: card, snapshot: snapshot)
            .map((p) => p.id),
        isNot(contains('dan')),
      );
    });

    test('a table of villagers only gets the pack card and the recap', () {
      final ids = idsOf([
        player('a', Roles.villager.id),
        player('b', Roles.villager.id),
        player('wolf', Roles.werewolf.id),
      ]);

      expect(ids, [NightActionTypes.werewolfVictim.id, 'summary']);
    });
  });
}
