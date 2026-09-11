import 'package:flutter/material.dart';

import '../../domain/passive_reminders.dart';

/// The passive rules that apply to the card being shown, in a quiet band the
/// narrator can read at a glance without losing their place.
class PassiveReminderBand extends StatelessWidget {
  const PassiveReminderBand({required this.reminders, super.key});

  final List<PassiveReminder> reminders;

  @override
  Widget build(BuildContext context) {
    if (reminders.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final reminder in reminders)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(reminder.emoji),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reminder.text,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
