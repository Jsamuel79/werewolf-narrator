import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../games/domain/game_entities.dart';

/// The list of players a card can pick from — one tap, one choice.
class PlayerChoiceList extends StatelessWidget {
  const PlayerChoiceList({
    required this.players,
    required this.selectedIds,
    required this.onTap,
    this.emptyLabel = 'Aucun joueur possible.',
    super.key,
  });

  final List<Player> players;
  final Set<String> selectedIds;
  final ValueChanged<Player> onTap;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (players.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(emptyLabel, style: theme.textTheme.bodyMedium),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final player in players)
          ChoiceChip(
            selected: selectedIds.contains(player.id),
            onSelected: (_) => onTap(player),
            avatar: player.isCaptain
                ? const Text('⭐')
                : Text(player.role.emoji),
            label: Text(player.name),
            selectedColor: AppTheme.loverColor.withValues(alpha: 0.35),
          ),
      ],
    );
  }
}
