import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/ui_feedback.dart';
import '../domain/role.dart';
import 'controllers/game_setup_controller.dart';
import 'game_detail_screen.dart';
import 'widgets/role_badge.dart';
import 'widgets/role_picker_sheet.dart';

class GameSetupScreen extends ConsumerStatefulWidget {
  const GameSetupScreen({super.key});

  @override
  ConsumerState<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends ConsumerState<GameSetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _playerController = TextEditingController();
  final FocusNode _playerFocus = FocusNode();

  @override
  void dispose() {
    _nameController.dispose();
    _playerController.dispose();
    _playerFocus.dispose();
    super.dispose();
  }

  void _addPlayer() {
    final name = _playerController.text;
    if (name.trim().isEmpty) return;
    ref.read(gameSetupControllerProvider.notifier).addPlayer(name);
    _playerController.clear();
    _playerFocus.requestFocus();
  }

  Future<void> _submit() async {
    final controller = ref.read(gameSetupControllerProvider.notifier);
    final navigator = Navigator.of(context);
    String? gameId;
    final ok = await runGuarded(context, () async {
      final game = await controller.submit();
      gameId = game.id;
    });
    if (!ok || gameId == null || !mounted) return;
    navigator.pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => GameDetailScreen(gameId: gameId!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameSetupControllerProvider);
    final controller = ref.read(gameSetupControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle partie')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _nameController,
              onChanged: controller.setName,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nom de la partie',
                hintText: 'Soirée du samedi',
                prefixIcon: Icon(Icons.local_activity_outlined),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _playerController,
                    focusNode: _playerFocus,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _addPlayer(),
                    decoration: const InputDecoration(
                      labelText: 'Ajouter un joueur',
                      prefixIcon: Icon(Icons.person_add_alt),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _addPlayer,
                  icon: const Icon(Icons.add),
                  tooltip: 'Ajouter',
                ),
              ],
            ),
          ),
          _SetupSummary(state: state),
          if (state.players.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: controller.randomizeRoles,
                  icon: const Icon(Icons.casino_outlined),
                  label: const Text('Distribution aléatoire'),
                ),
              ),
            ),
          const Divider(),
          Expanded(
            child: state.players.isEmpty
                ? const _NoPlayersYet()
                : ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: state.players.length,
                    onReorderItem: controller.reorder,
                    itemBuilder: (context, index) {
                      final draft = state.players[index];
                      final role = Roles.byId(draft.roleId);
                      return Card(
                        key: ValueKey('$index-${draft.name}'),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(child: Text('${index + 1}')),
                          title: Text(draft.name),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: RoleBadge(role: role),
                            ),
                          ),
                          onTap: () => _pickRole(index, draft.roleId),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: 'Renommer',
                                onPressed: () => _rename(index, draft.name),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                tooltip: 'Retirer',
                                onPressed: () =>
                                    controller.removePlayerAt(index),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: state.canSubmit ? _submit : null,
            icon: state.isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow),
            label: Text(
              state.players.length < 3
                  ? 'Au moins 3 joueurs'
                  : 'Lancer la partie',
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickRole(int index, String currentRoleId) async {
    final role = await RolePickerSheet.show(
      context,
      selectedRoleId: currentRoleId,
    );
    if (role == null) return;
    ref.read(gameSetupControllerProvider.notifier).setRoleAt(index, role.id);
  }

  Future<void> _rename(int index, String current) async {
    final controller = TextEditingController(text: current);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renommer le joueur'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nom'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
    if (name == null) return;
    ref.read(gameSetupControllerProvider.notifier).renamePlayerAt(index, name);
  }
}

class _SetupSummary extends StatelessWidget {
  const _SetupSummary({required this.state});

  final GameSetupState state;

  @override
  Widget build(BuildContext context) {
    if (state.players.isEmpty) return const SizedBox(height: 8);
    final theme = Theme.of(context);
    final wolves = state.werewolfCount;
    final suggested = state.suggestedWerewolfCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                pluralFr(state.players.length, 'joueur'),
                style: theme.textTheme.labelLarge,
              ),
              const Spacer(),
              Text(
                wolves == suggested
                    ? '🐺 $wolves loup${wolves > 1 ? 's' : ''}'
                    : '🐺 $wolves — suggéré : $suggested',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: wolves == suggested
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.tertiary,
                ),
              ),
            ],
          ),
          // Without a wolf the village has already won: the game would end on
          // the very first recap. Better to say so now than at the table.
          if (wolves == 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '⚠️ Aucun Loup-Garou : la partie se terminera dès le premier '
                'bilan par une victoire du Village.',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NoPlayersYet extends StatelessWidget {
  const _NoPlayersYet();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🪑', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 12),
            Text(
              'Ajoutez les joueurs autour de la table,\n'
              'puis touchez un joueur pour lui donner son rôle.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
