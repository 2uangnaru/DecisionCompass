import 'package:decision_compass/app_locale.dart';
import 'package:decision_compass/l10n/app_localizations.dart';
import 'package:decision_compass/theme.dart';
import 'package:decision_compass/widgets/birth_date_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reading_test_rig.dart';

/// The birth-date sheet at Android's larger font sizes.
///
/// Separate from `birth_date_picker_test.dart`, which owns the behaviour of
/// the picker itself; this file owns only the question of whether that
/// behaviour survives a reader who has turned their font size up. The two
/// concerns need different harnesses anyway: the text scale has to sit in the
/// tree *above* the sheet, because `showModalBottomSheet` pushes a route that
/// inherits the app's `MediaQuery` rather than the opening widget's.
///
/// 2.0 is the top of Android's own font-size slider. 320x568 is narrower than
/// the 360dp the product targets, so a sheet that holds here holds on a real
/// phone.
void main() {
  setUpAll(loadBundledFonts);

  const narrow = Size(320, 568);

  /// Opens the sheet at [scale] in [locale] and returns the chosen date, once
  /// something chooses one.
  Future<DateTime? Function()> openScaled(
    WidgetTester tester, {
    required Locale locale,
    required double scale,
  }) async {
    tester.view.physicalSize = narrow;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    DateTime? result;
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildCompassTheme(
          AppLocale.forLocale(locale) ?? AppLocale.english,
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showModalBottomSheet<DateTime>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) =>
                      BirthDatePickerSheet(lastDate: DateTime(2026, 9, 30)),
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

  // English, the most verbose Latin language the app ships, and a script whose
  // marks stack above and below the line and therefore needs the most room.
  const locales = <(String, Locale)>[
    ('en', Locale('en')),
    ('es', Locale('es')),
    ('th', Locale('th')),
  ];

  for (final (tag, locale) in locales) {
    for (final scale in const <double>[1.3, 1.5, 2.0]) {
      testWidgets('$tag at ${scale}x lays out in both modes', (tester) async {
        await openScaled(tester, locale: locale, scale: scale);

        // `takeException` is what catches a RenderFlex overflow: the framework
        // reports one as a test exception, and a layout that overflows is
        // exactly the failure mode a larger font size produces.
        expect(tester.takeException(), isNull, reason: '$tag ${scale}x wheel');
        expect(find.byType(CupertinoPicker), findsNWidgets(3));

        await tester.tap(find.byKey(const Key('birth_date_type_tab')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$tag ${scale}x manual');

        // Typing a date is the point of this mode, so all three fields have to
        // survive the scale, not just the sheet.
        for (final part in const ['day', 'month', 'year']) {
          expect(
            find.byKey(Key('birth_date_$part')),
            findsOneWidget,
            reason: '$part went missing at $tag ${scale}x',
          );
        }
        expect(find.byKey(const Key('birth_date_confirm')), findsOneWidget);
        expect(find.byKey(const Key('birth_date_cancel')), findsOneWidget);
      });
    }
  }

  testWidgets('the sheet still stops at 90% of a short screen', (tester) async {
    // The cap is what keeps the sheet from swallowing the screen once every
    // line inside it has doubled in height.
    await openScaled(tester, locale: const Locale('es'), scale: 2);
    final sheet = tester.getSize(find.byKey(const Key('birth_date_sheet')));
    expect(sheet.height, lessThanOrEqualTo(narrow.height * 0.9 + 0.5));
  });

  testWidgets('both controls stay reachable by scrolling at 2.0x', (
    tester,
  ) async {
    // The sheet scrolls rather than growing, so Continue may start below the
    // fold. What matters is that it can be brought into view and tapped.
    await openScaled(tester, locale: const Locale('th'), scale: 2);
    await tester.tap(find.byKey(const Key('birth_date_type_tab')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('birth_date_confirm')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final confirm = tester.getRect(find.byKey(const Key('birth_date_confirm')));
    expect(confirm.top, greaterThanOrEqualTo(0));
    expect(confirm.bottom, lessThanOrEqualTo(narrow.height));
  });

  testWidgets('a date can still be typed and confirmed at 2.0x', (
    tester,
  ) async {
    // The scale must not cost the reader the thing the sheet is for.
    final result = await openScaled(
      tester,
      locale: const Locale('en'),
      scale: 2,
    );
    await tester.tap(find.byKey(const Key('birth_date_type_tab')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('birth_date_day')), '21');
    await tester.enterText(find.byKey(const Key('birth_date_month')), '06');
    await tester.enterText(find.byKey(const Key('birth_date_year')), '1998');
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('birth_date_confirm')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('birth_date_confirm')));
    await tester.pumpAndSettle();

    expect(result(), DateTime(1998, 6, 21));
  });

  testWidgets('a date can still be chosen on the wheel at 2.0x', (
    tester,
  ) async {
    // The wheel is the default and the easier of the two, so it has to work
    // at the scale as well — its row height is driven by the same text.
    final result = await openScaled(
      tester,
      locale: const Locale('en'),
      scale: 2,
    );
    expect(find.byType(CupertinoPicker), findsNWidgets(3));
    await tester.ensureVisible(find.byKey(const Key('birth_date_confirm')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('birth_date_confirm')));
    await tester.pumpAndSettle();

    // No initial date was given, so the wheel opens on its own default rather
    // than on nothing — a reader who just taps Continue still gets a date.
    expect(result(), isNotNull);
  });
}
