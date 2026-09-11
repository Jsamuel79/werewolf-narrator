import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/ui_feedback.dart';
import '../../games/presentation/game_detail_screen.dart';
import '../data/auto_backup_service.dart';
import 'controllers/export_providers.dart';

/// The automatic snapshots, and the way back from a bad evening.
///
/// Each game keeps one, rewritten after every half-round and sealed with the
/// database key. Restoring never overwrites anything: it recreates the game
/// beside the one on the board.
class BackupsScreen extends ConsumerWidget {
  const BackupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backupsAsync = ref.watch(gameBackupsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Instantanés de secours')),
      body: backupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (backups) {
          if (backups.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('💾', style: TextStyle(fontSize: 44)),
                    const SizedBox(height: 12),
                    Text(
                      'Aucun instantané pour l\'instant.\n'
                      'L\'application en enregistre un après chaque nuit et '
                      'chaque journée, chiffré avec la clé de l\'appareil.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Restaurer crée une copie de la partie : celle qui est en '
                  'cours n\'est jamais écrasée.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
              for (final backup in backups)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Text(
                      backup.isFinished ? '🏆' : '🌙',
                      style: const TextStyle(fontSize: 22),
                    ),
                    title: Text(backup.gameName),
                    subtitle: Text(
                      '${formatDateTimeFr(backup.savedAt)}\n'
                      '${pluralFr(backup.playerCount, 'joueur')} · '
                      '${pluralFr(backup.roundCount, 'tour')}',
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton<_BackupAction>(
                      onSelected: (action) =>
                          _onAction(context, ref, backup, action),
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: _BackupAction.restore,
                          child: ListTile(
                            leading: Icon(Icons.restore),
                            title: Text('Restaurer'),
                          ),
                        ),
                        PopupMenuItem(
                          value: _BackupAction.delete,
                          child: ListTile(
                            leading: Icon(Icons.delete_outline),
                            title: Text('Supprimer'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _onAction(
    BuildContext context,
    WidgetRef ref,
    GameBackup backup,
    _BackupAction action,
  ) async {
    final service = ref.read(autoBackupServiceProvider);
    if (service == null) return;
    final navigator = Navigator.of(context);

    switch (action) {
      case _BackupAction.restore:
        final restored = await runGuardedValue(
          context,
          () => service.restore(backup),
        );
        ref.invalidate(gameBackupsProvider);
        if (restored == null || !context.mounted) return;
        showMessage(context, '« ${restored.name} » a été restaurée.');
        await navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => GameDetailScreen(gameId: restored.id),
          ),
        );
      case _BackupAction.delete:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Supprimer cet instantané ?'),
            content: Text(
              'La sauvegarde de « ${backup.gameName} » sera effacée. '
              'La partie elle-même n\'est pas touchée.',
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
        if (confirmed != true || !context.mounted) return;
        await runGuarded(context, () => service.delete(backup));
        ref.invalidate(gameBackupsProvider);
    }
  }
}

enum _BackupAction { restore, delete }
