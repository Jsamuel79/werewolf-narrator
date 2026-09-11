import '../../games/domain/game_entities.dart';
import '../../games/domain/role.dart';
import 'victory_entities.dart';

/// The board, pre-digested for the victory rules.
class VictoryContext {
  VictoryContext(this.players)
    : survivors = players.where((p) => p.isAlive).toList(growable: false);

  final List<Player> players;
  final List<Player> survivors;

  /// Everyone who hunts with the pack — includes the White Werewolf.
  List<Player> get wolves =>
      survivors.where((p) => p.role.wolfSide).toList(growable: false);

  /// Survivors the wolves still have to eat.
  List<Player> get nonWolves =>
      survivors.where((p) => !p.role.wolfSide).toList(growable: false);

  List<Player> get villagers => survivors
      .where((p) => p.role.team == RoleTeam.village)
      .toList(growable: false);

  Player? playerById(String? id) {
    if (id == null) return null;
    for (final player in players) {
      if (player.id == id) return player;
    }
    return null;
  }

  List<String> idsOf(Iterable<Player> players) =>
      players.map((p) => p.id).toList(growable: false);
}

/// One way a game can end.
///
/// Rules are objects rather than branches of a single `if` so a role with its
/// own win condition (a new solo role, a variant) is added by appending to
/// [VictoryEngine.rules] — nothing else moves.
abstract interface class VictoryRule {
  String get id;

  /// `null` when this rule has nothing to say about the current board.
  VictoryResult? evaluate(VictoryContext context);
}

/// Decides whether a game is over, and who won.
///
/// Pure: it takes the board and returns a verdict. The order of [rules] *is*
/// the rule of precedence — the mixed lovers beat both the village and the
/// wolves, which is why they are evaluated before them.
///
/// The Piper comes first of all. His tune is a win condition of its own, owed
/// to nobody: it can close the game on a board where the village has already
/// killed the last wolf, or where the pack has reached parity, and it holds
/// even when he is one half of a mixed couple.
abstract final class VictoryEngine {
  static const List<VictoryRule> rules = [
    _PiperRule(),
    _NobodyLeftRule(),
    _MixedLoversRule(),
    _AngelRule(),
    _SoloSurvivorRule(),
    _VillageRule(),
    _WerewolvesRule(),
    _LastStandingRule(),
  ];

  /// The first rule that fires, or `null` while the game is still on.
  static VictoryResult? evaluate(List<Player> players) {
    if (players.isEmpty) return null;
    final context = VictoryContext(players);
    for (final rule in rules) {
      final result = rule.evaluate(context);
      if (result != null) return result;
    }
    return null;
  }

  /// Convenience wrapper for the screens, which hold a snapshot.
  static VictoryResult? evaluateSnapshot(GameSnapshot snapshot) =>
      evaluate(snapshot.players);
}

/// Everyone is dead — the round wiped the table out.
class _NobodyLeftRule implements VictoryRule {
  const _NobodyLeftRule();

  @override
  String get id => 'nobodyLeft';

  @override
  VictoryResult? evaluate(VictoryContext context) {
    if (context.survivors.isNotEmpty) return null;
    return const VictoryResult(
      camp: VictoryCamp.nobody,
      reason: 'Plus personne n\'est en vie : la partie s\'arrête sans '
          'vainqueur.',
      ruleId: 'nobodyLeft',
    );
  }
}

/// Two lovers from different camps, alone at the table, win together.
class _MixedLoversRule implements VictoryRule {
  const _MixedLoversRule();

  @override
  String get id => 'mixedLovers';

  @override
  VictoryResult? evaluate(VictoryContext context) {
    if (context.survivors.length != 2) return null;
    final first = context.survivors[0];
    final second = context.survivors[1];
    if (first.coupledWithPlayerId != second.id) return null;
    if (second.coupledWithPlayerId != first.id) return null;
    if (first.role.team == second.role.team) return null;

    return VictoryResult(
      camp: VictoryCamp.lovers,
      reason:
          '${first.name} et ${second.name} sont les deux derniers survivants '
          'et forment un couple mixte : les Amoureux gagnent ensemble.',
      winnerPlayerIds: [first.id, second.id],
      ruleId: 'mixedLovers',
    );
  }
}

/// The Angel wins if the village gets rid of them in the very first round.
class _AngelRule implements VictoryRule {
  const _AngelRule();

  @override
  String get id => 'angel';

  @override
  VictoryResult? evaluate(VictoryContext context) {
    for (final player in context.players) {
      if (player.roleId != Roles.angel.id) continue;
      if (player.isAlive || player.deathNightNumber != 1) continue;
      return VictoryResult(
        camp: VictoryCamp.forSoloRole(Roles.angel),
        reason:
            '${player.name} était l\'Ange et a été éliminé dès le premier '
            'tour : il gagne seul.',
        winnerPlayerIds: [player.id],
        ruleId: 'angel',
      );
    }
    return null;
  }
}

