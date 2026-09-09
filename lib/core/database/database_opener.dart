import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../errors/app_exception.dart';
import 'app_database.dart';

const String databaseFileName = 'werewolf_narrator.db';

/// Opens the on-disk database, encrypted with SQLCipher (AES-256).
///
/// [hexKey] must be the 64-character key handed out by `DatabaseKeyStore`.
Future<AppDatabase> openEncryptedDatabase(String hexKey) async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, databaseFileName));
    return AppDatabase(encryptedExecutor(file, hexKey));
  } on AppException {
    rethrow;
  } on Object catch (error) {
    throw DatabaseException(
      'Impossible d\'ouvrir la base de données chiffrée.',
      cause: error,
    );
  }
}

/// Builds an executor for [file] encrypted with [hexKey].
///
/// Exposed separately from [openEncryptedDatabase] so tests can point it at a
/// temporary file without depending on platform channels.
QueryExecutor encryptedExecutor(File file, String hexKey) {
  return NativeDatabase.createInBackground(
    file,
    setup: (rawDb) {
      // `PRAGMA key` has to be the very first statement issued on the
      // connection, before SQLite reads a single page of the file.
      rawDb.execute('PRAGMA key = "x\'$hexKey\'";');
      // Forces SQLCipher to read the header now: with a wrong key this throws
      // here instead of failing later inside an unrelated query.
      rawDb.execute('SELECT count(*) FROM sqlite_master;');
    },
  );
}
