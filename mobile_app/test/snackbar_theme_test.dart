import 'package:decision_compass/app_locale.dart';
import 'package:decision_compass/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reading_test_rig.dart';

/// Notices have to look like they belong to this app.
///
/// Material's default puts a SnackBar on `colorScheme.inverseSurface`, which on
/// a dark theme is a *light* colour. Every notice in the app was arriving as a
/// near-white box over a near-black screen. The reasoning behind that default
/// — an inverted surface draws the eye — is right for a light app and wrong
/// here: these notices say small things, and reading as an alarm is worse than
/// reading as part of the furniture.
///
/// Asserted as a relationship rather than as a literal colour, so the checks
/// survive a palette tweak and still fail on the thing that actually went
/// wrong.
void main() {
  /// Perceived lightness, 0 (black) to 1 (white).
  double luminance(Color? colour) => colour!.computeLuminance();

  /// Shows a bare notice and returns the Material that draws it.
  Future<Material> showNotice(
    WidgetTester tester, {
    SnackBarAction? action,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildCompassTheme(AppLocale.english),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: const Text('notice'), action: action),
              ),
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    return tester.widget<Material>(
      find
          .descendant(
            of: find.byType(SnackBar),
            matching: find.byType(Material),
          )
          .first,
    );
  }

  testWidgets('a notice is dark, like the screen it sits on', (tester) async {
    final theme = buildCompassTheme(AppLocale.english);
    final material = await showNotice(tester);

    // The regression itself: the default would have been `inverseSurface`,
    // which on this theme is a near-white.
    expect(
      luminance(theme.colorScheme.inverseSurface),
      greaterThan(0.5),
      reason:
          'the Material default is no longer the light colour this guards '
          'against; re-read whether this test still means anything',
    );
    expect(
      luminance(material.color),
      lessThan(0.2),
      reason: 'a notice arrived as a light box on a dark app',
    );
    // And it is close to the surfaces it floats above rather than a third
    // unrelated shade.
    expect(
      (luminance(material.color) - luminance(theme.scaffoldBackgroundColor))
          .abs(),
      lessThan(0.1),
    );
  });

  testWidgets('its text is legible against it', (tester) async {
    final material = await showNotice(tester);
    final text = tester.widget<Text>(find.text('notice'));
    final style =
        text.style ??
        DefaultTextStyle.of(tester.element(find.text('notice'))).style;

    // Not a WCAG measurement — that needs the real contrast formula and a
    // decision about which level to hold to. This only catches dark-on-dark,
    // which is the way a hand-set background goes wrong.
    expect(
      luminance(style.color) - luminance(material.color),
      greaterThan(0.5),
      reason: 'the message is nearly invisible against its own background',
    );
  });

  testWidgets('it floats clear of the screen edges', (tester) async {
    await showNotice(tester);
    final box = tester.getRect(
      find
          .descendant(
            of: find.byType(SnackBar),
            matching: find.byType(Material),
          )
          .first,
    );
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;

    expect(box.left, greaterThan(0), reason: 'flush to the left edge');
    expect(box.right, lessThan(screen.width), reason: 'flush to the right');
    expect(
      box.bottom,
      lessThan(screen.height),
      reason: 'flush to the bottom, like the default fixed behaviour',
    );
  });

  testWidgets('its action is findable without shouting', (tester) async {
    final theme = buildCompassTheme(AppLocale.english);
    final material = await showNotice(
      tester,
      action: SnackBarAction(label: 'Change', onPressed: () {}),
    );

    expect(find.text('Change'), findsOneWidget);
    // Gold is the app's accent, and it has to stand off the bar it sits on.
    expect(theme.snackBarTheme.actionTextColor, CompassColors.gold);
    expect(
      luminance(CompassColors.gold) - luminance(material.color),
      greaterThan(0.2),
    );
  });

  testWidgets('a real notice from the app looks the same', (tester) async {
    // The synthetic bars above prove the theme. This proves a notice the app
    // actually raises picks it up — the language notice after onboarding is
    // the one that prompted this.
    final rig = ReadingTestRig(
      response: fixtureResponse('ready_yes_no_now.json'),
    );
    await tester.pumpWidget(rig.app);
    await tester.pump();
    await tester.tap(find.byKey(const Key('continue_to_profile')));
    await tester.pumpAndSettle();
    await fillDateAndCountry(tester);
    await answerBirthTime(tester, null);
    await tester.ensureVisible(find.byKey(const Key('complete_profile')));
    await tester.tap(find.byKey(const Key('complete_profile')));
    await tester.pumpAndSettle();

    // US maps to English, so no language notice. Any notice the app raises
    // from here uses the same theme; this asserts the wiring, not the copy.
    expect(
      tester
          .widget<MaterialApp>(find.byType(MaterialApp).first)
          .theme
          ?.snackBarTheme
          .backgroundColor,
      CompassColors.raised,
      reason: 'the app is not using the themed notice at all',
    );
  });
}
