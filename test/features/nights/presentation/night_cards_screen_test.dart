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

  group('the witch reads the victim designated moments earlier', () {
    /// Designates [name] on the wolves' card, which is the second one.
    Future<void> feedThePack(WidgetTester tester, String name) async {
      await tester.tap(find.text('Passer'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, name).last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Valider').last);
      await tester.pumpAndSettle();
    }

    bool saveButtonIsEnabled(WidgetTester tester, String name) {
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Sauver $name').last,
      );
      return button.onPressed != null;
    }

    testWidgets('the life potion targets the victim of this very night', (
      tester,
    ) async {
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      await feedThePack(tester, 'Chloé');

      // We are now on the witch's card, in the same night, before any
      // resolution: nobody is dead yet, but the pack has chosen.
      expect(find.textContaining('La meute a désigné Chloé'), findsOneWidget);
      expect(find.text('Sauver Chloé'), findsOneWidget);
      expect(saveButtonIsEnabled(tester, 'Chloé'), isTrue);
      expect(
        (await games.loadGame(snapshot.game.id))!
            .players
            .firstWhere((p) => p.name == 'Chloé')
            .isAlive,
        isTrue,
        reason: 'the victim only dies when the night is resolved',
      );

      await disposeTree(tester);
    });

    testWidgets('the life potion survives a trip back and forth', (
      tester,
    ) async {
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      await feedThePack(tester, 'David');
      expect(find.text('Sauver David'), findsOneWidget);

      // Back to the wolves' card to check the answer, then forward again.
      await tester.tap(find.text('Précédent'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'David').last)
            .selected,
        isTrue,
        reason: 'going back must show what was recorded',
      );

      await tester.tap(find.text('Passer'));
      await tester.pumpAndSettle();

      expect(find.text('Sauver David'), findsOneWidget);
      expect(saveButtonIsEnabled(tester, 'David'), isTrue);

      await disposeTree(tester);
    });

    testWidgets('changing the victim changes who the witch may save', (
      tester,
    ) async {
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      await feedThePack(tester, 'Chloé');
      expect(find.text('Sauver Chloé'), findsOneWidget);

      await tester.tap(find.text('Précédent'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'David').last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Valider').last);
      await tester.pumpAndSettle();

      expect(find.text('Sauver David'), findsOneWidget);
      expect(find.text('Sauver Chloé'), findsNothing);
      // And the pack still has exactly one victim, not two.
      final stored = (await nights.loadNight(night.id))!.actions;
      expect(
        stored.where(
          (a) => a.typeId == NightActionTypes.werewolfVictim.id,
        ),
        hasLength(1),
      );

      await disposeTree(tester);
    });

    testWidgets('no victim means no life potion to offer', (tester) async {
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Passer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Passer'));
      await tester.pumpAndSettle();

      expect(find.text('Personne à sauver'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Personne à sauver').last,
            )
            .onPressed,
        isNull,
        reason: 'there is nobody to bring back',
      );

      await disposeTree(tester);
    });
  });

  testWidgets('the pack card recalls the passive powers in play', (
    tester,
  ) async {
    final david = snapshot.players.firstWhere((p) => p.name == 'David');
    await games.savePlayers([david.copyWith(roleId: 'ancient')]);

    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Passer'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('L\'Ancien survit à la première attaque'),
      findsOneWidget,
    );

    await disposeTree(tester);
  });

  testWidgets('a table without passive powers gets no reminder at all', (
    tester,
  ) async {
    // The seeded table is a seer, a witch, two villagers and a wolf: nothing
    // passive to remember.
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Passer'));
    await tester.pumpAndSettle();

    expect(find.textContaining('L\'Ancien'), findsNothing);
    expect(find.textContaining('Chevalier'), findsNothing);

    await disposeTree(tester);
  });

  /// Bug 3: the narrator wants to know what the Witch must not be told.
  ///
  /// The player around the table must never learn that the Guard already
  /// covered the victim — that is the rule, and it stays true. The narrator
  /// holding the phone is the one who decides whether to let it slip, so the
  /// information belongs on their screen, marked as theirs alone.
  group('what the narrator knows and the Witch does not', () {
    /// Swaps Alice's seer card for the Guard's, so the deck opens on him.
    Future<void> seatTheGuard() async {
      final alice = snapshot.players.firstWhere((p) => p.name == 'Alice');
      await games.savePlayers([alice.copyWith(roleId: Roles.guard.id)]);
      snapshot = (await games.loadGame(snapshot.game.id))!;
    }

    /// Answers the Guard's card, then the pack's.
    Future<void> playTheNight(
      WidgetTester tester, {
      required String protect,
      required String eat,
    }) async {
      await tester.tap(find.widgetWithText(ChoiceChip, protect).last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Valider').last);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ChoiceChip, eat).last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Valider').last);
      await tester.pumpAndSettle();
    }

    testWidgets('says the victim is already under the shield', (tester) async {
      await seatTheGuard();
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      await playTheNight(tester, protect: 'Chloé', eat: 'Chloé');

      expect(find.textContaining('Info narrateur'), findsOneWidget);
      expect(
        find.textContaining('Salvateur protège déjà Chloé'),
        findsOneWidget,
      );

      await disposeTree(tester);
    });

    testWidgets('leaves every button free to be pressed anyway', (
      tester,
    ) async {
      await seatTheGuard();
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      await playTheNight(tester, protect: 'Chloé', eat: 'Chloé');

      // An information, never a constraint: the narrator may still let the
      // Witch spend her potion on a victim who was never in danger.
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Sauver Chloé').last,
            )
            .onPressed,
        isNotNull,
      );

      await disposeTree(tester);
    });

    testWidgets('stays quiet when the shield covers somebody else', (
      tester,
    ) async {
      await seatTheGuard();
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      await playTheNight(tester, protect: 'David', eat: 'Chloé');

      expect(find.textContaining('Info narrateur'), findsNothing);
      expect(find.text('Sauver Chloé'), findsOneWidget);

      await disposeTree(tester);
    });

    testWidgets('stays quiet when no Guard is at the table', (tester) async {
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Passer'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Chloé').last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Valider').last);
      await tester.pumpAndSettle();

      expect(find.textContaining('Info narrateur'), findsNothing);

      await disposeTree(tester);
    });
  });


  /// Point 5: the ritual of the charmed, which the narrator has to run every
  /// night — and which the app never asked them to.
  group('the charmed recognise each other', () {
    /// Turns Alice into the Piper, so the deck carries his card.
    Future<void> seatThePiper() async {
      final alice = snapshot.players.firstWhere((p) => p.name == 'Alice');
      await games.savePlayers([alice.copyWith(roleId: Roles.piper.id)]);
      snapshot = (await games.loadGame(snapshot.game.id))!;
    }

    /// Answers the Piper's card, which is the third of the deck.
    Future<void> charm(
      WidgetTester tester,
      String first, [
      String? second,
    ]) async {
      // Both halves of the card list the same names, so each tap is scoped to
      // its own list. `.last` picks the card on top: the deck paints the next
      // one behind it.
      Future<void> pick(String key, String name) async {
        await tester.tap(
          find.descendant(
            of: find.byKey(ValueKey(key)).last,
            matching: find.widgetWithText(ChoiceChip, name),
          ),
        );
        await tester.pumpAndSettle();
      }

      await pick('primary-targets', first);
      if (second != null) await pick('secondary-targets', second);
      await tester.tap(find.widgetWithText(FilledButton, 'Valider').last);
      await tester.pumpAndSettle();
    }

    Future<void> skipTo(WidgetTester tester, int cards) async {
      for (var i = 0; i < cards; i++) {
        await tester.tap(find.text('Passer'));
        await tester.pumpAndSettle();
      }
    }

    testWidgets('no roll call before anybody is charmed', (tester) async {
      await seatThePiper();
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      // Pack, witch, Piper, recap — no ritual card in an empty night.
      expect(find.textContaining('Carte 1 sur 4'), findsOneWidget);
      expect(find.text('Les charmés se reconnaissent'), findsNothing);

      await disposeTree(tester);
    });

    testWidgets('the ritual card follows the designation straight away', (
      tester,
    ) async {
      await seatThePiper();
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      await skipTo(tester, 2);
      await charm(tester, 'Chloé', 'David');

      expect(find.text('Les charmés se reconnaissent'), findsOneWidget);
      expect(
        find.textContaining('les anciens comme ceux de cette nuit'),
        findsOneWidget,
      );
      expect(find.textContaining('2 joueurs charmés'), findsOneWidget);
      // The deck grew by one card, and we are standing on it.
      expect(find.textContaining('Carte 4 sur 5'), findsOneWidget);

      await disposeTree(tester);
    });

    testWidgets('night two lists the old charmed alongside the new', (
      tester,
    ) async {
      await seatThePiper();

      // Night one, played through the repository: Chloé and David are charmed.
      await nights.addAction(
        nightId: night.id,
        typeId: NightActionTypes.piperCharm.id,
        actorPlayerId: idOf('Alice'),
        targetPlayerId: idOf('Chloé'),
        secondaryTargetPlayerId: idOf('David'),
      );
      await nights.resolveNight(night.id);
      await nights.resolveDay(night.id);
      night = await nights.startNight(snapshot.game.id);
      snapshot = (await games.loadGame(snapshot.game.id))!;

      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      await skipTo(tester, 2);
      // Only the wolf is left to charm — one name is enough.
      await charm(tester, 'Loup');

      expect(find.text('Les charmés se reconnaissent'), findsOneWidget);
      expect(find.textContaining('3 joueurs charmés'), findsOneWidget);
      for (final name in ['Chloé', 'David', 'Loup']) {
        expect(
          find.text(name),
          findsWidgets,
          reason: '$name was charmed and must be woken',
        );
      }

      await disposeTree(tester);
    });

    testWidgets('the roll call stands on its own, recording nothing', (
      tester,
    ) async {
      await seatThePiper();
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      await skipTo(tester, 2);
      await charm(tester, 'Chloé', 'David');
      await tester.tap(find.text('Ils se sont reconnus'));
      await tester.pumpAndSettle();

      expect(find.text('Bilan de la nuit'), findsOneWidget);
      // One action for the night: the charm itself.
      expect((await nights.loadNight(night.id))!.actions, hasLength(1));

      await disposeTree(tester);
    });
  });
}
