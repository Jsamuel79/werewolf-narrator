import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/security/crypto_service.dart';
import '../../data/auto_backup_service.dart';
import '../../data/export_service.dart';

final Provider<CryptoService> cryptoServiceProvider = Provider<CryptoService>(
  (ref) => CryptoService(),
);

final Provider<ExportService> exportServiceProvider = Provider<ExportService>((
  ref,
) {
  return ExportService(
    database: ref.watch(appDatabaseProvider),
    crypto: ref.watch(cryptoServiceProvider),
    uuid: ref.watch(uuidProvider),
    clock: ref.watch(clockProvider),
  );
});

/// Where the automatic snapshots live: the app's own support directory, which
/// no other app and no file browser reaches on Android.
final Provider<Future<Directory> Function()> backupDirectoryProvider =
    Provider<Future<Directory> Function()>(
      (ref) => getApplicationSupportDirectory,
    );

/// `null` when the database key was not injected — no key, no snapshots.
final Provider<AutoBackupService?> autoBackupServiceProvider =
    Provider<AutoBackupService?>((ref) {
      final key = ref.watch(databaseKeyProvider);
      if (key == null) return null;
      return AutoBackupService(
        exportService: ref.watch(exportServiceProvider),
        crypto: ref.watch(cryptoServiceProvider),
        databaseKey: key,
        directory: ref.watch(backupDirectoryProvider),
        clock: ref.watch(clockProvider),
      );
    });

/// The snapshots currently on the device, newest first.
final FutureProvider<List<GameBackup>> gameBackupsProvider =
    FutureProvider<List<GameBackup>>((ref) async {
      final service = ref.watch(autoBackupServiceProvider);
      return service == null ? const [] : service.list();
    }, isAutoDispose: true);