/// The Piper wins once every other survivor is under their spell.
///
/// Three things this rule deliberately does *not* do:
///
/// * it never asks the Piper to be charmed himself — he is the one playing the
///   tune, and the card excludes him from his own targets;
/// * it never counts the dead: a charmed player who has been eaten takes his
///   charm to the grave, and the survivors alone decide;
/// * it never makes the Piper's death a condition for anybody else. He simply
///   stops being able to win, and the board goes back to Village against pack.
class _PiperRule implements VictoryRule {
  const _PiperRule();

  @override
  String get id => 'piper';

  @override
  VictoryResult? evaluate(VictoryContext context) {
    Player? piper;
    for (final player in context.survivors) {
      if (player.roleId == Roles.piper.id) piper = player;
    }
    if (piper == null) return null;
    final others = context.survivors
        .where((p) => p.id != piper!.id)
        .toList(growable: false);
    if (others.isEmpty || others.any((p) => !p.isCharmed)) return null;

    // Cupid's thread survives even a solo win: a Piper who is in love wins
    // *with* his lover rather than against them, which is the only reading
    // that does not make the two rules contradict each other.
    final lover = context.playerById(piper.coupledWithPlayerId);
    final sharesWithLover = lover != null && lover.isAlive;

    return VictoryResult(
      camp: VictoryCamp.forSoloRole(Roles.piper),
      reason: sharesWithLover
          ? 'Tous les survivants sont charmés : ${piper.name}, Joueur de '
                'Flûte, gagne — et emmène ${lover.name}, son amoureux, avec '
                'lui.'
          : 'Tous les survivants sont charmés : ${piper.name}, Joueur de '
                'Flûte, gagne seul.',
      winnerPlayerIds: [piper.id, if (sharesWithLover) lover.id],
      ruleId: 'piper',
    );
  }
}

/// A solo role left alone at the table wins by itself — the White Werewolf's
/// condition, and any future role that plays for nobody but themselves.
class _SoloSurvivorRule implements VictoryRule {
  const _SoloSurvivorRule();

  @override
  String get id => 'soloSurvivor';

  @override
  VictoryResult? evaluate(VictoryContext context) {
    if (context.survivors.length != 1) return null;
    final survivor = context.survivors.single;
    if (survivor.role.team != RoleTeam.solo) return null;

    return VictoryResult(
      camp: VictoryCamp.forSoloRole(survivor.role),
      reason:
          '${survivor.name} (${survivor.role.label}) est le dernier survivant '
          'et gagne seul.',
      winnerPlayerIds: [survivor.id],
      ruleId: 'soloSurvivor',
    );
  }
}

/// No wolf left alive — the village has won.
class _VillageRule implements VictoryRule {
  const _VillageRule();

  @override
  String get id => 'village';

  @override
  VictoryResult? evaluate(VictoryContext context) {
    if (context.wolves.isNotEmpty) return null;
    final villagers = context.villagers;
    if (villagers.isEmpty) return null;

    return VictoryResult(
      camp: VictoryCamp.village,
      reason: context.players.any((p) => p.role.wolfSide)
          ? 'Le dernier Loup-Garou a été éliminé : le Village gagne.'
          : 'Aucun Loup-Garou ne menace le village : le Village gagne.',
      winnerPlayerIds: context.idsOf(villagers),
      ruleId: 'village',
    );
  }
}

/// The wolves have caught up: they now equal or outnumber everyone else.
class _WerewolvesRule implements VictoryRule {
  const _WerewolvesRule();

  @override
  String get id => 'werewolves';

  @override
  VictoryResult? evaluate(VictoryContext context) {
    final wolves = context.wolves;
    if (wolves.isEmpty) return null;
    if (context.nonWolves.length > wolves.length) return null;

    return VictoryResult(
      camp: VictoryCamp.werewolves,
      reason:
          'Les Loups-Garous sont aussi nombreux que les autres survivants : '
          'le village ne peut plus renverser la situation.',
      winnerPlayerIds: context.idsOf(wolves),
      ruleId: 'werewolves',
    );
  }
}

/// Safety net so a game can never run forever: one survivor and no rule above
/// fired (a lone role with an exotic team) means that player takes the win.
class _LastStandingRule implements VictoryRule {
  const _LastStandingRule();

  @override
  String get id => 'lastStanding';

  @override
  VictoryResult? evaluate(VictoryContext context) {
    if (context.survivors.length != 1) return null;
    final survivor = context.survivors.single;

    return VictoryResult(
      camp: VictoryCamp.lastStanding,
      reason: '${survivor.name} est le seul survivant : la partie s\'arrête.',
      winnerPlayerIds: [survivor.id],
      ruleId: 'lastStanding',
    );
  }
}
