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

/// Counting the raised hands: one editable count per living player.
///
/// The narrator does not record individual ballots — around a table, they count
/// hands and say a number. The captain's designated target gets the extra voice
/// their double vote is worth, and the running result is shown live so nothing
/// is applied by surprise.
///
/// The count is **typed as well as tapped**, and carries no upper bound: the
/// stepper alone meant one tap per hand, and the app has no business deciding
/// how many hands a table may raise (proxy votes, a variant, a narrator
/// counting something else entirely). The only thing it refuses is an answer
/// that is not a number of voices at all — empty, negative, or text.
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
  final Map<String, TextEditingController> _controllers = {};
  String? _captainTargetId;

  Player? get _captain => widget.snapshot.aliveCaptain;

  /// One controller per living player, created on first sight and kept for as
  /// long as the card lives so typing never fights with the rebuilds the live
  /// result triggers.
  TextEditingController _controllerFor(Player player) =>
      _controllers.putIfAbsent(
        player.id,
        () => TextEditingController(text: _votes[player.id]?.toString() ?? ''),
      );

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  VoteResult get _result => VoteResolver.resolve(
    players: widget.snapshot.players,
    votes: _votes,
    captainVoteTargetId: _captainTargetId,
    villageIdiotAlreadySpared: widget.villageIdiotAlreadySpared,
  );

  void _bump(String playerId, int delta) {
    _set(playerId, (_votes[playerId] ?? 0) + delta, echoToField: true);
  }

  /// What the narrator typed. Anything that is not a count of voices — text, a
  /// negative number, an empty field — reads as « no voice yet » rather than
  /// as an error: they are still typing.
  void _type(String playerId, String raw) {
    _set(playerId, int.tryParse(raw.trim()) ?? 0, echoToField: false);
  }

  void _set(String playerId, int count, {required bool echoToField}) {
    setState(() {
      if (count <= 0) {
        _votes.remove(playerId);
      } else {
        _votes[playerId] = count;
      }
      if (echoToField) {
        final controller = _controllers[playerId];
        if (controller != null) {
          controller.text = count <= 0 ? '' : '$count';
          controller.selection = TextSelection.collapsed(
            offset: controller.text.length,
          );
        }
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
            controller: _controllerFor(player),
            votes: _votes[player.id] ?? 0,
            extraFromCaptain: captain != null && _captainTargetId == player.id
                ? 1
                : 0,
            onAdd: () => _bump(player.id, 1),
            onRemove: () => _bump(player.id, -1),
            onTyped: (raw) => _type(player.id, raw),
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
    required this.controller,
    required this.votes,
    required this.extraFromCaptain,
    required this.onAdd,
    required this.onRemove,
    required this.onTyped,
  });

  final Player player;
  final TextEditingController controller;
  final int votes;
  final int extraFromCaptain;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final ValueChanged<String> onTyped;

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
            width: 52,
            child: TextField(
              key: ValueKey('vote-${player.id}'),
              controller: controller,
              onChanged: onTyped,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              style: theme.textTheme.titleMedium?.copyWith(
                color: votes > 0 ? AppTheme.soloColor : null,
              ),
              decoration: const InputDecoration(
                isDense: true,
                hintText: '0',
                contentPadding: EdgeInsets.symmetric(vertical: 6),
              ),
            ),
          ),
          IconButton(
            onPressed: onAdd,
            icon: const Icon(Icons.add_circle_outline),
            visualDensity: VisualDensity.compact,
          ),
          // The captain's extra voice is shown beside the count rather than
          // folded into it: the field holds the hands that were raised, and
          // nothing the narrator did not type.
          SizedBox(
            width: 30,
            child: extraFromCaptain > 0
                ? Text(
                    '+$extraFromCaptain⭐',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.soloColor,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          SizedBox(
            width: 26,
            child: Text(
              total > 0 ? '=$total' : '',
              style: theme.textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }
}
