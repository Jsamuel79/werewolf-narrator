import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/game_entities.dart';
import 'role_badge.dart';

class PlayerTile extends StatelessWidget {
  const PlayerTile({
    required this.player,
    required this.snapshot,
    this.onTap,
    super.key,
  });

  final Player player;
  final GameSnapshot snapshot;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dead = !player.isAlive;
    final partner = snapshot.playerById(player.coupledWithPlayerId);

    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              backgroundColor: dead
                  ? AppTheme.deadColor.withValues(alpha: 0.25)
                  : teamColor(player.role.team).withValues(alpha: 0.25),
              child: Text(
                player.role.emoji,
                style: TextStyle(fontSize: 18, color: dead ? Colors.grey : null),
              ),
            ),
            if (player.isCaptain)
              const Positioned(
                right: -4,
                top: -4,
                child: Text('⭐', style: TextStyle(fontSize: 14)),
              ),
          ],
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                player.name,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  decoration: dead ? TextDecoration.lineThrough : null,
                  color: dead ? AppTheme.deadColor : null,
                ),
              ),
            ),
            if (player.isInLove) const Text('  💘'),
            if (player.isCharmed) const Text('  🎶'),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: RoleBadge(role: player.role, dimmed: dead),
            ),
            if (partner != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Amoureux de ${partner.name}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.loverColor,
                  ),
                ),
              ),
            if (dead && player.deathCause != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  player.deathNightNumber != null
                      ? '${player.deathCause} (tour ${player.deathNightNumber})'
                      : player.deathCause!,
                  style: theme.textTheme.bodySmall,
                ),
              ),
          ],
        ),
        trailing: Icon(
          dead ? Icons.sentiment_very_dissatisfied : Icons.favorite,
          size: 18,
          color: dead ? AppTheme.deadColor : AppTheme.villageColor,
        ),
      ),
    );
  }
}
