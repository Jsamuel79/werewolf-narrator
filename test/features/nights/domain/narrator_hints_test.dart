import 'package:flutter_test/flutter_test.dart';
import 'package:werewolf_narrator/features/games/domain/game_entities.dart';
import 'package:werewolf_narrator/features/nights/domain/narrator_hints.dart';
import 'package:werewolf_narrator/features/nights/domain/night_action_type.dart';
import 'package:werewolf_narrator/features/nights/domain/night_entities.dart';

int _order = 0;

Player player(String name, String roleId) => Player(
  id: name,
  gameId: 'g',
  name: name,
  roleId: roleId,
  seatOrder: 0,
);

NightAction action(NightActionType type, {String? target}) => NightAction(
  id: 'a${_order++}',
  nightId: 'n',
  gameId: 'g',
  typeId: type.id,
  targetPlayerId: target,
  orderIndex: _order,
  createdAt: DateTime(2026),
);

final table = [
  player('Alice', 'guard'),
  player('Bob', 'witch'),
  player('Chloé', 'villager'),
  player('Loup', 'werewolf'),
];

GameSnapshot get snapshot => GameSnapshot(
  game: Game(
    id: 'g',
    name: 'Partie',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    status: GameStatus.inProgress,
  ),
  players: table,
);

List<String> hintsFor(String cardId, List<NightAction> actions) =>
    NarratorHints.forNightCard(
      cardId: cardId,
      actions: actions,
      snapshot: snapshot,
    ).map((h) => h.text).toList();

void main() {
  group('the witch card', () {
    test('warns that the life potion would be spent for nothing', () {
      final hints = hintsFor('witchHeal', [
        action(NightActionTypes.guardProtect, target: 'Chloé'),
        action(NightActionTypes.werewolfVictim, target: 'Chloé'),
      ]);

      expect(hints, hasLength(1));
      expect(hints.single, contains('Salvateur protège déjà Chloé'));
      expect(
        hints.single,
        contains('n\'est pas censée le savoir'),
        reason: 'the hint must say out loud that the table must not hear it',
      );
    });

    test('says nothing when the shield covers somebody else', () {
      expect(
        hintsFor('witchHeal', [
          action(NightActionTypes.guardProtect, target: 'Bob'),
          action(NightActionTypes.werewolfVictim, target: 'Chloé'),
        ]),
        isEmpty,
      );
    });

    test('says nothing before the pack has chosen', () {
      expect(
        hintsFor('witchHeal', [
          action(NightActionTypes.guardProtect, target: 'Chloé'),
        ]),
        isEmpty,
      );
    });
  });

  group('the same pattern on the other cards', () {
    test('the Big Bad Wolf is told whom the pack already ate', () {
      final hints = hintsFor('bigBadWolfVictim', [
        action(NightActionTypes.werewolfVictim, target: 'Chloé'),
      ]);

      expect(hints, hasLength(1));
      expect(hints.single, contains('déjà désigné Chloé'));
    });

    test('the infection is told which meal it replaces', () {
      final hints = hintsFor('infectiousWolfInfect', [
        action(NightActionTypes.werewolfVictim, target: 'Chloé'),
      ]);

      expect(hints, hasLength(1));
      expect(hints.single, contains('Chloé'));
    });

    test('and that a shielded victim makes it a wasted power', () {
      final hints = hintsFor('infectiousWolfInfect', [
        action(NightActionTypes.guardProtect, target: 'Chloé'),
        action(NightActionTypes.werewolfVictim, target: 'Chloé'),
      ]);

      expect(hints, hasLength(2));
      expect(hints.last, contains('dépensé pour rien'));
    });

    test('a card nobody has anything to whisper about stays empty', () {
      expect(
        hintsFor('seerVision', [
          action(NightActionTypes.guardProtect, target: 'Chloé'),
          action(NightActionTypes.werewolfVictim, target: 'Chloé'),
        ]),
        isEmpty,
      );
    });
  });

  test('every hint carries a stable id and its own emoji', () {
    final hints = NarratorHints.forNightCard(
      cardId: 'infectiousWolfInfect',
      actions: [
        action(NightActionTypes.guardProtect, target: 'Chloé'),
        action(NightActionTypes.werewolfVictim, target: 'Chloé'),
      ],
      snapshot: snapshot,
    );

    expect(hints.map((h) => h.id).toSet(), hasLength(hints.length));
    expect(hints.every((h) => h.emoji.isNotEmpty), isTrue);
  });

  test('the banner says plainly that it is not to be read out', () {
    expect(NarratorHints.banner, contains('Info narrateur'));
    expect(NarratorHints.banner, contains('à ne pas lire'));
  });
}
