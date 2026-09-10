import 'dart:math';

import 'role.dart';

/// Deals the roles of a table at random, the way a narrator shuffles the deck.
///
/// Pure and deterministic for a given [Random]: the screens hand it a player
/// count and the roles allowed for this game, and get back one role id per
/// seat. Nothing is written anywhere — the narrator can redeal as often as
/// they like, and edit the result by hand afterwards.
abstract final class RoleDealer {
  /// Werewolves per table size, as printed in the rulebook of *Les Loups-Garous
  /// de Thiercelieux* (roughly one wolf for four players).
  ///
  /// Below 4 players the game is a curiosity, but it still gets its wolf.
  static int recommendedWerewolfCount(int playerCount) {
    if (playerCount < 4) return 1;
    if (playerCount <= 6) return 1;
    if (playerCount <= 9) return 2;
    if (playerCount <= 12) return 3;
    if (playerCount <= 15) return 4;
    if (playerCount <= 18) return 5;
    return 6;
  }

  /// The wolves must never start the game already holding the win, so the pack
  /// is capped one short of half the table.
  static int werewolfCountFor(int playerCount) {
    if (playerCount <= 0) return 0;
    final capped = (playerCount - 1) ~/ 2;
    return min(recommendedWerewolfCount(playerCount), max(1, capped));
  }

  /// Village roles every table wants first, in that order.
  static const List<String> _coreSpecials = [
    'seer',
    'witch',
    'hunter',
    'cupid',
    'guard',
  ];

  /// One role id per seat, shuffled.
  ///
  /// [allowedRoleIds] is the composition chosen for this game; `null` means the
  /// whole catalogue. The Villager and the Werewolf are always in play — they
  /// are the foundations of the game — whatever the selection says.
  static List<String> deal({
    required int playerCount,
    Set<String>? allowedRoleIds,
    Random? random,
  }) {
    if (playerCount <= 0) return const [];
    final rng = random ?? Random();
    final allowed = allowedRoleIds;
    bool isAllowed(RoleDefinition role) =>
        allowed == null || allowed.contains(role.id);

    final seats = <String>[];

    // 1. The pack. Wolf variants replace a plain wolf, and only on a pack big
    //    enough to keep at least one ordinary Werewolf in it.
    final wolfCount = werewolfCountFor(playerCount);
    final wolfVariants = Roles.all
        .where(
          (role) =>
              role.wolfSide &&
              role.id != Roles.werewolf.id &&
              role.minPlayers <= playerCount &&
              isAllowed(role),
        )
        .toList()
      ..shuffle(rng);

    var remainingWolfSeats = wolfCount;
    if (remainingWolfSeats >= 2) {
      for (final variant in wolfVariants) {
        if (remainingWolfSeats <= 1) break;
        seats.add(variant.id);
        remainingWolfSeats--;
      }
    }
    for (var i = 0; i < remainingWolfSeats; i++) {
      seats.add(Roles.werewolf.id);
    }

    // 2. Special roles, keeping a floor of plain villagers so the table still
    //    has ordinary people to convince.
    final plainVillagerFloor = max(1, playerCount ~/ 4);
    final specials = _specialsFor(
      playerCount: playerCount,
      isAllowed: isAllowed,
      rng: rng,
    );

    for (final role in specials) {
      final copies = role.dealCopies;
      final free = playerCount - seats.length - plainVillagerFloor;
      if (free < copies) continue;
      for (var i = 0; i < copies; i++) {
        seats.add(role.id);
      }
    }

    // 3. Everyone else is a plain villager.
    while (seats.length < playerCount) {
      seats.add(Roles.villager.id);
    }

    // A table smaller than the pack it was dealt would be a bug upstream, but
    // truncating keeps the contract « one role per seat » true regardless.
    final dealt = seats.take(playerCount).toList()..shuffle(rng);
    return dealt;
  }

  /// Eligible special roles: the classics first, then the rest in random
  /// order, so two deals of the same table rarely feature the same cast.
  static List<RoleDefinition> _specialsFor({
    required int playerCount,
    required bool Function(RoleDefinition) isAllowed,
    required Random rng,
  }) {
    final eligible = Roles.all
        .where(
          (role) =>
              !role.wolfSide &&
              role.dealCopies > 0 &&
              role.minPlayers <= playerCount &&
              isAllowed(role),
        )
        .toList();

    final core = <RoleDefinition>[];
    for (final id in _coreSpecials) {
      final match = eligible.where((role) => role.id == id);
      if (match.isNotEmpty) core.add(match.first);
    }
    final rest = eligible.where((role) => !core.contains(role)).toList()
      ..shuffle(rng);

    return [...core, ...rest];
  }
}
