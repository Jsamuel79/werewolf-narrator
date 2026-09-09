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
import 'package:werewolf_narrator/features/nights/data/nights_repository_impl.dart';
import 'package:werewolf_narrator/features/nights/domain/night_action_type.dart';
import 'package:werewolf_narrator/features/nights/domain/night_entities.dart';
import 'package:werewolf_narrator/features/nights/presentation/night_screen.dart';

void main() {
  late AppDatabase db;
  late DriftGamesRepository games;
  late DriftNightsRepository nights;
  late Game game;
  late GameSnapshot snapshot;
  late Night night;

  setUpAll(() => initializeDateFormatting('fr_FR'));

  setUp(() async {
    db = AppDatabase.memory();
    games = DriftGamesRepository(database: db, uuid: const Uuid());
    nights = DriftNightsRepository(database: db, uuid: const Uuid());
    game = await games.createGame(
      name: 'Partie test',
      players: const [
        PlayerDraft(name: 'Alice', roleId: 'villager'),
        PlayerDraft(name: 'Bob', roleId: 'werewolf'),
        PlayerDraft(name: 'Chloé', roleId: 'seer'),
      ],
    );
    snapshot = (await games.loadGame(game.id))!;
    night = await nights.startNight(game.id);
  });

  tearDown(() => db.close());

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

  Widget screen() => wrap(
    NightScreen(gameId: game.id, nightId: night.id),
  );

  testWidgets('offers only the actions of roles present at the table', (
    tester,
  ) async {
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();

    expect(find.text('🌙 Nuit 1'), findsOneWidget);
    expect(find.text(NightActionTypes.werewolfVictim.label), findsOneWidget);
    expect(find.text(NightActionTypes.seerVision.label), findsOneWidget);
    // Nobody plays the witch in this game.
    expect(find.text(NightActionTypes.witchHeal.label), findsNothing);
    // Cupid is a first-night role but nobody plays it either.
    expect(find.text(NightActionTypes.cupidCouple.label), findsNothing);

    await disposeTree(tester);
  });

  testWidgets('records an action entered through the dialog', (tester) async {
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();

    await tester.tap(find.text(NightActionTypes.werewolfVictim.label));
    await tester.pumpAndSettle();

    expect(find.text('Qui la meute dévore-t-elle cette nuit ?'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Alice').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    final stored = await nights.loadNight(night.id);
    expect(stored!.actions, hasLength(1));
    expect(stored.actions.single.typeId, NightActionTypes.werewolfVictim.id);
    expect(
      stored.actions.single.targetPlayerId,
      snapshot.players.firstWhere((p) => p.name == 'Alice').id,
    );

    await disposeTree(tester);
  });

  testWidgets('previews the outcome before the round is closed', (
    tester,
  ) async {
    await nights.addAction(
      nightId: night.id,
      typeId: NightActionTypes.werewolfVictim.id,
      targetPlayerId: snapshot.players.firstWhere((p) => p.name == 'Alice').id,
    );

    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();

    // The recap card sits at the bottom of a lazy ListView.
    await tester.scrollUntilVisible(
      find.text('Aperçu du bilan'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Aperçu du bilan'), findsOneWidget);
    expect(
      find.textContaining('Alice — Dévoré par les Loups-Garous'),
      findsOneWidget,
    );

    await disposeTree(tester);
  });

  testWidgets('closing the round applies it to the board', (tester) async {
    await nights.addAction(
      nightId: night.id,
      typeId: NightActionTypes.werewolfVictim.id,
      targetPlayerId: snapshot.players.firstWhere((p) => p.name == 'Alice').id,
    );

    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Clore la nuit et lever le jour'));
    await tester.pumpAndSettle();

    expect(find.text('Bilan de la nuit 1'), findsOneWidget);

    await tester.tap(find.text('Clore'));
    await tester.pumpAndSettle();

    final after = (await games.loadGame(game.id))!;
    expect(
      after.players.firstWhere((p) => p.name == 'Alice').isAlive,
      isFalse,
    );
    expect((await nights.loadNight(night.id))!.night.isResolved, isTrue);

    await disposeTree(tester);
  });

  testWidgets('a closed round is read-only', (tester) async {
    await nights.resolveNight(night.id);

    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();

    expect(find.text('Nuit close'), findsOneWidget);
    expect(find.text('Clore la nuit et lever le jour'), findsNothing);
    expect(find.text(NightActionTypes.werewolfVictim.label), findsNothing);

    await disposeTree(tester);
  });
}
