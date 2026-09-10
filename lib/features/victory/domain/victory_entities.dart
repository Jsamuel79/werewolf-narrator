import '../../games/domain/role.dart';

/// Who is holding the win when a game ends.
///
/// The four fixed camps below cover the base game; a solo role that wins on its
/// own (White Werewolf, Piper, Angel, ...) gets a camp built from its own
/// [RoleDefinition], so adding such a role never means touching this class.
class VictoryCamp {
  const VictoryCamp({
    required this.id,
    required this.label,
    required this.emoji,
  });

  final String id;
  final String label;
  final String emoji;

  static const VictoryCamp village = VictoryCamp(
    id: 'village',
    label: 'Le Village',
    emoji: '🧑‍🌾',
  );

  static const VictoryCamp werewolves = VictoryCamp(
    id: 'werewolves',
    label: 'Les Loups-Garous',
    emoji: '🐺',
  );

  static const VictoryCamp lovers = VictoryCamp(
    id: 'lovers',
    label: 'Les Amoureux',
    emoji: '💘',
  );

  /// Everybody died at once — nobody is left to claim the win.
  static const VictoryCamp nobody = VictoryCamp(
    id: 'nobody',
    label: 'Personne',
    emoji: '🪦',
  );

  /// Safety net: a single survivor no other rule accounts for.
  static const VictoryCamp lastStanding = VictoryCamp(
    id: 'lastStanding',
    label: 'Le dernier survivant',
    emoji: '🏳️',
  );

  static const VictoryCamp unknown = VictoryCamp(
    id: 'unknown',
    label: 'Camp inconnu',
    emoji: '❓',
  );

  static const List<VictoryCamp> fixed = [
    village,
    werewolves,
    lovers,
    nobody,
    lastStanding,
  ];

  /// A camp made of one solo role, identified by that role's id.
  static VictoryCamp forSoloRole(RoleDefinition role) =>
      VictoryCamp(id: role.id, label: role.label, emoji: role.emoji);

  /// Rebuilds a camp from the id stored on the game row.
  static VictoryCamp byId(String? id) {
    if (id == null) return unknown;
    for (final camp in fixed) {
      if (camp.id == id) return camp;
    }
    final role = Roles.byId(id);
    return role.id == Roles.unknown.id ? unknown : forSoloRole(role);
  }

  @override
  bool operator ==(Object other) => other is VictoryCamp && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'VictoryCamp($id)';
}

/// The end of a game: who won, why, and which players are holding the win.
class VictoryResult {
  const VictoryResult({
    required this.camp,
    required this.reason,
    this.winnerPlayerIds = const [],
    this.ruleId = '',
  });

  final VictoryCamp camp;

  /// One sentence the narrator can read out loud.
  final String reason;

  /// Players credited with the win — the survivors of the winning camp.
  final List<String> winnerPlayerIds;

  /// Which rule fired, kept for tests and for the history.
  final String ruleId;
}
