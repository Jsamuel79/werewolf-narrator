import 'package:flutter_test/flutter_test.dart';
import 'package:werewolf_narrator/features/day/domain/vote_resolver.dart';
import 'package:werewolf_narrator/features/games/domain/game_entities.dart';
import 'package:werewolf_narrator/features/games/domain/role.dart';

Player player(
  String id, {
  String roleId = 'villager',
  bool alive = true,
  bool captain = false,
}) {
  return Player(
    id: id,
    gameId: 'g',
    name: id,
    roleId: roleId,
    seatOrder: 0,
    isAlive: alive,
    isCaptain: captain,
  );
}

void main() {
  final table = [
    player('alice'),
    player('bob'),
    player('carl'),
    player('wolf', roleId: Roles.werewolf.id),
  ];

  test('eliminates the player with the most votes', () {
    final result = VoteResolver.resolve(
      players: table,
      votes: const {'wolf': 3, 'alice': 1},
    );

    expect(result.kind, VoteOutcomeKind.clear);
    expect(result.eliminatedPlayerId, 'wolf');
  });

  test('ignores votes cast on a dead player', () {
    final result = VoteResolver.resolve(
      players: [...table, player('ghost', alive: false)],
      votes: const {'ghost': 5, 'wolf': 1},
    );

    expect(result.eliminatedPlayerId, 'wolf');
    expect(result.effectiveVotes, isNot(contains('ghost')));
  });

  test('nobody is eliminated when nobody voted', () {
    final result = VoteResolver.resolve(players: table, votes: const {});

    expect(result.kind, VoteOutcomeKind.noVote);
    expect(result.eliminatesSomeone, isFalse);
  });

  group('the captain', () {
    final withCaptain = [
      player('alice', captain: true),
      player('bob'),
      player('carl'),
      player('wolf', roleId: Roles.werewolf.id),
    ];

    test('votes double: one extra voice on top of their raised hand', () {
      final result = VoteResolver.resolve(
        players: withCaptain,
        votes: const {'wolf': 2, 'bob': 2},
        captainVoteTargetId: 'wolf',
      );

      expect(result.effectiveVotes['wolf'], 3);
      expect(result.kind, VoteOutcomeKind.clear);
      expect(result.eliminatedPlayerId, 'wolf');
    });

    test('settles a tie with their voice', () {
      final result = VoteResolver.resolve(
        players: withCaptain,
        // The extra voice is already counted, and it still ties.
        votes: const {'wolf': 2, 'bob': 3},
        captainVoteTargetId: 'wolf',
      );

      expect(result.effectiveVotes['wolf'], 3);
      expect(result.kind, VoteOutcomeKind.decidedByCaptain);
      expect(result.eliminatedPlayerId, 'wolf');
    });

    test('a dead captain no longer weighs anything', () {
      final result = VoteResolver.resolve(
        players: [
          player('alice', captain: true, alive: false),
          player('bob'),
          player('wolf', roleId: Roles.werewolf.id),
        ],
        votes: const {'wolf': 1, 'bob': 1},
        captainVoteTargetId: 'wolf',
      );

      expect(result.effectiveVotes['wolf'], 1);
      expect(result.kind, VoteOutcomeKind.unresolvedTie);
    });

    test('a tie the captain did not weigh in on stays unresolved', () {
      final result = VoteResolver.resolve(
        players: withCaptain,
        votes: const {'wolf': 2, 'bob': 2},
      );

      expect(result.kind, VoteOutcomeKind.unresolvedTie);
      expect(result.tiedPlayerIds, containsAll(['wolf', 'bob']));
      expect(result.eliminatesSomeone, isFalse);
    });
  });

  group('roles the vote has to respect', () {
    test('a tie sends the Scapegoat to the stake', () {
      final result = VoteResolver.resolve(
        players: [
          player('alice'),
          player('bob'),
          player('goat', roleId: Roles.scapegoat.id),
          player('wolf', roleId: Roles.werewolf.id),
        ],
        votes: const {'alice': 2, 'wolf': 2},
      );

      expect(result.kind, VoteOutcomeKind.scapegoat);
      expect(result.eliminatedPlayerId, 'goat');
    });

    test('the Scapegoat is spared when the vote is clear', () {
      final result = VoteResolver.resolve(
        players: [
          player('alice'),
          player('goat', roleId: Roles.scapegoat.id),
          player('wolf', roleId: Roles.werewolf.id),
        ],
        votes: const {'wolf': 2, 'alice': 1},
      );

      expect(result.eliminatedPlayerId, 'wolf');
    });

    test('the Village Idiot survives the vote that unmasks him', () {
      final result = VoteResolver.resolve(
        players: [
          player('idiot', roleId: Roles.villageIdiot.id),
          player('bob'),
          player('wolf', roleId: Roles.werewolf.id),
        ],
        votes: const {'idiot': 2},
      );

      expect(result.kind, VoteOutcomeKind.idiotSpared);
      expect(result.sparedPlayerId, 'idiot');
      expect(result.eliminatesSomeone, isFalse);
    });

    test('the Village Idiot only escapes once', () {
      final result = VoteResolver.resolve(
        players: [
          player('idiot', roleId: Roles.villageIdiot.id),
          player('bob'),
          player('wolf', roleId: Roles.werewolf.id),
        ],
        votes: const {'idiot': 2},
        villageIdiotAlreadySpared: true,
      );

      expect(result.kind, VoteOutcomeKind.clear);
      expect(result.eliminatedPlayerId, 'idiot');
    });
  });
}
