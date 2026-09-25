import 'package:country_picker/country_picker.dart';
import 'package:decision_compass/local_engine/time/tzdb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reading_test_rig.dart';

void main() {
  test(
    'country search covers the launch countries and engine-supported codes',
    () {
      final codes = CountryService()
          .getAll()
          .map((country) => country.countryCode)
          .toSet();
      expect(codes.length, greaterThan(200));
      expect(codes, containsAll(['US', 'JP', 'ES', 'TH', 'VN']));
      expect(
        codes.intersection(tzdbCountries().toSet()).length,
        greaterThan(200),
      );
    },
  );

  testWidgets('a birth date and country must be explicitly selected', (
    tester,
  ) async {
    final rig = ReadingTestRig();
    await tester.pumpWidget(rig.app);
    await tester.pump();
    await tester.tap(find.byKey(const Key('continue_to_profile')));
    await tester.pumpAndSettle();

    expect(find.text('Alex'), findsNothing);
    expect(find.text('Select your date of birth'), findsOneWidget);
    expect(find.text('Search and select a country'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('complete_profile')));
    await tester.tap(find.byKey(const Key('complete_profile')));
    await tester.pump();

    expect(find.text('Select your birth date to continue.'), findsOneWidget);
    expect(
      find.text('Select your country of birth to continue.'),
      findsOneWidget,
    );
    expect(await rig.profileRepository.load(), isNull);
  });
}
