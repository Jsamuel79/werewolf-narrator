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
import 'package:werewolf_narrator/features/games/domain/role.dart';
import 'package:werewolf_narrator/features/nights/data/nights_repository_impl.dart';
import 'package:werewolf_narrator/features/nights/domain/night_action_type.dart';
import 'package:werewolf_narrator/features/nights/domain/night_entities.dart';
import 'package:werewolf_narrator/features/nights/presentation/night_cards_screen.dart';

void main() {
  late AppDatabase db;
  late DriftGamesRepository games;
  late DriftNightsRepository nights;
  late GameSnapshot snapshot;
  late Night night;

  setUpAll(() => initializeDateFormatting('fr_FR'));

  setUp(() async {
    db = AppDatabase.memory();
    games = DriftGamesRepository(database: db, uuid: const Uuid());
    nights = DriftNightsRepository(database: db, uuid: const Uuid());
    final game = await games.createGame(
      name: 'Partie test',
      players: const [
        PlayerDraft(name: 'Alice', roleId: 'seer'),
        PlayerDraft(name: 'Bob', roleId: 'witch'),
        PlayerDraft(name: 'Chloé', roleId: 'villager'),
        PlayerDraft(name: 'David', roleId: 'villager'),
        PlayerDraft(name: 'Loup', roleId: 'werewolf'),
      ],
    );
    snapshot = (await games.loadGame(game.id))!;
    night = await nights.startNight(game.id);
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

  Widget screen() => wrap(
    NightCardsScreen(gameId: snapshot.game.id, nightId: night.id),
  );

  testWidgets('deals one card per living role, recap last', (tester) async {
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();

    // Seer, wolves, witch, recap.
    expect(find.textContaining('Carte 1 sur 4'), findsOneWidget);
    expect(find.text(Roles.seer.label), findsOneWidget);
    // Cupid is not at this table, so it never comes up.
    expect(find.text(Roles.cupid.label), findsNothing);

    await disposeTree(tester);
  });

  testWidgets('swiping left moves on without recording anything', (
    tester,
  ) async {
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();

    await tester.drag(find.text(Roles.seer.label), const Offset(-400, 0));
    await tester.pumpAndSettle();

    expect(find.textContaining('Carte 2 sur 4'), findsOneWidget);
    expect((await nights.loadNight(night.id))!.actions, isEmpty);

    await disposeTree(tester);
  });

  testWidgets('the « Passer » button moves on just like the swipe', (
    tester,
  ) async {
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Passer'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Carte 2 sur 4'), findsOneWidget);
    expect((await nights.loadNight(night.id))!.actions, isEmpty);

    await disposeTree(tester);
  });

  testWidgets('validating a card records the action and advances', (
    tester,
  ) async {
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();

    // The Seer looks at the wolf; the app reveals the role to the narrator.
    await tester.tap(find.widgetWithText(ChoiceChip, 'Loup'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Révéler le rôle'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Loup est Loup-Garou'), findsOneWidget);
    await tester.tap(find.text('Vu'));
    await tester.pumpAndSettle();

    final stored = (await nights.loadNight(night.id))!.actions;
    expect(stored, hasLength(1));
    expect(stored.single.typeId, NightActionTypes.seerVision.id);
    expect(stored.single.targetPlayerId, idOf('Loup'));
    expect(stored.single.detail, Roles.werewolf.label);
    expect(find.textContaining('Carte 2 sur 4'), findsOneWidget);

    await disposeTree(tester);
  });

  testWidgets('the narrator can go back to fix an answer', (tester) async {
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Passer'));
    await tester.pumpAndSettle();

    // Wolves' card: eat Chloé. The deck paints the next card behind the
    // current one, so the chip on top of the stack is the last match.
    await tester.tap(find.widgetWithText(ChoiceChip, 'Chloé').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Précédent'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Précédent'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Carte 1 sur 4'), findsOneWidget);
    expect(
      (await nights.loadNight(night.id))!.actions.single.typeId,
      NightActionTypes.werewolfVictim.id,
    );

    await disposeTree(tester);
  });

  testWidgets('the witch may only save the victim of the pack', (
    tester,
  ) async {
    await nights.addAction(
      nightId: night.id,
      typeId: NightActionTypes.werewolfVictim.id,
      targetPlayerId: idOf('Chloé'),
    );

    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Passer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Passer'));
    await tester.pumpAndSettle();

    expect(find.text('Sauver Chloé'), findsOneWidget);
    await tester.tap(find.text('Sauver Chloé'));
    await tester.pumpAndSettle();

    final stored = (await nights.loadNight(night.id))!.actions;
    expect(
      stored.map((a) => a.typeId),
      contains(NightActionTypes.witchHeal.id),
    );
    expect(
      stored
          .firstWhere((a) => a.typeId == NightActionTypes.witchHeal.id)
          .targetPlayerId,
      idOf('Chloé'),
      reason: 'the life potion revives the pack\'s victim, nobody else',
    );

    await disposeTree(tester);
  });

  testWidgets('the recap card closes the night and applies it', (tester) async {
    await nights.addAction(
      nightId: night.id,
      typeId: NightActionTypes.werewolfVictim.id,
      targetPlayerId: idOf('Chloé'),
    );

    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Passer'));
      await tester.pumpAndSettle();
    }

    expect(find.text('Bilan de la nuit'), findsOneWidget);
    expect(
      find.textContaining('Chloé — Dévoré par les Loups-Garous'),
      findsOneWidget,
    );

    await tester.tap(find.text('Valider et passer au jour'));
    await tester.pumpAndSettle();

    final after = (await games.loadGame(snapshot.game.id))!;
    expect(after.players.firstWhere((p) => p.name == 'Chloé').isAlive, isFalse);
    expect((await nights.loadNight(night.id))!.night.isResolved, isTrue);

    await disposeTree(tester);
  });

  testWidgets('a closed night is read-only', (tester) async {
    await nights.resolveNight(night.id);

    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();

    expect(find.text('Nuit close'), findsOneWidget);
    expect(find.text('Passer'), findsNothing);

    await disposeTree(tester);
  });
}
