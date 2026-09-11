import 'game_entities.dart';
import 'role.dart';

/// A rule the app cannot apply on its own, surfaced at the moment it matters.
///
/// Some powers of the catalogue are passive: nobody wakes up, nothing is
/// recorded, and the narrator simply has to remember them at the right second —
/// the Ancient shrugging off the first attack, the Knight's rusty sword, the
/// bear that growls at dawn. Printing them on the card that raises the question
/// is the whole point.
class PassiveReminder {
  const PassiveReminder({
    required this.roleId,
    required this.emoji,
    required this.text,
  });

  final String roleId;
  final String emoji;
  final String text;

  RoleDefinition get role => Roles.byId(roleId);
}

/// Which reminders belong on which card.
///
/// Pure and stateless: a reminder never claims to know what already happened,
/// it only says what the narrator has to keep in mind. Rules the engine *does*
/// apply (the Scapegoat, the Village Idiot) are worded as confirmations, so the
/// narrator knows they are handled and does not double-apply them.
abstract final class PassiveReminders {
  /// Reminders for the night card identified by [cardId] (an action type id).
  static List<PassiveReminder> forNightCard({
    required String cardId,
    required GameSnapshot snapshot,
  }) {
    if (cardId != 'werewolfVictim') return const [];

    return [
      if (_alive(snapshot, Roles.ancient.id))
        const PassiveReminder(
          roleId: 'ancient',
          emoji: '👴',
          text:
              'L\'Ancien survit à la première attaque des loups. Vérifiez '
              's\'ils l\'ont déjà visé cette partie.',
        ),
      if (_alive(snapshot, Roles.knight.id))
        const PassiveReminder(
          roleId: 'knight',
          emoji: '⚔️',
          text:
              'Si le Chevalier est dévoré, le premier Loup-Garou à sa gauche '
              'meurt la nuit suivante.',
        ),
    ];
  }

  /// Reminders for the day card identified by [cardId] (a `DayCardKind` name).
  static List<PassiveReminder> forDayCard({
    required String cardId,
    required GameSnapshot snapshot,
  }) {
    return switch (cardId) {
      'dawnRecap' => [
        if (_alive(snapshot, Roles.bearShowman.id))
          const PassiveReminder(
            roleId: 'bearShowman',
            emoji: '🐻',
            text:
                'L\'ours grogne au réveil si un voisin direct du Montreur '
                'd\'ours est un Loup-Garou.',
          ),
        if (_alive(snapshot, Roles.servant.id))
          const PassiveReminder(
            roleId: 'servant',
            emoji: '🙇',
            text:
                'La Servante dévouée pourra reprendre la carte du joueur '
                'éliminé par le vote, avant qu\'elle ne soit retournée.',
          ),
      ],
      'vote' || 'vote2' => [
        if (_alive(snapshot, Roles.villageIdiot.id))
          const PassiveReminder(
            roleId: 'villageIdiot',
            emoji: '🤡',
            text:
                'Désigné par le vote, l\'Idiot du Village est démasqué mais '
                'survit — une seule fois. L\'application s\'en charge.',
          ),
        if (_alive(snapshot, Roles.scapegoat.id))
          const PassiveReminder(
            roleId: 'scapegoat',
            emoji: '🐐',
            text:
                'En cas d\'égalité, c\'est le Bouc émissaire qui est éliminé. '
                'L\'application s\'en charge.',
          ),
        if (_alive(snapshot, Roles.ancient.id))
          const PassiveReminder(
            roleId: 'ancient',
            emoji: '👴',
            text:
                'Si le village élimine l\'Ancien, tous les villageois perdent '
                'leur pouvoir pour le reste de la partie.',
          ),
      ],
      _ => const [],
    };
  }

  static bool _alive(GameSnapshot snapshot, String roleId) =>
      snapshot.alivePlayers.any((player) => player.roleId == roleId);
}
