import 'role.dart';

/// Which roles the narrator allows for one game.
///
/// The Villager and the Werewolf are the foundations of the game and are never
/// optional; everything else is a choice made before the cards are dealt. An
/// empty selection therefore still means « villagers and wolves ».
abstract final class GameComposition {
  /// Always in play, whatever the narrator ticks.
  static const Set<String> mandatoryRoleIds = {'villager', 'werewolf'};

  /// What a brand new game starts from when there is no previous game to copy:
  /// the base box, without the variants that need a big table.
  static const Set<String> defaultRoleIds = {
    'villager',
    'werewolf',
    'seer',
    'witch',
    'hunter',
    'cupid',
    'guard',
    'littleGirl',
  };

  /// Roles the narrator may tick or untick, in catalogue order.
  static List<RoleDefinition> get optionalRoles => Roles.all
      .where((role) => !mandatoryRoleIds.contains(role.id))
      .toList(growable: false);

  static bool isMandatory(String roleId) => mandatoryRoleIds.contains(roleId);

  /// Drops unknown ids and puts the two foundations back in.
  static Set<String> normalize(Iterable<String> roleIds) {
    return {
      ...mandatoryRoleIds,
      ...roleIds.where((id) => Roles.byId(id).id != Roles.unknown.id),
    };
  }

  /// The selection to apply when a game has none recorded: the whole
  /// catalogue, so an old game keeps behaving exactly as it used to.
  static Set<String> get everything =>
      Roles.all.map((role) => role.id).toSet();
}
