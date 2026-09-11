import '../../games/domain/game_entities.dart';
import '../../games/domain/role.dart';
import 'night_action_type.dart';
import 'night_entities.dart';

/// The shape of the card shown for one step of the night.
enum NightCardKind {
  /// Pick one living player.
  singleTarget,

  /// Pick two distinct living players (Cupid, Piper).
  dualTarget,

  /// Pick one player, then read their role out of the app.
  reveal,

  /// Pick one player and type what the narrator answered.
  targetWithNote,

  /// A yes/no question, with an optional note.
  confirm,

  /// The witch and her two potions — the only card with three buttons.
  witch,

  /// No question: the list of everybody the Piper has charmed so far, to be
  /// woken together so they recognise each other.
  charmedRollCall,

  /// The recap that closes the night.
  summary,
}

/// Who a card may target.
enum NightTargetScope {
  /// Everybody still alive.
  alive,

  /// Everybody alive except the player(s) holding the acting role.
  aliveOthers,

  /// The pack's meal: everybody alive who does not hunt with it.
  aliveNonWolves,

  /// The White Werewolf's meal: the other wolves.
  aliveWolves,
}

/// One step of the night, ready to be drawn as a card.
class NightCardSpec {
  const NightCardSpec({
    required this.id,
    required this.kind,
    required this.title,
    required this.prompt,
    required this.emoji,
    this.type,
    this.secondaryType,
    this.role,
    this.scope = NightTargetScope.alive,
    this.excludedPlayerIds = const {},
    this.listedPlayerIds = const {},
    this.hint,
  });

  /// Stable key of the card — the action type id, or `summary`.
  final String id;
  final NightCardKind kind;
  final String title;
  final String prompt;
  final String emoji;

  /// Action recorded when the narrator validates. `null` on the summary card.
  final NightActionType? type;

  /// Second action the card can record (the witch's other potion).
  final NightActionType? secondaryType;

  final RoleDefinition? role;
  final NightTargetScope scope;

  /// Players this particular card may not target — the Salvateur's previous
  /// protection, for instance.
  final Set<String> excludedPlayerIds;

  /// Players the card is *about* rather than players it asks to choose from —
  /// the charmed, on the roll-call card. In seat order.
  final Set<String> listedPlayerIds;

  /// One extra line explaining a restriction, shown under the prompt.
  final String? hint;

  static const String summaryId = 'summary';
  static const String charmedRollCallId = 'charmedRollCall';
}

/// Builds the ordered list of cards for one night.
///
/// Pure: it takes the board and what has already been recorded, and returns
/// what the narrator has to ask, in the order of the rulebook — Thief, Cupid,
/// the siblings, the Seer, the Guard, the pack, the Witch, and the loners last.
/// The narrator never chooses what comes next.
abstract final class NightSequenceBuilder {
  /// Canonical wake-up order. The Seer wakes *before* the pack, as the
  /// rulebook has it: she must not know who was eaten.
  static const List<String> order = [
    'thiefSwap',
    'cupidCouple',
    'sistersRecognition',
    'brothersRecognition',
    'wildChildModel',
    'seerVision',
    'foxSniff',
    'guardProtect',
    'werewolfVictim',
    'littleGirlSpy',
    'bigBadWolfVictim',
    'infectiousWolfInfect',
    'whiteWerewolfVictim',
    'witchHeal',
    'piperCharm',
    'ravenCurse',
  ];

