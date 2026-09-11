import 'package:flutter_test/flutter_test.dart';
import 'package:werewolf_narrator/features/games/domain/game_entities.dart';
import 'package:werewolf_narrator/features/games/domain/passive_reminders.dart';
import 'package:werewolf_narrator/features/games/domain/role.dart';

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

void main() {
  List<String> nightRoles(List<Player> players, String cardId) =>
      PassiveReminders.forNightCard(
        cardId: cardId,
        snapshot: snapshotOf(players),
      ).map((reminder) => reminder.roleId).toList();

  List<String> dayRoles(List<Player> players, String cardId) =>
      PassiveReminders.forDayCard(
        cardId: cardId,
        snapshot: snapshotOf(players),
      ).map((reminder) => reminder.roleId).toList();

  group('at night', () {
    test('the pack card recalls the Ancient and the Knight', () {
      final roles = nightRoles([
        player('old', Roles.ancient.id),
        player('knight', Roles.knight.id),
        player('wolf', Roles.werewolf.id),
      ], 'werewolfVictim');

      expect(roles, containsAll([Roles.ancient.id, Roles.knight.id]));
    });

    test('says nothing about a role nobody plays', () {
      expect(
        nightRoles([
          player('bob', Roles.villager.id),
          player('wolf', Roles.werewolf.id),
        ], 'werewolfVictim'),
        isEmpty,
      );
    });

    test('says nothing about a dead Ancient', () {
      expect(
        nightRoles([
          player('old', Roles.ancient.id, alive: false),
          player('wolf', Roles.werewolf.id),
        ], 'werewolfVictim'),
        isEmpty,
      );
    });

    test('does not clutter the other cards', () {
      expect(
        nightRoles([
          player('old', Roles.ancient.id),
          player('wolf', Roles.werewolf.id),
        ], 'seerVision'),
        isEmpty,
      );
    });
  });

  group('by day', () {
    test('the vote card recalls who the vote treats differently', () {
      final roles = dayRoles([
        player('idiot', Roles.villageIdiot.id),
        player('goat', Roles.scapegoat.id),
        player('old', Roles.ancient.id),
        player('wolf', Roles.werewolf.id),
      ], 'vote');

      expect(
        roles,
        containsAll([
          Roles.villageIdiot.id,
          Roles.scapegoat.id,
          Roles.ancient.id,
        ]),
      );
    });

    test('the second vote gets the same reminders as the first', () {
      final players = [
        player('goat', Roles.scapegoat.id),
        player('wolf', Roles.werewolf.id),
      ];

      expect(dayRoles(players, 'vote2'), dayRoles(players, 'vote'));
    });

    test('the dawn card recalls the bear and the servant', () {
      final roles = dayRoles([
        player('bear', Roles.bearShowman.id),
        player('servant', Roles.servant.id),
        player('wolf', Roles.werewolf.id),
      ], 'dawnRecap');

      expect(roles, containsAll([Roles.bearShowman.id, Roles.servant.id]));
    });

    test('the rules the engine applies are worded as confirmations', () {
      final texts = PassiveReminders.forDayCard(
        cardId: 'vote',
        snapshot: snapshotOf([
          player('goat', Roles.scapegoat.id),
          player('wolf', Roles.werewolf.id),
        ]),
      ).map((reminder) => reminder.text);

      expect(
        texts.single,
        contains('L\'application s\'en charge'),
        reason: 'the narrator must not apply it a second time by hand',
      );
    });

    test('an unknown card asks for nothing', () {
      expect(
        dayRoles([player('old', Roles.ancient.id)], 'debate'),
        isEmpty,
      );
    });
  });

  test('every reminder points at a role of the catalogue', () {
    final snapshot = snapshotOf([
      for (final role in Roles.all) player(role.id, role.id),
    ]);

    final all = [
      ...PassiveReminders.forNightCard(
        cardId: 'werewolfVictim',
        snapshot: snapshot,
      ),
      for (final card in ['dawnRecap', 'vote'])
        ...PassiveReminders.forDayCard(cardId: card, snapshot: snapshot),
    ];

    expect(all, isNotEmpty);
    for (final reminder in all) {
      expect(
        reminder.role.id,
        isNot(Roles.unknown.id),
        reason: '${reminder.roleId} is not in the catalogue',
      );
      expect(reminder.text, isNotEmpty);
    }
  });
}
