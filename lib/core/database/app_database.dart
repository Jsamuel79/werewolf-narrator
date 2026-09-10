import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Games, Players, Nights, NightActions, GameRoleSelections],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// Unencrypted in-memory database, for tests only.
  AppDatabase.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    // Games recorded by an older build must survive an update: every step adds
    // to the schema, none recreates a table.
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        // v2 — remember which camp won a finished game.
        await m.addColumn(games, games.winnerCampId);
        await m.addColumn(games, games.winnerReason);
      }
      if (from < 3) {
        // v3 — the roles allowed for a given game.
        await m.createTable(gameRoleSelections);
      }
      if (from < 4) {
        // v4 — the day phase gets its own resolution, and every action says
        // which half of the round it belongs to.
        await m.addColumn(nights, nights.dayResolvedAt);
        await m.addColumn(nights, nights.daySummaryJson);
        await m.addColumn(nightActions, nightActions.phase);
        // A round closed by 1.0.0 covered the night *and* the vote of the day
        // that followed, so it is complete: mark its day as resolved too,
        // otherwise it would look like a round still waiting for its dawn.
        await customStatement(
          'UPDATE nights SET day_resolved_at = resolved_at '
          'WHERE resolved_at IS NOT NULL',
        );
      }
    },
    beforeOpen: (OpeningDetails details) async {
      // Drift opens the database before running this, so the cascade deletes
      // declared on the tables only take effect once this pragma is set.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
