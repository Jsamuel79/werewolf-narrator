import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../games/domain/game_entities.dart';
import '../../domain/vote_resolver.dart';

/// What the narrator entered for one village vote.
class VoteEntry {
  const VoteEntry({
    required this.votes,
    required this.result,
    this.captainVoteTargetId,
  });

  final Map<String, int> votes;
  final VoteResult result;
  final String? captainVoteTargetId;
}

/// Counting the raised hands: one stepper per living player.
///
/// The narrator does not record individual ballots — around a table, they count
/// hands and say a number. The captain's designated target gets the extra voice
/// their double vote is worth, and the running result is shown live so nothing
/// is applied by surprise.
class VillageVoteCard extends StatefulWidget {
  const VillageVoteCard({
    required this.snapshot,
    required this.villageIdiotAlreadySpared,
    required this.onSubmit,
    super.key,
  });

  final GameSnapshot snapshot;
  final bool villageIdiotAlreadySpared;
  final ValueChanged<VoteEntry> onSubmit;

  @override
  State<VillageVoteCard> createState() => _VillageVoteCardState();
}

class _VillageVoteCardState extends State<VillageVoteCard> {
  final Map<String, int> _votes = {};
  String? _captainTargetId;

  Player? get _captain => widget.snapshot.aliveCaptain;

  VoteResult get _result => VoteResolver.resolve(
    players: widget.snapshot.players,
    votes: _votes,
    captainVoteTargetId: _captainTargetId,
    villageIdiotAlreadySpared: widget.villageIdiotAlreadySpared,
  );

  void _bump(String playerId, int delta) {
    setState(() {
      final next = (_votes[playerId] ?? 0) + delta;
      if (next <= 0) {
        _votes.remove(playerId);
      } else {
        _votes[playerId] = next;
      }
    });
  }

  String _nameOf(String? id) =>
      widget.snapshot.playerById(id)?.name ?? 'Inconnu';

  String get _resultLine => switch (_result.kind) {
    VoteOutcomeKind.noVote => 'Aucune voix pour l\'instant.',
    VoteOutcomeKind.clear =>
      '${_nameOf(_result.eliminatedPlayerId)} est éliminé.',
    VoteOutcomeKind.decidedByCaptain =>
      '${_nameOf(_result.eliminatedPlayerId)} est éliminé — égalité '
          'tranchée par le Capitaine.',
    VoteOutcomeKind.scapegoat =>
      'Égalité : le Bouc émissaire ${_nameOf(_result.eliminatedPlayerId)} '
          'est éliminé.',
    VoteOutcomeKind.idiotSpared =>
      '${_nameOf(_result.sparedPlayerId)} est l\'Idiot du Village : il est '
          'démasqué, survit, et perd son droit de vote.',
    VoteOutcomeKind.unresolvedTie =>
      'Égalité entre ${_result.tiedPlayerIds.map(_nameOf).join(', ')} : '
          'personne n\'est éliminé. Faites revoter, ou validez une journée '
          'blanche.',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alive = widget.snapshot.alivePlayers;
    final captain = _captain;
    final result = _result;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final player in alive)
          _VoteRow(
            player: player,
            votes: _votes[player.id] ?? 0,
            extraFromCaptain:
                captain != null && _captainTargetId == player.id ? 1 : 0,
            onAdd: () => _bump(player.id, 1),
            onRemove: () => _bump(player.id, -1),
          ),
        if (captain != null) ...[
          const SizedBox(height: 16),
          Text(
            '⭐ Le Capitaine ${captain.name} vote pour '
            '(sa voix compte double : +1)',
            style: theme.textTheme.labelMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                selected: _captainTargetId == null,
                onSelected: (_) => setState(() => _captainTargetId = null),
                label: const Text('Personne'),
              ),
              for (final player in alive)
                ChoiceChip(
                  selected: _captainTargetId == player.id,
                  onSelected: (_) =>
                      setState(() => _captainTargetId = player.id),
                  label: Text(player.name),
                ),
            ],
          ),
        ],
        const SizedBox(height: 20),
        Card(
          color: theme.colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(_resultLine, style: theme.textTheme.bodyMedium),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: result.kind == VoteOutcomeKind.noVote
              ? null
              : () => widget.onSubmit(
                  VoteEntry(
                    votes: Map.of(_votes),
                    result: result,
                    captainVoteTargetId: _captainTargetId,
                  ),
                ),
          icon: const Icon(Icons.gavel),
          label: const Text('Valider le vote'),
        ),
      ],
    );
  }
}

class _VoteRow extends StatelessWidget {
  const _VoteRow({
    required this.player,
    required this.votes,
    required this.extraFromCaptain,
    required this.onAdd,
    required this.onRemove,
  });

  final Player player;
  final int votes;
  final int extraFromCaptain;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = votes + extraFromCaptain;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(player.isCaptain ? '⭐' : player.role.emoji),
          const SizedBox(width: 8),
          Expanded(child: Text(player.name)),
          IconButton(
            onPressed: votes == 0 ? null : onRemove,
            icon: const Icon(Icons.remove_circle_outline),
            visualDensity: VisualDensity.compact,
          ),
          SizedBox(
            width: 34,
            child: Text(
              '$total',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: total > 0 ? AppTheme.soloColor : null,
              ),
            ),
          ),
          IconButton(
            onPressed: onAdd,
            icon: const Icon(Icons.add_circle_outline),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
