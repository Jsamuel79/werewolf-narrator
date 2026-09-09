import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/role.dart';

Color teamColor(RoleTeam team) => switch (team) {
  RoleTeam.village => AppTheme.villageColor,
  RoleTeam.werewolves => AppTheme.werewolfColor,
  RoleTeam.solo => AppTheme.soloColor,
};

class RoleBadge extends StatelessWidget {
  const RoleBadge({required this.role, this.dimmed = false, super.key});

  final RoleDefinition role;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final color = dimmed ? AppTheme.deadColor : teamColor(role.team);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        '${role.emoji} ${role.label}',
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}
