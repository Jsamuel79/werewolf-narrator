import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:werewolf_narrator/core/database/app_database.dart';
import 'package:werewolf_narrator/core/providers/core_providers.dart';
import 'package:werewolf_narrator/features/games/domain/game_composition.dart';
import 'package:werewolf_narrator/features/games/domain/role.dart';
import 'package:werewolf_narrator/features/games/presentation/composition_screen.dart';
import 'package:werewolf_narrator/features/games/presentation/game_setup_screen.dart';

void main() {
  late AppDatabase db;

  setUpAll(() => initializeDateFormatting('fr_FR'));
  setUp(() => db = AppDatabase.memory());
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

  Finder tileOf(RoleDefinition role) =>
      find.widgetWithText(CheckboxListTile, '${role.emoji} ${role.label}');

  testWidgets('the villager and the werewolf cannot be unticked', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        CompositionScreen(initialSelection: GameComposition.defaultRoleIds),
      ),
    );
    await tester.pumpAndSettle();

    final villager = tester.widget<CheckboxListTile>(tileOf(Roles.villager));
    expect(villager.value, isTrue);
    expect(villager.onChanged, isNull, reason: 'the tile must be locked');

    // The pack sits further down a lazy list.
    await tester.scrollUntilVisible(
      tileOf(Roles.werewolf),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    final wolf = tester.widget<CheckboxListTile>(tileOf(Roles.werewolf));
    expect(wolf.value, isTrue);
    expect(wolf.onChanged, isNull);

    await disposeTree(tester);
  });

  testWidgets('ticking a role returns it in the selection', (tester) async {
    Set<String>? result;
    await tester.pumpWidget(
      wrap(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await CompositionScreen.show(
                context,
                initialSelection: const {'villager', 'werewolf', 'seer'},
                playerCount: 8,
              );
            },
            child: const Text('ouvrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();

    // Untick the seer, tick the witch.
    await tester.tap(tileOf(Roles.seer));
    await tester.pump();
    await tester.tap(tileOf(Roles.witch));
    await tester.pump();

    await tester.tap(find.textContaining('Valider'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result, contains(Roles.witch.id));
    expect(result, isNot(contains(Roles.seer.id)));
    expect(result, containsAll(GameComposition.mandatoryRoleIds));

    await disposeTree(tester);
  });

  testWidgets('flags a role the table is too small for', (tester) async {
    await tester.pumpWidget(
      wrap(
        CompositionScreen(
          initialSelection: GameComposition.everything,
          playerCount: 5,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Table trop petite', findRichText: true),
      findsWidgets,
    );

    await disposeTree(tester);
  });

  testWidgets('the setup screen carries the chosen composition', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const GameSetupScreen()));
    await tester.pumpAndSettle();

    expect(
      find.text('Composition (${GameComposition.defaultRoleIds.length})'),
      findsOneWidget,
    );

    await tester.tap(find.textContaining('Composition ('));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tout'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Valider'));
    await tester.pumpAndSettle();

    expect(
      find.text('Composition (${GameComposition.everything.length})'),
      findsOneWidget,
    );

    await disposeTree(tester);
  });
}
