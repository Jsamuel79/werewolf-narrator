import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/ui_feedback.dart';
import '../../../core/widgets/swipe_card_stack.dart';
import '../data/nights_repository_impl.dart';
import '../domain/night_action_type.dart';
import '../domain/night_sequence.dart';
import 'controllers/nights_providers.dart';
import 'widgets/night_card_view.dart';
import 'widgets/night_outcome_view.dart';

/// The night, as a deck of cards.
///
/// The app decides what comes next — the rulebook order, filtered by who is
/// still alive — and the narrator only answers. Swiping left moves on without
/// recording anything (« ce rôle ne fait rien »), swiping right goes back to
/// fix an answer, and the buttons under the deck do the same for anyone who
/// would rather tap than swipe.
class NightCardsScreen extends ConsumerStatefulWidget {
  const NightCardsScreen({
    required this.gameId,
    required this.nightId,
    this.onNightResolved,
    super.key,
  });

  final String gameId;
  final String nightId;

  /// Called once the night has been applied to the board — the day takes over.
  final void Function(BuildContext context)? onNightResolved;

  @override
  ConsumerState<NightCardsScreen> createState() => _NightCardsScreenState();
}

class _NightCardsScreenState extends ConsumerState<NightCardsScreen> {
  final GlobalKey<SwipeCardStackState> _stackKey =
      GlobalKey<SwipeCardStackState>();
  int _index = 0;

  void _goTo(int index, int count) {
    setState(() => _index = index.clamp(0, count - 1));
  }

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
            body: const Center(child: Text('Nuit introuvable.')),
          );
        }
        return _build(context, nightContext);
      },
    );
  }

  Widget _build(BuildContext context, NightContext nightContext) {
    final night = nightContext.detail.night;
    final theme = Theme.of(context);

    if (night.isResolved) {
      return Scaffold(
        appBar: AppBar(title: Text('🌙 Nuit ${night.nightNumber}')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Card(
              child: ListTile(
                leading: Icon(Icons.lock_outline),
                title: Text('Nuit close'),
                subtitle: Text('Les actions ne sont plus modifiables.'),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: NightOutcomeView(
                  outcome: night.outcome ?? nightContext.preview,
                  snapshot: nightContext.snapshot,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final cards = nightContext.cards;
    final index = _index.clamp(0, cards.length - 1);
    final current = cards[index];

    return Scaffold(
      appBar: AppBar(
        title: Text('🌙 Nuit ${night.nightNumber}'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: cards.isEmpty ? 0 : (index + 1) / cards.length,
                  minHeight: 4,
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Carte ${index + 1} sur ${cards.length} · '
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
          itemBuilder: (context, i) {
            final spec = cards[i];
            if (spec.kind == NightCardKind.summary) {
              return _SummaryCard(
                nightContext: nightContext,
                onResolve: () => _resolve(nightContext),
              );
            }
            return NightCardView(
              key: ValueKey('${night.id}-${spec.id}'),
              spec: spec,
              snapshot: nightContext.snapshot,
              recorded: nightContext.actionOf(spec.id),
              werewolfVictimId: NightSequenceBuilder.werewolfVictimOf(
                nightContext.nightActions,
              ),
              onSubmit: (draft) => _record(nightContext, draft, cards.length),
              onSkip: () => _next(cards.length),
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: index == 0 ? null : () => _previous(),
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
                  label: Text(
                    current.kind == NightCardKind.summary
                        ? 'Suivant'
                        : 'Passer',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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

  Future<void> _record(
    NightContext nightContext,
    NightActionDraft draft,
    int cardCount,
  ) async {
    final repository = ref.read(nightsRepositoryProvider);
    final existing = nightContext.actionOf(draft.typeId);

    final ok = await runGuarded(context, () async {
      // Going back and answering again replaces the previous answer rather
      // than stacking a second action of the same kind.
      if (existing != null) await repository.removeAction(existing.id);
      await repository.addAction(
        nightId: widget.nightId,
        typeId: draft.typeId,
        phase: ActionPhase.night,
        actorPlayerId: draft.actorPlayerId,
        targetPlayerId: draft.targetPlayerId,
        secondaryTargetPlayerId: draft.secondaryTargetPlayerId,
        details: draft.details,
      );
    });
    if (!ok || !mounted) return;
    _next(cardCount);
  }

  Future<void> _resolve(NightContext nightContext) async {
    final navigator = Navigator.of(context);
    final onResolved = widget.onNightResolved;
    final ok = await runGuarded(
      context,
      () => ref.read(nightsRepositoryProvider).resolveNight(widget.nightId),
    );
    if (!ok || !mounted) return;
    if (onResolved != null) {
      onResolved(context);
    } else if (navigator.canPop()) {
      navigator.pop();
    }
  }
}

/// The last card: what the night did to the board, and the way out of it.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.nightContext, required this.onResolve});

  final NightContext nightContext;
  final VoidCallback onResolve;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.5),
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
                const Text('🌅', style: TextStyle(fontSize: 36)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Bilan de la nuit',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: NightOutcomeView(
                  outcome: nightContext.preview,
                  snapshot: nightContext.snapshot,
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onResolve,
              icon: const Icon(Icons.wb_sunny_outlined),
              label: const Text('Valider et passer au jour'),
            ),
          ],
        ),
      ),
    );
  }
}
