import '../../games/domain/game_entities.dart';
import 'night_action_type.dart';
import 'night_entities.dart';
import 'night_sequence.dart';

/// One thing the narrator knows and the table must not hear.
///
/// The rulebook keeps players in the dark on purpose — the Witch never learns
/// that the Guard covered her victim, the second wolf never hears whom the pack
/// already chose. None of that applies to the narrator: they are holding every
/// card face up, and the app hiding it from them only makes them re-derive it
/// from memory. So the fact is printed, marked as theirs, and left as an
/// information: no button is ever disabled because of a hint.
class NarratorHint {
  const NarratorHint({
    required this.id,
    required this.text,
    this.emoji = '🛡️',
  });

  /// Stable key, handy in tests and for a future « don't show this again ».
  final String id;

  /// One sentence, written for the narrator's eyes only.
  final String text;

  final String emoji;
}

/// What the app can tell the narrator about the night already recorded.
///
/// Pure: it reads the actions of the current round and the board, and returns
/// sentences. Every rule below answers the same question — « does what the
/// narrator is about to record collide with something already recorded
/// tonight? » — which is why a new card only ever adds one `case`.
abstract final class NarratorHints {
  /// Header the band prints above the hints. Never part of a hint text, so a
  /// screen can look for one or the other.
  static const String banner = 'Info narrateur — à ne pas lire à voix haute';

  static List<NarratorHint> forNightCard({
    required String cardId,
    required List<NightAction> actions,
    required GameSnapshot snapshot,
  }) {
    final victim = snapshot.playerById(
      NightSequenceBuilder.werewolfVictimOf(actions),
    );
    final shielded =
        victim != null && _protectedIds(actions).contains(victim.id);

    return switch (cardId) {
      'witchHeal' => [
        if (shielded)
          NarratorHint(
            id: 'witchHealRedundant',
            text:
                'Le Salvateur protège déjà ${victim.name} : la potion de vie '
                'ferait double emploi. La Sorcière, elle, n\'est pas censée '
                'le savoir.',
          ),
      ],
      'bigBadWolfVictim' => [
        if (victim != null)
          NarratorHint(
            id: 'packAlreadyChose',
            emoji: '🐺',
            text:
                'La meute a déjà désigné ${victim.name} : le Grand Méchant '
                'Loup dévore une seconde victime, donc quelqu\'un d\'autre.',
          ),
      ],
      'infectiousWolfInfect' => [
        if (victim != null)
          NarratorHint(
            id: 'infectReplacesMeal',
            emoji: '🩸',
            text:
                'L\'infection remplace le repas de la meute : c\'est '
                '${victim.name} qui survivrait en loup.',
          ),
        if (shielded)
          NarratorHint(
            id: 'infectOnShielded',
            text:
                'Le Salvateur protège déjà ${victim.name} : elle ou il survit '
                'de toute façon, et le pouvoir serait dépensé pour rien.',
          ),
      ],
      _ => const [],
    };
  }

  static Set<String> _protectedIds(List<NightAction> actions) => {
    for (final action in actions)
      if (action.type.effect == ActionEffect.protect &&
          action.targetPlayerId != null)
        action.targetPlayerId!,
  };
}
