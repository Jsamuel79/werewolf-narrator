import '../../games/domain/game_entities.dart';
import '../../games/domain/role.dart';
import '../../nights/domain/night_action_type.dart';
import '../../nights/domain/night_entities.dart';

/// The steps of a day, in the order the village lives them.
enum DayCardKind {
  /// Who died during the night, and how.
  dawnRecap,

  /// Electing the captain — only while the seat is vacant.
  captain,

  /// The debate stopwatch.
  debate,

  /// Counting the raised hands.
  vote,

  /// The Stuttering Judge asking for a second vote, once per game.
  judgeCall,

  /// The Devoted Servant taking the place of the player just voted out.
  servantSwap,

  /// The hunter takes someone with him.
  hunterShot,

  /// What the day did to the board, then on to the next night.
  summary,
}

/// One card of the day phase.
class DayCardSpec {
  const DayCardSpec({
    required this.kind,
    required this.title,
    required this.prompt,
    required this.emoji,
    this.hunterPlayerId,
    this.servantPlayerId,
    this.eliminatedPlayerId,
    this.secondVote = false,
  });

  final DayCardKind kind;
  final String title;
  final String prompt;
  final String emoji;

  /// The hunter about to fire, on a [DayCardKind.hunterShot] card.
  final String? hunterPlayerId;

  /// The Devoted Servant about to reveal herself.
  final String? servantPlayerId;

  /// Whose card she would take — the player the village just voted out.
  final String? eliminatedPlayerId;

  /// Whether a [DayCardKind.vote] card is the Judge's second vote.
  final bool secondVote;

  String get id => secondVote ? '${kind.name}2' : kind.name;
}

/// Builds the day that follows a night.
///
/// Pure, and recomputed whenever the board or the recorded actions change: the
/// hunter's card only appears once a hunter has actually fallen, and the
/// captain's card disappears as soon as somebody wears the badge.
abstract final class DaySequenceBuilder {
  static List<DayCardSpec> build({
    required GameSnapshot snapshot,
    required Night night,
    required List<DayAction> dayActions,
    Set<String> usedOncePerGameActionIds = const {},
  }) {
    final cards = <DayCardSpec>[
      const DayCardSpec(
        kind: DayCardKind.dawnRecap,
        title: 'Le village se réveille',
        prompt: 'Annoncez les morts de la nuit.',
        emoji: '🌤️',
      ),
    ];

    if (snapshot.aliveCaptain == null) {
      final died = night.outcome?.captainDiedId != null;
      cards.add(
        DayCardSpec(
          kind: DayCardKind.captain,
          title: 'Le Capitaine',
          prompt: died
              ? 'Le Capitaine est mort. Son successeur est-il désigné par lui '
                    'ou élu par le village ?'
              : 'Le village élit son Capitaine. Sa voix comptera double.',
          emoji: '⭐',
        ),
      );
    }

    cards
      ..add(
        const DayCardSpec(
          kind: DayCardKind.debate,
          title: 'Le débat',
          prompt: 'Laissez le village s\'accuser, puis passez au vote.',
          emoji: '⏱️',
        ),
      )
      ..add(
        const DayCardSpec(
          kind: DayCardKind.vote,
          title: 'Le vote du village',
          prompt: 'Comptez les mains levées pour chaque joueur.',
          emoji: '🗳️',
        ),
      );

    // The Stuttering Judge may call for a second vote, once in the game. His
    // card stays on the deck once answered so the narrator can go back to it.
    final judgeCalled = dayActions.any(
      (action) => action.typeId == NightActionTypes.judgeSecondVote.id,
    );
    final judge = _livingHolderOf(snapshot, Roles.stutteringJudge.id);
    final judgeAvailable =
        judge != null &&
        !usedOncePerGameActionIds.contains(
          NightActionTypes.judgeSecondVote.id,
        );
    if (judgeAvailable || judgeCalled) {
      cards.add(
        const DayCardSpec(
          kind: DayCardKind.judgeCall,
          title: 'Le Juge bègue',
          prompt: 'Réclame-t-il un second vote, ici et maintenant ?',
          emoji: '⚖️',
        ),
      );
    }
    if (judgeCalled) {
      cards.add(
        const DayCardSpec(
          kind: DayCardKind.vote,
          title: 'Le second vote',
          prompt: 'Le village vote une seconde fois. Recomptez les mains.',
          emoji: '🗳️',
          secondVote: true,
        ),
      );
    }

    // The Devoted Servant steps in before the eliminated player turns their
    // card over — so only once the village has actually voted somebody out.
    final servant = _livingHolderOf(snapshot, Roles.servant.id);
    final eliminatedId = _votedOutId(dayActions);
    final servantSwapped = dayActions.any(
      (action) => action.typeId == NightActionTypes.servantSwap.id,
    );
    final servantAvailable =
        servant != null &&
        eliminatedId != null &&
        servant.id != eliminatedId &&
        !usedOncePerGameActionIds.contains(NightActionTypes.servantSwap.id);
    if (servantAvailable || servantSwapped) {
      cards.add(
        DayCardSpec(
          kind: DayCardKind.servantSwap,
          title: Roles.servant.label,
          prompt:
              'Avant que la carte ne soit retournée, la Servante peut prendre '
              'la place de l\'éliminé.',
          emoji: Roles.servant.emoji,
          servantPlayerId: servant?.id,
          eliminatedPlayerId: eliminatedId,
        ),
      );
    }

    final hunterId = _hunterToFire(
      snapshot: snapshot,
      night: night,
      dayActions: dayActions,
    );
    if (hunterId != null) {
      cards.add(
        DayCardSpec(
          kind: DayCardKind.hunterShot,
          title: Roles.hunter.label,
          prompt: 'Le Chasseur s\'écroule. Qui emporte-t-il avec lui ?',
          emoji: Roles.hunter.emoji,
          hunterPlayerId: hunterId,
        ),
      );
    }

    cards.add(
      const DayCardSpec(
        kind: DayCardKind.summary,
        title: 'Fin de la journée',
        prompt: 'Voici ce que le jour a changé.',
        emoji: '🌇',
      ),
    );
    return cards;
  }

