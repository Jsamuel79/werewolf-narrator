import '../../games/domain/role.dart';

/// When in a round the narrator records the action.
enum ActionPhase {
  night('Nuit'),
  day('Jour'),
  any('À tout moment');

  const ActionPhase(this.label);

  final String label;
}

/// What the resolver does with the action once the night is closed.
enum ActionEffect {
  /// Kills the target unless [NightActionType.protectable] and protected.
  kill,

  /// Cancels protectable kills aimed at the target this round.
  protect,

  /// Ties the two targets together as lovers.
  couple,

  /// Marks the target as charmed by the Piper.
  charm,

  /// Turns the target into a werewolf and spares them this round.
  infect,

  /// Changes the actor's own role (Thief, devoted Servant).
  roleChange,

  /// Records information for the narrator without changing the board.
  reveal,

  /// Elects the target as captain.
  captain,

  /// Free-form note.
  note,
}

/// One kind of thing that can be recorded during a round.
class NightActionType {
  const NightActionType({
    required this.id,
    required this.label,
    required this.prompt,
    required this.emoji,
    required this.effect,
    this.roleId,
    this.phase = ActionPhase.night,
    this.requiresTarget = true,
    this.requiresSecondaryTarget = false,
    this.firstNightOnly = false,
    this.oncePerGame = false,
    this.protectable = false,
    this.deathCause,
    this.detailLabel,
    this.secondaryTargetLabel,
  });

  final String id;
  final String label;

  /// What the narrator is being asked, in their own words.
  final String prompt;
  final String emoji;
  final ActionEffect effect;

  /// Role that unlocks this action; `null` means it is always available.
  final String? roleId;
  final ActionPhase phase;
  final bool requiresTarget;
  final bool requiresSecondaryTarget;
  final bool firstNightOnly;

  /// Offered only if it has not already been used earlier in the game.
  final bool oncePerGame;

  /// Whether [ActionEffect.protect] can cancel this kill.
  final bool protectable;

  /// Wording used in the history when this action kills someone.
  final String? deathCause;

  /// Label of the optional free-text detail (role seen, answer given, ...).
  final String? detailLabel;

  final String? secondaryTargetLabel;

  RoleDefinition? get role => roleId == null ? null : Roles.byId(roleId!);
}

abstract final class NightActionTypes {
  static const NightActionType werewolfVictim = NightActionType(
    id: 'werewolfVictim',
    label: 'Victime des Loups-Garous',
    prompt: 'Qui la meute dévore-t-elle cette nuit ?',
    emoji: '🐺',
    effect: ActionEffect.kill,
    roleId: 'werewolf',
    protectable: true,
    deathCause: 'Dévoré par les Loups-Garous',
  );

  static const NightActionType bigBadWolfVictim = NightActionType(
    id: 'bigBadWolfVictim',
    label: 'Seconde victime du Grand Méchant Loup',
    prompt: 'Qui le Grand Méchant Loup dévore-t-il en plus ?',
    emoji: '🐺',
    effect: ActionEffect.kill,
    roleId: 'bigBadWolf',
    protectable: true,
    deathCause: 'Dévoré par le Grand Méchant Loup',
  );

  static const NightActionType whiteWerewolfVictim = NightActionType(
    id: 'whiteWerewolfVictim',
    label: 'Victime du Loup-Garou Blanc',
    prompt: 'Quel loup le Loup-Garou Blanc dévore-t-il ?',
    emoji: '🌕',
    effect: ActionEffect.kill,
    roleId: 'whiteWerewolf',
    protectable: true,
    deathCause: 'Dévoré par le Loup-Garou Blanc',
  );

  static const NightActionType witchHeal = NightActionType(
    id: 'witchHeal',
    label: 'Potion de vie',
    prompt: 'La Sorcière sauve-t-elle quelqu\'un ?',
    emoji: '💚',
    effect: ActionEffect.protect,
    roleId: 'witch',
    oncePerGame: true,
  );

  static const NightActionType witchPoison = NightActionType(
    id: 'witchPoison',
    label: 'Potion de mort',
    prompt: 'La Sorcière empoisonne-t-elle quelqu\'un ?',
    emoji: '☠️',
    effect: ActionEffect.kill,
    roleId: 'witch',
    oncePerGame: true,
    deathCause: 'Empoisonné par la Sorcière',
  );

  static const NightActionType seerVision = NightActionType(
    id: 'seerVision',
    label: 'Vision de la Voyante',
    prompt: 'De quel joueur la Voyante découvre-t-elle le rôle ?',
    emoji: '🔮',
    effect: ActionEffect.reveal,
    roleId: 'seer',
    detailLabel: 'Rôle découvert',
  );

  static const NightActionType guardProtect = NightActionType(
    id: 'guardProtect',
    label: 'Protection du Salvateur',
    prompt: 'Qui le Salvateur protège-t-il cette nuit ?',
    emoji: '🛡️',
    effect: ActionEffect.protect,
    roleId: 'guard',
  );

  static const NightActionType cupidCouple = NightActionType(
    id: 'cupidCouple',
    label: 'Création du couple',
    prompt: 'Quels deux joueurs Cupidon rend-il amoureux ?',
    emoji: '💘',
    effect: ActionEffect.couple,
    roleId: 'cupid',
    requiresSecondaryTarget: true,
    firstNightOnly: true,
    secondaryTargetLabel: 'Second amoureux',
  );

