import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ui_feedback.dart';
import '../../../core/widgets/swipe_card_stack.dart';
import '../../games/domain/game_entities.dart';
import '../../games/domain/role.dart';
import '../../games/presentation/controllers/games_providers.dart';
import '../../nights/data/nights_repository_impl.dart';
import '../../nights/domain/night_action_type.dart';
import '../../nights/presentation/controllers/nights_providers.dart';
import '../../nights/presentation/widgets/night_outcome_view.dart';
import '../../nights/presentation/widgets/player_choice_list.dart';
import '../../victory/presentation/victory_screen.dart';
import '../domain/day_entities.dart';
import 'widgets/debate_timer_card.dart';
import 'widgets/village_vote_card.dart';

/// The day that follows a night, as a deck of cards: dawn recap, captain,
/// debate stopwatch, vote, consequences.
class DayScreen extends ConsumerStatefulWidget {
  const DayScreen({
    required this.gameId,
    required this.nightId,
    this.onDayResolved,
    super.key,
  });

  final String gameId;
  final String nightId;

  /// Called once the day has been applied to the board.
  final void Function(BuildContext context)? onDayResolved;

  @override
  ConsumerState<DayScreen> createState() => _DayScreenState();
}

class _DayScreenState extends ConsumerState<DayScreen> {
  final GlobalKey<SwipeCardStackState> _stackKey =
      GlobalKey<SwipeCardStackState>();
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final contextAsync = ref.watch(
      nightContextProvider((gameId: widget.gameId, nightId: widget.nightId)),
    );

