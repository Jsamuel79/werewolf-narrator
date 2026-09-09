import 'package:flutter_test/flutter_test.dart';
import 'package:werewolf_narrator/features/games/domain/role.dart';

void main() {
  group('Roles catalogue', () {
    test('exposes a non-trivial, extensible list of roles', () {
      expect(Roles.all.length, greaterThanOrEqualTo(20));
    });

    test('role ids are unique', () {
      final ids = Roles.all.map((r) => r.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('every role has a label and a short description', () {
      for (final role in Roles.all) {
        expect(role.label, isNotEmpty, reason: role.id);
        expect(role.description, isNotEmpty, reason: role.id);
        expect(role.emoji, isNotEmpty, reason: role.id);
      }
    });

    test('byId returns the matching role', () {
      expect(Roles.byId('seer'), same(Roles.seer));
      expect(Roles.byId('werewolf').team, RoleTeam.werewolves);
    });

    test('byId degrades to `unknown` instead of throwing', () {
      // A game saved with a role that was later removed must still open.
      expect(Roles.byId('roleRemovedInAFutureVersion'), same(Roles.unknown));
    });

    test('every team has at least one role', () {
      for (final team in RoleTeam.values) {
        expect(Roles.byTeam(team), isNotEmpty, reason: team.name);
      }
    });

    test('firstNightOnly roles also act at night', () {
      for (final role in Roles.all.where((r) => r.firstNightOnly)) {
        expect(role.actsAtNight, isTrue, reason: role.id);
      }
    });
  });
}
