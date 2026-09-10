import 'package:flutter_test/flutter_test.dart';
import 'package:werewolf_narrator/features/day/domain/day_entities.dart';
import 'package:werewolf_narrator/features/games/domain/game_entities.dart';
import 'package:werewolf_narrator/features/games/domain/role.dart';
import 'package:werewolf_narrator/features/nights/domain/night_action_type.dart';
import 'package:werewolf_narrator/features/nights/domain/night_entities.dart';

Player player(
  String id, {
  String roleId = 'villager',
  bool alive = true,
  bool captain = false,
  int? deathNightNumber,
}) {
  return Player(
    id: id,
    gameId: 'g',
    name: id,
    roleId: roleId,
    seatOrder: 0,
    isAlive: alive,
    isCaptain: captain,
    deathNightNumber: deathNightNumber,
  );
}

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

Night nightOf({int number = 1, NightOutcome? outcome}) => Night(
  id: 'n$number',
  gameId: 'g',
  nightNumber: number,
  createdAt: DateTime(2026),
  resolvedAt: DateTime(2026),
  outcome: outcome ?? NightOutcome(nightNumber: number),
);

List<DayCardKind> kindsOf({
  required List<Player> players,
  Night? night,
  List<DayAction> dayActions = const [],
}) {
  return DaySequenceBuilder.build(
    snapshot: snapshotOf(players),
    night: night ?? nightOf(),
    dayActions: dayActions,
  ).map((card) => card.kind).toList();
}

void main() {
  final table = [
    player('alice'),
    player('bob'),
    player('wolf', roleId: Roles.werewolf.id),
    player('dan'),
  ];

  test('a plain day is recap, captain, debate, vote, summary', () {
    expect(kindsOf(players: table), [
      DayCardKind.dawnRecap,
      DayCardKind.captain,
      DayCardKind.debate,
      DayCardKind.vote,
      DayCardKind.summary,
    ]);
  });

  test('the captain card disappears while somebody wears the badge', () {
    final kinds = kindsOf(
      players: [
        player('alice', captain: true),
        player('bob'),
        player('wolf', roleId: Roles.werewolf.id),
      ],
    );

    expect(kinds, isNot(contains(DayCardKind.captain)));
  });

  test('the captain card comes back when the captain died in the night', () {
    final kinds = kindsOf(
      players: [
        player('alice', captain: false, alive: false, deathNightNumber: 2),
        player('bob'),
        player('wolf', roleId: Roles.werewolf.id),
      ],
      night: nightOf(
        number: 2,
        outcome: const NightOutcome(nightNumber: 2, captainDiedId: 'alice'),
      ),
    );

    expect(kinds, contains(DayCardKind.captain));
  });

  test('a hunter who fell in the night gets his shot', () {
    final cards = DaySequenceBuilder.build(
      snapshot: snapshotOf([
        player('hunter', roleId: Roles.hunter.id, alive: false,
            deathNightNumber: 2),
        player('bob'),
        player('wolf', roleId: Roles.werewolf.id),
      ]),
      night: nightOf(number: 2),
      dayActions: const [],
    );

    final shot = cards.firstWhere(
      (card) => card.kind == DayCardKind.hunterShot,
    );
    expect(shot.hunterPlayerId, 'hunter');
    // He fires after the vote, before the recap.
    expect(cards.map((c) => c.kind).toList().indexOf(DayCardKind.hunterShot),
        greaterThan(
          cards.map((c) => c.kind).toList().indexOf(DayCardKind.vote),
        ));
  });

  test('a hunter voted out gets his shot too', () {
    final kinds = kindsOf(
      players: [
        player('hunter', roleId: Roles.hunter.id),
        player('bob'),
        player('wolf', roleId: Roles.werewolf.id),
      ],
      dayActions: const [
        DayAction(
          typeId: 'villageVote',
          targetPlayerId: 'hunter',
        ),
      ],
    );

    expect(kinds, contains(DayCardKind.hunterShot));
  });

  test('a hunter who already fired is not asked twice', () {
    final kinds = kindsOf(
      players: [
        player('hunter', roleId: Roles.hunter.id, alive: false,
            deathNightNumber: 1),
        player('bob'),
        player('wolf', roleId: Roles.werewolf.id),
      ],
      dayActions: const [
        DayAction(typeId: 'hunterShot', targetPlayerId: 'bob'),
      ],
    );

    expect(kinds, isNot(contains(DayCardKind.hunterShot)));
  });

  test('a hunter who died in an earlier round is not asked again', () {
    final kinds = kindsOf(
      players: [
        player('hunter', roleId: Roles.hunter.id, alive: false,
            deathNightNumber: 1),
        player('bob'),
        player('wolf', roleId: Roles.werewolf.id),
      ],
      night: nightOf(number: 3),
    );

    expect(kinds, isNot(contains(DayCardKind.hunterShot)));
  });

  test('the recap always closes the day', () {
    expect(kindsOf(players: table).last, DayCardKind.summary);
  });

  test('DayAction reads what it needs from a recorded action', () {
    final actions = DayAction.from([
      NightAction(
        id: 'a',
        nightId: 'n',
        gameId: 'g',
        typeId: NightActionTypes.villageVote.id,
        targetPlayerId: 'bob',
        orderIndex: 0,
        createdAt: DateTime(2026),
      ),
    ]);

    expect(actions.single.typeId, NightActionTypes.villageVote.id);
    expect(actions.single.targetPlayerId, 'bob');
  });
}
