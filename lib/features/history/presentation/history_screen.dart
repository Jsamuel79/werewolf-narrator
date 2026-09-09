import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../games/domain/game_entities.dart';
import '../../games/presentation/controllers/games_providers.dart';
import '../../nights/domain/night_entities.dart';
import '../../nights/presentation/controllers/nights_providers.dart';
import '../../nights/presentation/widgets/night_outcome_view.dart';

/// The whole game, round by round, so the narrator can recall anything that
/// happened without reopening each night.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({required this.gameId, super.key});

  final String gameId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotAsync = ref.watch(gameSnapshotProvider(gameId));
    final historyAsync = ref.watch(gameHistoryProvider(gameId));

    return Scaffold(
      appBar: AppBar(title: const Text('Historique de la partie')),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (history) {
          final snapshot = snapshotAsync.value;
          if (snapshot == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return _HistoryList(snapshot: snapshot, history: history);
        },
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.snapshot, required this.history});

  final GameSnapshot snapshot;
  final List<NightDetail> history;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Aucune nuit jouée pour l\'instant.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _GameHeader(snapshot: snapshot, history: history),
        const SizedBox(height: 20),
        for (final detail in history) ...[
          _NightBlock(detail: detail, snapshot: snapshot),
          const SizedBox(height: 16),
        ],
        _Roster(snapshot: snapshot),
      ],
    );
  }
}

class _GameHeader extends StatelessWidget {
  const _GameHeader({required this.snapshot, required this.history});

  final GameSnapshot snapshot;
  final List<NightDetail> history;

  @override
  Widget build(BuildContext context) {
    final deaths = history
        .expand((d) => d.night.outcome?.deaths ?? const <PlayerDeath>[])
        .length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              snapshot.game.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Commencée le ${formatDateTimeFr(snapshot.game.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Text(
              '${pluralFr(history.length, 'tour')} · '
              '${pluralFr(snapshot.players.length, 'joueur')} · '
              '${pluralFr(deaths, 'mort')}',
            ),
          ],
        ),
      ),
    );
  }
}

class _NightBlock extends StatelessWidget {
  const _NightBlock({required this.detail, required this.snapshot});

  final NightDetail detail;
  final GameSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final night = detail.night;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  child: Text(
                    '${night.nightNumber}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(width: 10),
                Text('Nuit ${night.nightNumber}',
                    style: theme.textTheme.titleMedium),
                const Spacer(),
                Text(
                  night.isResolved ? 'Close' : 'En cours',
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              formatDateTimeFr(night.createdAt),
              style: theme.textTheme.bodySmall,
            ),
            const Divider(height: 20),
            if (detail.actions.isEmpty)
              Text('Aucune action notée.', style: theme.textTheme.bodySmall)
            else
              for (final action in detail.actions)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _ActionLine(action: action, snapshot: snapshot),
                ),
            if (night.outcome != null) ...[
              const Divider(height: 20),
              Text('Bilan', style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              NightOutcomeView(
                outcome: night.outcome!,
                snapshot: snapshot,
                dense: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionLine extends StatelessWidget {
  const _ActionLine({required this.action, required this.snapshot});

  final NightAction action;
  final GameSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final type = action.type;
    final actor = snapshot.playerById(action.actorPlayerId);
    final target = snapshot.playerById(action.targetPlayerId);
    final secondary = snapshot.playerById(action.secondaryTargetPlayerId);

    final parts = <String>[
      if (actor != null) actor.name,
      if (target != null) '→ ${target.name}',
      if (secondary != null) '+ ${secondary.name}',
      if (action.detail != null) '« ${action.detail} »',
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(type.emoji),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: theme.textTheme.bodyMedium,
              children: [
                TextSpan(text: type.label),
                if (parts.isNotEmpty)
                  TextSpan(
                    text: '  ${parts.join('  ')}',
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ),
        Text(
          formatTimeFr(action.createdAt),
          style: theme.textTheme.labelSmall,
        ),
      ],
    );
  }
}

class _Roster extends StatelessWidget {
  const _Roster({required this.snapshot});

  final GameSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('État final des joueurs', style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            for (final player in snapshot.players)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Text(player.role.emoji),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${player.name} — ${player.role.label}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: player.isAlive ? null : AppTheme.deadColor,
                          decoration: player.isAlive
                              ? null
                              : TextDecoration.lineThrough,
                        ),
                      ),
                    ),
                    Text(
                      player.isAlive
                          ? 'En vie'
                          : '† tour ${player.deathNightNumber ?? '?'}',
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
