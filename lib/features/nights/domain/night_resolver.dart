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
            roleChanges.add(
              RoleChange(
                playerId: actor,
                newRoleId: newRoleId,
                // Taking someone else's card can mean starting over with a
                // clean slate — the Devoted Servant says so in her action.
                resetStatuses: action.details['resetStatuses'] == true,
              ),
            );
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

    // Losing the captain matters beyond the death itself: the badge has to be
    // handed over before the next vote.
    String? captainDiedId;
    for (final player in players) {
      if (player.isCaptain && player.isAlive && deadIds.contains(player.id)) {
        captainDiedId = player.id;
      }
    }

    return NightOutcome(
      nightNumber: nightNumber,
      deaths: deaths,
      savedPlayerIds: savedIds,
      newCouple: newCouple,
      charmedPlayerIds: charmedIds.toList(growable: false),
      roleChanges: roleChanges,
      newCaptainId: newCaptainId,
      captainDiedId: captainDiedId,
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
    final changeById = {
      for (final change in outcome.roleChanges) change.playerId: change,
    };
    final couple = outcome.newCouple;

    // A player whose statuses are wiped drags their partner out of the couple
    // too: the link is symmetric, and half a couple is not a couple.
    final resetIds = <String>{
      for (final change in outcome.roleChanges)
        if (change.resetStatuses) change.playerId,
    };
    final orphanedPartnerIds = <String>{
      for (final player in players)
        if (resetIds.contains(player.id) && player.coupledWithPlayerId != null)
          player.coupledWithPlayerId!,
    };

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
      final change = changeById[player.id];
      if (change != null) {
        updated = updated.copyWith(roleId: change.newRoleId);
        if (change.resetStatuses) {
          updated = updated.copyWith(
            clearCouple: true,
            isCaptain: false,
            isCharmed: false,
          );
        }
      }
      if (orphanedPartnerIds.contains(player.id)) {
        updated = updated.copyWith(clearCouple: true);
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
      } else if (outcome.captainDiedId == player.id) {
        // The badge dies with its holder; the election action reopens.
        updated = updated.copyWith(isCaptain: false);
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
    final gameHasHunter = snapshot.players.any(
      (p) => p.roleId == Roles.hunter.id,
    );
    final hasLivingCaptain = snapshot.aliveCaptain != null;

    return NightActionTypes.all.where((type) {
      if (type.id == NightActionTypes.unknown.id) return false;
      if (type.firstNightOnly && nightNumber != 1) return false;
      if (type.oncePerGame && alreadyUsedOncePerGameIds.contains(type.id)) {
        return false;
      }
      // The captain is elected once and keeps the badge until he dies: while
      // one is in office there is nothing to elect.
      if (type.effect == ActionEffect.captain) return !hasLivingCaptain;
      final roleId = type.roleId;
      if (roleId == null) return true;
      // The hunter shoots as he dies, so his action stays available for as long
      // as he is part of the game at all.
      if (roleId == Roles.hunter.id) return gameHasHunter;
      return aliveRoles.contains(roleId);
    }).toList(growable: false);
  }
}
