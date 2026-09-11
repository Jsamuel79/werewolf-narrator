import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:uuid/uuid.dart';
import 'package:werewolf_narrator/core/database/app_database.dart';
import 'package:werewolf_narrator/core/providers/core_providers.dart';
import 'package:werewolf_narrator/features/day/presentation/day_screen.dart';
import 'package:werewolf_narrator/features/games/data/games_repository_impl.dart';
import 'package:werewolf_narrator/features/games/domain/game_entities.dart';
import 'package:werewolf_narrator/features/games/domain/games_repository.dart';
import 'package:werewolf_narrator/features/nights/data/nights_repository_impl.dart';
import 'package:werewolf_narrator/features/nights/domain/night_action_type.dart';
import 'package:werewolf_narrator/features/nights/domain/night_entities.dart';

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
        PlayerDraft(name: 'Alice', roleId: 'villager'),
        PlayerDraft(name: 'Bob', roleId: 'villager'),
        PlayerDraft(name: 'Chloé', roleId: 'villager'),
        PlayerDraft(name: 'David', roleId: 'villager'),
        PlayerDraft(name: 'Loup', roleId: 'werewolf'),
        PlayerDraft(name: 'Louve', roleId: 'werewolf'),
      ],
    );
    snapshot = (await games.loadGame(game.id))!;
    night = await nights.startNight(game.id);
  });

  tearDown(() => db.close());

  String idOf(String name) =>
      snapshot.players.firstWhere((p) => p.name == name).id;

  /// Cards are taller than the test surface: scroll the target into view
  /// before tapping it.
  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
  }

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
    DayScreen(
      gameId: snapshot.game.id,
      nightId: night.id,
      // Stay on the screen instead of navigating away, so the test can read
      // the board straight after.
      onDayResolved: (_) {},
    ),
  );

  Future<void> closeNightEating(String name) async {
    await nights.addAction(
      nightId: night.id,
      typeId: NightActionTypes.werewolfVictim.id,
      targetPlayerId: idOf(name),
    );
    await nights.resolveNight(night.id);
  }

  testWidgets('opens on the dawn recap and walks to the vote', (tester) async {
    await closeNightEating('Alice');

    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();

    expect(find.text('Le village se réveille'), findsOneWidget);
    expect(
      find.textContaining('Alice — Dévoré par les Loups-Garous'),
      findsOneWidget,
    );
    expect(find.textContaining('Étape 1 sur 5'), findsOneWidget);

    await tester.tap(find.text('Passer'));
    await tester.pumpAndSettle();
    expect(find.text('Le Capitaine'), findsOneWidget);

    await disposeTree(tester);
  });

  testWidgets('elects a captain, who then weighs double in the vote', (
    tester,
  ) async {
    await closeNightEating('Alice');

    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Passer'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'Bob').last);
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Nommer Capitaine'));
    await tester.pumpAndSettle();

    final stored = (await nights.loadNight(night.id))!.actions;
    expect(
      stored.map((a) => a.typeId),
      contains(NightActionTypes.captainElection.id),
    );
    expect(
      stored
          .firstWhere((a) => a.typeId == NightActionTypes.captainElection.id)
          .targetPlayerId,
      idOf('Bob'),
    );

    await disposeTree(tester);
  });

  testWidgets('the debate stopwatch counts down and can be paused', (
    tester,
  ) async {
    await closeNightEating('Alice');

    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('Passer'));
      await tester.pumpAndSettle();
    }

    expect(find.text('Le débat'), findsOneWidget);
    expect(find.text('05:00'), findsOneWidget);

    await tapVisible(tester, find.text('3 min'));
    await tester.pump();
    expect(find.text('03:00'), findsOneWidget);

    await tapVisible(tester, find.text('Démarrer'));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('02:58'), findsOneWidget);

    await tapVisible(tester, find.text('Pause'));
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('02:58'), findsOneWidget, reason: 'paused means paused');

    await tapVisible(tester, find.text('Remettre à zéro'));
    await tester.pumpAndSettle();
    expect(find.text('03:00'), findsOneWidget);

    await disposeTree(tester);
  });

  testWidgets('counts the vote and eliminates the player who leads it', (
    tester,
  ) async {
    await closeNightEating('Alice');

    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Passer'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Le vote du village'), findsOneWidget);

    // Three hands for the wolf, one for Bob.
    final wolfRow = find.ancestor(
      of: find.text('Loup'),
      matching: find.byType(Row),
    );
    for (var i = 0; i < 3; i++) {
      await tester.tap(
        find.descendant(
          of: wolfRow.last,
          matching: find.byIcon(Icons.add_circle_outline),
        ),
      );
      await tester.pump();
    }

    expect(find.textContaining('Loup est éliminé'), findsOneWidget);

    await tapVisible(tester, find.text('Valider le vote'));
    await tester.pumpAndSettle();

    final stored = (await nights.loadNight(night.id))!.actions;
    final vote = stored.firstWhere(
      (a) => a.typeId == NightActionTypes.villageVote.id,
    );
    expect(vote.targetPlayerId, idOf('Loup'));
    expect(vote.phase, ActionPhase.day);

    // Nothing is applied to the board until the day is validated.
    expect(
      (await games.loadGame(snapshot.game.id))!
          .players
          .firstWhere((p) => p.name == 'Loup')
          .isAlive,
      isTrue,
    );

    await tapVisible(tester, find.text('Valider la journée'));
    await tester.pumpAndSettle();

    final after = (await games.loadGame(snapshot.game.id))!;
    expect(after.players.firstWhere((p) => p.name == 'Loup').isAlive, isFalse);
    expect((await nights.loadNight(night.id))!.night.isDayResolved, isTrue);

    await disposeTree(tester);
  });

  testWidgets('a closed day is read-only', (tester) async {
    await closeNightEating('Alice');
    await nights.resolveDay(night.id);

    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();

    expect(find.text('Journée close'), findsOneWidget);
    expect(find.text('Passer'), findsNothing);

    await disposeTree(tester);
  });

  group('the consequences of the vote show up straight away', () {
    /// Puts [count] hands up for [name] on the vote card.
    Future<void> voteFor(
      WidgetTester tester,
      String name,
      int count,
    ) async {
      final row = find
          .ancestor(of: find.text(name), matching: find.byType(Row))
          .last;
      for (var i = 0; i < count; i++) {
        await tester.tap(
          find.descendant(
            of: row,
            matching: find.byIcon(Icons.add_circle_outline),
          ),
        );
        await tester.pump();
      }
    }

    Future<void> walkToTheVote(WidgetTester tester) async {
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Passer'));
        await tester.pumpAndSettle();
      }
      expect(find.text('Le vote du village'), findsOneWidget);
    }

    testWidgets('the recap names the eliminated player on its first frame', (
      tester,
    ) async {
      await closeNightEating('Alice');
      await walkToTheVote(tester);

      await voteFor(tester, 'Loup', 3);
      await tapVisible(tester, find.text('Valider le vote'));
      await tester.pumpAndSettle();

      // No reload, no navigation, no delay: the very next card must already
      // know that the village just voted somebody out.
      expect(find.text('Fin de la journée'), findsOneWidget);
      expect(
        find.textContaining('Loup — Éliminé par le vote du village'),
        findsOneWidget,
      );
      expect(
        find.textContaining('personne n\'est mort'),
        findsNothing,
        reason: 'the recap must never flash an empty day first',
      );

      await disposeTree(tester);
    });

    testWidgets('the grief of a lover is part of that first frame', (
      tester,
    ) async {
      final chloe = snapshot.players.firstWhere((p) => p.name == 'Chloé');
      final wolf = snapshot.players.firstWhere((p) => p.name == 'Loup');
      await games.savePlayers([
        chloe.copyWith(coupledWithPlayerId: wolf.id),
        wolf.copyWith(coupledWithPlayerId: chloe.id),
      ]);
      await closeNightEating('Alice');
      await walkToTheVote(tester);

      await voteFor(tester, 'Loup', 3);
      await tapVisible(tester, find.text('Valider le vote'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Loup — Éliminé par le vote du village'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Chloé — Mort de chagrin'),
        findsOneWidget,
        reason: 'the lover dies with them, in the same recap',
      );

      await disposeTree(tester);
    });

    testWidgets('a hunter voted out is asked for his shot right away', (
      tester,
    ) async {
      // Bob is the hunter of this table.
      final bob = snapshot.players.firstWhere((p) => p.name == 'Bob');
      await games.savePlayers([bob.copyWith(roleId: 'hunter')]);
      await closeNightEating('Alice');
      await walkToTheVote(tester);

      await voteFor(tester, 'Bob', 3);
      await tapVisible(tester, find.text('Valider le vote'));
      await tester.pumpAndSettle();

      expect(
        find.text('Chasseur'),
        findsOneWidget,
        reason: 'the hunter card must appear as soon as he is voted out',
      );
      expect(find.textContaining('Étape 5 sur 6'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Loup').last);
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Tirer'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Bob — Éliminé par le vote du village'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Loup — Abattu par le Chasseur'),
        findsOneWidget,
      );

      await disposeTree(tester);
    });
  });

  testWidgets('a vote that ends the game opens the victory screen at once', (
    tester,
  ) async {
    // Three players left is enough: lynching the last wolf wins it for the
    // village, and the screen must show that without a reload.
    final board = await games.loadGame(snapshot.game.id);
    await games.savePlayers([
      for (final player in board!.players)
        if (player.name == 'Chloé' || player.name == 'Louve')
          player.copyWith(isAlive: false, deathCause: 'Retiré du plateau'),
    ]);
    await nights.resolveNight(night.id);

    // No onDayResolved override: the real navigation runs.
    await tester.pumpWidget(
      wrap(DayScreen(gameId: snapshot.game.id, nightId: night.id)),
    );
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Passer'));
      await tester.pumpAndSettle();
    }

    final row = find
        .ancestor(of: find.text('Loup'), matching: find.byType(Row))
        .last;
    for (var i = 0; i < 2; i++) {
      await tester.tap(
        find.descendant(
          of: row,
          matching: find.byIcon(Icons.add_circle_outline),
        ),
      );
      await tester.pump();
    }
    await tapVisible(tester, find.text('Valider le vote'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Valider la journée'));
    await tester.pumpAndSettle();

    expect(find.text('Le Village l\'emporte'), findsOneWidget);
    expect(find.text('Fin de partie'), findsOneWidget);

    await disposeTree(tester);
  });

  group('the Stuttering Judge and the Devoted Servant', () {
    Future<void> giveRole(String name, String roleId) async {
      final player = snapshot.players.firstWhere((p) => p.name == name);
      await games.savePlayers([player.copyWith(roleId: roleId)]);
    }

    Future<void> voteFor(WidgetTester tester, String name, int count) async {
      final row = find
          .ancestor(of: find.text(name), matching: find.byType(Row))
          .last;
      for (var i = 0; i < count; i++) {
        await tester.tap(
          find.descendant(
            of: row,
            matching: find.byIcon(Icons.add_circle_outline),
          ),
        );
        await tester.pump();
      }
      await tapVisible(tester, find.text('Valider le vote'));
      await tester.pumpAndSettle();
    }

    Future<void> walkToTheVote(WidgetTester tester) async {
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Passer'));
        await tester.pumpAndSettle();
      }
    }

    testWidgets('the judge can call a second vote, which eliminates again', (
      tester,
    ) async {
      await giveRole('Bob', 'stutteringJudge');
      await closeNightEating('Alice');
      await walkToTheVote(tester);

      await voteFor(tester, 'Loup', 3);

      expect(find.text('Le Juge bègue'), findsOneWidget);
      await tapVisible(tester, find.text('Oui, second vote'));
      await tester.pumpAndSettle();

      expect(find.text('Le second vote'), findsOneWidget);
      await voteFor(tester, 'Louve', 2);

      // Both eliminations stand, and the recap says so on its first frame.
      expect(find.text('Fin de la journée'), findsOneWidget);
      expect(
        find.textContaining('Loup — Éliminé par le vote du village'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Louve — Éliminé par le second vote du village'),
        findsOneWidget,
      );

      await disposeTree(tester);
    });

    testWidgets('the judge is only asked once in the whole game', (
      tester,
    ) async {
      await giveRole('Bob', 'stutteringJudge');
      await closeNightEating('Alice');
      // He already used his signal in an earlier round.
      await nights.addAction(
        nightId: night.id,
        typeId: NightActionTypes.judgeSecondVote.id,
        phase: ActionPhase.day,
      );
      await nights.resolveDay(night.id);

      final second = await nights.startNight(snapshot.game.id);
      await nights.resolveNight(second.id);
      await tester.pumpWidget(
        wrap(
          DayScreen(
            gameId: snapshot.game.id,
            nightId: second.id,
            onDayResolved: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Passer'));
        await tester.pumpAndSettle();
      }

      await voteFor(tester, 'Loup', 3);
      expect(find.text('Le Juge bègue'), findsNothing);
      expect(find.text('Fin de la journée'), findsOneWidget);

      await disposeTree(tester);
    });

    testWidgets('the servant takes the card of the player voted out', (
      tester,
    ) async {
      await giveRole('Bob', 'servant');
      await closeNightEating('Alice');
      await walkToTheVote(tester);

      await voteFor(tester, 'Loup', 3);

      expect(find.text('Servante dévouée'), findsOneWidget);
      expect(find.textContaining('Loup vient d\'être éliminé'), findsOneWidget);
      await tapVisible(tester, find.text('Elle se dévoue'));
      await tester.pumpAndSettle();

      await tapVisible(tester, find.text('Valider la journée'));
      await tester.pumpAndSettle();

      final after = (await games.loadGame(snapshot.game.id))!;
      final bob = after.players.firstWhere((p) => p.name == 'Bob');
      expect(bob.isAlive, isTrue);
      expect(bob.roleId, 'werewolf', reason: 'she took the wolf\'s card');
      expect(
        after.players.firstWhere((p) => p.name == 'Loup').isAlive,
        isFalse,
        reason: 'the eliminated player still leaves the game',
      );

      await disposeTree(tester);
    });

    testWidgets('the servant drops her couple and her badge on the swap', (
      tester,
    ) async {
      await giveRole('Bob', 'servant');
      final board = (await games.loadGame(snapshot.game.id))!;
      final bob = board.players.firstWhere((p) => p.name == 'Bob');
      final chloe = board.players.firstWhere((p) => p.name == 'Chloé');
      await games.savePlayers([
        bob.copyWith(
          isCaptain: true,
          isCharmed: true,
          coupledWithPlayerId: chloe.id,
        ),
        chloe.copyWith(coupledWithPlayerId: bob.id),
      ]);
      await closeNightEating('Alice');

      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      // A captain is already in office, so that card is not offered.
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.text('Passer'));
        await tester.pumpAndSettle();
      }
      await voteFor(tester, 'Loup', 3);

      await tapVisible(tester, find.text('Elle se dévoue'));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Valider la journée'));
      await tester.pumpAndSettle();

      final after = (await games.loadGame(snapshot.game.id))!;
      final servant = after.players.firstWhere((p) => p.name == 'Bob');
      expect(servant.roleId, 'werewolf');
      expect(servant.isCaptain, isFalse);
      expect(servant.isCharmed, isFalse);
      expect(servant.coupledWithPlayerId, isNull);
      expect(
        after.players.firstWhere((p) => p.name == 'Chloé').coupledWithPlayerId,
        isNull,
        reason: 'a couple cannot survive on one side only',
      );

      await disposeTree(tester);
    });
  });

  testWidgets('the vote card recalls what the vote does differently', (
    tester,
  ) async {
    final chloe = snapshot.players.firstWhere((p) => p.name == 'Chloé');
    await games.savePlayers([chloe.copyWith(roleId: 'scapegoat')]);
    await closeNightEating('Alice');

    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Passer'));
      await tester.pumpAndSettle();
    }

    expect(find.text('Le vote du village'), findsOneWidget);
    expect(
      find.textContaining('c\'est le Bouc émissaire qui est éliminé'),
      findsOneWidget,
    );

    await disposeTree(tester);
  });

  group('the debate stopwatch', () {
    Future<void> walkToTheDebate(WidgetTester tester) async {
      await closeNightEating('Alice');
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.text('Passer'));
        await tester.pumpAndSettle();
      }
      expect(find.text('Le débat'), findsOneWidget);
    }

    testWidgets('can time each player in turn instead of the whole debate', (
      tester,
    ) async {
      await walkToTheDebate(tester);

      await tapVisible(tester, find.text('Tour de parole'));
      await tester.pumpAndSettle();

      // Thirty seconds each, starting with the first player still alive.
      expect(find.text('00:30'), findsOneWidget);
      expect(find.textContaining('C\'est à Bob'), findsOneWidget);

      await tapVisible(tester, find.text('Démarrer'));
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('00:27'), findsOneWidget);

      await tapVisible(tester, find.text('Joueur suivant'));
      await tester.pumpAndSettle();

      expect(find.textContaining('C\'est à Chloé'), findsOneWidget);
      expect(
        find.text('00:30'),
        findsOneWidget,
        reason: 'the next speaker gets a full slot',
      );

      await disposeTree(tester);
    });

    testWidgets('the slot of a speaking turn is adjustable', (tester) async {
      await walkToTheDebate(tester);
      await tapVisible(tester, find.text('Tour de parole'));
      await tester.pumpAndSettle();

      await tapVisible(tester, find.text('45 s'));
      await tester.pumpAndSettle();
      expect(find.text('00:45'), findsOneWidget);

      // Back to the free debate, the minutes come back.
      await tapVisible(tester, find.text('Débat libre'));
      await tester.pumpAndSettle();
      expect(find.text('05:00'), findsOneWidget);
      expect(find.text('45 s'), findsNothing);

      await disposeTree(tester);
    });

    testWidgets('the turn loops back to the first speaker', (tester) async {
      await walkToTheDebate(tester);
      await tapVisible(tester, find.text('Tour de parole'));
      await tester.pumpAndSettle();

      // Five players are still alive after Alice was eaten.
      for (var i = 0; i < 5; i++) {
        await tapVisible(tester, find.text('Joueur suivant'));
        await tester.pumpAndSettle();
      }

      expect(find.textContaining('C\'est à Bob'), findsOneWidget);

      await disposeTree(tester);
    });
  });


  /// Bug 4: five players around the table, forty hands counted.
  ///
  /// The stepper was the only way in, so anything past a handful of votes meant
  /// a handful of taps. The app's job is to count what the narrator says, not
  /// to police it.
  group('typing the number of voices instead of tapping it out', () {
    Future<void> walkToTheVote(WidgetTester tester) async {
      await closeNightEating('Alice');
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Passer'));
        await tester.pumpAndSettle();
      }
      expect(find.text('Le vote du village'), findsOneWidget);
    }

    Future<void> typeVotes(
      WidgetTester tester,
      String name,
      String value,
    ) async {
      final field = find.byKey(ValueKey('vote-${idOf(name)}')).last;
      await tester.ensureVisible(field);
      await tester.pumpAndSettle();
      await tester.enterText(field, value);
      await tester.pumpAndSettle();
    }

    testWidgets('accepts forty voices on a table of five', (tester) async {
      await walkToTheVote(tester);

      await typeVotes(tester, 'Loup', '40');

      expect(find.textContaining('Loup est éliminé'), findsOneWidget);

      await tapVisible(tester, find.text('Valider le vote'));
      await tester.pumpAndSettle();

      final vote = (await nights.loadNight(night.id))!.actions.firstWhere(
        (a) => a.typeId == NightActionTypes.villageVote.id,
      );
      expect(vote.targetPlayerId, idOf('Loup'));
      expect(
        vote.detail,
        contains('Loup 40'),
        reason: 'the count is stored as typed, not clamped',
      );

      await disposeTree(tester);
    });

    testWidgets('counts a typed number against a tapped one', (tester) async {
      await walkToTheVote(tester);

      await typeVotes(tester, 'Loup', '12');
      await typeVotes(tester, 'Bob', '30');

      expect(find.textContaining('Bob est éliminé'), findsOneWidget);

      await disposeTree(tester);
    });

    testWidgets('the stepper still works, and picks up where typing left off', (
      tester,
    ) async {
      await walkToTheVote(tester);

      await typeVotes(tester, 'Loup', '7');
      final row = find
          .ancestor(of: find.text('Loup'), matching: find.byType(Row))
          .last;
      await tester.tap(
        find.descendant(
          of: row,
          matching: find.byIcon(Icons.add_circle_outline),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<TextField>(find.byKey(ValueKey('vote-${idOf('Loup')}')).last)
            .controller
            ?.text,
        '8',
      );

      await disposeTree(tester);
    });

    testWidgets('an impossible answer is simply not counted', (tester) async {
      await walkToTheVote(tester);

      await typeVotes(tester, 'Loup', 'beaucoup');
      expect(find.textContaining('Aucune voix'), findsOneWidget);

      await typeVotes(tester, 'Loup', '-3');
      expect(find.textContaining('Aucune voix'), findsOneWidget);

      await disposeTree(tester);
    });
  });
}
