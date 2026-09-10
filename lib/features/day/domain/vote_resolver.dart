import '../../games/domain/game_entities.dart';
import '../../games/domain/role.dart';

/// Why the vote ended the way it did — shown to the narrator before they
/// confirm the elimination.
enum VoteOutcomeKind {
  /// One player got strictly more votes than everybody else.
  clear,

  /// A tie the captain settled with their voice.
  decidedByCaptain,

  /// A tie the Scapegoat paid for, as the rulebook says.
  scapegoat,

  /// The Village Idiot was designated, is unmasked, and survives.
  idiotSpared,

  /// A tie nobody can settle: the narrator decides, or nobody dies.
  unresolvedTie,

  /// Nobody got a single vote.
  noVote,
}

/// The result of one village vote.
class VoteResult {
  const VoteResult({
    required this.kind,
    required this.effectiveVotes,
    this.eliminatedPlayerId,
    this.sparedPlayerId,
    this.tiedPlayerIds = const [],
  });

  final VoteOutcomeKind kind;

  /// Votes actually counted, captain's extra voice included.
  final Map<String, int> effectiveVotes;

  final String? eliminatedPlayerId;

  /// Designated by the village but still standing (the Village Idiot).
  final String? sparedPlayerId;

  final List<String> tiedPlayerIds;

  bool get eliminatesSomeone => eliminatedPlayerId != null;

  String get label => switch (kind) {
    VoteOutcomeKind.clear => 'Éliminé par le vote du village',
    VoteOutcomeKind.decidedByCaptain =>
      'Éliminé par le vote du village (départagé par le Capitaine)',
    VoteOutcomeKind.scapegoat =>
      'Bouc émissaire : éliminé faute de majorité',
    VoteOutcomeKind.idiotSpared => 'Démasqué par le vote, mais épargné',
    VoteOutcomeKind.unresolvedTie => 'Égalité : personne n\'est éliminé',
    VoteOutcomeKind.noVote => 'Aucune voix exprimée',
  };
}

/// Counts a village vote the way the table does it out loud.
///
/// The narrator counts raised hands and types the totals; this turns them into
/// an elimination. Pure — no database, no widget.
abstract final class VoteResolver {
  static VoteResult resolve({
    required List<Player> players,
    required Map<String, int> votes,

    /// Who the captain voted for. Their voice counts double, so this adds one
    /// extra vote on top of the hand already counted in [votes].
    String? captainVoteTargetId,

    /// The Idiot only survives the vote once; afterwards he is an ordinary
    /// villager who has lost his right to vote.
    bool villageIdiotAlreadySpared = false,
  }) {
    final alive = {
      for (final player in players)
        if (player.isAlive) player.id: player,
    };

    final effective = <String, int>{};
    votes.forEach((playerId, count) {
      if (!alive.containsKey(playerId) || count <= 0) return;
      effective[playerId] = count;
    });

    final captain = _aliveCaptain(players);
    if (captain != null &&
        captainVoteTargetId != null &&
        alive.containsKey(captainVoteTargetId)) {
      effective[captainVoteTargetId] = (effective[captainVoteTargetId] ?? 0) + 1;
    }

    if (effective.isEmpty) {
      return VoteResult(
        kind: VoteOutcomeKind.noVote,
        effectiveVotes: effective,
      );
    }

    final best = effective.values.reduce((a, b) => a > b ? a : b);
    final leaders = effective.entries
        .where((entry) => entry.value == best)
        .map((entry) => entry.key)
        .toList(growable: false);

    if (leaders.length == 1) {
      return _finish(
        candidateId: leaders.single,
        kind: VoteOutcomeKind.clear,
        effective: effective,
        alive: alive,
        villageIdiotAlreadySpared: villageIdiotAlreadySpared,
      );
    }

    // Tie. The rulebook settles it with the Scapegoat first — that is his whole
    // purpose — and with the captain's voice when he is not in play.
    final scapegoat = alive.values
        .where((player) => player.roleId == Roles.scapegoat.id)
        .toList(growable: false);
    if (scapegoat.isNotEmpty) {
      return _finish(
        candidateId: scapegoat.first.id,
        kind: VoteOutcomeKind.scapegoat,
        effective: effective,
        alive: alive,
        villageIdiotAlreadySpared: villageIdiotAlreadySpared,
        tied: leaders,
      );
    }

    if (captain != null &&
        captainVoteTargetId != null &&
        leaders.contains(captainVoteTargetId)) {
      return _finish(
        candidateId: captainVoteTargetId,
        kind: VoteOutcomeKind.decidedByCaptain,
        effective: effective,
        alive: alive,
        villageIdiotAlreadySpared: villageIdiotAlreadySpared,
        tied: leaders,
      );
    }

    return VoteResult(
      kind: VoteOutcomeKind.unresolvedTie,
      effectiveVotes: effective,
      tiedPlayerIds: leaders,
    );
  }

  static VoteResult _finish({
    required String candidateId,
    required VoteOutcomeKind kind,
    required Map<String, int> effective,
    required Map<String, Player> alive,
    required bool villageIdiotAlreadySpared,
    List<String> tied = const [],
  }) {
    final candidate = alive[candidateId];
    // The Village Idiot survives the first vote that designates him.
    if (candidate != null &&
        candidate.roleId == Roles.villageIdiot.id &&
        !villageIdiotAlreadySpared) {
      return VoteResult(
        kind: VoteOutcomeKind.idiotSpared,
        effectiveVotes: effective,
        sparedPlayerId: candidateId,
        tiedPlayerIds: tied,
      );
    }

    return VoteResult(
      kind: kind,
      effectiveVotes: effective,
      eliminatedPlayerId: candidateId,
      tiedPlayerIds: tied,
    );
  }

  static Player? _aliveCaptain(List<Player> players) {
    for (final player in players) {
      if (player.isCaptain && player.isAlive) return player;
    }
    return null;
  }
}