    return contextAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) =>
          Scaffold(appBar: AppBar(), body: Center(child: Text('$error'))),
      data: (nightContext) {
        if (nightContext == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Tour introuvable.')),
          );
        }
        return _build(context, nightContext);
      },
    );
  }

  Widget _build(BuildContext context, NightContext nightContext) {
    final night = nightContext.detail.night;
    final theme = Theme.of(context);

    if (night.isDayResolved) {
      return Scaffold(
        appBar: AppBar(title: Text('☀️ Jour ${night.nightNumber}')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Card(
              child: ListTile(
                leading: Icon(Icons.lock_outline),
                title: Text('Journée close'),
                subtitle: Text('Le tour est terminé.'),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: NightOutcomeView(
                  outcome: night.dayOutcome ?? nightContext.dayPreview,
                  snapshot: nightContext.snapshot,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final cards = DaySequenceBuilder.build(
      snapshot: nightContext.snapshot,
      night: night,
      dayActions: DayAction.from(nightContext.dayActions),
      usedOncePerGameActionIds: nightContext.usedOncePerGameActionIds,
    );
    final index = _index.clamp(0, cards.length - 1);

    return Scaffold(
      appBar: AppBar(
        title: Text('☀️ Jour ${night.nightNumber}'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: (index + 1) / cards.length,
                  minHeight: 4,
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Étape ${index + 1} sur ${cards.length} · '
                    '${nightContext.snapshot.alivePlayers.length} joueurs en vie',
                    style: theme.textTheme.labelSmall,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SwipeCardStack(
          key: _stackKey,
          itemCount: cards.length,
          index: index,
          onNext: () => _goTo(index + 1, cards.length),
          onPrevious: () => _goTo(index - 1, cards.length),
          itemBuilder: (context, i) => _DayCard(
            // Without a key, Flutter would reuse one card's State for the
            // next: the captain's pick would preselect the hunter's target,
            // and the Judge's second vote would open on the first count.
            key: ValueKey('${night.id}-${cards[i].id}'),
            spec: cards[i],
            nightContext: nightContext,
            onCaptain: (playerId, bySuccession) =>
                _electCaptain(nightContext, playerId, bySuccession, cards.length),
            onVote: (spec, entry) =>
                _recordVote(nightContext, spec, entry, cards.length),
            onHunterShot: (spec, targetId) =>
                _recordHunterShot(nightContext, spec, targetId, cards.length),
            onJudgeCall: () => _recordJudgeCall(nightContext, cards.length),
            onServantSwap: (spec) =>
                _recordServantSwap(nightContext, spec, cards.length),
            onSkip: () => _next(cards.length),
            onResolve: () => _resolve(nightContext),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: index == 0 ? null : _previous,
                  icon: const Icon(Icons.chevron_left),
                  label: const Text('Précédent'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: index >= cards.length - 1
                      ? null
                      : () => _next(cards.length),
                  icon: const Icon(Icons.chevron_right),
                  label: const Text('Passer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _goTo(int index, int count) =>
      setState(() => _index = index.clamp(0, count - 1));

  void _next(int count) {
    final stack = _stackKey.currentState;
    if (stack != null && _index < count - 1) {
      stack.fling(forward: true);
    } else {
      _goTo(_index + 1, count);
    }
  }

  void _previous() {
    final stack = _stackKey.currentState;
    if (stack != null && _index > 0) {
      stack.fling(forward: false);
    } else {
      _goTo(_index - 1, 1);
    }
  }

  Future<void> _add({
    required String typeId,
    String? actorPlayerId,
    String? targetPlayerId,
    Map<String, dynamic> details = const {},
  }) {
    return ref
        .read(nightsRepositoryProvider)
        .addAction(
          nightId: widget.nightId,
          typeId: typeId,
          phase: ActionPhase.day,
          actorPlayerId: actorPlayerId,
          targetPlayerId: targetPlayerId,
          details: details,
        );
  }

  Future<void> _electCaptain(
    NightContext nightContext,
    String playerId,
    bool bySuccession,
    int cardCount,
  ) async {
    final typeId = bySuccession
        ? NightActionTypes.captainSuccession.id
        : NightActionTypes.captainElection.id;
    final existing = nightContext.actionOf(typeId);

    final ok = await runGuarded(context, () async {
      if (existing != null) {
        await ref.read(nightsRepositoryProvider).removeAction(existing.id);
      }
      await _add(typeId: typeId, targetPlayerId: playerId);
    });
    if (!ok || !mounted) return;
    _next(cardCount);
  }

  Future<void> _recordVote(
    NightContext nightContext,
    DayCardSpec spec,
    VoteEntry entry,
    int cardCount,
  ) async {
    final result = entry.result;
    final snapshot = nightContext.snapshot;
    final detail = _voteDetail(entry, snapshot);
    final voteTypeId = spec.secondVote
        ? NightActionTypes.villageSecondVote.id
        : NightActionTypes.villageVote.id;

    final ok = await runGuarded(context, () async {
      // Answering again replaces the previous count.
      for (final typeId in [
        voteTypeId,
        NightActionTypes.villageIdiotSpared.id,
        NightActionTypes.customNote.id,
      ]) {
        final existing = nightContext.actionOf(typeId);
        if (existing != null) {
          await ref.read(nightsRepositoryProvider).removeAction(existing.id);
        }
      }

      if (result.eliminatesSomeone) {
        await _add(
          typeId: voteTypeId,
          targetPlayerId: result.eliminatedPlayerId,
          details: {'text': detail},
        );
      } else if (result.sparedPlayerId != null) {
        await _add(
          typeId: NightActionTypes.villageIdiotSpared.id,
          actorPlayerId: result.sparedPlayerId,
          details: {'text': detail},
        );
      } else {
        await _add(
          typeId: NightActionTypes.customNote.id,
          details: {'text': detail},
        );
      }
    });
    if (!ok || !mounted) return;
    _next(cardCount);
  }

  String _voteDetail(VoteEntry entry, GameSnapshot snapshot) {
    final counts = entry.result.effectiveVotes.entries
        .map((e) => '${snapshot.playerById(e.key)?.name ?? '?'} ${e.value}')
        .join(', ');
    final captain = snapshot.playerById(entry.captainVoteTargetId);
    return [
      if (counts.isNotEmpty) counts,
      if (captain != null) 'Capitaine → ${captain.name}',
      entry.result.label,
    ].join(' · ');
  }

  Future<void> _recordJudgeCall(
    NightContext nightContext,
    int cardCount,
  ) async {
    final ok = await runGuarded(
      context,
      () => _add(
        typeId: NightActionTypes.judgeSecondVote.id,
        actorPlayerId: nightContext.snapshot.alivePlayers
            .where((p) => p.roleId == Roles.stutteringJudge.id)
            .map((p) => p.id)
            .firstOrNull,
        details: const {'text': 'Un second vote est réclamé'},
      ),
    );
    if (!ok || !mounted) return;
    _next(cardCount);
  }

  Future<void> _recordServantSwap(
    NightContext nightContext,
    DayCardSpec spec,
    int cardCount,
  ) async {
    final eliminated = nightContext.snapshot.playerById(
      spec.eliminatedPlayerId,
    );
    if (eliminated == null) return;

    final ok = await runGuarded(
      context,
      () => _add(
        typeId: NightActionTypes.servantSwap.id,
        actorPlayerId: spec.servantPlayerId,
        targetPlayerId: eliminated.id,
        details: {
          'newRoleId': eliminated.roleId,
          // She takes a card, not a past: lover, badge and charm are dropped.
          'resetStatuses': true,
          'text': eliminated.role.label,
        },
      ),
    );
    if (!ok || !mounted) return;
    _next(cardCount);
  }

  Future<void> _recordHunterShot(
    NightContext nightContext,
    DayCardSpec spec,
    String targetId,
    int cardCount,
  ) async {
    final existing = nightContext.actionOf(NightActionTypes.hunterShot.id);
    final ok = await runGuarded(context, () async {
      if (existing != null) {
        await ref.read(nightsRepositoryProvider).removeAction(existing.id);
      }
      await _add(
        typeId: NightActionTypes.hunterShot.id,
        actorPlayerId: spec.hunterPlayerId,
        targetPlayerId: targetId,
      );
    });
    if (!ok || !mounted) return;
    _next(cardCount);
  }

  Future<void> _resolve(NightContext nightContext) async {
    final navigator = Navigator.of(context);
    final onResolved = widget.onDayResolved;
    final ok = await runGuarded(
      context,
      () => ref.read(nightsRepositoryProvider).resolveDay(widget.nightId),
    );
    if (!ok || !mounted) return;
    if (onResolved != null) {
      onResolved(context);
      return;
    }

    // The vote may have ended the game. Read the board back from the database
    // rather than from the watching provider: the provider still holds the
    // state it had before the transaction, and `.future` would hand that stale
    // value straight back.
    final snapshot = await ref
        .read(gamesRepositoryProvider)
        .loadGame(widget.gameId);
    if (!mounted) return;
    if (snapshot != null && snapshot.game.isFinished) {
      await navigator.pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => VictoryScreen(gameId: widget.gameId),
        ),
      );
      return;
    }
    if (navigator.canPop()) navigator.pop();
  }
}

/// One full-screen card of the day.
class _DayCard extends StatefulWidget {
  const _DayCard({
    required this.spec,
    super.key,
    required this.nightContext,
    required this.onCaptain,
    required this.onVote,
    required this.onHunterShot,
    required this.onJudgeCall,
    required this.onServantSwap,
    required this.onSkip,
    required this.onResolve,
  });

  final DayCardSpec spec;
  final NightContext nightContext;
  final void Function(String playerId, bool bySuccession) onCaptain;
  final void Function(DayCardSpec spec, VoteEntry entry) onVote;
  final void Function(DayCardSpec spec, String targetId) onHunterShot;
  final VoidCallback onJudgeCall;
  final ValueChanged<DayCardSpec> onServantSwap;
  final VoidCallback onSkip;
  final VoidCallback onResolve;

  @override
  State<_DayCard> createState() => _DayCardState();
}

class _DayCardState extends State<_DayCard> {
  String? _selectedId;
  bool _bySuccession = false;

  GameSnapshot get _snapshot => widget.nightContext.snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spec = widget.spec;

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: AppTheme.soloColor.withValues(alpha: 0.45),
          width: 1.5,
        ),
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
                  child: Text(spec.title, style: theme.textTheme.titleLarge),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(spec.prompt, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 16),
            Expanded(child: SingleChildScrollView(child: _body(context))),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context) => switch (widget.spec.kind) {
    DayCardKind.dawnRecap => _dawnRecap(context),
    DayCardKind.captain => _captain(context),
    DayCardKind.debate => const DebateTimerCard(),
    DayCardKind.vote => VillageVoteCard(
      snapshot: _snapshot,
      villageIdiotAlreadySpared: widget.nightContext
          .usedOncePerGameActionIds
          .contains(NightActionTypes.villageIdiotSpared.id),
      onSubmit: (entry) => widget.onVote(widget.spec, entry),
    ),
    DayCardKind.judgeCall => _judgeCall(context),
    DayCardKind.servantSwap => _servantSwap(context),
    DayCardKind.hunterShot => _hunterShot(context),
    DayCardKind.summary => _summary(context),
  };

  Widget _dawnRecap(BuildContext context) {
    final night = widget.nightContext.detail.night;
    final outcome = night.outcome;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (outcome == null)
          const Text('La nuit n\'a pas encore été close.')
        else
          NightOutcomeView(outcome: outcome, snapshot: _snapshot),
      ],
    );
  }

  Widget _captain(BuildContext context) {
    final theme = Theme.of(context);
    final died = widget.nightContext.detail.night.outcome?.captainDiedId != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (died) ...[
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Nouvelle élection')),
              ButtonSegment(value: true, label: Text('Désigné par lui')),
            ],
            selected: {_bySuccession},
            onSelectionChanged: (values) =>
                setState(() => _bySuccession = values.first),
          ),
          const SizedBox(height: 16),
        ],
        Text('Nouveau Capitaine', style: theme.textTheme.labelMedium),
        const SizedBox(height: 8),
        PlayerChoiceList(
          players: _snapshot.alivePlayers,
          selectedIds: {?_selectedId},
          onTap: (player) => setState(() => _selectedId = player.id),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _selectedId == null
              ? null
              : () => widget.onCaptain(_selectedId!, _bySuccession),
          icon: const Icon(Icons.star),
          label: const Text('Nommer Capitaine'),
        ),
      ],
    );
  }

  Widget _judgeCall(BuildContext context) {
    final theme = Theme.of(context);
    final called = widget.nightContext.actionOf(
      NightActionTypes.judgeSecondVote.id,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Une seule fois dans la partie, le Juge bègue peut faire son signe '
          'convenu et déclencher un second vote immédiatement après le '
          'premier, dans la même journée.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 20),
        if (called != null)
          Text(
            '⚖️ Le second vote a été réclamé.',
            style: theme.textTheme.titleSmall,
          )
        else ...[
          FilledButton.icon(
            onPressed: widget.onJudgeCall,
            icon: const Icon(Icons.gavel),
            label: const Text('Oui, second vote'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: widget.onSkip,
            icon: const Icon(Icons.skip_next),
            label: const Text('Non, la journée s\'arrête là'),
          ),
        ],
      ],
    );
  }

  Widget _servantSwap(BuildContext context) {
    final theme = Theme.of(context);
    final servant = _snapshot.playerById(widget.spec.servantPlayerId);
    final eliminated = _snapshot.playerById(widget.spec.eliminatedPlayerId);
    final done = widget.nightContext.actionOf(
      NightActionTypes.servantSwap.id,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (eliminated != null)
          Text(
            '${eliminated.name} vient d\'être éliminé. '
            '${servant?.name ?? 'La Servante'} peut se dévoiler et reprendre '
            'sa carte (${eliminated.role.label}) sans la montrer au village.',
            style: theme.textTheme.bodyMedium,
          ),
        const SizedBox(height: 12),
        Text(
          'Elle perd alors tous ses statuts : amoureux, écharpe de Capitaine, '
          'charme du Joueur de Flûte.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 20),
        if (done != null)
          Text(
            '🙇 La Servante a repris la carte.',
            style: theme.textTheme.titleSmall,
          )
        else ...[
          FilledButton.icon(
            onPressed: () => widget.onServantSwap(widget.spec),
            icon: const Icon(Icons.swap_horiz),
            label: const Text('Elle se dévoue'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: widget.onSkip,
            icon: const Icon(Icons.skip_next),
            label: const Text('Elle reste cachée'),
          ),
        ],
      ],
    );
  }

  Widget _hunterShot(BuildContext context) {
    final hunter = _snapshot.playerById(widget.spec.hunterPlayerId);
    final candidates = _snapshot.alivePlayers
        .where((player) => player.id != widget.spec.hunterPlayerId)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hunter != null)
          Text('${hunter.name} (${Roles.hunter.label}) tire une dernière fois.'),
        const SizedBox(height: 12),
        PlayerChoiceList(
          players: candidates,
          selectedIds: {?_selectedId},
          onTap: (player) => setState(() => _selectedId = player.id),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _selectedId == null
              ? null
              : () => widget.onHunterShot(widget.spec, _selectedId!),
          icon: const Icon(Icons.my_location),
          label: const Text('Tirer'),
        ),
      ],
    );
  }

  Widget _summary(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NightOutcomeView(
          outcome: widget.nightContext.dayPreview,
          snapshot: _snapshot,
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: widget.onResolve,
          icon: const Icon(Icons.nightlight_round),
          label: const Text('Valider la journée'),
        ),
      ],
    );
  }
}
