import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../games/domain/game_entities.dart';
import '../../../games/domain/passive_reminders.dart';
import '../../../games/domain/role.dart';
import '../../../games/presentation/widgets/passive_reminder_band.dart';
import '../../../games/presentation/widgets/role_picker_sheet.dart';
import '../../domain/narrator_hints.dart';
import '../../domain/night_action_type.dart';
import '../../domain/night_entities.dart';
import '../../domain/night_sequence.dart';
import 'narrator_hint_band.dart';
import 'player_choice_list.dart';

/// What a card hands back when the narrator validates it.
class NightActionDraft {
  const NightActionDraft({
    required this.typeId,
    this.actorPlayerId,
    this.targetPlayerId,
    this.secondaryTargetPlayerId,
    this.details = const {},
  });

  final String typeId;
  final String? actorPlayerId;
  final String? targetPlayerId;
  final String? secondaryTargetPlayerId;
  final Map<String, dynamic> details;
}

/// One full-screen card of the night: a role, its question, and the answer.
///
/// Every role that acts at night has one, built from its [NightCardSpec]; the
/// shape of the answer is the card's `kind`, so a new role never needs a new
/// screen.
class NightCardView extends StatefulWidget {
  const NightCardView({
    required this.spec,
    required this.snapshot,
    required this.recorded,
    required this.nightActions,
    required this.onSubmit,
    required this.onSkip,
    super.key,
  });

  final NightCardSpec spec;
  final GameSnapshot snapshot;

  /// The action already recorded for this card, when the narrator comes back.
  final NightAction? recorded;

  /// Everything already recorded for this night. The card reads two things
  /// from it: who the pack chose — the only player the witch may bring back —
  /// and the narrator-only hints.
  final List<NightAction> nightActions;

  /// Who the pack chose tonight, if the card has already been answered.
  String? get werewolfVictimId =>
      NightSequenceBuilder.werewolfVictimOf(nightActions);

  final ValueChanged<NightActionDraft> onSubmit;
  final VoidCallback onSkip;

  @override
  State<NightCardView> createState() => _NightCardViewState();
}

class _NightCardViewState extends State<NightCardView> {
  final TextEditingController _noteController = TextEditingController();
  String? _targetId;
  String? _secondaryId;

  @override
  void initState() {
    super.initState();
    _targetId = widget.recorded?.targetPlayerId;
    _secondaryId = widget.recorded?.secondaryTargetPlayerId;
    _noteController.text = widget.recorded?.detail ?? '';
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  List<Player> get _candidates => NightSequenceBuilder.candidates(
    spec: widget.spec,
    snapshot: widget.snapshot,
  );

  /// The player who acts, when a single living player holds the role.
  String? get _actorId {
    final roleId = widget.spec.role?.id;
    if (roleId == null) return null;
    final holders = widget.snapshot.alivePlayers
        .where((p) => p.roleId == roleId)
        .toList(growable: false);
    return holders.length == 1 ? holders.single.id : null;
  }

  Color get _accent {
    final role = widget.spec.role;
    if (role == null) return AppTheme.soloColor;
    return switch (role.team) {
      RoleTeam.village => AppTheme.villageColor,
      RoleTeam.werewolves => AppTheme.werewolfColor,
      RoleTeam.solo => AppTheme.soloColor,
    };
  }

  void _submit({
    String? typeId,
    String? targetId,
    String? secondaryId,
    Map<String, dynamic> details = const {},
  }) {
    widget.onSubmit(
      NightActionDraft(
        typeId: typeId ?? widget.spec.type!.id,
        actorPlayerId: _actorId,
        targetPlayerId: targetId ?? _targetId,
        secondaryTargetPlayerId: secondaryId ?? _secondaryId,
        details: {
          ...details,
          if (_noteController.text.trim().isNotEmpty &&
              !details.containsKey('text'))
            'text': _noteController.text.trim(),
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spec = widget.spec;

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: _accent.withValues(alpha: 0.45), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(spec.emoji, style: const TextStyle(fontSize: 36)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        spec.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: _accent,
                        ),
                      ),
                      if (spec.role != null)
                        Text(
                          spec.role!.description,
                          style: theme.textTheme.labelSmall,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(spec.prompt, style: theme.textTheme.bodyLarge),
            if (spec.hint != null && spec.hint!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  spec.hint!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.tertiary,
                  ),
                ),
              ),
            PassiveReminderBand(
              reminders: PassiveReminders.forNightCard(
                cardId: spec.id,
                snapshot: widget.snapshot,
              ),
            ),
            NarratorHintBand(
              hints: NarratorHints.forNightCard(
                cardId: spec.id,
                actions: widget.nightActions,
                snapshot: widget.snapshot,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(child: SingleChildScrollView(child: _body(context))),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context) => switch (widget.spec.kind) {
    NightCardKind.singleTarget => _singleTarget(context),
    NightCardKind.reveal => _singleTarget(context, reveal: true),
    NightCardKind.dualTarget => _dualTarget(context),
    NightCardKind.targetWithNote => _singleTarget(context, withNote: true),
    NightCardKind.confirm => _confirm(context),
    NightCardKind.witch => _witch(context),
    NightCardKind.summary => const SizedBox.shrink(),
  };

  Widget _singleTarget(
    BuildContext context, {
    bool reveal = false,
    bool withNote = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PlayerChoiceList(
          players: _candidates,
          selectedIds: {?_targetId},
          onTap: (player) => setState(() => _targetId = player.id),
        ),
        if (withNote) ...[
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            decoration: InputDecoration(
              labelText: widget.spec.type?.detailLabel ?? 'Note',
            ),
          ),
        ],
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _targetId == null
              ? null
              : () => reveal ? _revealAndSubmit() : _submit(),
          icon: Icon(reveal ? Icons.visibility : Icons.check),
          label: Text(reveal ? 'Révéler le rôle' : 'Valider'),
        ),
      ],
    );
  }

  Future<void> _revealAndSubmit() async {
    final target = widget.snapshot.playerById(_targetId);
    if (target == null) return;
    final role = Roles.byId(target.roleId);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${role.emoji} ${target.name}'),
        content: Text(
          '${target.name} est ${role.label}.\n\n'
          'Montrez discrètement la carte à la Voyante, puis validez.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Vu'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    _submit(details: {'text': role.label});
  }

  Widget _dualTarget(BuildContext context) {
    final theme = Theme.of(context);
    final secondaryLabel =
        widget.spec.type?.secondaryTargetLabel ?? 'Second joueur';
    // The Piper may charm a single player when only one name is left; Cupid
    // always needs his two.
    final secondaryOptional =
        widget.spec.type?.secondaryTargetOptional ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Premier joueur', style: theme.textTheme.labelMedium),
        const SizedBox(height: 8),
        PlayerChoiceList(
          players: _candidates,
          selectedIds: {?_targetId},
          onTap: (player) => setState(() {
            _targetId = player.id;
            if (_secondaryId == player.id) _secondaryId = null;
          }),
        ),
        const SizedBox(height: 16),
        Text(secondaryLabel, style: theme.textTheme.labelMedium),
        const SizedBox(height: 8),
        PlayerChoiceList(
          players: _candidates
              .where((player) => player.id != _targetId)
              .toList(growable: false),
          selectedIds: {?_secondaryId},
          onTap: (player) => setState(() => _secondaryId = player.id),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed:
              _targetId == null || (_secondaryId == null && !secondaryOptional)
              ? null
              : () => _submit(),
          icon: const Icon(Icons.check),
          label: const Text('Valider'),
        ),
      ],
    );
  }

