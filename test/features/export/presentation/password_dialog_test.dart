import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:werewolf_narrator/features/export/presentation/password_dialog.dart';

void main() {
  Future<void> openDialog(
    WidgetTester tester, {
    required bool confirm,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => PasswordDialog.show(
              context,
              title: 'Exporter',
              message: 'Le fichier sera chiffré.',
              confirm: confirm,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('refuses a password shorter than the minimum', (tester) async {
    await openDialog(tester, confirm: true);

    await tester.enterText(find.byType(TextField).first, 'abc');
    await tester.pump();

    expect(find.textContaining('Au moins 6 caractères'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });

  testWidgets('refuses two different passwords in confirm mode', (
    tester,
  ) async {
    await openDialog(tester, confirm: true);

    await tester.enterText(find.byType(TextField).first, 'motdepasse');
    await tester.enterText(find.byType(TextField).last, 'motdepassX');
    await tester.pump();

    expect(find.textContaining('diffèrent'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });

  testWidgets('accepts the password once both fields match', (tester) async {
    await openDialog(tester, confirm: true);

    await tester.enterText(find.byType(TextField).first, 'motdepasse');
    await tester.enterText(find.byType(TextField).last, 'motdepasse');
    await tester.pump();

    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );

    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('asks for the password only once when importing', (
    tester,
  ) async {
    await openDialog(tester, confirm: false);

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Confirmer le mot de passe'), findsNothing);
  });

  testWidgets('the password stays hidden until asked otherwise', (
    tester,
  ) async {
    await openDialog(tester, confirm: false);

    expect(
      tester.widget<TextField>(find.byType(TextField)).obscureText,
      isTrue,
    );

    await tester.tap(find.byIcon(Icons.visibility_off));
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextField>(find.byType(TextField)).obscureText,
      isFalse,
    );
  });
}
