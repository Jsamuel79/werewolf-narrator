import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/ui_feedback.dart';
import '../../export/presentation/backups_screen.dart';
import '../../export/presentation/export_actions.dart';
import '../domain/game_entities.dart';
import 'controllers/games_providers.dart';
import 'game_detail_screen.dart';
import 'game_setup_screen.dart';
import 'widgets/game_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Row(
            children: [
              Text('🐺 ', style: TextStyle(fontSize: 20)),
              Text('Werewolf Narrator'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.file_open_outlined),
              tooltip: 'Importer une partie',
              onPressed: () => _import(context, ref),
            ),
            IconButton(
              icon: const Icon(Icons.restore),
              tooltip: 'Instantanés de secours',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const BackupsScreen()),
              ),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Parties en cours'),
              Tab(text: 'Archives'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _GameList(archived: false),
            _GameList(archived: true),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const GameSetupScreen()),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Nouvelle partie'),
        ),
      ),
    );
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final game = await importGameFlow(context, ref);
    if (game == null || !context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameDetailScreen(gameId: game.id),
      ),
    );
  }
}

class _GameList extends ConsumerWidget {
  const _GameList({required this.archived});

  final bool archived;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final games = ref.watch(
      archived ? archivedGamesProvider : activeGamesProvider,
    );

    return games.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorState(message: '$error'),
      data: (snapshots) {
        if (snapshots.isEmpty) {
          return _EmptyState(archived: archived);
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          itemCount: snapshots.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final snapshot = snapshots[index];
            return GameCard(
              snapshot: snapshot,
              onOpen: () => _open(context, snapshot),
              onAction: (action) => _handle(context, ref, snapshot, action),
            );
          },
        );
      },
    );
  }

  void _open(BuildContext context, GameSnapshot snapshot) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameDetailScreen(gameId: snapshot.game.id),
      ),
    );
  }

  Future<void> _handle(
    BuildContext context,
    WidgetRef ref,
    GameSnapshot snapshot,
    GameCardAction action,
  ) async {
    final repository = ref.read(gamesRepositoryProvider);
    final game = snapshot.game;

    switch (action) {
      case GameCardAction.archive:
        await runGuarded(
          context,
          () => repository.setArchived(gameId: game.id, archived: true),
        );
      case GameCardAction.unarchive:
        await runGuarded(
          context,
          () => repository.setArchived(gameId: game.id, archived: false),
        );
      case GameCardAction.rename:
        final name = await _askName(context, game.name);
        if (name == null || !context.mounted) return;
        await runGuarded(context, () => repository.renameGame(game.id, name));
      case GameCardAction.export:
        await exportGameFlow(context, ref, game);
      case GameCardAction.delete:
        final confirmed = await _confirmDelete(context, game.name);
        if (!confirmed || !context.mounted) return;
        await runGuarded(context, () => repository.deleteGame(game.id));
    }
  }

  Future<String?> _askName(BuildContext context, String current) {
    final controller = TextEditingController(text: current);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renommer la partie'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nom de la partie'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Renommer'),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, String name) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la partie ?'),
        content: Text(
          '« $name » et tout son historique seront définitivement effacés.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.archived});

  final bool archived;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              archived ? '🗄️' : '🌕',
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 16),
            Text(
              archived
                  ? 'Aucune partie archivée.'
                  : 'Aucune partie en cours.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              archived
                  ? 'Les parties terminées que vous archivez apparaîtront ici.'
                  : 'Touchez « Nouvelle partie » pour distribuer les rôles.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