  Widget _confirm(BuildContext context) {
    final isThief = widget.spec.id == NightActionTypes.thiefSwap.id;
    final detailLabel = widget.spec.type?.detailLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (detailLabel != null && !isThief)
          TextField(
            controller: _noteController,
            decoration: InputDecoration(labelText: detailLabel),
          ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: isThief ? _pickStolenRole : () => _submit(),
          icon: const Icon(Icons.check),
          label: Text(isThief ? 'Choisir la nouvelle carte' : 'C\'est fait'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: widget.onSkip,
          icon: const Icon(Icons.skip_next),
          label: const Text('Rien cette nuit'),
        ),
      ],
    );
  }

  Future<void> _pickStolenRole() async {
    final role = await RolePickerSheet.show(context);
    if (role == null) return;
    _submit(details: {'newRoleId': role.id, 'text': role.label});
  }

  Widget _witch(BuildContext context) {
    final theme = Theme.of(context);
    final healUsed = widget.spec.hint?.contains('vie') ?? false;
    final poisonUsed = widget.spec.hint?.contains('mort') ?? false;
    final victim = widget.snapshot.playerById(widget.werewolfVictimId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (victim != null)
          Text(
            'La meute a désigné ${victim.name}.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.werewolfColor,
            ),
          )
        else
          Text(
            'La meute n\'a encore désigné personne cette nuit.',
            style: theme.textTheme.bodySmall,
          ),
        const SizedBox(height: 20),
        FilledButton.icon(
          // The life potion brings the pack's victim back, nobody else.
          onPressed: healUsed || victim == null
              ? null
              : () => _submit(
                  typeId: NightActionTypes.witchHeal.id,
                  targetId: victim.id,
                ),
          icon: const Icon(Icons.healing),
          label: Text(
            healUsed
                ? 'Potion de vie déjà utilisée'
                : victim == null
                ? 'Personne à sauver'
                : 'Sauver ${victim.name}',
          ),
        ),
        const SizedBox(height: 12),
        if (!poisonUsed) ...[
          Text('Tuer un joueur', style: theme.textTheme.labelMedium),
          const SizedBox(height: 8),
          PlayerChoiceList(
            players: widget.snapshot.alivePlayers,
            selectedIds: {?_targetId},
            onTap: (player) => setState(() => _targetId = player.id),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.werewolfColor,
            ),
            onPressed: _targetId == null
                ? null
                : () => _submit(typeId: NightActionTypes.witchPoison.id),
            icon: const Icon(Icons.science_outlined),
            label: const Text('Empoisonner'),
          ),
        ] else
          Text(
            'Potion de mort déjà utilisée.',
            style: theme.textTheme.bodySmall,
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: widget.onSkip,
          icon: const Icon(Icons.skip_next),
          label: const Text('Ne rien faire'),
        ),
      ],
    );
  }
}
