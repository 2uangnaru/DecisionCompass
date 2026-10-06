import 'package:decision_compass/app_locale.dart';
import 'package:decision_compass/app_profile.dart';
import 'package:decision_compass/models.dart';
import 'package:decision_compass/pages/profile_page.dart';
import 'package:decision_compass/reading_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reading_test_rig.dart';

/// The save-confirmation dialog's two buttons.
///
/// They used to arrive stacked, with Save spanning almost the full width. The
/// cause was not the dialog: this app's button themes ask for
/// `minimumSize: Size.fromHeight(56)`, which is `Size(infinity, 56)` — a
/// minimum *width* of infinity. Each button claimed the whole line, so
/// `OverflowBar` could not fit the pair side by side and did what it exists to
/// do. These measure the fix at the widths and text scales the product
/// targets, with the real bundled fonts, so the numbers are the fonts' own.
void main() {
  setUpAll(loadBundledFonts);

  /// The narrowest Android phones the product targets, and the text scales
  /// the accessibility settings actually reach.
  const widths = <double>[320, 360, 393];
  const scales = <double>[1.0, 1.3, 1.5];

  final profile = AppProfile(
    userName: 'Alex',
    birthDate: DateTime(1998, 6, 21),
    birthTime: '14:30',
    birthCountryCode: 'VN',
    zodiacSign: zodiacForDate(DateTime(1998, 6, 21)),
    useCurrentLocation: false,
    safetyAcknowledged: true,
  );

  /// What the Profile screen handed back when it closed, and how often.
  final result = <String, AppProfile?>{};
  var closed = 0;

  setUp(() {
    result.clear();
    closed = 0;
  });

  Future<void> openProfile(
    WidgetTester tester, {
    required ReadingDependencies dependencies,
    AppLocale locale = AppLocale.english,
  }) async {
    await tester.pumpWidget(
      localizedApp(
        locale: locale,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                key: const Key('open_profile'),
                onPressed: () async {
                  final saved = await Navigator.of(context).push<AppProfile>(
                    MaterialPageRoute<AppProfile>(
                      builder: (_) => ProfilePage(
                        profile: profile,
                        dependencies: dependencies,
                      ),
                    ),
                  );
                  closed++;
                  result['saved'] = saved;
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open_profile')));
    await tester.pumpAndSettle();
  }

  /// Makes one edit and taps Save, which is what raises the dialog.
  ///
  /// Turning the birth-time switch off is the cheapest real change on this
  /// screen: it moves a known hour to Unknown in one tap, with no picker in
  /// the way, which matters when the matrix below runs it 63 times.
  Future<void> raiseDialog(WidgetTester tester) async {
    await tester.ensureVisible(
      find.byKey(const Key('profile_knows_birth_time')),
    );
    await tester.tap(find.byKey(const Key('profile_knows_birth_time')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('profile_save')));
    await tester.tap(find.byKey(const Key('profile_save')));
    await tester.pumpAndSettle();
  }

  /// The painted box of a button, rather than its render object's outer box.
  ///
  /// `ButtonStyleButton` wraps itself in the tap-target padding that lifts
  /// every button to 48dp, so the outer boxes would come out equal even if
  /// the visible ones did not. The `Material` is what the reader sees.
  Rect painted(WidgetTester tester, String key) => tester.getRect(
    find
        .descendant(of: find.byKey(Key(key)), matching: find.byType(Material))
        .first,
  );

  Rect touchTarget(WidgetTester tester, String key) =>
      tester.getRect(find.byKey(Key(key)));

  for (final locale in AppLocale.values) {
    testWidgets('Cancel and Save are one row of equal boxes, ${locale.tag}', (
      tester,
    ) async {
      for (final width in widths) {
        for (final scale in scales) {
          final at = '${locale.tag} at ${width.toInt()}dp × $scale';
          useScreen(tester, size: Size(width, 640), textScale: scale);
          final rig = ReadingTestRig();
          await openProfile(
            tester,
            dependencies: rig.dependencies,
            locale: locale,
          );
          await raiseDialog(tester);

          expect(
            find.byKey(const Key('profile_confirm_dialog')),
            findsOneWidget,
            reason: 'the dialog never opened, $at',
          );

          final cancel = painted(tester, 'profile_confirm_cancel');
          final save = painted(tester, 'profile_confirm_save');

          // One row, not two.
          expect(
            cancel.center.dy,
            moreOrLessEquals(save.center.dy, epsilon: 0.5),
            reason: 'the buttons are stacked rather than side by side, $at',
          );
          // Cancel on the left, Save on the right, not overlapping.
          expect(
            cancel.right,
            lessThanOrEqualTo(save.left),
            reason: 'Cancel is not to the left of Save, $at',
          );
          expect(
            save.left - cancel.right,
            moreOrLessEquals(12, epsilon: 1),
            reason: 'the gap between them drifted, $at',
          );
          // Exactly the same size.
          expect(
            cancel.width,
            moreOrLessEquals(save.width, epsilon: 0.5),
            reason: 'one button is wider than the other, $at',
          );
          expect(
            cancel.height,
            moreOrLessEquals(save.height, epsilon: 0.5),
            reason: 'one button is taller than the other, $at',
          );
          // And both stay reachable.
          for (final key in const [
            'profile_confirm_cancel',
            'profile_confirm_save',
          ]) {
            expect(
              touchTarget(tester, key).height,
              greaterThanOrEqualTo(48),
              reason: '$key is under the 48dp touch target, $at',
            );
          }
          // Inside the screen, with nothing painted off the edge.
          for (final box in [cancel, save]) {
            expect(box.left, greaterThanOrEqualTo(0), reason: 'clipped, $at');
            expect(box.right, lessThanOrEqualTo(width), reason: 'clipped, $at');
          }
          // Any overflow the row caused would be waiting here.
          expect(
            tester.takeException(),
            isNull,
            reason: 'the dialog overflowed, $at',
          );

          // Back to the host before the next size. `pumpWidget` reuses a
          // structurally identical tree, so a Profile route left on the
          // navigator would hide the button the next iteration taps.
          await tester.tap(find.byKey(const Key('profile_confirm_cancel')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('profile_cancel')));
          await tester.pumpAndSettle();
        }
      }
    });
  }

  testWidgets('a label too long for its half wraps both boxes together, not '
      'one', (tester) async {
    // Spanish is the longest pair the app ships ("Cancelar" / "Guardar"), and
    // 320dp at 1.5x is the tightest the product targets. Whatever the text
    // does, the two boxes have to keep agreeing.
    useScreen(tester, size: const Size(320, 640), textScale: 1.5);
    final rig = ReadingTestRig();
    await openProfile(
      tester,
      dependencies: rig.dependencies,
      locale: AppLocale.spanish,
    );
    await raiseDialog(tester);

    final cancel = painted(tester, 'profile_confirm_cancel');
    final save = painted(tester, 'profile_confirm_save');
    expect(cancel.size, save.size);
    expect(cancel.top, moreOrLessEquals(save.top, epsilon: 0.5));
    expect(cancel.bottom, moreOrLessEquals(save.bottom, epsilon: 0.5));
  });

  testWidgets('the content scrolls on a short screen and the buttons stay '
      'put', (tester) async {
    // Both fields changed, so the dialog carries both consequence lines as
    // well as the history note — its tallest state — on a short screen.
    useScreen(tester, size: const Size(320, 420), textScale: 1.5);
    final rig = ReadingTestRig();
    await openProfile(
      tester,
      dependencies: rig.dependencies,
      locale: AppLocale.spanish,
    );
    await raiseDialog(tester);

    expect(tester.takeException(), isNull);
    final cancel = painted(tester, 'profile_confirm_cancel');
    final save = painted(tester, 'profile_confirm_save');
    expect(cancel.center.dy, moreOrLessEquals(save.center.dy, epsilon: 0.5));
    expect(cancel.bottom, lessThanOrEqualTo(420));
    // The text is what gives way, not the row.
    expect(
      find.descendant(
        of: find.byKey(const Key('profile_confirm_dialog')),
        matching: find.byType(SingleChildScrollView),
      ),
      findsOneWidget,
    );
  });

  group('and they still do what they did', () {
    testWidgets('Cancel closes the dialog and writes nothing', (tester) async {
      final rig = ReadingTestRig();
      await openProfile(tester, dependencies: rig.dependencies);
      await raiseDialog(tester);

      await tester.tap(find.byKey(const Key('profile_confirm_cancel')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('profile_confirm_dialog')), findsNothing);
      expect(rig.profileRepository.saves, 0);
      expect(await rig.profileRepository.load(), isNull);
      expect(closed, 0, reason: 'Profile stays open with the edit intact');
      expect(
        tester
            .widget<SwitchListTile>(
              find.byKey(const Key('profile_knows_birth_time')),
            )
            .value,
        isFalse,
      );
    });

    testWidgets('Save writes the profile and hands it back', (tester) async {
      final rig = ReadingTestRig();
      await openProfile(tester, dependencies: rig.dependencies);
      await raiseDialog(tester);

      await tester.tap(find.byKey(const Key('profile_confirm_save')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('profile_confirm_dialog')), findsNothing);
      expect(rig.profileRepository.saves, 1);
      expect(closed, 1);
      expect(result['saved']!.birthTime, isNull);
      expect(
        result['saved']!.birthTimeChangedAtUtc,
        isNotNull,
        reason: 'the cooldown still starts from a confirmed save',
      );
      expect(result['saved']!.birthCountryChangedAtUtc, isNull);
    });
  });
}
