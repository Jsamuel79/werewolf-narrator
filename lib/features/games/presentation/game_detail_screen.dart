import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ui_feedback.dart';
import '../domain/game_entities.dart';
import '../domain/role.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: Text(game.name),
        actions: [
          PopupMenuButton<_MenuAction>(
            onSelected: (action) => _onMenu(context, ref, action),
            itemBuilder: (context) => [
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
          _BoardSummary(snapshot: snapshot),
          if (snapshot.couples.isNotEmpty) ...[
            const SizedBox(height: 16),
            _CouplesCard(snapshot: snapshot),
          ],
          const SizedBox(height: 20),
          _SectionTitle(
            title: 'Joueurs',
            trailing: TextButton.icon(
              onPressed: () => _addPlayer(context, ref),
              icon: const Icon(Icons.person_add_alt, size: 18),
              label: const Text('Ajouter'),
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
      case _MenuAction.toggleStatus:
        final next = game.status == GameStatus.finished
            ? GameStatus.inProgress
            : GameStatus.finished;
        await runGuarded(
          context,
          () => controller.setStatus(gameId: game.id, status: next),
        );
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

enum _MenuAction { toggleStatus, toggleArchive }

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
