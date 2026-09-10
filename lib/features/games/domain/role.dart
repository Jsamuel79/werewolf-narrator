/// Which victory condition a role plays for.
enum RoleTeam {
  village('Village'),
  werewolves('Loups-Garous'),
  solo('Solitaire');

  const RoleTeam(this.label);

  final String label;
}

/// A role the narrator can deal to a player.
///
/// The catalogue below is plain code rather than data in the database: roles do
/// not change from one game to the next, and adding one must not require a
/// schema migration. `Players.roleId` is a free-form text column, so an unknown
/// id degrades to [Roles.unknown] instead of breaking an old game.
class RoleDefinition {
  const RoleDefinition({
    required this.id,
    required this.label,
    required this.description,
    required this.team,
    required this.emoji,
    this.actsAtNight = false,
    this.firstNightOnly = false,
    this.wolfSide = false,
    this.dealCopies = 1,
    this.minPlayers = 0,
  });

  final String id;
  final String label;

  /// One short sentence, shown under the role name when dealing cards.
  final String description;
  final RoleTeam team;
  final String emoji;

  /// Whether the narrator has something to ask this role during a night.
  final bool actsAtNight;

  /// Whether that night action only happens on the very first night.
  final bool firstNightOnly;

  /// Whether the role eats with the pack, whatever its [team].
  ///
  /// The White Werewolf plays for himself yet hunts with the wolves: the
  /// village only wins once he is dead too. Victory rules read this flag rather
  /// than testing role ids one by one.
  final bool wolfSide;

  /// How many copies the random dealer hands out when the role is in play.
  ///
  /// `0` means « as many as needed »: the Villager fills the empty seats and
  /// the Werewolf fills the pack. The Two Sisters need 2 copies and the Three
  /// Brothers 3 — they are pointless alone.
  final int dealCopies;

  /// Smallest table the random dealer will put this role on.
  ///
  /// A Cupid around four players makes the game unplayable; below the
  /// threshold the role stays available for a manual assignment, the dealer
  /// simply never picks it.
  final int minPlayers;

  /// A role dealt at most once — what the UI calls a « rôle unique ».
  bool get isUnique => dealCopies == 1;

  @override
  String toString() => 'RoleDefinition($id)';
}

abstract final class Roles {
  // --- Village -------------------------------------------------------------
  static const RoleDefinition villager = RoleDefinition(
    id: 'villager',
    label: 'Villageois',
    description: 'Aucun pouvoir. Doit démasquer les loups par le débat.',
    team: RoleTeam.village,
    emoji: '🧑‍🌾',
    dealCopies: 0,
  );

  static const RoleDefinition seer = RoleDefinition(
    id: 'seer',
    label: 'Voyante',
    description: "Chaque nuit, découvre le rôle d'un joueur.",
    team: RoleTeam.village,
    emoji: '🔮',
    actsAtNight: true,
    minPlayers: 4,
  );

  static const RoleDefinition witch = RoleDefinition(
    id: 'witch',
    label: 'Sorcière',
    description: 'Une potion de vie et une potion de mort, une fois chacune.',
    team: RoleTeam.village,
    emoji: '🧪',
    actsAtNight: true,
    minPlayers: 5,
  );

  static const RoleDefinition hunter = RoleDefinition(
    id: 'hunter',
    label: 'Chasseur',
    description: 'En mourant, élimine immédiatement un joueur de son choix.',
    team: RoleTeam.village,
    emoji: '🏹',
    minPlayers: 6,
  );

  static const RoleDefinition cupid = RoleDefinition(
    id: 'cupid',
    label: 'Cupidon',
    description: 'La première nuit, désigne deux amoureux.',
    team: RoleTeam.village,
    emoji: '💘',
    actsAtNight: true,
    firstNightOnly: true,
    minPlayers: 6,
  );

  static const RoleDefinition littleGirl = RoleDefinition(
    id: 'littleGirl',
    label: 'Petite Fille',
    description: 'Peut espionner les loups, à ses risques et périls.',
    team: RoleTeam.village,
    emoji: '👧',
    actsAtNight: true,
    minPlayers: 8,
  );

