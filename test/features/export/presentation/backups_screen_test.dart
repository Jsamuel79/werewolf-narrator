import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:werewolf_narrator/core/database/app_database.dart';
import 'package:werewolf_narrator/core/providers/core_providers.dart';
import 'package:werewolf_narrator/features/export/data/auto_backup_service.dart';
import 'package:werewolf_narrator/features/export/presentation/backups_screen.dart';
import 'package:werewolf_narrator/features/export/presentation/controllers/export_providers.dart';

/// The screen is driven through `gameBackupsProvider` rather than through real
/// files: a widget test runs in a zone where `dart:io` futures are never
/// pumped, so listing actual snapshots here would hang forever. What the
/// service does with real files — writing, listing, restoring, refusing a
/// foreign key — is covered by
/// `test/features/export/data/auto_backup_service_test.dart`.
void main() {
  late AppDatabase db;

  setUpAll(() => initializeDateFormatting('fr_FR'));
  setUp(() => db = AppDatabase.memory());
  tearDown(() => db.close());

  Future<void> disposeTree(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  }

  Widget wrap(
    Widget child, {
    List<GameBackup>? backups,
    bool withKey = true,
  }) => ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      // A key is enough for the service to exist; nothing here ever reads or
      // writes a file, because the listing is injected and the delete is
      // cancelled.
      if (withKey) ...[
        databaseKeyProvider.overrideWithValue(
          Uint8List.fromList(List<int>.generate(32, (i) => i)),
        ),
        backupDirectoryProvider.overrideWithValue(
          () async => Directory.systemTemp,
        ),
      ],
      if (backups != null)
        gameBackupsProvider.overrideWith((ref) async => backups),
    ],
    child: MaterialApp(
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [Locale('fr', 'FR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: child,
    ),
  );

  GameBackup backup({
    String name = 'Soirée du samedi',
    int players = 8,
    int rounds = 3,
    bool finished = false,
  }) {
    return GameBackup(
      file: File('/tmp/${name.hashCode}.wnb'),
      gameName: name,
      savedAt: DateTime(2026, 9, 10, 22, 15),
      playerCount: players,
      roundCount: rounds,
      isFinished: finished,
    );
  }

  testWidgets('says so when nothing has been saved yet', (tester) async {
    await tester.pumpWidget(wrap(const BackupsScreen(), backups: const []));
    await tester.pump();

    expect(find.textContaining('Aucun instantané'), findsOneWidget);
    expect(
      find.textContaining('chiffré avec la clé de l\'appareil'),
      findsOneWidget,
    );

    await disposeTree(tester);
  });

  testWidgets('lists a snapshot with what it holds', (tester) async {
    await tester.pumpWidget(wrap(const BackupsScreen(), backups: [backup()]));
    await tester.pump();

    expect(find.text('Soirée du samedi'), findsOneWidget);
    expect(find.textContaining('8 joueurs'), findsOneWidget);
    expect(find.textContaining('3 tours'), findsOneWidget);
    expect(
      find.textContaining('celle qui est en cours n\'est jamais écrasée'),
      findsOneWidget,
    );

    await disposeTree(tester);
  });

  testWidgets('marks a game that already has its winner', (tester) async {
    await tester.pumpWidget(
      wrap(
        const BackupsScreen(),
        backups: [backup(name: 'Partie finie', finished: true)],
      ),
    );
    await tester.pump();

    expect(find.text('🏆'), findsOneWidget);

    await disposeTree(tester);
  });

  testWidgets('offers to restore or to delete each snapshot', (tester) async {
    await tester.pumpWidget(wrap(const BackupsScreen(), backups: [backup()]));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('Restaurer'), findsOneWidget);
    expect(find.text('Supprimer'), findsOneWidget);

    await disposeTree(tester);
  });

  testWidgets('deleting a snapshot asks for confirmation first', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const BackupsScreen(), backups: [backup()]));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();

    expect(find.text('Supprimer cet instantané ?'), findsOneWidget);
    expect(
      find.textContaining('La partie elle-même n\'est pas touchée'),
      findsOneWidget,
    );

    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(find.text('Soirée du samedi'), findsOneWidget);

    await disposeTree(tester);
  });

  testWidgets('without a device key, there is simply nothing to show', (
    tester,
  ) async {
    // No override at all: the real provider runs, finds no key, and stays
    // empty without ever touching the disk.
    await tester.pumpWidget(wrap(const BackupsScreen(), withKey: false));
    await tester.pump();

    expect(find.textContaining('Aucun instantané'), findsOneWidget);

    await disposeTree(tester);
  });
}
