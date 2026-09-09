import '../../games/domain/game_entities.dart';
import '../../games/domain/role.dart';
import 'night_action_type.dart';
import 'night_entities.dart';

/// Turns the raw actions the narrator entered into the consequences on the
/// board: who dies, who was saved, who falls in love, who gets charmed.
///
/// Pure: no database, no clock, no randomness. Every rule of the game that
/// matters for bookkeeping lives here and nowhere else.
abstract final class NightResolver {
  static const String griefDeathCause = 'Mort de chagrin';

  /// [players] is the state of the board *before* the round is applied.
  static NightOutcome resolve({
    required List<Player> players,
    required List<NightAction> actions,
    required int nightNumber,
  }) {
    final byId = {for (final player in players) player.id: player};
    final ordered = [...actions]
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    final protectedIds = <String>{};
    final charmedIds = <String>{};
    final roleChanges = <RoleChange>[];
    final notes = <String>[];
    final attacks = <({String targetId, String cause, bool protectable})>[];
    (String, String)? newCouple;
    String? newCaptainId;

    // Lovers set during this very round must already count for the grief
    // cascade below, so start from the persisted couples and add the new one.
    final partnerOf = <String, String>{};
    for (final player in players) {
      final partner = player.coupledWithPlayerId;
      if (partner != null) partnerOf[player.id] = partner;
    }

    for (final action in ordered) {
      final type = action.type;
      switch (type.effect) {
        case ActionEffect.kill:
          final target = action.targetPlayerId;
          if (target == null) break;
          attacks.add((
            targetId: target,
            cause: type.deathCause ?? type.label,
            protectable: type.protectable,
          ));

        case ActionEffect.protect:
          final target = action.targetPlayerId;
          if (target != null) protectedIds.add(target);

        case ActionEffect.infect:
          final target = action.targetPlayerId;
          if (target == null) break;
          // Infection replaces the meal: the victim survives as a werewolf.
          protectedIds.add(target);
          roleChanges.add(
            RoleChange(playerId: target, newRoleId: Roles.werewolf.id),
          );

        case ActionEffect.couple:
          final first = action.targetPlayerId;
          final second = action.secondaryTargetPlayerId;
          if (first == null || second == null || first == second) break;
          newCouple = (first, second);
          partnerOf[first] = second;
          partnerOf[second] = first;

        case ActionEffect.charm:
          final first = action.targetPlayerId;
          final second = action.secondaryTargetPlayerId;
          if (first != null) charmedIds.add(first);
          if (second != null) charmedIds.add(second);

        case ActionEffect.roleChange:
          final actor = action.actorPlayerId;
          final newRoleId = action.details['newRoleId'] as String?;
          if (actor != null && newRoleId != null) {
            roleChanges.add(RoleChange(playerId: actor, newRoleId: newRoleId));
          }

        case ActionEffect.captain:
          newCaptainId = action.targetPlayerId;

        case ActionEffect.reveal:
        case ActionEffect.note:
          break;
      }

      final note = _noteFor(action, byId);
      if (note != null) notes.add(note);
    }

    final deaths = <PlayerDeath>[];
    final deadIds = <String>{
      for (final player in players)
        if (!player.isAlive) player.id,
    };
    final savedIds = <String>[];

    for (final attack in attacks) {
      final target = byId[attack.targetId];
      if (target == null || deadIds.contains(attack.targetId)) continue;
      if (attack.protectable && protectedIds.contains(attack.targetId)) {
        if (!savedIds.contains(attack.targetId)) savedIds.add(attack.targetId);
        continue;
      }
      deadIds.add(attack.targetId);
      deaths.add(PlayerDeath(playerId: attack.targetId, cause: attack.cause));
    }

    _cascadeGrief(deaths: deaths, deadIds: deadIds, partnerOf: partnerOf);

    // A player who died this round cannot also be reported as saved.
    savedIds.removeWhere(deadIds.contains);

    return NightOutcome(
      nightNumber: nightNumber,
      deaths: deaths,
      savedPlayerIds: savedIds,
      newCouple: newCouple,
      charmedPlayerIds: charmedIds.toList(growable: false),
      roleChanges: roleChanges,
      newCaptainId: newCaptainId,
      notes: notes,
    );
  }

