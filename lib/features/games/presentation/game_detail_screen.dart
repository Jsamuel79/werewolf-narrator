import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/ui_feedback.dart';
import '../../export/presentation/export_actions.dart';
import '../../history/presentation/history_screen.dart';
import '../../nights/domain/night_entities.dart';
import '../../nights/presentation/controllers/nights_providers.dart';
import '../../nights/presentation/night_cards_screen.dart';
import '../../victory/domain/victory_entities.dart';
import '../../victory/presentation/victory_screen.dart';
import '../domain/game_entities.dart';
import '../domain/role.dart';
import 'composition_screen.dart';
import 'controllers/game_board_controller.dart';
import 'controllers/games_providers.dart';
import 'widgets/player_actions_sheet.dart';
import 'widgets/player_tile.dart';
import 'widgets/role_picker_sheet.dart';

class GameDetailScreen extends ConsumerWidget {
  const GameDetailScreen({required this.gameId, super.key});

  final String gameId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotAsync = ref.watch(gameSnapshotProvider(gameId));

    return snapshotAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('$error')),
      ),
      data: (snapshot) {
        if (snapshot == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Partie introuvable.')),
          );
        }
        return _GameDetailView(snapshot: snapshot);
      },
    );
  }
}

class _GameDetailView extends ConsumerWidget {
  const _GameDetailView({required this.snapshot});

  final GameSnapshot snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = snapshot.game;
    // Dealing cards again only makes sense before the first round is opened.
    final nights = ref.watch(gameNightsProvider(game.id)).value ?? const [];
    final canDeal = nights.isEmpty && !game.isFinished;

    return Scaffold(
      appBar: AppBar(
        title: Text(game.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historique complet',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => HistoryScreen(gameId: game.id),
              ),
            ),
          ),
          PopupMenuButton<_MenuAction>(
            onSelected: (action) => _onMenu(context, ref, action),
            itemBuilder: (context) => [
              if (canDeal)
                const PopupMenuItem(
                  value: _MenuAction.composition,
                  child: ListTile(
                    leading: Icon(Icons.checklist),
                    title: Text('Composition de la partie'),
                  ),
                ),
              PopupMenuItem(
                value: _MenuAction.toggleStatus,
                child: ListTile(
                  leading: const Icon(Icons.flag_outlined),
                  title: Text(
                    game.status == GameStatus.finished
                        ? 'Reprendre la partie'
                        : 'Terminer la partie',
                  ),
                ),
              ),
              const PopupMenuItem(
                value: _MenuAction.export,
                child: ListTile(
                  leading: Icon(Icons.ios_share),
                  title: Text('Exporter (chiffré)'),
                ),
              ),
              PopupMenuItem(
                value: _MenuAction.toggleArchive,
                child: ListTile(
                  leading: const Icon(Icons.archive_outlined),
                  title: Text(
                    game.isArchived ? 'Désarchiver' : 'Archiver',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          if (game.isFinished) ...[
            _VictoryBanner(snapshot: snapshot),
            const SizedBox(height: 16),
          ],
          _BoardSummary(snapshot: snapshot),
          if (snapshot.couples.isNotEmpty) ...[
            const SizedBox(height: 16),
            _CouplesCard(snapshot: snapshot),
          ],
          const SizedBox(height: 20),
          _NightsSection(snapshot: snapshot),
          const SizedBox(height: 20),
          _SectionTitle(
            title: 'Joueurs',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (canDeal)
                  TextButton.icon(
                    onPressed: () => _randomizeRoles(context, ref),
                    icon: const Icon(Icons.casino_outlined, size: 18),
                    label: const Text('Distribuer'),
                  ),
                TextButton.icon(
                  onPressed: () => _addPlayer(context, ref),
                  icon: const Icon(Icons.person_add_alt, size: 18),
                  label: const Text('Ajouter'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          for (final player in snapshot.players)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: PlayerTile(
                player: player,
                snapshot: snapshot,
                onTap: () => _onPlayerTap(context, ref, player),
              ),
            ),
        ],
      ),
      // A finished game is a read-only archive: no round can be opened on it.
      floatingActionButton: game.isFinished
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _startNight(context, ref),
              icon: const Icon(Icons.nightlight_round),
              label: const Text('Nouvelle nuit'),
            ),
    );
  }

  Future<void> _startNight(BuildContext context, WidgetRef ref) async {
    final navigator = Navigator.of(context);
    Night? night;
    final ok = await runGuarded(context, () async {
      night = await ref
          .read(nightsRepositoryProvider)
          .startNight(snapshot.game.id);
    });
    if (!ok || night == null) return;
    await navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => NightCardsScreen(
          gameId: snapshot.game.id,
          nightId: night!.id,
        ),
      ),
    );
  }

