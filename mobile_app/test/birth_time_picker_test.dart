import 'package:decision_compass/app_locale.dart';
import 'package:decision_compass/l10n/app_localizations.dart';
import 'package:decision_compass/theme.dart';
import 'package:decision_compass/widgets/birth_time_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reading_test_rig.dart';

void main() {
  setUpAll(loadBundledFonts);

  Future<TimeOfDay? Function()> openPicker(
    WidgetTester tester, {
    TimeOfDay? initialTime,
    Locale locale = const Locale('en'),
  }) async {
    TimeOfDay? result;
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildCompassTheme(
          AppLocale.forLocale(locale) ?? AppLocale.english,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showBirthTimePicker(
                  context: context,
                  current: initialTime,
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
    await tester.tap(find.byKey(const Key('birth_time_type_tab')));
    await tester.pumpAndSettle();
  }

  testWidgets('wheel is the default and confirms an existing time', (
    tester,
  ) async {
    final result = await openPicker(
      tester,
      initialTime: const TimeOfDay(hour: 8, minute: 30),
    );
    expect(find.byType(CupertinoPicker), findsNWidgets(3));
    expect(
      tester.widget<Text>(find.byKey(const Key('birth_time_feedback'))).data,
      contains('Dragon'),
    );

    final cancel = tester.getCenter(find.byKey(const Key('birth_time_cancel')));
    final confirm = tester.getCenter(
      find.byKey(const Key('birth_time_confirm')),
    );
    expect(cancel.dy, confirm.dy);
    expect(cancel.dx, lessThan(confirm.dx));

    await tester.tap(find.byKey(const Key('birth_time_confirm')));
    await tester.pumpAndSettle();
    expect(result(), const TimeOfDay(hour: 8, minute: 30));
  });

  testWidgets('scrolling the wheel changes the selected birth time', (
    tester,
  ) async {
    final result = await openPicker(
      tester,
      initialTime: const TimeOfDay(hour: 8, minute: 30),
    );
    final before = tester
        .widget<Text>(find.byKey(const Key('birth_time_feedback')))
        .data;
    await tester.drag(
      find.byKey(const Key('birth_time_hour_wheel')),
      const Offset(0, -90),
    );
    await tester.pumpAndSettle();
    final after = tester
        .widget<Text>(find.byKey(const Key('birth_time_feedback')))
        .data;
    expect(after, isNot(before));

    await tester.tap(find.byKey(const Key('birth_time_confirm')));
    await tester.pumpAndSettle();
    expect(result(), isNot(const TimeOfDay(hour: 8, minute: 30)));
  });

  testWidgets('displays Vietnamese Canh Gio without detailed hours', (
    tester,
  ) async {
    // 08:30 AM -> Giờ Thìn (Rồng 🐲)
    await openPicker(
      tester,
      initialTime: const TimeOfDay(hour: 8, minute: 30),
      locale: const Locale('vi'),
    );
    expect(find.text('Giờ Thìn (Rồng 🐲)'), findsOneWidget);

    // Cancel to close
    await tester.tap(find.byKey(const Key('birth_time_cancel')));
    await tester.pumpAndSettle();

    // 05:15 AM -> Giờ Mão (Mão 🐱)
    await openPicker(
      tester,
      initialTime: const TimeOfDay(hour: 5, minute: 15),
      locale: const Locale('vi'),
    );
    expect(find.text('Giờ Mão (Mão 🐱)'), findsOneWidget);
    expect(find.textContaining('Mèo'), findsNothing);
    expect(find.textContaining('Thỏ'), findsNothing);
    expect(find.textContaining('🐇'), findsNothing);

    await tester.tap(find.byKey(const Key('birth_time_cancel')));
    await tester.pumpAndSettle();

    // Chinese: 05:15 AM -> 卯时 (兔 🐇)
    await openPicker(
      tester,
      initialTime: const TimeOfDay(hour: 5, minute: 15),
      locale: const Locale.fromSubtags(
        languageCode: 'zh',
        scriptCode: 'Hans',
        countryCode: 'CN',
      ),
    );
    expect(find.text('卯时 (兔 🐇)'), findsOneWidget);
    expect(find.textContaining('🐱'), findsNothing);

    await tester.tap(find.byKey(const Key('birth_time_cancel')));
    await tester.pumpAndSettle();

    // English: 05:15 AM -> Hour of the Rabbit 🐇
    await openPicker(
      tester,
      initialTime: const TimeOfDay(hour: 5, minute: 15),
      locale: const Locale('en'),
    );
    expect(find.text('Hour of the Rabbit 🐇'), findsOneWidget);
    expect(find.textContaining('🐱'), findsNothing);
    expect(find.textContaining('Cat'), findsNothing);

    await tester.tap(find.byKey(const Key('birth_time_cancel')));
    await tester.pumpAndSettle();

    // 23:45 -> Giờ Tý (Chuột 🐀)
    await openPicker(
      tester,
      initialTime: const TimeOfDay(hour: 23, minute: 45),
      locale: const Locale('vi'),
    );
    expect(find.text('Giờ Tý (Chuột 🐀)'), findsOneWidget);
  });

  testWidgets('period wheel shows Sáng and Tối in Vietnamese', (tester) async {
    await openPicker(
      tester,
      initialTime: const TimeOfDay(hour: 8, minute: 30),
      locale: const Locale('vi'),
    );
    expect(find.text('Sáng'), findsOneWidget);
    expect(find.text('Tối'), findsOneWidget);
  });

  testWidgets('period wheel shows AM and PM in English', (tester) async {
    await openPicker(
      tester,
      initialTime: const TimeOfDay(hour: 8, minute: 30),
      locale: const Locale('en'),
    );
    expect(find.text('AM'), findsOneWidget);
    expect(find.text('PM'), findsOneWidget);
  });

  testWidgets('manual entry allows typing hour, minute, and selecting PM', (
    tester,
  ) async {
    final result = await openPicker(tester);
    await useManualEntry(tester);
    await tester.enterText(
      find.byKey(const Key('birth_time_hour_field')),
      '04',
    );
    await tester.enterText(
      find.byKey(const Key('birth_time_minute_field')),
      '20',
    );
    await tester.tap(find.byKey(const Key('birth_time_pm')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('birth_time_confirm')));
    await tester.pumpAndSettle();
    expect(result(), const TimeOfDay(hour: 16, minute: 20));
  });

  testWidgets('cancel and continue buttons have equal height and width', (
    tester,
  ) async {
    await openPicker(tester);
    final cancelSize = tester.getSize(
      find.byKey(const Key('birth_time_cancel')),
    );
    final confirmSize = tester.getSize(
      find.byKey(const Key('birth_time_confirm')),
    );
    expect(cancelSize.height, equals(confirmSize.height));
    expect(cancelSize.width, equals(confirmSize.width));
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

      await openPicker(tester, locale: locale);
      expect(tester.takeException(), isNull);
      await useManualEntry(tester);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'unselected state displays placeholder dashes and disables continue',
    (tester) async {
      final result = await openPicker(tester);
      expect(find.text('--'), findsWidgets);

      final confirmButton = tester.widget<FilledButton>(
        find.byKey(const Key('birth_time_confirm')),
      );
      expect(confirmButton.onPressed, isNull);

      final feedback = tester
          .widget<Text>(find.byKey(const Key('birth_time_feedback')))
          .data;
      expect(feedback, 'Select your time of birth');

      // Scroll hour wheel
      await tester.drag(
        find.byKey(const Key('birth_time_hour_wheel')),
        const Offset(0, -50),
      );
      await tester.pumpAndSettle();

      // Scroll minute wheel
      await tester.drag(
        find.byKey(const Key('birth_time_minute_wheel')),
        const Offset(0, -50),
      );
      await tester.pumpAndSettle();

      // Scroll period wheel
      await tester.drag(
        find.byKey(const Key('birth_time_period_wheel')),
        const Offset(0, -50),
      );
      await tester.pumpAndSettle();

      final updatedConfirmButton = tester.widget<FilledButton>(
        find.byKey(const Key('birth_time_confirm')),
      );
      expect(updatedConfirmButton.onPressed, isNotNull);

      await tester.tap(find.byKey(const Key('birth_time_confirm')));
      await tester.pumpAndSettle();
      expect(result(), isNotNull);
    },
  );
}
