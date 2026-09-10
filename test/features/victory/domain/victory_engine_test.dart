import 'package:flutter_test/flutter_test.dart';
import 'package:werewolf_narrator/features/games/domain/game_entities.dart';
import 'package:werewolf_narrator/features/games/domain/role.dart';
import 'package:werewolf_narrator/features/victory/domain/victory_engine.dart';
import 'package:werewolf_narrator/features/victory/domain/victory_entities.dart';

Player player(
  String id, {
  required String roleId,
  bool alive = true,
  bool charmed = false,
  String? lover,
  int? deathNightNumber,
}) {
  return Player(
    id: id,
    gameId: 'g',
    name: id,
    roleId: roleId,
    seatOrder: 0,
    isAlive: alive,
    isCharmed: charmed,
    coupledWithPlayerId: lover,
    deathNightNumber: deathNightNumber,
  );
}

void main() {
  group('village victory', () {
    test('fires as soon as the last werewolf is eliminated', () {
      final result = VictoryEngine.evaluate([
        player('alice', roleId: Roles.villager.id),
        player('bob', roleId: Roles.seer.id),
        player('wolf', roleId: Roles.werewolf.id, alive: false),
      ]);

      expect(result, isNotNull);
      expect(result!.camp, VictoryCamp.village);
      expect(result.ruleId, 'village');
      expect(result.winnerPlayerIds, containsAll(['alice', 'bob']));
    });

    test('waits for the White Werewolf too, solo though he is', () {
      final players = [
        player('alice', roleId: Roles.villager.id),
        player('bob', roleId: Roles.villager.id),
        player('carl', roleId: Roles.villager.id),
        player('white', roleId: Roles.whiteWerewolf.id),
        player('wolf', roleId: Roles.werewolf.id, alive: false),
      ];

      expect(VictoryEngine.evaluate(players), isNull);

      final afterWhiteDies = [
        ...players.where((p) => p.id != 'white'),
        player('white', roleId: Roles.whiteWerewolf.id, alive: false),
      ];
      expect(VictoryEngine.evaluate(afterWhiteDies)!.camp, VictoryCamp.village);
    });
  });

  group('werewolf victory', () {
    test('fires when wolves equal the other survivors', () {
      final result = VictoryEngine.evaluate([
        player('wolf', roleId: Roles.werewolf.id),
        player('alice', roleId: Roles.villager.id),
        player('bob', roleId: Roles.villager.id, alive: false),
      ]);

      expect(result!.camp, VictoryCamp.werewolves);
      expect(result.winnerPlayerIds, ['wolf']);
    });

    test('does not fire while villagers still outnumber the pack', () {
      final result = VictoryEngine.evaluate([
        player('wolf', roleId: Roles.werewolf.id),
        player('alice', roleId: Roles.villager.id),
        player('bob', roleId: Roles.villager.id),
      ]);

      expect(result, isNull);
    });

    test('counts a solo survivor as prey, not as an ally', () {
      // One wolf, one piper: the wolf eats last, so the wolves win.
      final result = VictoryEngine.evaluate([
        player('wolf', roleId: Roles.werewolf.id),
        player('piper', roleId: Roles.piper.id),
      ]);

      expect(result!.camp, VictoryCamp.werewolves);
    });
  });

  group('mixed lovers', () {
    test('win over both other camps when they are the last two alive', () {
      final result = VictoryEngine.evaluate([
        player('wolf', roleId: Roles.werewolf.id, lover: 'alice'),
        player('alice', roleId: Roles.villager.id, lover: 'wolf'),
        player('bob', roleId: Roles.villager.id, alive: false),
      ]);

      expect(result!.camp, VictoryCamp.lovers);
      expect(result.ruleId, 'mixedLovers');
      expect(result.winnerPlayerIds, containsAll(['wolf', 'alice']));
    });

    test('two lovers of the same camp fall back on the normal rules', () {
      final result = VictoryEngine.evaluate([
        player('alice', roleId: Roles.villager.id, lover: 'bob'),
        player('bob', roleId: Roles.seer.id, lover: 'alice'),
        player('wolf', roleId: Roles.werewolf.id, alive: false),
      ]);

      expect(result!.camp, VictoryCamp.village);
    });

    test('a couple with a third survivor left decides nothing yet', () {
      final result = VictoryEngine.evaluate([
        player('wolf', roleId: Roles.werewolf.id, lover: 'alice'),
        player('alice', roleId: Roles.villager.id, lover: 'wolf'),
        player('bob', roleId: Roles.villager.id),
        player('carl', roleId: Roles.villager.id),
      ]);

      expect(result, isNull);
    });
  });

  group('solo roles', () {
    test('the Piper wins once every other survivor is charmed', () {
      final result = VictoryEngine.evaluate([
        player('piper', roleId: Roles.piper.id),
        player('alice', roleId: Roles.villager.id, charmed: true),
        player('wolf', roleId: Roles.werewolf.id, charmed: true),
        player('bob', roleId: Roles.villager.id, alive: false),
      ]);

      expect(result!.camp.id, Roles.piper.id);
      expect(result.winnerPlayerIds, ['piper']);
    });

    test('the Piper waits while one survivor resists the tune', () {
      final result = VictoryEngine.evaluate([
        player('piper', roleId: Roles.piper.id),
        player('alice', roleId: Roles.villager.id, charmed: true),
        player('bob', roleId: Roles.villager.id),
        player('wolf', roleId: Roles.werewolf.id, charmed: true),
      ]);

      expect(result, isNull);
    });

    test('the White Werewolf wins alone at the end', () {
      final result = VictoryEngine.evaluate([
        player('white', roleId: Roles.whiteWerewolf.id),
        player('wolf', roleId: Roles.werewolf.id, alive: false),
        player('alice', roleId: Roles.villager.id, alive: false),
      ]);

      expect(result!.camp.id, Roles.whiteWerewolf.id);
      expect(result.ruleId, 'soloSurvivor');
    });

    test('the Angel wins when eliminated during the first round', () {
      final result = VictoryEngine.evaluate([
        player(
          'angel',
          roleId: Roles.angel.id,
          alive: false,
          deathNightNumber: 1,
        ),
        player('wolf', roleId: Roles.werewolf.id),
        player('alice', roleId: Roles.villager.id),
        player('bob', roleId: Roles.villager.id),
      ]);

      expect(result!.camp.id, Roles.angel.id);
      expect(result.ruleId, 'angel');
    });

    test('the Angel loses the bet when eliminated later', () {
      final result = VictoryEngine.evaluate([
        player(
          'angel',
          roleId: Roles.angel.id,
          alive: false,
          deathNightNumber: 2,
        ),
        player('wolf', roleId: Roles.werewolf.id),
        player('alice', roleId: Roles.villager.id),
        player('bob', roleId: Roles.villager.id),
      ]);

      expect(result, isNull);
    });
  });

  group('degenerate boards', () {
    test('a table without a single wolf ends at the first check', () {
      final result = VictoryEngine.evaluate([
        player('alice', roleId: Roles.villager.id),
        player('bob', roleId: Roles.villager.id),
        player('carl', roleId: Roles.villager.id),
      ]);

      expect(result!.camp, VictoryCamp.village);
      expect(
        result.reason,
        contains('Aucun Loup-Garou'),
        reason: 'the wording must not claim a wolf was killed',
      );
    });

    test('a wiped out table stops without a winner', () {
      final result = VictoryEngine.evaluate([
        player('alice', roleId: Roles.villager.id, alive: false),
        player('wolf', roleId: Roles.werewolf.id, alive: false),
      ]);

      expect(result!.camp, VictoryCamp.nobody);
    });

    test('an empty board is not a victory', () {
      expect(VictoryEngine.evaluate(const []), isNull);
    });
  });

  test('a running game returns no verdict', () {
    final result = VictoryEngine.evaluate([
      player('wolf', roleId: Roles.werewolf.id),
      player('alice', roleId: Roles.villager.id),
      player('bob', roleId: Roles.seer.id),
      player('carl', roleId: Roles.witch.id),
    ]);

    expect(result, isNull);
  });

  group('VictoryCamp', () {
    test('round-trips a fixed camp through its id', () {
      expect(VictoryCamp.byId('werewolves'), VictoryCamp.werewolves);
      expect(VictoryCamp.byId('lovers').label, 'Les Amoureux');
    });

    test('rebuilds a solo camp from the role catalogue', () {
      expect(VictoryCamp.byId(Roles.piper.id).label, Roles.piper.label);
    });

    test('falls back on an unknown camp for a removed role', () {
      expect(VictoryCamp.byId('nope'), VictoryCamp.unknown);
      expect(VictoryCamp.byId(null), VictoryCamp.unknown);
    });
  });
}
