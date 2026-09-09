import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../domain/game_entities.dart';

enum GameCardAction { archive, unarchive, rename, delete }

class GameCard extends StatelessWidget {
  const GameCard({
    required this.snapshot,
    required this.onOpen,
    required this.onAction,
    super.key,
  });

  final GameSnapshot snapshot;
  final VoidCallback onOpen;
  final void Function(GameCardAction action) onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final game = snapshot.game;
    final alive = snapshot.alivePlayers.length;
    final total = snapshot.players.length;

    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(game.name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      '${formatDateFr(game.createdAt)} · '
                      '${pluralFr(total, 'joueur')} · '
                      '$alive en vie',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: [
                        Chip(
                          label: Text(game.status.label),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ),
                        if (snapshot.couples.isNotEmpty)
                          const Chip(
                            label: Text('💘 Couple'),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<GameCardAction>(
                onSelected: onAction,
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: GameCardAction.rename,
                    child: ListTile(
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Renommer'),
                    ),
                  ),
                  if (game.isArchived)
                    const PopupMenuItem(
                      value: GameCardAction.unarchive,
                      child: ListTile(
                        leading: Icon(Icons.unarchive_outlined),
                        title: Text('Désarchiver'),
                      ),
                    )
                  else
                    const PopupMenuItem(
                      value: GameCardAction.archive,
                      child: ListTile(
                        leading: Icon(Icons.archive_outlined),
                        title: Text('Archiver'),
                      ),
                    ),
                  const PopupMenuItem(
                    value: GameCardAction.delete,
                    child: ListTile(
                      leading: Icon(Icons.delete_outline),
                      title: Text('Supprimer'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