  /// The hunter who owes the village a shot: one who fell during the night, or
  /// one the village just voted out — and who has not fired yet.
  static String? _hunterToFire({
    required GameSnapshot snapshot,
    required Night night,
    required List<DayAction> dayActions,
  }) {
    final alreadyFired = dayActions.any(
      (action) => action.typeId == NightActionTypes.hunterShot.id,
    );
    if (alreadyFired) return null;

    for (final player in snapshot.players) {
      if (player.roleId != Roles.hunter.id) continue;
      final fellTonight =
          !player.isAlive && player.deathNightNumber == night.nightNumber;
      if (fellTonight) return player.id;
    }

    final votedOut = snapshot.playerById(_votedOutId(dayActions));
    if (votedOut != null && votedOut.roleId == Roles.hunter.id) {
      return votedOut.id;
    }
    return null;
  }

  /// Who the village voted out today — the second vote has the final word.
  static String? _votedOutId(List<DayAction> dayActions) {
    String? id;
    for (final action in dayActions) {
      if (action.typeId == NightActionTypes.villageVote.id ||
          action.typeId == NightActionTypes.villageSecondVote.id) {
        id = action.targetPlayerId ?? id;
      }
    }
    return id;
  }

  static Player? _livingHolderOf(GameSnapshot snapshot, String roleId) {
    for (final player in snapshot.alivePlayers) {
      if (player.roleId == roleId) return player;
    }
    return null;
  }
}

/// The little the day sequence needs to know about an action already recorded.
///
/// Keeps `day/domain` from depending on the whole `NightAction` shape.
class DayAction {
  const DayAction({required this.typeId, this.targetPlayerId});

  final String typeId;
  final String? targetPlayerId;

  static List<DayAction> from(Iterable<NightAction> actions) => [
    for (final action in actions)
      DayAction(
        typeId: action.typeId,
        targetPlayerId: action.targetPlayerId,
      ),
  ];
}
