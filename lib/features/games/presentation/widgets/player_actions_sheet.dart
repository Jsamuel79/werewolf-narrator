import 'package:flutter/material.dart';

import '../../domain/game_entities.dart';

enum PlayerAction {
  toggleAlive,
  changeRole,
  toggleCaptain,
  breakCouple,
  remove,
}

/// Manual overrides for one player — the escape hatch when the narrator needs
/// to fix something the night form did not cover.
class PlayerActionsSheet extends StatelessWidget {
  const PlayerActionsSheet({required this.player, super.key});

  final Player player;

  static Future<PlayerAction?> show(BuildContext context, Player player) {
    return showModalBottomSheet<PlayerAction>(
      context: context,
      showDragHandle: true,
      builder: (_) => PlayerActionsSheet(player: player),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(
              player.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: Text('${player.role.emoji} ${player.role.label}'),
          ),
          const Divider(),
          ListTile(
            leading: Icon(
              player.isAlive ? Icons.heart_broken : Icons.favorite,
            ),
            title: Text(
              player.isAlive ? 'Marquer comme mort' : 'Marquer comme vivant',
            ),
            onTap: () =>
                Navigator.of(context).pop(PlayerAction.toggleAlive),
          ),
          ListTile(
            leading: const Icon(Icons.theater_comedy_outlined),
            title: const Text('Changer de rôle'),
            onTap: () =>
                Navigator.of(context).pop(PlayerAction.changeRole),
          ),
          ListTile(
            leading: const Icon(Icons.star_outline),
            title: Text(
              player.isCaptain ? 'Retirer le capitanat' : 'Nommer Capitaine',
            ),
            onTap: () =>
                Navigator.of(context).pop(PlayerAction.toggleCaptain),
          ),
          if (player.isInLove)
            ListTile(
              leading: const Icon(Icons.link_off),
              title: const Text('Dissoudre le couple'),
              onTap: () =>
                  Navigator.of(context).pop(PlayerAction.breakCouple),
            ),
          ListTile(
            leading: const Icon(Icons.person_remove_outlined),
            title: const Text('Retirer de la partie'),
            onTap: () => Navigator.of(context).pop(PlayerAction.remove),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
