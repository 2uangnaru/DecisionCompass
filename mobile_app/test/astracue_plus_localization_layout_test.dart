import 'package:decision_compass/app_locale.dart';
import 'package:decision_compass/widgets/astracue_plus_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reading_test_rig.dart';

void main() {
  setUpAll(loadBundledFonts);

  const narrow = Size(360, 640);

  void expectNoLayoutTrouble(WidgetTester tester, String where) {
    final thrown = tester.takeException();
    if (thrown == null) return;
    if ('$thrown'.contains('is not supported by all of its localization')) {
      return;
    }
    fail('$where: $thrown');
  }

  for (final locale in AppLocale.values) {
    for (final scale in const [1.0, 1.25, 1.5]) {
      final at =
          '${locale.tag} @ ${narrow.width.toInt()}x${narrow.height.toInt()} scale=$scale';

      testWidgets('AstraCuePlusSheet renders cleanly without overflow, $at', (
        tester,
      ) async {
        useScreen(tester, size: narrow, textScale: scale);

        await tester.pumpWidget(
          localizedApp(
            locale: locale,
            home: Scaffold(
              body: Center(
                child: AstraCuePlusSheet(
                  locale: locale,
                  snapshot: const ReadingEnergySnapshot(
                    usedFreeTurns: 2,
                    remainingFreeTurns: 1,
                    cooldownRemaining: Duration(minutes: 45),
                    timeUntilMidnight: Duration(hours: 6),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expectNoLayoutTrouble(tester, 'AstraCuePlusSheet $at');

        // Check CTA button exists and is visible
        expect(
          find.byKey(const Key('astracue_plus_sheet_cta')),
          findsOneWidget,
        );

        // Check sheet container width does not exceed screen
        final sheetSize = tester.getSize(
          find.byKey(const Key('astracue_plus_sheet')),
        );
        expect(sheetSize.width, lessThanOrEqualTo(narrow.width));
      });

      testWidgets('HomeEmbeddedEnergyTray renders cleanly, $at', (
        tester,
      ) async {
        useScreen(tester, size: narrow, textScale: scale);

        await tester.pumpWidget(
          localizedApp(
            locale: locale,
            home: Scaffold(
              body: HomeEmbeddedEnergyTray(
                locale: locale,
                snapshot: const ReadingEnergySnapshot(
                  usedFreeTurns: 3,
                  remainingFreeTurns: 0,
                  cooldownRemaining: Duration.zero,
                  timeUntilMidnight: Duration(hours: 4, minutes: 12),
                ),
                onTapPlus: () {},
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expectNoLayoutTrouble(tester, 'HomeEmbeddedEnergyTray $at');
      });

      testWidgets(
        'AnalysisEnergyPlusCard singleRow & doubleRow render cleanly, $at',
        (tester) async {
          useScreen(tester, size: narrow, textScale: scale);

          await tester.pumpWidget(
            localizedApp(
              locale: locale,
              home: Scaffold(
                body: Column(
                  children: [
                    AnalysisEnergyPlusCard(
                      locale: locale,
                      snapshot: const ReadingEnergySnapshot(
                        usedFreeTurns: 1,
                        remainingFreeTurns: 2,
                        cooldownRemaining: Duration.zero,
                        timeUntilMidnight: Duration(hours: 8),
                      ),
                      isPostReadingResult: false, // single row
                      onTapPlus: () {},
                    ),
                    const SizedBox(height: 12),
                    AnalysisEnergyPlusCard(
                      locale: locale,
                      snapshot: const ReadingEnergySnapshot(
                        usedFreeTurns: 2,
                        remainingFreeTurns: 1,
                        cooldownRemaining: Duration(hours: 1, minutes: 30),
                        timeUntilMidnight: Duration(hours: 8),
                      ),
                      isPostReadingResult: true, // 2-cell row
                      onTapPlus: () {},
                    ),
                  ],
                ),
              ),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expectNoLayoutTrouble(tester, 'AnalysisEnergyPlusCard $at');
        },
      );
    }
  }
}