  /// Losing a lover kills the other one, which may in turn kill a third if the
  /// couples chain — hence the fixed-point loop rather than a single pass.
  static void _cascadeGrief({
    required List<PlayerDeath> deaths,
    required Set<String> deadIds,
    required Map<String, String> partnerOf,
  }) {
    var changed = true;
    while (changed) {
      changed = false;
      for (final id in deadIds.toList(growable: false)) {
        final partner = partnerOf[id];
        if (partner == null || deadIds.contains(partner)) continue;
        deadIds.add(partner);
        deaths.add(
          PlayerDeath(playerId: partner, cause: griefDeathCause),
        );
        changed = true;
      }
    }
  }

  static String? _noteFor(NightAction action, Map<String, Player> byId) {
    final type = action.type;
    if (type.effect != ActionEffect.reveal &&
        type.effect != ActionEffect.note) {
      return null;
    }
    final target = byId[action.targetPlayerId]?.name;
    final detail = action.detail;
    final parts = <String>[type.label];
    if (target != null) parts.add('→ $target');
    if (detail != null && detail.trim().isNotEmpty) parts.add('($detail)');
    return parts.join(' ');
  }

  /// Applies [outcome] to [players], returning the new board state.
  ///
  /// Kept next to [resolve] so the write path in the repository stays a thin
  /// translation to SQL.
  static List<Player> apply({
    required List<Player> players,
    required NightOutcome outcome,
  }) {
    final deathById = {for (final d in outcome.deaths) d.playerId: d};
    final charmed = outcome.charmedPlayerIds.toSet();
    final roleById = {
      for (final change in outcome.roleChanges) change.playerId: change.newRoleId,
    };
    final couple = outcome.newCouple;

    return players.map((player) {
      var updated = player;
      final death = deathById[player.id];
      if (death != null && player.isAlive) {
        updated = updated.copyWith(
          isAlive: false,
          deathNightNumber: outcome.nightNumber,
          deathCause: death.cause,
        );
      }
      if (charmed.contains(player.id)) {
        updated = updated.copyWith(isCharmed: true);
      }
      final newRole = roleById[player.id];
      if (newRole != null) {
        updated = updated.copyWith(roleId: newRole);
      }
      if (couple != null) {
        if (player.id == couple.$1) {
          updated = updated.copyWith(coupledWithPlayerId: couple.$2);
        } else if (player.id == couple.$2) {
          updated = updated.copyWith(coupledWithPlayerId: couple.$1);
        }
      }
      if (outcome.newCaptainId != null) {
        updated = updated.copyWith(
          isCaptain: player.id == outcome.newCaptainId,
        );
      }
      return updated;
    }).toList(growable: false);
  }

  /// Actions the narrator should be offered for [nightNumber], given who is
  /// still alive and what has already been used earlier in the game.
  static List<NightActionType> availableActions({
    required GameSnapshot snapshot,
    required int nightNumber,
    required Set<String> alreadyUsedOncePerGameIds,
  }) {
    final aliveRoles = snapshot.aliveRoleIds;
    final hasHunterDeadThisRound = snapshot.players.any(
      (p) => p.roleId == Roles.hunter.id,
    );

    return NightActionTypes.all.where((type) {
      if (type.id == NightActionTypes.unknown.id) return false;
      if (type.firstNightOnly && nightNumber != 1) return false;
      if (type.oncePerGame && alreadyUsedOncePerGameIds.contains(type.id)) {
        return false;
      }
      final roleId = type.roleId;
      if (roleId == null) return true;
      // The hunter shoots as he dies, so his action stays available for as long
      // as he is part of the game at all.
      if (roleId == Roles.hunter.id) return hasHunterDeadThisRound;
      return aliveRoles.contains(roleId);
    }).toList(growable: false);
  }
}
