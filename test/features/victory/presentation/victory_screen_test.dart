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
import 'package:werewolf_narrator/features/victory/presentation/victory_screen.dart'
    show VictoryScreen, VictoryScreenTestHooks;

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
      find.text('Rejouer avec les mêmes joueurs'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Voir l\'historique complet'), findsOneWidget);
    expect(find.text('Rejouer avec les mêmes joueurs'), findsOneWidget);
    expect(find.text('Nouvelle partie, nouveaux joueurs'), findsOneWidget);

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

  testWidgets('replays with the same table without touching the old game', (
    tester,
  ) async {
    // The composition played tonight is the starting point of the replay.
    await games.saveComposition(
      gameId: snapshot.game.id,
      roleIds: const {'villager', 'werewolf', 'seer', 'witch'},
    );
    await killTheWolf();

    await tester.pumpWidget(wrap(VictoryScreen(gameId: snapshot.game.id)));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Rejouer avec les mêmes joueurs'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rejouer avec les mêmes joueurs'));
    await tester.pumpAndSettle();

    // The setup screen opens with the same players and a fresh name.
    expect(find.text('Nouvelle partie'), findsOneWidget);
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);
    expect(find.text('Loup'), findsOneWidget);
    expect(find.text('Composition (4)'), findsOneWidget);

    await tester.tap(find.text('Lancer la partie'));
    await tester.pumpAndSettle();

    final stored = await db.select(db.games).get();
    expect(stored, hasLength(2), reason: 'the finished game is kept');
    final replay = stored.firstWhere((g) => g.id != snapshot.game.id);
    expect(replay.name, 'Partie test (2)');
    expect(replay.status, 'inProgress');
    expect(replay.winnerCampId, isNull);

    // Everybody starts alive again, in a game of their own.
    final players = await db.select(db.players).get();
    final replayed = players.where((p) => p.gameId == replay.id);
    expect(replayed, hasLength(3));
    expect(replayed.every((p) => p.isAlive), isTrue);
    expect(replayed.every((p) => !p.isCaptain), isTrue);
    expect(replayed.every((p) => p.deathCause == null), isTrue);

    final composition = await db.select(db.gameRoleSelections).get();
    expect(
      composition.where((row) => row.gameId == replay.id).map((r) => r.roleId),
      containsAll(<String>['villager', 'werewolf', 'seer', 'witch']),
    );

    await disposeTree(tester);
  });

  test('a replay name counts up rather than piling up suffixes', () {
    expect(VictoryScreenTestHooks.nextGameName('Soirée'), 'Soirée (2)');
    expect(VictoryScreenTestHooks.nextGameName('Soirée (2)'), 'Soirée (3)');
    expect(VictoryScreenTestHooks.nextGameName('Soirée (9)'), 'Soirée (10)');
  });
}
