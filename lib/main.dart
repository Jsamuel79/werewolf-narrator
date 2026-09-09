import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/database/database_opener.dart';
import 'core/errors/app_exception.dart';
import 'core/providers/core_providers.dart';
import 'core/security/key_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');

  try {
    // The key is created on first launch and lives only in the platform
    // keystore; losing it means the database can never be read again.
    final key = await SecureStorageKeyStore().readOrCreateKey();
    final database = await openEncryptedDatabase(key);

    runApp(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: const WerewolfNarratorApp(),
      ),
    );
  } on AppException catch (error) {
    runApp(StartupFailureApp(message: error.message));
  }
}
