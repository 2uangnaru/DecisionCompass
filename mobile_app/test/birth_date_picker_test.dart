import 'package:decision_compass/l10n/app_localizations.dart';
import 'package:decision_compass/widgets/birth_date_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<DateTime? Function()> openPicker(
    WidgetTester tester, {
    DateTime? initialDate,
    DateTime? lastDate,
    Locale locale = const Locale('en'),
  }) async {
    DateTime? result;
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showModalBottomSheet<DateTime>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => BirthDatePickerSheet(
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

  Future<void> useManualEntry(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('birth_date_type_tab')));
    await tester.pumpAndSettle();
  }

  testWidgets('wheel is the default and confirms an existing date', (
    tester,
  ) async {
    final result = await openPicker(tester, initialDate: DateTime(1998, 6, 21));
    expect(find.byType(CupertinoPicker), findsNWidgets(3));
    expect(find.byType(DatePickerDialog), findsNothing);
    expect(
      tester.widget<Text>(find.byKey(const Key('birth_date_feedback'))).data,
      contains('Tiger'),
    );

    final cancel = tester.getCenter(find.byKey(const Key('birth_date_cancel')));
    final confirm = tester.getCenter(
      find.byKey(const Key('birth_date_confirm')),
    );
    expect(cancel.dy, confirm.dy);
    expect(cancel.dx, lessThan(confirm.dx));

    await tester.tap(find.byKey(const Key('birth_date_confirm')));
    await tester.pumpAndSettle();
    expect(result(), DateTime(1998, 6, 21));
  });

  testWidgets('scrolling the wheel changes the selected birth date', (
    tester,
  ) async {
    final result = await openPicker(tester, initialDate: DateTime(2000, 6, 15));
    final before = tester
        .widget<Text>(find.byKey(const Key('birth_date_feedback')))
        .data;
    await tester.drag(
      find.byKey(const Key('birth_date_year_wheel')),
      const Offset(0, -90),
    );
    await tester.pumpAndSettle();
    final after = tester
        .widget<Text>(find.byKey(const Key('birth_date_feedback')))
        .data;
    expect(after, isNot(before));

    await tester.tap(find.byKey(const Key('birth_date_confirm')));
    await tester.pumpAndSettle();
    expect(result(), isNot(DateTime(2000, 6, 15)));
  });

  testWidgets('month wheel clamps day to the last valid day', (tester) async {
    final result = await openPicker(
      tester,
      initialDate: DateTime(2024, 1, 31),
      lastDate: DateTime(2026, 9, 30),
    );
    await tester.drag(
      find.byKey(const Key('birth_date_month_wheel')),
      const Offset(0, -48),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('birth_date_confirm')));
    await tester.pumpAndSettle();
    expect(result(), DateTime(2024, 2, 29));
  });

  testWidgets('manual entry rejects impossible dates and accepts leap day', (
    tester,
  ) async {
    final result = await openPicker(tester, lastDate: DateTime(2026, 9, 30));
    await useManualEntry(tester);
    await tester.enterText(find.byKey(const Key('birth_date_day')), '31');
    await tester.enterText(find.byKey(const Key('birth_date_month')), '02');
    await tester.enterText(find.byKey(const Key('birth_date_year')), '2024');
    await tester.pump();

    expect(find.text('Enter a valid date from 1900 to today.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('birth_date_confirm')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('birth_date_sheet')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('birth_date_day')), '29');
    await tester.tap(find.byKey(const Key('birth_date_confirm')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('birth_date_sheet')), findsNothing);
    expect(result(), DateTime(2024, 2, 29));
  });

  testWidgets('manual entry rejects a future birth date', (tester) async {
    final result = await openPicker(tester, lastDate: DateTime(2026, 9, 30));
    await useManualEntry(tester);
    await tester.enterText(find.byKey(const Key('birth_date_day')), '01');
    await tester.enterText(find.byKey(const Key('birth_date_month')), '10');
    await tester.enterText(find.byKey(const Key('birth_date_year')), '2026');
    await tester.tap(find.byKey(const Key('birth_date_confirm')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('birth_date_sheet')), findsOneWidget);
    expect(find.text('Enter a valid date from 1900 to today.'), findsOneWidget);
    expect(result(), isNull);
  });

  testWidgets(
    'existing date is available for manual editing; cancel preserves it',
    (tester) async {
      final result = await openPicker(
        tester,
        initialDate: DateTime(1998, 6, 21),
      );
      await useManualEntry(tester);
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
      expect(find.byKey(const Key('birth_date_sheet')), findsNothing);
      expect(result(), isNull);
    },
  );

  testWidgets('switching from manual entry updates the wheel date', (
    tester,
  ) async {
    final result = await openPicker(tester, lastDate: DateTime(2026, 9, 30));
    await useManualEntry(tester);
    await tester.enterText(find.byKey(const Key('birth_date_day')), '15');
    await tester.enterText(find.byKey(const Key('birth_date_month')), '08');
    await tester.enterText(find.byKey(const Key('birth_date_year')), '1995');
    await tester.tap(find.byKey(const Key('birth_date_scroll_tab')));
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoPicker), findsNWidgets(3));
    await tester.tap(find.byKey(const Key('birth_date_confirm')));
    await tester.pumpAndSettle();
    expect(result(), DateTime(1995, 8, 15));
  });

  testWidgets('sheet fits a narrow phone screen in both modes', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await openPicker(tester, lastDate: DateTime(2026, 9, 30));
    expect(tester.takeException(), isNull);
    expect(find.byType(CupertinoPicker), findsNWidgets(3));
    await useManualEntry(tester);
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('birth_date_year')), findsOneWidget);
    expect(find.byKey(const Key('birth_date_confirm')), findsOneWidget);

    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('birth_date_confirm')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      tester.getBottomLeft(find.byKey(const Key('birth_date_confirm'))).dy,
      lessThanOrEqualTo(308),
    );
  });

  for (final locale in [
    const Locale('vi'),
    const Locale('es'),
    const Locale('ja'),
    const Locale('th'),
    const Locale('hi', 'IN'),
    const Locale.fromSubtags(
      languageCode: 'zh',
      scriptCode: 'Hans',
      countryCode: 'CN',
    ),
  ]) {
    testWidgets('sheet fits a narrow phone in $locale', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await openPicker(tester, lastDate: DateTime(2026, 9, 30), locale: locale);
      expect(tester.takeException(), isNull);
      await useManualEntry(tester);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'displays Vietnamese Con Giap and Can Chi for the selected date',
    (tester) async {
      await openPicker(
        tester,
        initialDate: DateTime(1998, 8, 25),
        locale: const Locale('vi'),
      );
      expect(find.textContaining('Tuổi Mậu Dần'), findsOneWidget);
      expect(find.textContaining('Hổ'), findsOneWidget);
    },
  );

  testWidgets(
    'names Mao as Mão (Cat 🐱) in Vietnamese, and Rabbit 🐇 in Chinese and English',
    (tester) async {
      await openPicker(
        tester,
        initialDate: DateTime(1999, 8, 25),
        locale: const Locale('vi'),
      );
      expect(find.textContaining('Tuổi Kỷ Mão (Mèo) 🐱'), findsOneWidget);
      expect(find.textContaining('Thỏ'), findsNothing);
      expect(find.textContaining('🐇'), findsNothing);

      await tester.tap(find.byKey(const Key('birth_date_cancel')));
      await tester.pumpAndSettle();

      await openPicker(
        tester,
        initialDate: DateTime(1999, 8, 25),
        locale: const Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hans',
          countryCode: 'CN',
        ),
      );
      expect(find.textContaining('卯年 (兔) 🐇'), findsOneWidget);
      expect(find.textContaining('🐱'), findsNothing);

      await tester.tap(find.byKey(const Key('birth_date_cancel')));
      await tester.pumpAndSettle();

      await openPicker(
        tester,
        initialDate: DateTime(1999, 8, 25),
        locale: const Locale('en'),
      );
      expect(find.textContaining('Year of the Rabbit 🐇'), findsOneWidget);
      expect(find.textContaining('🐱'), findsNothing);
    },
  );

  testWidgets(
    'cancel and continue buttons have equal height and width',
    (tester) async {
      await openPicker(tester);
      final cancelSize = tester.getSize(find.byKey(const Key('birth_date_cancel')));
      final confirmSize = tester.getSize(find.byKey(const Key('birth_date_confirm')));
      expect(cancelSize.height, equals(confirmSize.height));
      expect(cancelSize.width, equals(confirmSize.width));
    },
  );

  testWidgets(
    'unselected state displays placeholder dashes and disables continue',
    (tester) async {
      final result = await openPicker(tester);
      expect(find.text('--'), findsWidgets);
      expect(find.text('----'), findsOneWidget);

      final confirmButton = tester.widget<FilledButton>(
        find.byKey(const Key('birth_date_confirm')),
      );
      expect(confirmButton.onPressed, isNull);

      final feedback = tester
          .widget<Text>(find.byKey(const Key('birth_date_feedback')))
          .data;
      expect(feedback, 'Select your date of birth');

      // Scroll day wheel to select day
      await tester.drag(
        find.byKey(const Key('birth_date_day_wheel')),
        const Offset(0, -50),
      );
      await tester.pumpAndSettle();

      // Scroll month wheel to select month
      await tester.drag(
        find.byKey(const Key('birth_date_month_wheel')),
        const Offset(0, -50),
      );
      await tester.pumpAndSettle();

      // Scroll year wheel to select year
      await tester.drag(
        find.byKey(const Key('birth_date_year_wheel')),
        const Offset(0, -50),
      );
      await tester.pumpAndSettle();

      final updatedConfirmButton = tester.widget<FilledButton>(
        find.byKey(const Key('birth_date_confirm')),
      );
      expect(updatedConfirmButton.onPressed, isNotNull);

      await tester.tap(find.byKey(const Key('birth_date_confirm')));
      await tester.pumpAndSettle();
      expect(result(), isNotNull);
    },
  );
}