  Future<void> _onMenu(
    BuildContext context,
    WidgetRef ref,
    _MenuAction action,
  ) async {
    final controller = ref.read(gameBoardControllerProvider);
    final game = snapshot.game;
    switch (action) {
      case _MenuAction.composition:
        final current = await ref.read(
          gameCompositionProvider(game.id).future,
        );
        if (!context.mounted) return;
        final selection = await CompositionScreen.show(
          context,
          initialSelection: current,
          playerCount: snapshot.players.length,
        );
        if (selection == null || !context.mounted) return;
        await runGuarded(
          context,
          () => controller.setComposition(
            gameId: game.id,
            roleIds: selection,
          ),
        );
      case _MenuAction.toggleStatus:
        final next = game.status == GameStatus.finished
            ? GameStatus.inProgress
            : GameStatus.finished;
        await runGuarded(
          context,
          () => controller.setStatus(gameId: game.id, status: next),
        );
      case _MenuAction.export:
        await exportGameFlow(context, ref, game);
      case _MenuAction.toggleArchive:
        await runGuarded(
          context,
          () => controller.setArchived(
            gameId: game.id,
            archived: !game.isArchived,
          ),
        );
    }
  }

  Future<void> _onPlayerTap(
    BuildContext context,
    WidgetRef ref,
    Player player,
  ) async {
    final action = await PlayerActionsSheet.show(context, player);
    if (action == null || !context.mounted) return;
    final controller = ref.read(gameBoardControllerProvider);

    switch (action) {
      case PlayerAction.toggleAlive:
        await runGuarded(
          context,
          () => controller.setAlive(player: player, alive: !player.isAlive),
        );
      case PlayerAction.changeRole:
        final role = await RolePickerSheet.show(
          context,
          selectedRoleId: player.roleId,
        );
        if (role == null || !context.mounted) return;
        await runGuarded(
          context,
          () => controller.setRole(player: player, roleId: role.id),
        );
      case PlayerAction.toggleCaptain:
        await runGuarded(
          context,
          () => controller.toggleCaptain(snapshot: snapshot, player: player),
        );
      case PlayerAction.breakCouple:
        await runGuarded(
          context,
          () => controller.breakCouple(snapshot: snapshot, player: player),
        );
      case PlayerAction.remove:
        await runGuarded(
          context,
          () => controller.removePlayer(snapshot: snapshot, player: player),
        );
    }
  }

  Future<void> _randomizeRoles(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Distribution aléatoire'),
        content: Text(
          'Les rôles des ${snapshot.players.length} joueurs vont être '
          'retirés au sort. Vous pourrez encore les modifier un par un '
          'avant de commencer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Distribuer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final allowed = await ref.read(
      gameCompositionProvider(snapshot.game.id).future,
    );
    if (!context.mounted) return;

    await runGuarded(
      context,
      () => ref
          .read(gameBoardControllerProvider)
          .randomizeRoles(snapshot: snapshot, allowedRoleIds: allowed),
    );
  }

