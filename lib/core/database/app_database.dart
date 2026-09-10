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
  int get schemaVersion => 3;

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
    },
    beforeOpen: (OpeningDetails details) async {
      // Drift opens the database before running this, so the cascade deletes
      // declared on the tables only take effect once this pragma is set.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