  static const RoleDefinition thief = RoleDefinition(
    id: 'thief',
    label: 'Voleur',
    description: 'La première nuit, peut échanger sa carte contre une autre.',
    team: RoleTeam.village,
    emoji: '🎭',
    actsAtNight: true,
    firstNightOnly: true,
    minPlayers: 9,
  );

  static const RoleDefinition guard = RoleDefinition(
    id: 'guard',
    label: 'Salvateur',
    description: 'Protège un joueur des loups, jamais deux nuits de suite.',
    team: RoleTeam.village,
    emoji: '🛡️',
    actsAtNight: true,
    minPlayers: 8,
  );

  static const RoleDefinition ancient = RoleDefinition(
    id: 'ancient',
    label: 'Ancien',
    description: 'Survit à la première attaque des Loups-Garous.',
    team: RoleTeam.village,
    emoji: '👴',
    minPlayers: 9,
  );

  static const RoleDefinition scapegoat = RoleDefinition(
    id: 'scapegoat',
    label: 'Bouc émissaire',
    description: "En cas d'égalité au vote, c'est lui qui est éliminé.",
    team: RoleTeam.village,
    emoji: '🐐',
    minPlayers: 10,
  );

  static const RoleDefinition villageIdiot = RoleDefinition(
    id: 'villageIdiot',
    label: 'Idiot du Village',
    description: 'Désigné par le vote, il survit mais perd son droit de vote.',
    team: RoleTeam.village,
    emoji: '🤡',
    minPlayers: 9,
  );

  static const RoleDefinition twoSisters = RoleDefinition(
    id: 'twoSisters',
    label: 'Deux Sœurs',
    description: 'Se reconnaissent la première nuit.',
    team: RoleTeam.village,
    emoji: '👭',
    actsAtNight: true,
    firstNightOnly: true,
    dealCopies: 2,
    minPlayers: 9,
  );

  static const RoleDefinition threeBrothers = RoleDefinition(
    id: 'threeBrothers',
    label: 'Trois Frères',
    description: 'Se reconnaissent la première nuit.',
    team: RoleTeam.village,
    emoji: '👬',
    actsAtNight: true,
    firstNightOnly: true,
    dealCopies: 3,
    minPlayers: 11,
  );

  static const RoleDefinition fox = RoleDefinition(
    id: 'fox',
    label: 'Renard',
    description: 'Flaire trois joueurs voisins : y a-t-il un loup parmi eux ?',
    team: RoleTeam.village,
    emoji: '🦊',
    actsAtNight: true,
    minPlayers: 9,
  );

  static const RoleDefinition knight = RoleDefinition(
    id: 'knight',
    label: 'Chevalier à l\'épée rouillée',
    description: 'Dévoré, il contamine le premier loup à sa gauche.',
    team: RoleTeam.village,
    emoji: '⚔️',
    minPlayers: 10,
  );

  static const RoleDefinition bearShowman = RoleDefinition(
    id: 'bearShowman',
    label: "Montreur d'ours",
    description: "L'ours grogne si un voisin direct est un Loup-Garou.",
    team: RoleTeam.village,
    emoji: '🐻',
    minPlayers: 10,
  );

  static const RoleDefinition stutteringJudge = RoleDefinition(
    id: 'stutteringJudge',
    label: 'Juge bègue',
    description: 'Peut provoquer un second vote, une fois dans la partie.',
    team: RoleTeam.village,
    emoji: '⚖️',
    minPlayers: 10,
  );

  static const RoleDefinition ravenAccuser = RoleDefinition(
    id: 'ravenAccuser',
    label: 'Corbeau',
    description: 'Désigne un joueur qui aura deux voix contre lui au vote.',
    team: RoleTeam.village,
    emoji: '🐦‍⬛',
    actsAtNight: true,
    minPlayers: 10,
  );

