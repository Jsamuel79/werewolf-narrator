import 'package:intl/intl.dart';

final DateFormat _dayFormat = DateFormat("d MMMM y 'à' HH:mm", 'fr_FR');
final DateFormat _shortDayFormat = DateFormat('d MMM y', 'fr_FR');
final DateFormat _timeFormat = DateFormat('HH:mm', 'fr_FR');

String formatDateTimeFr(DateTime value) => _dayFormat.format(value);

String formatDateFr(DateTime value) => _shortDayFormat.format(value);

String formatTimeFr(DateTime value) => _timeFormat.format(value);

/// `pluralFr(1, 'joueur')` → `1 joueur`, `pluralFr(3, 'joueur')` → `3 joueurs`.
String pluralFr(int count, String singular, {String? plural}) {
  if (count <= 1) return '$count $singular';
  return '$count ${plural ?? '${singular}s'}';
}
