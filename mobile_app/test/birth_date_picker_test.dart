import 'package:decision_compass/l10n/app_localizations.dart';
import 'package:decision_compass/widgets/birth_date_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<DateTime? Function()> openPicker(
    WidgetTester tester, {
    DateTime? initialDate,
    DateTime? lastDate,
  }) async {
    DateTime? result;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showDialog<DateTime>(
                  context: context,
                  builder: (_) => BirthDatePickerDialog(
                    initialDate: initialDate,
                    lastDate: lastDate,
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    return () => result;
  }

  testWidgets('validates real dates and accepts leap day', (tester) async {
    final result = await openPicker(tester, lastDate: DateTime(2026, 9, 30));
    await tester.enterText(find.byKey(const Key('birth_date_day')), '31');
    await tester.enterText(find.byKey(const Key('birth_date_month')), '02');
    await tester.enterText(find.byKey(const Key('birth_date_year')), '2024');
    await tester.pump();

    expect(find.text('Enter a valid date from 1900 to today.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('birth_date_confirm')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('birth_date_dialog')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('birth_date_day')), '29');
    await tester.tap(find.byKey(const Key('birth_date_confirm')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('birth_date_dialog')), findsNothing);
    expect(result(), DateTime(2024, 2, 29));
  });

  testWidgets('rejects a future birth date', (tester) async {
    final result = await openPicker(tester, lastDate: DateTime(2026, 9, 30));
    await tester.enterText(find.byKey(const Key('birth_date_day')), '01');
    await tester.enterText(find.byKey(const Key('birth_date_month')), '10');
    await tester.enterText(find.byKey(const Key('birth_date_year')), '2026');
    await tester.tap(find.byKey(const Key('birth_date_confirm')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('birth_date_dialog')), findsOneWidget);
    expect(find.text('Enter a valid date from 1900 to today.'), findsOneWidget);
    expect(result(), isNull);
  });

  testWidgets('keeps an existing answer available for editing', (tester) async {
    final result = await openPicker(tester, initialDate: DateTime(1998, 6, 21));
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('birth_date_day')))
          .controller!
          .text,
      '21',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('birth_date_month')))
          .controller!
          .text,
      '06',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('birth_date_year')))
          .controller!
          .text,
      '1998',
    );
    await tester.tap(find.byKey(const Key('birth_date_cancel')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('birth_date_dialog')), findsNothing);
    expect(result(), isNull);
  });
}