  static const RoleDefinition servant = RoleDefinition(
    id: 'servant',
    label: 'Servante dévouée',
    description: "Prend la place et le rôle d'un joueur qui vient de mourir.",
    team: RoleTeam.village,
    emoji: '🙇',
    minPlayers: 10,
  );

  static const RoleDefinition wildChild = RoleDefinition(
    id: 'wildChild',
    label: 'Enfant sauvage',
    description: 'Choisit un modèle ; si le modèle meurt, il devient loup.',
    team: RoleTeam.village,
    emoji: '🧒',
    actsAtNight: true,
    firstNightOnly: true,
    minPlayers: 9,
  );

  // --- Werewolves ----------------------------------------------------------
  static const RoleDefinition werewolf = RoleDefinition(
    id: 'werewolf',
    label: 'Loup-Garou',
    description: 'Chaque nuit, dévore une victime avec la meute.',
    team: RoleTeam.werewolves,
    emoji: '🐺',
    actsAtNight: true,
    wolfSide: true,
    dealCopies: 0,
  );

  static const RoleDefinition bigBadWolf = RoleDefinition(
    id: 'bigBadWolf',
    label: 'Grand Méchant Loup',
    description: 'Dévore une seconde victime tant qu\'aucun loup n\'est mort.',
    team: RoleTeam.werewolves,
    emoji: '🐺',
    actsAtNight: true,
    wolfSide: true,
    minPlayers: 10,
  );

  static const RoleDefinition infectiousWolf = RoleDefinition(
    id: 'infectiousWolf',
    label: 'Infect Père des Loups',
    description: 'Une fois par partie, infecte la victime au lieu de la tuer.',
    team: RoleTeam.werewolves,
    emoji: '🩸',
    actsAtNight: true,
    wolfSide: true,
    minPlayers: 12,
  );

  // --- Solo ----------------------------------------------------------------
  static const RoleDefinition whiteWerewolf = RoleDefinition(
    id: 'whiteWerewolf',
    label: 'Loup-Garou Blanc',
    description: 'Joue seul. Une nuit sur deux, dévore un autre loup.',
    team: RoleTeam.solo,
    emoji: '🌕',
    actsAtNight: true,
    wolfSide: true,
    minPlayers: 12,
  );

  static const RoleDefinition piper = RoleDefinition(
    id: 'piper',
    label: 'Joueur de Flûte',
    description: 'Charme deux joueurs par nuit. Gagne si tous sont charmés.',
    team: RoleTeam.solo,
    emoji: '🎶',
    actsAtNight: true,
    minPlayers: 12,
  );

  static const RoleDefinition angel = RoleDefinition(
    id: 'angel',
    label: 'Ange',
    description: "Gagne s'il est éliminé dès le premier tour de jeu.",
    team: RoleTeam.solo,
    emoji: '👼',
    minPlayers: 9,
  );

  /// Fallback for a role id that is not (or no longer) in the catalogue.
  static const RoleDefinition unknown = RoleDefinition(
    id: 'unknown',
    label: 'Rôle inconnu',
    description: 'Ce rôle ne fait plus partie du catalogue.',
    team: RoleTeam.village,
    emoji: '❓',
  );

  /// Every role offered when dealing cards, grouped by team.
  static const List<RoleDefinition> all = [
    werewolf,
    bigBadWolf,
    infectiousWolf,
    villager,
    seer,
    witch,
    hunter,
    cupid,
    guard,
    littleGirl,
    thief,
    ancient,
    scapegoat,
    villageIdiot,
    twoSisters,
    threeBrothers,
    fox,
    knight,
    bearShowman,
    stutteringJudge,
    ravenAccuser,
    servant,
    wildChild,
    whiteWerewolf,
    piper,
    angel,
  ];

  static final Map<String, RoleDefinition> _byId = {
    for (final role in all) role.id: role,
  };

  static RoleDefinition byId(String id) => _byId[id] ?? unknown;

  static List<RoleDefinition> byTeam(RoleTeam team) =>
      all.where((role) => role.team == team).toList(growable: false);
}
