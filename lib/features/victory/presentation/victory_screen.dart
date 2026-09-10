import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ui_feedback.dart';
import '../../games/domain/game_entities.dart';
import '../../games/domain/role.dart';
import '../../games/presentation/controllers/games_providers.dart';
import '../../games/presentation/game_setup_screen.dart';
import '../../history/presentation/history_screen.dart';
import '../domain/victory_entities.dart';

/// The end of a game: who won, who was still standing, and what to do next.
class VictoryScreen extends ConsumerWidget {
  const VictoryScreen({required this.gameId, super.key});

  final String gameId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotAsync = ref.watch(gameSnapshotProvider(gameId));

    return snapshotAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) =>
          Scaffold(appBar: AppBar(), body: Center(child: Text('$error'))),
      data: (snapshot) {
        if (snapshot == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Partie introuvable.')),
          );
        }
        return _VictoryView(snapshot: snapshot, ref: ref);
      },
    );
  }
}

class _VictoryView extends StatelessWidget {
  const _VictoryView({required this.snapshot, required this.ref});

  final GameSnapshot snapshot;
  final WidgetRef ref;

  /// « Soirée du samedi » → « Soirée du samedi (2) » → « … (3) ».
  static String nextGameName(String name) {
    final match = RegExp(r'^(.*) \((\d+)\)$').firstMatch(name.trim());
    if (match == null) return '${name.trim()} (2)';
    final number = int.tryParse(match.group(2)!) ?? 1;
    return '${match.group(1)} (${number + 1})';
  }

  /// Replays with the same table: a brand new game row, every status reset —
  /// the finished one stays in the history untouched.
  Future<void> _rematch(BuildContext context) async {
    final composition = await runGuardedValue(
      context,
      () => ref
          .read(gamesRepositoryProvider)
          .loadComposition(snapshot.game.id),
    );
    if (composition == null || !context.mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameSetupScreen(
          initialName: nextGameName(snapshot.game.name),
          initialPlayerNames: [
            for (final player in snapshot.players) player.name,
          ],
          initialComposition: composition,
        ),
      ),
    );
  }

  Color _campColor(VictoryCamp camp) {
    if (camp.id == VictoryCamp.village.id) return AppTheme.villageColor;
    if (camp.id == VictoryCamp.werewolves.id) return AppTheme.werewolfColor;
    if (camp.id == VictoryCamp.lovers.id) return AppTheme.loverColor;
    if (camp.id == VictoryCamp.nobody.id) return AppTheme.deadColor;
    return AppTheme.soloColor;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final game = snapshot.game;
    final camp = VictoryCamp.byId(game.winnerCampId);
    final color = _campColor(camp);
    final survivors = snapshot.alivePlayers;

    return Scaffold(
      appBar: AppBar(title: const Text('Fin de partie')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        children: [
          Center(
            child: Column(
              children: [
                Text(camp.emoji, style: const TextStyle(fontSize: 64)),
                const SizedBox(height: 12),
                Text(
                  '${camp.label} l\'emporte',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(color: color),
                ),
                const SizedBox(height: 8),
                Text(
                  game.winnerReason ?? 'La partie est terminée.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Survivants', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  if (survivors.isEmpty)
                    const Text('Personne n\'a survécu.')
                  else
                    for (final player in survivors)
                      _PlayerLine(player: player, highlighted: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Éliminés (${snapshot.deadPlayers.length})',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  if (snapshot.deadPlayers.isEmpty)
                    const Text('Aucun mort — partie éclair.')
                  else
                    for (final player in snapshot.deadPlayers)
                      _PlayerLine(player: player),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => HistoryScreen(gameId: game.id),
              ),
            ),
            icon: const Icon(Icons.history),
            label: const Text('Voir l\'historique complet'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _rematch(context),
            icon: const Icon(Icons.replay),
            label: const Text('Rejouer avec les mêmes joueurs'),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const GameSetupScreen(),
              ),
            ),
            icon: const Icon(Icons.group_add_outlined),
            label: const Text('Nouvelle partie, nouveaux joueurs'),
          ),
        ],
      ),
    );
  }
}

class _PlayerLine extends StatelessWidget {
  const _PlayerLine({required this.player, this.highlighted = false});

  final Player player;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final role = Roles.byId(player.roleId);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(role.emoji),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              player.name,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: highlighted ? null : AppTheme.deadColor,
                decoration: highlighted ? null : TextDecoration.lineThrough,
              ),
            ),
          ),
          Text(
            role.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small window into the private view, for tests that check the naming rule
/// without going through the whole screen.
abstract final class VictoryScreenTestHooks {
  static String nextGameName(String name) => _VictoryView.nextGameName(name);
}
