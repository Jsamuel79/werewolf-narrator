import 'package:flutter/material.dart';

import '../../domain/narrator_hints.dart';

/// The narrator's own margin notes, visually apart from everything they read
/// out loud.
///
/// Deliberately not styled like the rest of the card: a dashed-looking border,
/// a mask icon and an explicit banner, so a narrator glancing down mid-sentence
/// can never mistake it for the prompt.
class NarratorHintBand extends StatelessWidget {
  const NarratorHintBand({required this.hints, super.key});

  final List<NarratorHint> hints;

  @override
  Widget build(BuildContext context) {
    if (hints.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final accent = theme.colorScheme.tertiary;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.visibility_off_outlined, size: 14, color: accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  NarratorHints.banner,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          for (final hint in hints)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(hint.emoji, style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hint.text,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
