import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Games, Players, Nights, NightActions])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// Unencrypted in-memory database, for tests only.
  AppDatabase.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    beforeOpen: (OpeningDetails details) async {
      // Drift opens the database before running this, so the cascade deletes
      // declared on the tables only take effect once this pragma is set.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
