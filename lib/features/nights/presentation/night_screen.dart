import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/ui_feedback.dart';
import '../../games/domain/game_entities.dart';
import '../data/nights_repository_impl.dart';
import '../domain/night_action_type.dart';
import '../domain/night_entities.dart';
import 'controllers/nights_providers.dart';
import 'widgets/action_entry_dialog.dart';
import 'widgets/night_outcome_view.dart';

/// Where the narrator types what happens while the village sleeps.
class NightScreen extends ConsumerWidget {
  const NightScreen({required this.gameId, required this.nightId, super.key});

  final String gameId;
  final String nightId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contextAsync = ref.watch(
      nightContextProvider((gameId: gameId, nightId: nightId)),
    );

    return contextAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('$error')),
      ),
      data: (nightContext) {
        if (nightContext == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Nuit introuvable.')),
          );
        }
        return _NightView(nightContext: nightContext);
      },
    );
  }
}

class _NightView extends ConsumerWidget {
  const _NightView({required this.nightContext});

  final NightContext nightContext;

  GameSnapshot get snapshot => nightContext.snapshot;
  NightDetail get detail => nightContext.detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final night = detail.night;
    final byPhase = <ActionPhase, List<NightActionType>>{};
    for (final type in nightContext.availableActions) {
      byPhase.putIfAbsent(type.phase, () => []).add(type);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('🌙 Nuit ${night.nightNumber}'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${snapshot.game.name} · '
                '${snapshot.alivePlayers.length} joueurs en vie',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          if (night.isResolved)
            const Card(
              child: ListTile(
                leading: Icon(Icons.lock_outline),
                title: Text('Nuit close'),
                subtitle: Text('Les actions ne sont plus modifiables.'),
              ),
            ),
          Text(
            'Actions enregistrées',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (detail.actions.isEmpty)
            const Card(
              child: ListTile(
                leading: Icon(Icons.hourglass_empty),
                title: Text('Aucune action pour l\'instant'),
                subtitle: Text(
                  'Appelez les rôles un par un et notez ce qu\'ils font.',
                ),
              ),
            )
          else
            for (final action in detail.actions)
              _ActionTile(
                action: action,
                snapshot: snapshot,
                onDelete: night.isResolved
                    ? null
                    : () => runGuarded(
                        context,
                        () => ref
                            .read(nightsRepositoryProvider)
                            .removeAction(action.id),
                      ),
              ),
          if (!night.isResolved) ...[
            const SizedBox(height: 24),
            Text(
              'Ajouter une action',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            for (final phase in ActionPhase.values)
              if (byPhase[phase] != null) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 6),
                  child: Text(
                    phase.label,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final type in byPhase[phase]!)
                      ActionChip(
                        avatar: Text(type.emoji),
                        label: Text(type.label),
                        onPressed: () => _addAction(context, ref, type),
                      ),
                  ],
                ),
              ],
          ],
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    night.isResolved ? 'Bilan de la nuit' : 'Aperçu du bilan',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  NightOutcomeView(
                    outcome: night.outcome ?? nightContext.preview,
                    snapshot: snapshot,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: night.isResolved
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: () => _resolve(context, ref),
                  icon: const Icon(Icons.wb_sunny_outlined),
                  label: const Text('Clore la nuit et lever le jour'),
                ),
              ),
            ),
    );
  }

  Future<void> _addAction(
    BuildContext context,
    WidgetRef ref,
    NightActionType type,
  ) async {
    final entry = await ActionEntryDialog.show(
      context,
      type: type,
      snapshot: snapshot,
    );
    if (entry == null || !context.mounted) return;

    await runGuarded(
      context,
      () => ref.read(nightsRepositoryProvider).addAction(
        nightId: detail.night.id,
        typeId: type.id,
        actorPlayerId: entry.actorPlayerId,
        targetPlayerId: entry.targetPlayerId,
        secondaryTargetPlayerId: entry.secondaryTargetPlayerId,
        details: entry.details,
      ),
    );
  }

  Future<void> _resolve(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bilan de la nuit ${detail.night.nightNumber}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              NightOutcomeView(
                outcome: nightContext.preview,
                snapshot: snapshot,
              ),
              const SizedBox(height: 16),
              Text(
                'Une fois close, la nuit n\'est plus modifiable.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Continuer la nuit'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clore'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final navigator = Navigator.of(context);
    final ok = await runGuarded(
      context,
      () => ref
          .read(nightsRepositoryProvider)
          .resolveNight(detail.night.id),
    );
    if (ok && navigator.canPop()) navigator.pop();
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.action,
    required this.snapshot,
    this.onDelete,
  });

  final NightAction action;
  final GameSnapshot snapshot;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final type = action.type;
    final target = snapshot.playerById(action.targetPlayerId);
    final secondary = snapshot.playerById(action.secondaryTargetPlayerId);
    final actor = snapshot.playerById(action.actorPlayerId);

    final subtitle = <String>[
      if (actor != null) 'par ${actor.name}',
      if (target != null) '→ ${target.name}',
      if (secondary != null) '+ ${secondary.name}',
      if (action.detail != null) '« ${action.detail} »',
    ].join('  ');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Text(type.emoji, style: const TextStyle(fontSize: 20)),
        title: Text(type.label),
        subtitle: subtitle.isEmpty ? null : Text(subtitle),
        trailing: onDelete == null
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Retirer cette action',
                onPressed: onDelete,
              ),
      ),
    );
  }
}
