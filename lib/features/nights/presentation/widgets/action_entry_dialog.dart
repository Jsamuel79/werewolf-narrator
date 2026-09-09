import 'package:flutter/material.dart';

import '../../../games/domain/game_entities.dart';
import '../../domain/night_action_type.dart';

/// What the narrator filled in for one action.
class ActionEntry {
  const ActionEntry({
    this.actorPlayerId,
    this.targetPlayerId,
    this.secondaryTargetPlayerId,
    this.detail,
  });

  final String? actorPlayerId;
  final String? targetPlayerId;
  final String? secondaryTargetPlayerId;
  final String? detail;

  Map<String, dynamic> get details =>
      detail == null || detail!.trim().isEmpty
      ? const {}
      : {'text': detail!.trim()};
}

class ActionEntryDialog extends StatefulWidget {
  const ActionEntryDialog({
    required this.type,
    required this.snapshot,
    super.key,
  });

  final NightActionType type;
  final GameSnapshot snapshot;

  static Future<ActionEntry?> show(
    BuildContext context, {
    required NightActionType type,
    required GameSnapshot snapshot,
  }) {
    return showDialog<ActionEntry>(
      context: context,
      builder: (_) => ActionEntryDialog(type: type, snapshot: snapshot),
    );
  }

  @override
  State<ActionEntryDialog> createState() => _ActionEntryDialogState();
}

class _ActionEntryDialogState extends State<ActionEntryDialog> {
  final TextEditingController _detailController = TextEditingController();
  String? _actorId;
  String? _targetId;
  String? _secondaryId;

  @override
  void initState() {
    super.initState();
    _actorId = _defaultActorId();
  }

  @override
  void dispose() {
    _detailController.dispose();
    super.dispose();
  }

  /// When exactly one player holds the role, there is nothing to ask.
  String? _defaultActorId() {
    final roleId = widget.type.roleId;
    if (roleId == null) return null;
    final candidates = _actorCandidates;
    return candidates.length == 1 ? candidates.single.id : null;
  }

  List<Player> get _actorCandidates {
    final roleId = widget.type.roleId;
    if (roleId == null) return const [];
    return widget.snapshot.players
        .where((p) => p.roleId == roleId)
        .toList(growable: false);
  }

  /// Dead players stay selectable as targets: the narrator sometimes records a
  /// vote or a shot aimed at someone who turned out to be already gone.
  List<Player> get _targetCandidates => widget.snapshot.players;

  bool get _isValid {
    if (widget.type.requiresTarget && _targetId == null) return false;
    if (widget.type.requiresSecondaryTarget && _secondaryId == null) {
      return false;
    }
    if (_targetId != null && _targetId == _secondaryId) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.type;

    return AlertDialog(
      title: Text('${type.emoji} ${type.label}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(type.prompt, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            if (_actorCandidates.length > 1)
              _PlayerDropdown(
                label: 'Qui agit ?',
                players: _actorCandidates,
                value: _actorId,
                onChanged: (id) => setState(() => _actorId = id),
              ),
            if (type.requiresTarget)
              _PlayerDropdown(
                label: 'Cible',
                players: _targetCandidates,
                value: _targetId,
                onChanged: (id) => setState(() => _targetId = id),
              ),
            if (type.requiresSecondaryTarget)
              _PlayerDropdown(
                label: type.secondaryTargetLabel ?? 'Seconde cible',
                players: _targetCandidates,
                value: _secondaryId,
                onChanged: (id) => setState(() => _secondaryId = id),
              ),
            if (type.detailLabel != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextField(
                  controller: _detailController,
                  decoration: InputDecoration(labelText: type.detailLabel),
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
            if (_targetId != null && _targetId == _secondaryId)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Les deux cibles doivent être différentes.',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _isValid
              ? () => Navigator.of(context).pop(
                  ActionEntry(
                    actorPlayerId: _actorId,
                    targetPlayerId: _targetId,
                    secondaryTargetPlayerId: _secondaryId,
                    detail: _detailController.text,
                  ),
                )
              : null,
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}

class _PlayerDropdown extends StatelessWidget {
  const _PlayerDropdown({
    required this.label,
    required this.players,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final List<Player> players;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: [
          for (final player in players)
            DropdownMenuItem(
              value: player.id,
              child: Text(
                player.isAlive
                    ? '${player.role.emoji} ${player.name}'
                    : '${player.role.emoji} ${player.name} (mort)',
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}
