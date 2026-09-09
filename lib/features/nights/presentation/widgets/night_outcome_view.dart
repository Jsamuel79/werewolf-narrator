import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../games/domain/game_entities.dart';
import '../../../games/domain/role.dart';
import '../../domain/night_entities.dart';

/// Renders a [NightOutcome] as the recap the narrator reads out at dawn.
class NightOutcomeView extends StatelessWidget {
  const NightOutcomeView({
    required this.outcome,
    required this.snapshot,
    this.dense = false,
    super.key,
  });

  final NightOutcome outcome;
  final GameSnapshot snapshot;
  final bool dense;

  String _name(String? id) => snapshot.playerById(id)?.name ?? 'Inconnu';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lines = <Widget>[];

    for (final death in outcome.deaths) {
      lines.add(
        _OutcomeLine(
          icon: '💀',
          color: AppTheme.werewolfColor,
          text: '${_name(death.playerId)} — ${death.cause}',
        ),
      );
    }
    for (final savedId in outcome.savedPlayerIds) {
      lines.add(
        _OutcomeLine(
          icon: '🛡️',
          color: AppTheme.villageColor,
          text: '${_name(savedId)} a été sauvé',
        ),
      );
    }
    final couple = outcome.newCouple;
    if (couple != null) {
      lines.add(
        _OutcomeLine(
          icon: '💘',
          color: AppTheme.loverColor,
          text: '${_name(couple.$1)} et ${_name(couple.$2)} sont amoureux',
        ),
      );
    }
    for (final charmedId in outcome.charmedPlayerIds) {
      lines.add(
        _OutcomeLine(
          icon: '🎶',
          color: AppTheme.soloColor,
          text: '${_name(charmedId)} est charmé',
        ),
      );
    }
    for (final change in outcome.roleChanges) {
      lines.add(
        _OutcomeLine(
          icon: '🔄',
          color: AppTheme.soloColor,
          text:
              '${_name(change.playerId)} devient '
              '${Roles.byId(change.newRoleId).label}',
        ),
      );
    }
    if (outcome.newCaptainId != null) {
      lines.add(
        _OutcomeLine(
          icon: '⭐',
          color: AppTheme.soloColor,
          text: '${_name(outcome.newCaptainId)} est élu Capitaine',
        ),
      );
    }
    for (final note in outcome.notes) {
      lines.add(_OutcomeLine(icon: 'ℹ️', text: note));
    }

    if (lines.isEmpty) {
      return Text(
        'Nuit calme : personne n\'est mort.',
        style: theme.textTheme.bodyMedium,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines)
          Padding(
            padding: EdgeInsets.symmetric(vertical: dense ? 2 : 4),
            child: line,
          ),
      ],
    );
  }
}

class _OutcomeLine extends StatelessWidget {
  const _OutcomeLine({required this.icon, required this.text, this.color});

  final String icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(icon),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
