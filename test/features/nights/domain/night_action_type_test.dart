import 'package:flutter_test/flutter_test.dart';
import 'package:werewolf_narrator/features/games/domain/role.dart';
import 'package:werewolf_narrator/features/nights/domain/night_action_type.dart';

void main() {
  group('NightActionTypes catalogue', () {
    test('action ids are unique', () {
      final ids = NightActionTypes.all.map((t) => t.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('every action references an existing role or none at all', () {
      for (final type in NightActionTypes.all) {
        if (type.roleId == null) continue;
        expect(
          Roles.byId(type.roleId!),
          isNot(same(Roles.unknown)),
          reason: '${type.id} points at an unknown role',
        );
      }
    });

    test('every lethal action carries a death cause', () {
      for (final type in NightActionTypes.all) {
        if (type.effect != ActionEffect.kill) continue;
        expect(type.deathCause, isNotNull, reason: type.id);
      }
    });

    test('actions needing a second target ask for a target first', () {
      for (final type in NightActionTypes.all) {
        if (!type.requiresSecondaryTarget) continue;
        expect(type.requiresTarget, isTrue, reason: type.id);
        expect(type.secondaryTargetLabel, isNotNull, reason: type.id);
      }
    });

    test('byId degrades to `unknown` for a removed action', () {
      expect(NightActionTypes.byId('nope'), same(NightActionTypes.unknown));
    });

    test('every night-acting role has at least one action', () {
      final withActions = NightActionTypes.all
          .map((t) => t.roleId)
          .whereType<String>()
          .toSet();
      for (final role in Roles.all.where((r) => r.actsAtNight)) {
        expect(
          withActions,
          contains(role.id),
          reason: '${role.label} acts at night but has no action type',
        );
      }
    });
  });
}
