import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:werewolf_narrator/features/games/domain/role.dart';
import 'package:werewolf_narrator/features/games/domain/role_dealer.dart';

void main() {
  int wolvesIn(List<String> deal) =>
      deal.where((id) => Roles.byId(id).wolfSide).length;

  group('recommended pack size', () {
    test('follows the table of the rulebook', () {
      expect(RoleDealer.recommendedWerewolfCount(4), 1);
      expect(RoleDealer.recommendedWerewolfCount(6), 1);
      expect(RoleDealer.recommendedWerewolfCount(7), 2);
      expect(RoleDealer.recommendedWerewolfCount(9), 2);
      expect(RoleDealer.recommendedWerewolfCount(10), 3);
      expect(RoleDealer.recommendedWerewolfCount(12), 3);
      expect(RoleDealer.recommendedWerewolfCount(13), 4);
      expect(RoleDealer.recommendedWerewolfCount(16), 5);
      expect(RoleDealer.recommendedWerewolfCount(30), 6);
    });

    test('never lets the pack start the game already winning', () {
      for (var players = 3; players <= 20; players++) {
        final wolves = RoleDealer.werewolfCountFor(players);
        expect(
          wolves,
          greaterThanOrEqualTo(1),
          reason: 'a game without a wolf can never be played ($players)',
        );
        expect(
          players - wolves,
          greaterThan(wolves),
          reason: 'villagers must outnumber the pack at $players players',
        );
      }
    });
  });

  group('deal', () {
    test('gives exactly one role per seat', () {
      for (var players = 3; players <= 18; players++) {
        final deal = RoleDealer.deal(
          playerCount: players,
          random: Random(players),
        );
        expect(deal, hasLength(players));
        expect(
          deal.every((id) => Roles.byId(id).id != Roles.unknown.id),
          isTrue,
        );
      }
    });

    test('deals the recommended number of wolves', () {
      for (var players = 4; players <= 18; players++) {
        final deal = RoleDealer.deal(
          playerCount: players,
          random: Random(players * 7),
        );
        expect(
          wolvesIn(deal),
          RoleDealer.werewolfCountFor(players),
          reason: 'at $players players',
        );
      }
    });

    test('keeps a plain Werewolf in every pack of variants', () {
      final deal = RoleDealer.deal(playerCount: 14, random: Random(3));
      expect(deal, contains(Roles.werewolf.id));
    });

    test('never deals a unique role twice', () {
      for (var seed = 0; seed < 40; seed++) {
        final deal = RoleDealer.deal(playerCount: 15, random: Random(seed));
        final counts = <String, int>{};
        for (final id in deal) {
          counts[id] = (counts[id] ?? 0) + 1;
        }
        for (final entry in counts.entries) {
          final role = Roles.byId(entry.key);
          if (role.dealCopies == 0) continue;
          expect(
            entry.value,
            lessThanOrEqualTo(role.dealCopies),
            reason: '${role.label} dealt ${entry.value} times (seed $seed)',
          );
        }
      }
    });

    test('deals the Sisters and the Brothers as a full set or not at all', () {
      for (var seed = 0; seed < 40; seed++) {
        final deal = RoleDealer.deal(playerCount: 16, random: Random(seed));
        final sisters = deal.where((id) => id == Roles.twoSisters.id).length;
        final brothers = deal.where((id) => id == Roles.threeBrothers.id).length;
        expect(sisters, anyOf(0, 2), reason: 'seed $seed');
        expect(brothers, anyOf(0, 3), reason: 'seed $seed');
      }
    });

    test('leaves plain villagers at the table', () {
      for (var players = 6; players <= 18; players++) {
        final deal = RoleDealer.deal(
          playerCount: players,
          random: Random(players),
        );
        expect(
          deal.where((id) => id == Roles.villager.id).length,
          greaterThanOrEqualTo(1),
          reason: 'at $players players',
        );
      }
    });

    test('keeps big-table roles away from a small table', () {
      final deal = RoleDealer.deal(playerCount: 5, random: Random(1));
      for (final id in deal) {
        expect(
          Roles.byId(id).minPlayers,
          lessThanOrEqualTo(5),
          reason: '$id needs a bigger table',
        );
      }
      expect(deal, isNot(contains(Roles.cupid.id)));
      expect(deal, isNot(contains(Roles.piper.id)));
    });

    test('only deals roles allowed for this game', () {
      final allowed = {Roles.werewolf.id, Roles.villager.id, Roles.seer.id};
      final deal = RoleDealer.deal(
        playerCount: 10,
        allowedRoleIds: allowed,
        random: Random(9),
      );

      expect(deal.toSet().difference(allowed), isEmpty);
      expect(wolvesIn(deal), RoleDealer.werewolfCountFor(10));
    });

    test('still deals wolves and villagers when the selection excludes them', () {
      // The two foundations of the game are never optional.
      final deal = RoleDealer.deal(
        playerCount: 8,
        allowedRoleIds: const {},
        random: Random(4),
      );

      expect(wolvesIn(deal), RoleDealer.werewolfCountFor(8));
      expect(
        deal.where((id) => id == Roles.villager.id).length,
        8 - RoleDealer.werewolfCountFor(8),
      );
    });

    test('redealing shuffles the table instead of repeating itself', () {
      // Not a claim about randomness: a stuck dealer would return the very
      // same seating every time, which is the bug this guards against.
      final deals = [
        for (var i = 0; i < 20; i++) RoleDealer.deal(playerCount: 12).join(','),
      ];

      expect(deals.toSet().length, greaterThan(1));
    });

    test('an empty table deals nothing', () {
      expect(RoleDealer.deal(playerCount: 0), isEmpty);
    });
  });
}
