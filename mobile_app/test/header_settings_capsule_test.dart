import 'package:decision_compass/data/locale_store.dart';
import 'package:decision_compass/data/locale_controller.dart';
import 'package:decision_compass/l10n/app_localizations.dart';
import 'package:decision_compass/theme.dart';
import 'package:decision_compass/widgets/header_settings_capsule.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reading_test_rig.dart';

void main() {
  Widget buildTestCapsule({
    required bool isOpen,
    required VoidCallback onToggle,
    required VoidCallback onClose,
    VoidCallback? onOpenResponsibleUse,
    VoidCallback? onOpenHistory,
  }) {
    final controller = LocaleController(store: InMemoryLocaleStore());
    return MaterialApp(
      theme: buildCompassTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: HeaderSettingsCapsule(
            isOpen: isOpen,
            onToggle: onToggle,
            onClose: onClose,
            localeController: controller,
            onOpenResponsibleUse: onOpenResponsibleUse ?? () {},
            onOpenHistory: onOpenHistory ?? () {},
          ),
        ),
      ),
    );
  }

  group('HeaderSettingsCapsule', () {
    testWidgets('starts collapsed as a 41x41 circle with 6-tooth gear', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestCapsule(
          isOpen: false,
          onToggle: () {},
          onClose: () {},
        ),
      );
      await tester.pumpAndSettle();

      // Evaluates width rendered
      final size = tester.getSize(find.byKey(const Key('header_actions_capsule')));
      expect(size.width, HeaderSettingsCapsule.collapsedWidth);
      expect(size.height, HeaderSettingsCapsule.capsuleHeight);

      // Gear button is visible with Icons.settings_rounded
      expect(find.byKey(const Key('home_settings_button')), findsOneWidget);
      expect(find.byIcon(Icons.settings_rounded), findsOneWidget);

      final icon = tester.widget<Icon>(find.byIcon(Icons.settings_rounded));
      expect(icon.color, CompassColors.secondary);

      // The 3 action buttons are present in tree but ignored for pointer events
      final ignoreWidgets = tester.widgetList<IgnorePointer>(find.ancestor(
        of: find.byKey(const Key('language_button')),
        matching: find.byType(IgnorePointer),
      ));
      expect(ignoreWidgets.any((w) => w.ignoring), isTrue);

      // No vertical line separator │ in capsule
      expect(find.text('│'), findsNothing);
    });

    testWidgets('expands to 160px width when open and enables action buttons', (
      tester,
    ) async {
      var toggled = false;
      var closed = false;
      var openedResponsibleUse = false;
      var openedHistory = false;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return buildTestCapsule(
              isOpen: toggled,
              onToggle: () => setState(() => toggled = !toggled),
              onClose: () => setState(() => closed = true),
              onOpenResponsibleUse: () => openedResponsibleUse = true,
              onOpenHistory: () => openedHistory = true,
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      // Tap settings button to expand
      await tester.tap(find.byKey(const Key('home_settings_button')));
      await tester.pumpAndSettle();

      expect(toggled, isTrue);
      final size = tester.getSize(find.byKey(const Key('header_actions_capsule')));
      expect(size.width, HeaderSettingsCapsule.expandedWidth);

      // 3 action buttons are now active
      final activeIgnoreWidgets = tester.widgetList<IgnorePointer>(find.ancestor(
        of: find.byKey(const Key('language_button')),
        matching: find.byType(IgnorePointer),
      ));
      expect(activeIgnoreWidgets.any((w) => w.ignoring), isFalse);

      // Tapping responsible use triggers callback and onClose
      await tester.tap(find.byKey(const Key('home_responsible_use_button')));
      await tester.pumpAndSettle();
      expect(openedResponsibleUse, isTrue);
      expect(closed, isTrue);

      // Reset and test history button
      closed = false;
      await tester.tap(find.byKey(const Key('home_history_button')));
      await tester.pumpAndSettle();
      expect(openedHistory, isTrue);
      expect(closed, isTrue);
    });

    testWidgets(
      'on HomePage, opening settings does not shrink the name, and tapping outside or scrolling closes it',
      (tester) async {
        final rig = ReadingTestRig(
          response: fixtureResponse('ready_yes_no_now.json'),
          localNow: DateTime(2026, 9, 18, 7),
        );
        await tester.pumpWidget(rig.app);
        await completeOnboarding(tester);
        await tester.pump();

        // Find the name text widget
        final nameFinder = find.text('Explorer');
        expect(nameFinder, findsOneWidget);
        final sizeBefore = tester.getSize(nameFinder);

        // Open settings capsule
        await tester.tap(find.byKey(const Key('home_settings_button')));
        await tester.pumpAndSettle();

        // The name size does NOT change when settings is open
        final sizeAfter = tester.getSize(nameFinder);
        expect(sizeAfter, equals(sizeBefore));

        // Capsule is open (172px width)
        final capsuleFinder = find.byKey(const Key('header_actions_capsule'));
        expect(
          tester.getSize(capsuleFinder).width,
          HeaderSettingsCapsule.expandedWidth,
        );

        // Tapping outside (e.g. positioning title) closes it automatically
        await tester.tap(find.byKey(const Key('home_positioning')));
        await tester.pumpAndSettle();
        expect(
          tester.getSize(capsuleFinder).width,
          HeaderSettingsCapsule.collapsedWidth,
        );

        // Re-open settings capsule
        await tester.tap(find.byKey(const Key('home_settings_button')));
        await tester.pumpAndSettle();
        expect(
          tester.getSize(capsuleFinder).width,
          HeaderSettingsCapsule.expandedWidth,
        );

        // Scrolling closes it automatically
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -100),
        );
        await tester.pumpAndSettle();
        expect(
          tester.getSize(capsuleFinder).width,
          HeaderSettingsCapsule.collapsedWidth,
        );
      },
    );
  });
}