  Future<void> _addPlayer(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un joueur'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nom'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(nameController.text),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
    if (name == null || name.trim().isEmpty || !context.mounted) return;

    final role = await RolePickerSheet.show(context);
    if (role == null || !context.mounted) return;

    await runGuarded(
      context,
      () => ref.read(gameBoardControllerProvider).addPlayer(
        gameId: snapshot.game.id,
        name: name,
        roleId: role.id,
      ),
    );
  }
}

enum _MenuAction { composition, toggleStatus, export, toggleArchive }

/// Shown at the top of a finished game: which camp won, and why.
class _VictoryBanner extends StatelessWidget {
  const _VictoryBanner({required this.snapshot});

  final GameSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final game = snapshot.game;
    final camp = VictoryCamp.byId(game.winnerCampId);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => VictoryScreen(gameId: game.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(camp.emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.hasWinner
                          ? '${camp.label} l\'emporte'
                          : 'Partie terminée',
                      style: theme.textTheme.titleMedium,
                    ),
                    if (game.winnerReason != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          game.winnerReason!,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _BoardSummary extends StatelessWidget {
  const _BoardSummary({required this.snapshot});

  final GameSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final alive = snapshot.alivePlayers;
    final wolves = alive
        .where((p) => p.role.team == RoleTeam.werewolves)
        .length;
    final villagers = alive
        .where((p) => p.role.team == RoleTeam.village)
        .length;
    final solo = alive.where((p) => p.role.team == RoleTeam.solo).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _Stat(label: 'En vie', value: '${alive.length}'),
            _Stat(
              label: 'Village',
              value: '$villagers',
              color: AppTheme.villageColor,
            ),
            _Stat(
              label: 'Loups',
              value: '$wolves',
              color: AppTheme.werewolfColor,
            ),
            if (solo > 0)
              _Stat(label: 'Solo', value: '$solo', color: AppTheme.soloColor),
            _Stat(
              label: 'Morts',
              value: '${snapshot.deadPlayers.length}',
              color: AppTheme.deadColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(color: color),
        ),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }
}

class _CouplesCard extends StatelessWidget {
  const _CouplesCard({required this.snapshot});

  final GameSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '💘 Amoureux',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            for (final couple in snapshot.couples)
              Text('${couple.$1.name} ❤️ ${couple.$2.name}'),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const Spacer(),
        ?trailing,
      ],
    );
  }
}

class _NightsSection extends ConsumerWidget {
  const _NightsSection({required this.snapshot});

  final GameSnapshot snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nightsAsync = ref.watch(gameNightsProvider(snapshot.game.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Nuits'),
        const SizedBox(height: 4),
        nightsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Text('$error'),
          data: (nights) {
            if (nights.isEmpty) {
              return const Card(
                child: ListTile(
                  leading: Icon(Icons.bedtime_outlined),
                  title: Text('La partie n\'a pas encore commencé'),
                  subtitle: Text(
                    'Touchez « Nouvelle nuit » pour ouvrir le premier tour.',
                  ),
                ),
              );
            }
            return Column(
              children: [
                for (final night in nights)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text('${night.nightNumber}'),
                      ),
                      title: Text(
                        night.isResolved
                            ? 'Nuit ${night.nightNumber}'
                            : 'Nuit ${night.nightNumber} — en cours',
                      ),
                      subtitle: Text(_summaryOf(night)),
                      trailing: Icon(
                        night.isResolved
                            ? Icons.lock_outline
                            : Icons.edit_outlined,
                        size: 18,
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => NightCardsScreen(
                            gameId: snapshot.game.id,
                            nightId: night.id,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  String _summaryOf(Night night) {
    final outcome = night.outcome;
    if (outcome == null) return formatDateTimeFr(night.createdAt);
    if (outcome.deaths.isEmpty) return 'Aucune victime';
    final names = outcome.deaths
        .map((d) => snapshot.playerById(d.playerId)?.name ?? '?')
        .join(', ');
    return '💀 $names';
  }
}
