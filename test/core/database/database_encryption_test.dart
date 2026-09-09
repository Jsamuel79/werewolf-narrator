import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:werewolf_narrator/core/database/app_database.dart';
import 'package:werewolf_narrator/core/database/database_opener.dart';

/// These tests assert the security promise of the app: the database file on
/// disk is unreadable without the key held in the platform keystore.
void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('werewolf_narrator_test');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  const key = 'a1b2c3d4e5f60718293a4b5c6d7e8f90'
      'a1b2c3d4e5f60718293a4b5c6d7e8f90';

  test('the SQLCipher build is the one bundled with the app', () {
    // The community SQLCipher build exposes `PRAGMA cipher_version`; the plain
    // SQLite build returns nothing for it.
    final db = sqlite3.openInMemory();
    addTearDown(db.dispose);
    final rows = db.select('PRAGMA cipher_version;');
    expect(
      rows,
      isNotEmpty,
      reason: 'pubspec must select `source: sqlcipher` for package:sqlite3',
    );
  });

  test('the database file is encrypted at rest', () async {
    final file = File(p.join(tempDir.path, 'encrypted.db'));
    final db = AppDatabase(encryptedExecutor(file, key));
    await db.customStatement(
      "INSERT INTO games (id, name, created_at, updated_at, status, "
      "is_archived) VALUES ('g1', 'CONFIDENTIAL_MARKER', 0, 0, 'setup', 0)",
    );
    await db.close();

    final bytes = await file.readAsBytes();
    final asText = String.fromCharCodes(bytes);

    expect(
      asText.startsWith('SQLite format 3'),
      isFalse,
      reason: 'a plaintext SQLite file starts with that magic header',
    );
    expect(
      asText.contains('CONFIDENTIAL_MARKER'),
      isFalse,
      reason: 'row content must not be readable in the raw file',
    );
  });

  test('a wrong key cannot open the database', () async {
    final file = File(p.join(tempDir.path, 'encrypted.db'));
    final db = AppDatabase(encryptedExecutor(file, key));
    await db.customStatement('SELECT 1');
    await db.close();

    final wrongKey = 'ff' * 32;
    final reopened = AppDatabase(encryptedExecutor(file, wrongKey));
    await expectLater(
      reopened.customStatement('SELECT count(*) FROM games'),
      throwsA(anything),
    );
  });

  test('the same key reopens the database and returns the data', () async {
    final file = File(p.join(tempDir.path, 'encrypted.db'));
    final db = AppDatabase(encryptedExecutor(file, key));
    await db.into(db.games).insert(
          GamesCompanion.insert(
            id: 'g1',
            name: 'Partie du samedi',
            createdAt: DateTime(2026, 1, 1),
            updatedAt: DateTime(2026, 1, 1),
            status: 'setup',
          ),
        );
    await db.close();

    final reopened = AppDatabase(encryptedExecutor(file, key));
    addTearDown(reopened.close);
    final games = await reopened.select(reopened.games).get();

    expect(games, hasLength(1));
    expect(games.single.name, 'Partie du samedi');
  });
}
