import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/security/crypto_service.dart';
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
