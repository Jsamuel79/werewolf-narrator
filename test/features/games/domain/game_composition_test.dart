import 'package:flutter_test/flutter_test.dart';
import 'package:werewolf_narrator/features/games/domain/game_composition.dart';
import 'package:werewolf_narrator/features/games/domain/role.dart';

void main() {
  test('the villager and the werewolf can never be dropped', () {
    final normalized = GameComposition.normalize(const {'seer'});

    expect(normalized, contains(Roles.villager.id));
    expect(normalized, contains(Roles.werewolf.id));
    expect(normalized, contains(Roles.seer.id));
    expect(GameComposition.isMandatory(Roles.villager.id), isTrue);
    expect(GameComposition.isMandatory(Roles.seer.id), isFalse);
  });

  test('an empty selection still holds the two foundations', () {
    expect(GameComposition.normalize(const []), GameComposition.mandatoryRoleIds);
  });

  test('a role that left the catalogue is dropped', () {
    expect(GameComposition.normalize(const {'werefish'}), isNot(contains('werefish')));
  });

  test('the optional list is the catalogue minus the two foundations', () {
    final optional = GameComposition.optionalRoles.map((r) => r.id).toSet();

    expect(optional, isNot(contains(Roles.villager.id)));
    expect(optional, isNot(contains(Roles.werewolf.id)));
    expect(optional.length, Roles.all.length - 2);
  });

  test('the default selection is the base box', () {
    expect(GameComposition.defaultRoleIds, contains(Roles.seer.id));
    expect(GameComposition.defaultRoleIds, contains(Roles.witch.id));
    expect(GameComposition.defaultRoleIds, isNot(contains(Roles.piper.id)));
  });

  test('« everything » covers the whole catalogue', () {
    expect(GameComposition.everything.length, Roles.all.length);
  });
}
