import 'package:flutter_test/flutter_test.dart';
import 'package:werewolf_narrator/features/games/domain/game_entities.dart';
import 'package:werewolf_narrator/features/games/domain/role.dart';
import 'package:werewolf_narrator/features/nights/domain/night_action_type.dart';
import 'package:werewolf_narrator/features/nights/domain/night_sequence.dart';

Player player(String id, String roleId, {bool alive = true}) => Player(
  id: id,
  gameId: 'g',
  name: id,
  roleId: roleId,
  seatOrder: 0,
  isAlive: alive,
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
}) {
  return NightSequenceBuilder.build(
    snapshot: snapshotOf(players),
    nightNumber: nightNumber,
    usedOncePerGameActionIds: used,
    lastGuardedPlayerId: lastGuarded,
  ).map((card) => card.id).toList();
}

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