  static const NightActionType littleGirlSpy = NightActionType(
    id: 'littleGirlSpy',
    label: 'Espionnage de la Petite Fille',
    prompt: 'La Petite Fille a-t-elle espionné ? Qui a-t-elle entrevu ?',
    emoji: '👧',
    effect: ActionEffect.note,
    roleId: 'littleGirl',
    requiresTarget: false,
    detailLabel: 'Ce qu\'elle a vu',
  );

  static const NightActionType thiefSwap = NightActionType(
    id: 'thiefSwap',
    label: 'Échange du Voleur',
    prompt: 'Le Voleur prend-il une des deux cartes du milieu ?',
    emoji: '🎭',
    effect: ActionEffect.roleChange,
    roleId: 'thief',
    requiresTarget: false,
    firstNightOnly: true,
    detailLabel: 'Nouveau rôle',
  );

  static const NightActionType foxSniff = NightActionType(
    id: 'foxSniff',
    label: 'Flair du Renard',
    prompt: 'Quel groupe de trois joueurs le Renard flaire-t-il ?',
    emoji: '🦊',
    effect: ActionEffect.reveal,
    roleId: 'fox',
    detailLabel: 'Réponse donnée',
  );

  static const NightActionType wildChildModel = NightActionType(
    id: 'wildChildModel',
    label: "Modèle de l'Enfant sauvage",
    prompt: "Qui l'Enfant sauvage choisit-il comme modèle ?",
    emoji: '🧒',
    effect: ActionEffect.note,
    roleId: 'wildChild',
    firstNightOnly: true,
  );

  static const NightActionType piperCharm = NightActionType(
    id: 'piperCharm',
    label: 'Charme du Joueur de Flûte',
    prompt: 'Quels joueurs le Joueur de Flûte charme-t-il ?',
    emoji: '🎶',
    effect: ActionEffect.charm,
    roleId: 'piper',
    requiresSecondaryTarget: true,
    secondaryTargetLabel: 'Second joueur charmé',
  );

  static const NightActionType ravenCurse = NightActionType(
    id: 'ravenCurse',
    label: 'Rancune du Corbeau',
    prompt: 'Sur qui le Corbeau pose-t-il ses deux voix ?',
    emoji: '🐦‍⬛',
    effect: ActionEffect.note,
    roleId: 'ravenAccuser',
  );

  static const NightActionType infectiousWolfInfect = NightActionType(
    id: 'infectiousWolfInfect',
    label: 'Infection',
    prompt: "L'Infect Père des Loups infecte-t-il la victime ?",
    emoji: '🩸',
    effect: ActionEffect.infect,
    roleId: 'infectiousWolf',
    oncePerGame: true,
  );

  static const NightActionType sistersRecognition = NightActionType(
    id: 'sistersRecognition',
    label: 'Réveil des Sœurs',
    prompt: 'Les Deux Sœurs se sont-elles reconnues ?',
    emoji: '👭',
    effect: ActionEffect.note,
    roleId: 'twoSisters',
    requiresTarget: false,
    firstNightOnly: true,
  );

  static const NightActionType brothersRecognition = NightActionType(
    id: 'brothersRecognition',
    label: 'Réveil des Frères',
    prompt: 'Les Trois Frères se sont-ils reconnus ?',
    emoji: '👬',
    effect: ActionEffect.note,
    roleId: 'threeBrothers',
    requiresTarget: false,
    firstNightOnly: true,
  );

  static const NightActionType captainElection = NightActionType(
    id: 'captainElection',
    label: 'Élection du Capitaine',
    prompt: 'Qui le village élit-il Capitaine ?',
    emoji: '⭐',
    effect: ActionEffect.captain,
    phase: ActionPhase.day,
  );

  static const NightActionType villageVote = NightActionType(
    id: 'villageVote',
    label: 'Vote du village',
    prompt: 'Qui le village élimine-t-il ?',
    emoji: '🗳️',
    effect: ActionEffect.kill,
    phase: ActionPhase.day,
    deathCause: 'Éliminé par le vote du village',
    detailLabel: 'Détail du vote',
  );

  static const NightActionType hunterShot = NightActionType(
    id: 'hunterShot',
    label: 'Tir du Chasseur',
    prompt: 'Qui le Chasseur emporte-t-il avec lui ?',
    emoji: '🏹',
    effect: ActionEffect.kill,
    roleId: 'hunter',
    phase: ActionPhase.any,
    deathCause: 'Abattu par le Chasseur',
  );

  static const NightActionType customNote = NightActionType(
    id: 'customNote',
    label: 'Note libre',
    prompt: 'Note du narrateur',
    emoji: '📝',
    effect: ActionEffect.note,
    phase: ActionPhase.any,
    requiresTarget: false,
    detailLabel: 'Note',
  );

  /// Fallback so an old game recorded with a removed action still renders.
  static const NightActionType unknown = NightActionType(
    id: 'unknown',
    label: 'Action inconnue',
    prompt: '',
    emoji: '❔',
    effect: ActionEffect.note,
    phase: ActionPhase.any,
    requiresTarget: false,
  );

  static const List<NightActionType> all = [
    werewolfVictim,
    bigBadWolfVictim,
    whiteWerewolfVictim,
    infectiousWolfInfect,
    seerVision,
    witchHeal,
    witchPoison,
    guardProtect,
    cupidCouple,
    piperCharm,
    littleGirlSpy,
    thiefSwap,
    foxSniff,
    wildChildModel,
    ravenCurse,
    sistersRecognition,
    brothersRecognition,
    captainElection,
    villageVote,
    hunterShot,
    customNote,
  ];

  static final Map<String, NightActionType> _byId = {
    for (final type in all) type.id: type,
  };

  static NightActionType byId(String id) => _byId[id] ?? unknown;
}
