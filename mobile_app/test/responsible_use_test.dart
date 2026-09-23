import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reading_test_rig.dart';

void main() {
  testWidgets(
    'first reading reveal triggers safety boundaries modal with 7 prohibited categories',
    (tester) async {
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
        safetyAcknowledged: false,
      );
      await tester.pumpWidget(rig.app);
      await completeOnboarding(tester);

      // On Home, tap Find My Direction to enter RitualPage
      await tester.ensureVisible(find.byKey(const Key('find_direction')));
      await tester.tap(find.byKey(const Key('find_direction')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      // We are on RitualPage
      expect(find.byKey(const Key('reveal_button')), findsOneWidget);
      expect(
        find.text(
          'For everyday reflection only • Never for medical, financial, political, or harmful choices.',
        ),
        findsOneWidget,
      );

      // Ritual header has the Responsible Use shield icon
      final ritualShield = find.byKey(
        const Key('ritual_responsible_use_button'),
      );
      expect(ritualShield, findsOneWidget);
      await tester.tap(ritualShield);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Sheet opens in reference mode (has Close button and Crisis Support)
      expect(find.byKey(const Key('close_safety_sheet')), findsOneWidget);
      expect(find.textContaining('Crisis Support:'), findsOneWidget);
      await tester.tap(find.byKey(const Key('close_safety_sheet')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Tap reveal for the first time: triggers the safety modal
      await tester.tap(find.byKey(const Key('reveal_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // The safety sheet is presented
      expect(find.text('BOUNDARIES & RESPONSIBLE USE'), findsOneWidget);
      expect(find.text('A Mirror for Everyday Moments'), findsOneWidget);

      // Check all 7 safety pillars
      expect(find.text('Harm & Self-Violence'), findsOneWidget);
      expect(find.text('Driving & Physical Navigation'), findsOneWidget);
      expect(find.text('Politics & Social Conflicts'), findsOneWidget);
      expect(find.text('Health, Medical & Emergencies'), findsOneWidget);
      expect(
        find.text('Legal, Criminal & High-Stakes Contracts'),
        findsOneWidget,
      );
      expect(find.text('Financial Investments & Gambling'), findsOneWidget);
      expect(find.text('Consent, Minors & Relationships'), findsOneWidget);

      // Check legal disclaimers
      expect(find.text('LEGAL DISCLAIMER & AGE NOTICE'), findsOneWidget);
      expect(
        find.textContaining('Age Requirement: You must be at least 13'),
        findsOneWidget,
      );
      expect(find.textContaining('No Professional Advice'), findsOneWidget);
      expect(find.textContaining('Assumption of Risk'), findsOneWidget);

      // Accept agreement
      final agreeButton = find.byKey(const Key('agree_safety_boundaries'));
      expect(agreeButton, findsOneWidget);
      await tester.tap(agreeButton);
      await tester.pump(const Duration(milliseconds: 380));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 5300));
      await tester.pumpAndSettle();

      // On ResultPage, verify footer link opens safety sheet
      final footerLink = find.byKey(const Key('result_responsible_use_link'));
      expect(footerLink, findsOneWidget);
      await tester.ensureVisible(footerLink);
      await tester.tap(footerLink);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('close_safety_sheet')), findsOneWidget);
      await tester.tap(find.byKey(const Key('close_safety_sheet')));
      await tester.pumpAndSettle();

      // Go back to Home
      await tester.tap(find.text('Try Another Direction'));
      await tester.pumpAndSettle();

      // Tap Find My Direction again
      await tester.ensureVisible(find.byKey(const Key('find_direction')));
      await tester.tap(find.byKey(const Key('find_direction')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      // Tap Reveal on the second reading: safety modal must NOT appear
      await tester.tap(find.byKey(const Key('reveal_button')));
      await tester.pump(const Duration(milliseconds: 380));
      await tester.pump();

      // Directly locks moment and enters loading without showing modal
      expect(find.byKey(const Key('agree_safety_boundaries')), findsNothing);

      // Drain loading timer so no pending timers remain at test exit
      await tester.pump(const Duration(milliseconds: 5400));
      await tester.pumpAndSettle();
    },
  );
}
