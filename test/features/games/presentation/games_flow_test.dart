import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:uuid/uuid.dart';
import 'package:werewolf_narrator/core/database/app_database.dart';
import 'package:werewolf_narrator/core/providers/core_providers.dart';
import 'package:werewolf_narrator/features/games/data/games_repository_impl.dart';
import 'package:werewolf_narrator/features/games/domain/games_repository.dart';
import 'package:werewolf_narrator/features/games/presentation/game_setup_screen.dart';
import 'package:werewolf_narrator/features/games/presentation/home_screen.dart';

void main() {
  late AppDatabase db;

  setUpAll(() => initializeDateFormatting('fr_FR'));

  setUp(() => db = AppDatabase.memory());
  tearDown(() => db.close());

  /// Tears the tree down inside the test body, then pumps once.
  ///
  /// Drift schedules a zero-duration timer when a query stream is cancelled;
  /// letting the framework dispose the tree during teardown would trip the
  /// "a Timer is still pending" invariant.
  Future<void> disposeTree(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  }

  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
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
  }

  Future<void> seedGame(String name) async {
    await DriftGamesRepository(database: db, uuid: const Uuid()).createGame(
      name: name,
      players: const [
        PlayerDraft(name: 'Alice', roleId: 'seer'),
        PlayerDraft(name: 'Bob', roleId: 'werewolf'),
        PlayerDraft(name: 'Chloé', roleId: 'villager'),
      ],
    );
  }

  group('HomeScreen', () {
    testWidgets('invites the narrator to create a game when empty', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(const HomeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Aucune partie en cours.'), findsOneWidget);
      expect(find.text('Nouvelle partie'), findsOneWidget);

      await disposeTree(tester);
    });

    testWidgets('lists stored games with their player count', (tester) async {
      await seedGame('Soirée du samedi');
      await tester.pumpWidget(wrap(const HomeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Soirée du samedi'), findsOneWidget);
      expect(find.textContaining('3 joueurs'), findsOneWidget);
      expect(find.textContaining('3 en vie'), findsOneWidget);

      await disposeTree(tester);
    });

    testWidgets('archived games appear in the second tab only', (
      tester,
    ) async {
      final repository = DriftGamesRepository(
        database: db,
        uuid: const Uuid(),
      );
      final game = await repository.createGame(
        name: 'Vieille partie',
        players: const [
          PlayerDraft(name: 'A', roleId: 'villager'),
          PlayerDraft(name: 'B', roleId: 'werewolf'),
          PlayerDraft(name: 'C', roleId: 'seer'),
        ],
      );
      await repository.setArchived(gameId: game.id, archived: true);

      await tester.pumpWidget(wrap(const HomeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Aucune partie en cours.'), findsOneWidget);

      await tester.tap(find.text('Archives'));
      await tester.pumpAndSettle();

      expect(find.text('Vieille partie'), findsOneWidget);

      await disposeTree(tester);
    });

    testWidgets('deleting a game asks for confirmation first', (tester) async {
      await seedGame('À supprimer');
      await tester.pumpWidget(wrap(const HomeScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Supprimer'));
      await tester.pumpAndSettle();

      expect(find.text('Supprimer la partie ?'), findsOneWidget);

      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(find.text('À supprimer'), findsOneWidget);

      await disposeTree(tester);
    });
  });

  group('GameSetupScreen', () {
    testWidgets('keeps the submit button disabled under three players', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(const GameSetupScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Au moins 3 joueurs'), findsOneWidget);

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);

      await disposeTree(tester);
    });

    testWidgets('creates a game once a name and three players are given', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(const GameSetupScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Nom de la partie'),
        'Partie test',
      );
      for (final name in ['Alice', 'Bob', 'Chloé']) {
        await tester.enterText(
          find.widgetWithText(TextField, 'Ajouter un joueur'),
          name,
        );
        await tester.tap(find.byIcon(Icons.add));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Lancer la partie'), findsOneWidget);

      await tester.tap(find.text('Lancer la partie'));
      await tester.pumpAndSettle();

      final stored = await db.select(db.games).get();
      expect(stored, hasLength(1));
      expect(stored.single.name, 'Partie test');
      expect(await db.select(db.players).get(), hasLength(3));

      await disposeTree(tester);
    });

    testWidgets('suggests a werewolf count for the table', (tester) async {
      await tester.pumpWidget(wrap(const GameSetupScreen()));
      await tester.pumpAndSettle();

      for (final name in ['A', 'B', 'C', 'D']) {
        await tester.enterText(
          find.widgetWithText(TextField, 'Ajouter un joueur'),
          name,
        );
        await tester.tap(find.byIcon(Icons.add));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      // Four villagers, no wolf yet: the hint nudges towards one.
      expect(find.textContaining('suggéré : 1'), findsOneWidget);

      await disposeTree(tester);
    });
  });
}
