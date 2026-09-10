import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/game_composition.dart';
import '../domain/role.dart';

/// Which roles are allowed in this game — ticked before the cards are dealt.
///
/// Returns the new selection, or `null` if the narrator backed out. The
/// Villager and the Werewolf are shown ticked and locked: without them there is
/// no game to play.
class CompositionScreen extends StatefulWidget {
  const CompositionScreen({
    required this.initialSelection,
    this.playerCount,
    super.key,
  });

  final Set<String> initialSelection;

  /// Table size, when known, to flag the roles that need more players.
  final int? playerCount;

  static Future<Set<String>?> show(
    BuildContext context, {
    required Set<String> initialSelection,
    int? playerCount,
  }) {
    return Navigator.of(context).push<Set<String>>(
      MaterialPageRoute<Set<String>>(
        builder: (_) => CompositionScreen(
          initialSelection: initialSelection,
          playerCount: playerCount,
        ),
      ),
    );
  }

  @override
  State<CompositionScreen> createState() => _CompositionScreenState();
}

class _CompositionScreenState extends State<CompositionScreen> {
  late Set<String> _selected = GameComposition.normalize(
    widget.initialSelection,
  );

  void _toggle(String roleId, bool value) {
    if (GameComposition.isMandatory(roleId)) return;
    setState(() {
      if (value) {
        _selected.add(roleId);
      } else {
        _selected.remove(roleId);
      }
    });
  }

  Color _teamColor(RoleTeam team) => switch (team) {
    RoleTeam.village => AppTheme.villageColor,
    RoleTeam.werewolves => AppTheme.werewolfColor,
    RoleTeam.solo => AppTheme.soloColor,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = _selected.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Composition de la partie'),
        actions: [
          TextButton(
            onPressed: () => setState(
              () => _selected = {...GameComposition.everything},
            ),
            child: const Text('Tout'),
          ),
          TextButton(
            onPressed: () => setState(
              () => _selected = {...GameComposition.defaultRoleIds},
            ),
            child: const Text('Base'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
            child: Text(
              'Cochez les rôles autorisés dans cette partie. La distribution '
              'aléatoire ne piochera que parmi eux.',
              style: theme.textTheme.bodySmall,
            ),
          ),
          for (final team in RoleTeam.values) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
              child: Text(
                team.label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: _teamColor(team),
                ),
              ),
            ),
            for (final role in Roles.byTeam(team))
              _RoleCheckTile(
                role: role,
                selected: _selected.contains(role.id),
                locked: GameComposition.isMandatory(role.id),
                tooSmallTable:
                    widget.playerCount != null &&
                    role.minPlayers > widget.playerCount!,
                onChanged: (value) => _toggle(role.id, value),
              ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(_selected),
            icon: const Icon(Icons.check),
            label: Text('Valider ($count rôles)'),
          ),
        ),
      ),
    );
  }
}

class _RoleCheckTile extends StatelessWidget {
  const _RoleCheckTile({
    required this.role,
    required this.selected,
    required this.locked,
    required this.tooSmallTable,
    required this.onChanged,
  });

  final RoleDefinition role;
  final bool selected;
  final bool locked;
  final bool tooSmallTable;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = <String>[
      role.description,
      if (locked) 'Toujours en jeu',
      if (!locked && role.dealCopies > 1)
        'Distribué par ${role.dealCopies}',
      if (!locked && tooSmallTable)
        'Table trop petite pour le tirage (${role.minPlayers} joueurs)',
    ].join(' · ');

    return CheckboxListTile(
      value: selected,
      onChanged: locked ? null : (value) => onChanged(value ?? false),
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
      title: Text('${role.emoji} ${role.label}'),
      subtitle: Text(subtitle, style: theme.textTheme.labelSmall),
    );
  }
}