  static List<NightCardSpec> build({
    required GameSnapshot snapshot,
    required int nightNumber,
    required Set<String> usedOncePerGameActionIds,
    String? lastGuardedPlayerId,

    /// What has already been recorded tonight. Only the roll call of the
    /// charmed depends on it: it has to count the names the Piper gave a
    /// minute ago, which are not on the board until the night is resolved.
    List<NightAction> actions = const [],
  }) {
    final aliveRoles = snapshot.aliveRoleIds;
    final cards = <NightCardSpec>[];

    for (final typeId in order) {
      final type = NightActionTypes.byId(typeId);
      if (type.id == NightActionTypes.unknown.id) continue;
      if (type.firstNightOnly && nightNumber != 1) continue;

      final roleId = type.roleId;
      if (roleId != null && !aliveRoles.contains(roleId)) continue;

      // The White Werewolf only feeds every other night.
      if (typeId == NightActionTypes.whiteWerewolfVictim.id &&
          nightNumber.isOdd) {
        continue;
      }

      if (typeId == NightActionTypes.witchHeal.id) {
        final healUsed = usedOncePerGameActionIds.contains(
          NightActionTypes.witchHeal.id,
        );
        final poisonUsed = usedOncePerGameActionIds.contains(
          NightActionTypes.witchPoison.id,
        );
        if (healUsed && poisonUsed) continue;
        cards.add(_witchCard(healUsed: healUsed, poisonUsed: poisonUsed));
        continue;
      }

      if (type.oncePerGame && usedOncePerGameActionIds.contains(type.id)) {
        continue;
      }

      cards.add(
        _cardFor(
          type,
          lastGuardedPlayerId: lastGuardedPlayerId,
          snapshot: snapshot,
        ),
      );

      // The rulebook asks for a ritual right after the Piper designates: every
      // charmed player — tonight's and every night before — opens their eyes
      // together and recognises the others. It is not a choice, so it is not
      // an action; it is a step the narrator must not skip, so it is a card.
      if (typeId == NightActionTypes.piperCharm.id) {
        final charmed = charmedSoFar(snapshot: snapshot, actions: actions);
        if (charmed.isNotEmpty) {
          cards.add(_charmedRollCallCard(charmed));
        }
      }
    }

    cards.add(
      const NightCardSpec(
        id: NightCardSpec.summaryId,
        kind: NightCardKind.summary,
        title: 'Bilan de la nuit',
        prompt: 'Voici ce qui s\'est passé pendant que le village dormait.',
        emoji: '🌅',
      ),
    );
    return cards;
  }

  /// Everybody under the Piper's spell at this point of the night: the board's
  /// own charmed players — the charm is never lifted — plus the names given on
  /// tonight's card, which only reach the board when the night is resolved.
  /// Dead players are left out: they cannot open their eyes.
  static Set<String> charmedSoFar({
    required GameSnapshot snapshot,
    required List<NightAction> actions,
  }) {
    final tonight = <String>{};
    for (final action in actions) {
      if (action.type.effect != ActionEffect.charm) continue;
      final first = action.targetPlayerId;
      final second = action.secondaryTargetPlayerId;
      if (first != null) tonight.add(first);
      if (second != null) tonight.add(second);
    }

    return {
      for (final player in snapshot.alivePlayers)
        if (player.isCharmed || tonight.contains(player.id)) player.id,
    };
  }

  static NightCardSpec _charmedRollCallCard(Set<String> charmed) {
    return NightCardSpec(
      id: NightCardSpec.charmedRollCallId,
      kind: NightCardKind.charmedRollCall,
      title: 'Les charmés se reconnaissent',
      prompt:
          'Fais ouvrir les yeux à tous les joueurs charmés — les anciens '
          'comme ceux de cette nuit — pour qu\'ils se reconnaissent entre eux, '
          'puis rendors-les.',
      emoji: '🎶',
      role: Roles.piper,
      listedPlayerIds: charmed,
    );
  }

  static NightCardSpec _witchCard({
    required bool healUsed,
    required bool poisonUsed,
  }) {
    return NightCardSpec(
      id: NightActionTypes.witchHeal.id,
      kind: NightCardKind.witch,
      title: Roles.witch.label,
      prompt: 'La Sorcière ouvre les yeux. Que fait-elle ?',
      emoji: Roles.witch.emoji,
      type: NightActionTypes.witchHeal,
      secondaryType: NightActionTypes.witchPoison,
      role: Roles.witch,
      hint: [
        if (healUsed) 'Potion de vie déjà utilisée',
        if (poisonUsed) 'Potion de mort déjà utilisée',
      ].join(' · '),
    );
  }

