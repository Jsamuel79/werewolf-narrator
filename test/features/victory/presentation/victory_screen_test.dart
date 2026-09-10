import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:uuid/uuid.dart';
import 'package:werewolf_narrator/core/database/app_database.dart';
import 'package:werewolf_narrator/core/providers/core_providers.dart';
import 'package:werewolf_narrator/features/games/data/games_repository_impl.dart';
import 'package:werewolf_narrator/features/games/domain/game_entities.dart';
import 'package:werewolf_narrator/features/games/domain/games_repository.dart';
import 'package:werewolf_narrator/features/games/presentation/game_detail_screen.dart';
import 'package:werewolf_narrator/features/victory/presentation/victory_screen.dart';

void main() {
  late AppDatabase db;
  late DriftGamesRepository games;
  late GameSnapshot snapshot;

  setUpAll(() => initializeDateFormatting('fr_FR'));

  setUp(() async {
    db = AppDatabase.memory();
    games = DriftGamesRepository(database: db, uuid: const Uuid());
    final game = await games.createGame(
      name: 'Partie test',
      players: const [
        PlayerDraft(name: 'Alice', roleId: 'villager'),
        PlayerDraft(name: 'Bob', roleId: 'seer'),
        PlayerDraft(name: 'Loup', roleId: 'werewolf'),
      ],
    );
    snapshot = (await games.loadGame(game.id))!;
  });

  tearDown(() => db.close());

  Future<void> disposeTree(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  }

  Widget wrap(Widget child) => ProviderScope(
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

  Future<void> killTheWolf() async {
    final wolf = snapshot.players.firstWhere((p) => p.name == 'Loup');
    await games.savePlayers([
      wolf.copyWith(isAlive: false, deathCause: 'Éliminé par le vote'),
    ]);
  }

  testWidgets('names the winning camp and lists the survivors', (tester) async {
    await killTheWolf();

    await tester.pumpWidget(wrap(VictoryScreen(gameId: snapshot.game.id)));
    await tester.pumpAndSettle();

    expect(find.text('Le Village l\'emporte'), findsOneWidget);
    expect(find.textContaining('dernier Loup-Garou'), findsOneWidget);
    expect(find.text('Survivants'), findsOneWidget);
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);
    expect(find.text('Éliminés (1)'), findsOneWidget);
    // The two buttons sit at the bottom of a lazy ListView.
    await tester.scrollUntilVisible(
      find.text('Nouvelle partie'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Voir l\'historique complet'), findsOneWidget);
    expect(find.text('Nouvelle partie'), findsOneWidget);

    await disposeTree(tester);
  });

  testWidgets('a finished game no longer offers to open a night', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(GameDetailScreen(gameId: snapshot.game.id)));
    await tester.pumpAndSettle();
    expect(find.text('Nouvelle nuit'), findsOneWidget);

    await killTheWolf();
    await tester.pumpAndSettle();

    expect(find.text('Nouvelle nuit'), findsNothing);
    expect(find.text('Le Village l\'emporte'), findsOneWidget);

    await disposeTree(tester);
  });
}
