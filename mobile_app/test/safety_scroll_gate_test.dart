import 'package:decision_compass/app_locale.dart';
import 'package:decision_compass/l10n/app_localizations.dart';
import 'package:decision_compass/theme.dart';
import 'package:decision_compass/widgets/responsible_use_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reading_test_rig.dart';

/// The first-time acknowledgement cannot be given before the policy has been
/// on screen.
///
/// The button stays where it is and stays tappable; what changes is what the
/// tap does. A genuinely disabled control would tell a reader nothing and give
/// them no way to ask — on a screen whose entire purpose is that the policy was
/// read, "nothing happens" is the worst available answer. So the locked state
/// answers with the reason instead.
///
/// Reference mode — the same sheet opened later from Home, the ritual screen or
/// a result — is not gated and is checked here to stay that way.
void main() {
  setUpAll(loadBundledFonts);

  final gateHint = stringsFor(AppLocale.english).safetyScrollToContinue;

  final agree = find.byKey(const Key('agree_safety_boundaries'));
  final hint = find.byKey(const Key('safety_scroll_hint'));
  final sheet = find.byKey(const Key('responsible_use_sheet'));

  /// Mounts the sheet directly, so the gate can be exercised without walking
  /// onboarding first. [size] is the window; a tall one is how the "it already
  /// fits" case is reached.
  Future<bool? Function()> openSheet(
    WidgetTester tester, {
    bool firstTime = true,
    Size size = const Size(390, 700),
    double textScale = 1,
    Locale locale = const Locale('en'),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    bool? result;
    var settled = false;
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildCompassTheme(
          AppLocale.forLocale(locale) ?? AppLocale.english,
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showResponsibleUseSheet(
                  context,
                  isFirstTimeAcknowledgement: firstTime,
                );
                settled = true;
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(sheet, findsOneWidget, reason: 'the sheet did not open');
    return () => settled ? result : null;
  }

  /// Drags the policy content to its very end.
  Future<void> scrollToEnd(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -600),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
    }
  }

  /// The button's own background, which is what "grey" means here.
  Color? agreeBackground(WidgetTester tester) {
    final button = tester.widget<FilledButton>(agree);
    return button.style?.backgroundColor?.resolve(<WidgetState>{});
  }

  group('before the policy has been read', () {
    testWidgets('the button looks locked and the hint is not showing yet', (
      tester,
    ) async {
      await openSheet(tester);
      expect(agree, findsOneWidget);
      expect(
        agreeBackground(tester),
        isNotNull,
        reason: 'the locked button is not styled differently at all',
      );
      // Nothing is said until the reader asks.
      expect(hint, findsNothing);
    });

    testWidgets('tapping it shows the hint and nothing else happens', (
      tester,
    ) async {
      final result = await openSheet(tester);
      await tester.tap(agree);
      await tester.pumpAndSettle();

      expect(hint, findsOneWidget);
      expect(find.text(gateHint), findsOneWidget);
      // The sheet is still open and no acknowledgement was given.
      expect(sheet, findsOneWidget);
      expect(result(), isNull);
    });

    testWidgets('tapping it twice does not acknowledge by accident', (
      tester,
    ) async {
      final result = await openSheet(tester);
      for (var i = 0; i < 4; i++) {
        await tester.tap(agree);
        await tester.pumpAndSettle();
      }
      expect(sheet, findsOneWidget);
      expect(result(), isNull);
      expect(hint, findsOneWidget);
    });

    testWidgets('a tap elsewhere dismisses the hint', (tester) async {
      await openSheet(tester);
      await tester.tap(agree);
      await tester.pumpAndSettle();
      expect(hint, findsOneWidget);

      // The heading, which is part of the sheet but not the button.
      await tester.tapAt(tester.getCenter(sheet));
      await tester.pumpAndSettle();
      expect(hint, findsNothing);

      // And it comes back when asked again.
      await tester.tap(agree);
      await tester.pumpAndSettle();
      expect(hint, findsOneWidget);
    });

    testWidgets('starting to scroll dismisses the hint', (tester) async {
      await openSheet(tester);
      await tester.tap(agree);
      await tester.pumpAndSettle();
      expect(hint, findsOneWidget);

      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -80),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      expect(hint, findsNothing);
    });
  });

  group('once the policy has been read', () {
    testWidgets('reaching the end enables the button and hides the hint', (
      tester,
    ) async {
      final result = await openSheet(tester);
      await tester.tap(agree);
      await tester.pumpAndSettle();
      expect(hint, findsOneWidget);

      await scrollToEnd(tester);

      expect(hint, findsNothing);
      expect(
        agreeBackground(tester),
        isNull,
        reason: 'the button is still wearing its locked style',
      );
      expect(result(), isNull, reason: 'scrolling must not acknowledge');

      await tester.tap(agree);
      await tester.pumpAndSettle();
      expect(sheet, findsNothing);
      expect(result(), isTrue);
    });

    testWidgets('it stays enabled after scrolling back up', (tester) async {
      // Re-locking somebody who has already read everything would be hostile,
      // and they would have no way to know what they did wrong.
      await openSheet(tester);
      await scrollToEnd(tester);
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, 900),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      expect(agreeBackground(tester), isNull);
    });

    testWidgets('acknowledging happens exactly once', (tester) async {
      final result = await openSheet(tester);
      await scrollToEnd(tester);
      await tester.tap(agree);
      await tester.pumpAndSettle();

      expect(result(), isTrue);
      // The sheet is gone, so there is nothing left to tap a second time.
      expect(agree, findsNothing);
    });
  });

  group('when the content already fits', () {
    testWidgets('the button is enabled from the first frame', (tester) async {
      // A window tall enough that the policy needs no scrolling at all. There
      // is nothing to wait for, so waiting would be a dead end.
      final result = await openSheet(
        tester,
        size: const Size(420, 3000),
        textScale: 0.9,
      );
      final scrollable = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView).first,
      );
      expect(scrollable, isNotNull);
      expect(
        tester
            .widget<Scrollable>(find.byType(Scrollable).first)
            .controller
            ?.position
            .maxScrollExtent,
        lessThanOrEqualTo(2),
        reason: 'this window still needs scrolling; the case is not covered',
      );

      expect(agreeBackground(tester), isNull);
      await tester.tap(agree);
      await tester.pumpAndSettle();
      expect(result(), isTrue);
    });
  });

  group('dismissing without agreeing', () {
    testWidgets('Android Back closes the sheet and agrees to nothing', (
      tester,
    ) async {
      final result = await openSheet(tester);
      await tester.tap(agree); // locked; shows the hint
      await tester.pumpAndSettle();

      final dispatcher = tester.binding.defaultBinaryMessenger;
      await dispatcher.handlePlatformMessage(
        'flutter/navigation',
        const JSONMethodCodec().encodeMethodCall(const MethodCall('popRoute')),
        (_) {},
      );
      await tester.pumpAndSettle();

      expect(sheet, findsNothing);
      expect(result(), isFalse, reason: 'back must not acknowledge');
    });

    testWidgets('tapping the barrier closes the sheet and agrees to nothing', (
      tester,
    ) async {
      final result = await openSheet(tester);
      // Above the sheet is the modal barrier.
      await tester.tapAt(const Offset(195, 10));
      await tester.pumpAndSettle();

      expect(sheet, findsNothing);
      expect(result(), isFalse);
    });
  });

  group('reference mode is not gated', () {
    testWidgets('it opens with Close, no gate and no hint', (tester) async {
      await openSheet(tester, firstTime: false);

      expect(find.byKey(const Key('close_safety_sheet')), findsOneWidget);
      expect(agree, findsNothing);
      expect(hint, findsNothing);
      // The crisis-support line is reference-mode only and still there.
      expect(find.byKey(const Key('crisis_support')), findsOneWidget);
    });

    testWidgets('Close returns no acknowledgement', (tester) async {
      final result = await openSheet(tester, firstTime: false);
      await tester.tap(find.byKey(const Key('close_safety_sheet')));
      await tester.pumpAndSettle();
      expect(result(), isFalse);
    });
  });

  group('the hint in every language', () {
    for (final locale in AppLocale.values) {
      testWidgets('${locale.tag} renders its own hint without overflowing', (
        tester,
      ) async {
        // 320dp is narrower than the product's 360dp target, and 1.5 is a
        // text size readers really do use. Spanish and Thai are the long ones.
        await openSheet(
          tester,
          size: const Size(320, 640),
          textScale: 1.5,
          locale: locale.locale,
        );
        await tester.tap(agree);
        await tester.pumpAndSettle();

        expect(
          tester.takeException(),
          isNull,
          reason: '${locale.tag} overflow',
        );
        expect(hint, findsOneWidget);
        expect(
          tester.widget<Text>(hint).data,
          stringsFor(locale).safetyScrollToContinue,
        );
        // On screen, not clipped off the bottom edge by the action bar.
        final box = tester.getRect(hint);
        expect(box.top, greaterThanOrEqualTo(0));
        expect(box.bottom, lessThanOrEqualTo(640));
      });
    }
  });

  group('without a touchscreen', () {
    testWidgets('the locked button explains itself to a screen reader', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await openSheet(tester);

      expect(
        tester.getSemantics(agree),
        isSemantics(
          isButton: true,
          // Described the way it looks and the way it behaves: not available
          // yet, and carrying the reason why.
          hasEnabledState: true,
          isEnabled: false,
          label: stringsFor(AppLocale.english).acknowledge,
          hint: gateHint,
        ),
      );
      semantics.dispose();
    });

    testWidgets('the hint announces itself when it appears', (tester) async {
      final semantics = tester.ensureSemantics();
      await openSheet(tester);
      await tester.tap(agree);
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(hint),
        isSemantics(label: gateHint, isLiveRegion: true),
        reason:
            'the explanation is visual only, or shares a node with the '
            'fixed line below it',
      );
      semantics.dispose();
    });

    testWidgets('a scroll action, not a swipe, can reach the end', (
      tester,
    ) async {
      // The gate must not depend on a drag gesture: assistive technology and
      // a D-pad both scroll through the semantics scroll action instead.
      final semantics = tester.ensureSemantics();
      final result = await openSheet(tester);

      // `scrollUp` moves the content up, which is what reveals what is below
      // it — the forward direction. It disappears from the tree once there is
      // nothing left below, which is itself the signal that the end is here.
      expect(
        find.semantics.byAction(SemanticsAction.scrollUp),
        findsWidgets,
        reason: 'the policy offers no accessible way to scroll at all',
      );
      for (var i = 0; i < 30; i++) {
        final scrollable = find.semantics.byAction(SemanticsAction.scrollUp);
        if (scrollable.evaluate().isEmpty) break;
        tester.semantics.performAction(
          scrollable.first,
          SemanticsAction.scrollUp,
        );
        await tester.pumpAndSettle();
      }

      expect(
        agreeBackground(tester),
        isNull,
        reason: 'the end could not be reached without a swipe',
      );
      await tester.tap(agree);
      await tester.pumpAndSettle();
      expect(result(), isTrue);
      semantics.dispose();
    });
  });

  group('through the real first reading', () {
    // The sheet tests above mount the sheet on its own. These go through the
    // ritual screen, because what matters is not what the sheet returns but
    // whether a reading happens, and nothing between the button and the
    // engine is exercised by mounting the sheet alone.
    //
    // Fixed pumps rather than `pumpAndSettle`: the ritual screen's reveal
    // pulse animates forever, so nothing on this route ever reaches a quiet
    // frame — settling here hangs until the test times out.
    final reveal = find.byKey(const Key('reveal_button'));

    Future<void> settle(WidgetTester tester) async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
    }

    Future<void> dragToEnd(WidgetTester tester) async {
      for (var i = 0; i < 12; i++) {
        await tester.drag(
          find.byType(SingleChildScrollView).first,
          const Offset(0, -600),
          warnIfMissed: false,
        );
        await settle(tester);
      }
    }

    Future<ReadingTestRig> openFirstReveal(WidgetTester tester) async {
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
        safetyAcknowledged: false,
      );
      await tester.pumpWidget(rig.app);
      await completeOnboarding(tester);
      await tester.ensureVisible(find.byKey(const Key('find_direction')));
      await tester.tap(find.byKey(const Key('find_direction')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      await tester.tap(reveal);
      await settle(tester);
      expect(sheet, findsOneWidget, reason: 'the first-time gate did not open');
      return rig;
    }

    testWidgets('the locked button cannot start a reading', (tester) async {
      final rig = await openFirstReveal(tester);

      await tester.tap(agree);
      await settle(tester);
      expect(hint, findsOneWidget);

      // Long enough for any ritual delay a real reveal would have started.
      await tester.pump(const Duration(milliseconds: 5400));
      await settle(tester);

      expect(sheet, findsOneWidget, reason: 'the sheet closed on a locked tap');
      expect(rig.repository.requests, isEmpty);
      expect(rig.contextProvider.captures, isEmpty);
      expect(find.byKey(const Key('result_ready')), findsNothing);
    });

    testWidgets('dismissing without agreeing leaves the ritual usable', (
      tester,
    ) async {
      final rig = await openFirstReveal(tester);

      await tester.tapAt(const Offset(400, 8)); // the modal barrier
      await settle(tester);

      expect(sheet, findsNothing);
      expect(rig.repository.requests, isEmpty);
      // Not trapped: the ritual screen is still there and still offers Reveal.
      expect(reveal, findsOneWidget);

      // And the gate comes back on the next attempt rather than being spent.
      await tester.tap(reveal);
      await settle(tester);
      expect(sheet, findsOneWidget);
      expect(agree, findsOneWidget);
    });

    testWidgets('reading to the end and agreeing starts exactly one reading', (
      tester,
    ) async {
      final rig = await openFirstReveal(tester);
      await dragToEnd(tester);
      await tester.tap(agree);
      await settle(tester);

      expect(sheet, findsNothing);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 5400));
      await tester.pumpAndSettle();

      expect(rig.repository.requests, hasLength(1));
      expect(find.byKey(const Key('result_ready')), findsOneWidget);
    });
  });
}
