import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';

/// The encrypted database, opened during startup and injected through an
/// override on [ProviderScope]. Reading it without that override is a bug.
final Provider<AppDatabase> appDatabaseProvider = Provider<AppDatabase>(
  (ref) => throw StateError(
    'appDatabaseProvider must be overridden with an open AppDatabase.',
  ),
);

final Provider<Uuid> uuidProvider = Provider<Uuid>((ref) => const Uuid());

/// Injected rather than called directly so tests can freeze time.
final Provider<DateTime Function()> clockProvider =
    Provider<DateTime Function()>((ref) => DateTime.now);
