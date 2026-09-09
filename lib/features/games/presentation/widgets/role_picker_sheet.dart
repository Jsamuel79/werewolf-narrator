import 'package:flutter/material.dart';

import '../../domain/role.dart';
import 'role_badge.dart';

/// Full-height picker listing every role of the catalogue, grouped by team.
class RolePickerSheet extends StatelessWidget {
  const RolePickerSheet({required this.selectedRoleId, super.key});

  final String? selectedRoleId;

  static Future<RoleDefinition?> show(
    BuildContext context, {
    String? selectedRoleId,
  }) {
    return showModalBottomSheet<RoleDefinition>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => RolePickerSheet(selectedRoleId: selectedRoleId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (context, controller) {
        return ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Text(
              'Choisir un rôle',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            for (final team in RoleTeam.values) ...[
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 6),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: teamColor(team),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      team.label,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
              ),
              for (final role in Roles.byTeam(team))
                ListTile(
                  leading: Text(
                    role.emoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                  title: Text(role.label),
                  subtitle: Text(role.description),
                  selected: role.id == selectedRoleId,
                  trailing: role.actsAtNight
                      ? const Icon(Icons.nightlight_round, size: 18)
                      : null,
                  onTap: () => Navigator.of(context).pop(role),
                ),
            ],
          ],
        );
      },
    );
  }
}
