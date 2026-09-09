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
import 'package:werewolf_narrator/features/history/presentation/history_screen.dart';
import 'package:werewolf_narrator/features/nights/data/nights_repository_impl.dart';
import 'package:werewolf_narrator/features/nights/domain/night_action_type.dart';

void main() {
  late AppDatabase db;
  late DriftGamesRepository games;
  late DriftNightsRepository nights;
  late Game game;
  late GameSnapshot snapshot;

  setUpAll(() => initializeDateFormatting('fr_FR'));

  setUp(() async {
    db = AppDatabase.memory();
    games = DriftGamesRepository(database: db, uuid: const Uuid());
    nights = DriftNightsRepository(database: db, uuid: const Uuid());
    game = await games.createGame(
      name: 'Partie du samedi',
      players: const [
        PlayerDraft(name: 'Alice', roleId: 'villager'),
        PlayerDraft(name: 'Bob', roleId: 'werewolf'),
        PlayerDraft(name: 'Chloé', roleId: 'seer'),
      ],
    );
    snapshot = (await games.loadGame(game.id))!;
  });

  tearDown(() => db.close());

  String idOf(String name) =>
      snapshot.players.firstWhere((p) => p.name == name).id;

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

  testWidgets('says so when no night has been played', (tester) async {
    await tester.pumpWidget(wrap(HistoryScreen(gameId: game.id)));
    await tester.pumpAndSettle();

    expect(find.text('Aucune nuit jouée pour l\'instant.'), findsOneWidget);

    await disposeTree(tester);
  });

  testWidgets('lays out every round with its actions and recap', (
    tester,
  ) async {
    final first = await nights.startNight(game.id);
    await nights.addAction(
      nightId: first.id,
      typeId: NightActionTypes.seerVision.id,
      actorPlayerId: idOf('Chloé'),
      targetPlayerId: idOf('Bob'),
      details: const {'text': 'Loup-Garou'},
    );
    await nights.addAction(
      nightId: first.id,
      typeId: NightActionTypes.werewolfVictim.id,
      targetPlayerId: idOf('Alice'),
    );
    await nights.resolveNight(first.id);

    final second = await nights.startNight(game.id);
    await nights.addAction(
      nightId: second.id,
      typeId: NightActionTypes.villageVote.id,
      targetPlayerId: idOf('Bob'),
    );
    await nights.resolveNight(second.id);

    await tester.pumpWidget(wrap(HistoryScreen(gameId: game.id)));
    await tester.pumpAndSettle();

    expect(find.text('Partie du samedi'), findsOneWidget);
    expect(find.textContaining('2 tours'), findsOneWidget);
    expect(find.text('Nuit 1'), findsOneWidget);
    expect(find.text('Nuit 2'), findsOneWidget);
    // The action line is a RichText: label plus a smaller detail span.
    // Once in the action list of the round, once in its recap notes.
    expect(
      find.textContaining(NightActionTypes.seerVision.label,
          findRichText: true),
      findsNWidgets(2),
    );
    expect(
      find.textContaining('Loup-Garou', findRichText: true),
      findsWidgets,
    );
    expect(
      find.textContaining('Alice — Dévoré par les Loups-Garous'),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.text('État final des joueurs'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Alice — Villageois'), findsOneWidget);
    expect(find.textContaining('† tour 1'), findsOneWidget);
    expect(find.textContaining('† tour 2'), findsOneWidget);
    expect(find.text('En vie'), findsOneWidget);

    await disposeTree(tester);
  });
}