  static NightCardSpec _cardFor(
    NightActionType type, {
    required GameSnapshot snapshot,
    String? lastGuardedPlayerId,
  }) {
    final role = type.role;
    final title = role?.label ?? type.label;

    NightCardKind kind;
    var scope = NightTargetScope.aliveOthers;
    var excluded = <String>{};
    String? hint;

    switch (type.id) {
      case 'werewolfVictim':
      case 'bigBadWolfVictim':
        kind = NightCardKind.singleTarget;
        scope = NightTargetScope.aliveNonWolves;
      case 'whiteWerewolfVictim':
        kind = NightCardKind.singleTarget;
        scope = NightTargetScope.aliveWolves;
      case 'infectiousWolfInfect':
        kind = NightCardKind.singleTarget;
        scope = NightTargetScope.aliveNonWolves;
        hint = 'Une seule fois par partie : la victime survit en loup.';
      case 'seerVision':
        kind = NightCardKind.reveal;
      case 'guardProtect':
        kind = NightCardKind.singleTarget;
        scope = NightTargetScope.alive;
        if (lastGuardedPlayerId != null) {
          excluded = {lastGuardedPlayerId};
          hint =
              'Le Salvateur ne peut pas protéger deux nuits de suite le même '
              'joueur.';
        }
      case 'cupidCouple':
        kind = NightCardKind.dualTarget;
        scope = NightTargetScope.alive;
      case 'piperCharm':
        kind = NightCardKind.dualTarget;
        scope = NightTargetScope.aliveOthers;
        // A charm is never lifted, so re-charming somebody would be a wasted
        // night — and the narrator, seeing the name offered again, could think
        // the spell had worn off. Already-charmed players simply leave the
        // list.
        excluded = {
          for (final player in snapshot.players)
            if (player.isCharmed) player.id,
        };
        if (excluded.isNotEmpty) {
          hint =
              'Les joueurs déjà charmés ne sont plus proposés : le charme '
              'reste jusqu\'à la fin de la partie.';
        }
      case 'foxSniff':
      case 'ravenCurse':
        kind = NightCardKind.targetWithNote;
      case 'wildChildModel':
        kind = NightCardKind.singleTarget;
      case 'thiefSwap':
      case 'sistersRecognition':
      case 'brothersRecognition':
      case 'littleGirlSpy':
        kind = NightCardKind.confirm;
      default:
        kind = type.requiresSecondaryTarget
            ? NightCardKind.dualTarget
            : type.requiresTarget
            ? NightCardKind.singleTarget
            : NightCardKind.confirm;
    }

    return NightCardSpec(
      id: type.id,
      kind: kind,
      title: title,
      prompt: type.prompt,
      emoji: type.emoji,
      type: type,
      role: role,
      scope: scope,
      excludedPlayerIds: excluded,
      hint: hint,
    );
  }

  /// The players a card may target, given the board and what the pack already
  /// chose tonight.
  static List<Player> candidates({
    required NightCardSpec spec,
    required GameSnapshot snapshot,
  }) {
    final roleId = spec.role?.id;
    return snapshot.alivePlayers.where((player) {
      if (spec.excludedPlayerIds.contains(player.id)) return false;
      return switch (spec.scope) {
        NightTargetScope.alive => true,
        NightTargetScope.aliveOthers => roleId == null || player.roleId != roleId,
        NightTargetScope.aliveNonWolves => !player.role.wolfSide,
        NightTargetScope.aliveWolves =>
          player.role.wolfSide && player.roleId != Roles.whiteWerewolf.id,
      };
    }).toList(growable: false);
  }

  /// The player the pack chose tonight, if the card was already validated —
  /// the only one the witch's life potion may save.
  static String? werewolfVictimOf(List<NightAction> actions) {
    for (final action in actions) {
      if (action.typeId == NightActionTypes.werewolfVictim.id) {
        return action.targetPlayerId;
      }
    }
    return null;
  }
}
