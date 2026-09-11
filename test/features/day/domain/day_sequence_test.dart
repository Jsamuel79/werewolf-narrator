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

List<DayCardSpec> cardsOf({
  required List<Player> players,
  Night? night,
  List<DayAction> dayActions = const [],
  Set<String> used = const {},
}) {
  return DaySequenceBuilder.build(
    snapshot: snapshotOf(players),
    night: night ?? nightOf(),
    dayActions: dayActions,
    usedOncePerGameActionIds: used,
  );
}

List<DayCardKind> kindsOf({
  required List<Player> players,
  Night? night,
  List<DayAction> dayActions = const [],
  Set<String> used = const {},
}) {
  return cardsOf(
    players: players,
    night: night,
    dayActions: dayActions,
    used: used,
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

  group('the Stuttering Judge', () {
    final withJudge = [
      player('judge', roleId: Roles.stutteringJudge.id),
      player('bob'),
      player('dan'),
      player('wolf', roleId: Roles.werewolf.id),
    ];

    test('is asked, once in the game, whether he wants a second vote', () {
      expect(kindsOf(players: withJudge), contains(DayCardKind.judgeCall));
    });

    test('is not asked once he has used his power', () {
      expect(
        kindsOf(
          players: withJudge,
          used: const {'judgeSecondVote'},
        ),
        isNot(contains(DayCardKind.judgeCall)),
      );
    });

    test('is not asked at all when he is dead', () {
      expect(
        kindsOf(
          players: [
            player('judge', roleId: Roles.stutteringJudge.id, alive: false),
            player('bob'),
            player('wolf', roleId: Roles.werewolf.id),
          ],
        ),
        isNot(contains(DayCardKind.judgeCall)),
      );
    });

    test('his call adds a second vote right after the first one', () {
      final cards = cardsOf(
        players: withJudge,
        dayActions: const [
          DayAction(typeId: 'villageVote', targetPlayerId: 'bob'),
          DayAction(typeId: 'judgeSecondVote'),
        ],
        // Recording the call spends the power for the rest of the game.
        used: const {'judgeSecondVote'},
      );

      final votes = cards.where((card) => card.kind == DayCardKind.vote);
      expect(votes, hasLength(2));
      expect(votes.last.secondVote, isTrue);
      expect(votes.last.id, isNot(votes.first.id));
      // The question he answered stays on the deck, so going back still works.
      expect(
        cards.map((c) => c.kind),
        containsAllInOrder([
          DayCardKind.vote,
          DayCardKind.judgeCall,
          DayCardKind.vote,
        ]),
      );
    });

    test('the second vote has the final word on who the hunter is', () {
      final kinds = kindsOf(
        players: [
          player('judge', roleId: Roles.stutteringJudge.id),
          player('hunter', roleId: Roles.hunter.id),
          player('bob'),
          player('wolf', roleId: Roles.werewolf.id),
        ],
        dayActions: const [
          DayAction(typeId: 'villageVote', targetPlayerId: 'bob'),
          DayAction(typeId: 'judgeSecondVote'),
          DayAction(typeId: 'villageSecondVote', targetPlayerId: 'hunter'),
        ],
        used: const {'judgeSecondVote'},
      );

      expect(kinds, contains(DayCardKind.hunterShot));
    });
  });

  group('the Devoted Servant', () {
    final withServant = [
      player('servant', roleId: Roles.servant.id),
      player('bob'),
      player('dan'),
      player('wolf', roleId: Roles.werewolf.id),
    ];

    test('is only offered once the village voted somebody out', () {
      expect(
        kindsOf(players: withServant),
        isNot(contains(DayCardKind.servantSwap)),
      );

      final cards = cardsOf(
        players: withServant,
        dayActions: const [
          DayAction(typeId: 'villageVote', targetPlayerId: 'bob'),
        ],
      );
      final swap = cards.firstWhere(
        (card) => card.kind == DayCardKind.servantSwap,
      );
      expect(swap.servantPlayerId, 'servant');
      expect(swap.eliminatedPlayerId, 'bob');
    });

    test('steps in before the hunter fires', () {
      final kinds = kindsOf(
        players: [
          player('servant', roleId: Roles.servant.id),
          player('hunter', roleId: Roles.hunter.id),
          player('bob'),
          player('wolf', roleId: Roles.werewolf.id),
        ],
        dayActions: const [
          DayAction(typeId: 'villageVote', targetPlayerId: 'hunter'),
        ],
      );

      expect(
        kinds,
        containsAllInOrder([
          DayCardKind.vote,
          DayCardKind.servantSwap,
          DayCardKind.hunterShot,
        ]),
      );
    });

    test('does not offer to take her own place', () {
      expect(
        kindsOf(
          players: withServant,
          dayActions: const [
            DayAction(typeId: 'villageVote', targetPlayerId: 'servant'),
          ],
        ),
        isNot(contains(DayCardKind.servantSwap)),
      );
    });

    test('is offered once per game only', () {
      expect(
        kindsOf(
          players: withServant,
          dayActions: const [
            DayAction(typeId: 'villageVote', targetPlayerId: 'bob'),
          ],
          used: const {'servantSwap'},
        ),
        isNot(contains(DayCardKind.servantSwap)),
      );
    });

    test('takes the place of the player the second vote eliminated', () {
      final cards = cardsOf(
        players: [
          player('servant', roleId: Roles.servant.id),
          player('judge', roleId: Roles.stutteringJudge.id),
          player('bob'),
          player('wolf', roleId: Roles.werewolf.id),
        ],
        dayActions: const [
          DayAction(typeId: 'villageVote', targetPlayerId: 'bob'),
          DayAction(typeId: 'judgeSecondVote'),
          DayAction(typeId: 'villageSecondVote', targetPlayerId: 'judge'),
        ],
        used: const {'judgeSecondVote'},
      );

      expect(
        cards
            .firstWhere((card) => card.kind == DayCardKind.servantSwap)
            .eliminatedPlayerId,
        'judge',
      );
    });
  });
}
