import 'package:decision_compass/local_engine/astronomy/astronomy.dart';
import 'package:decision_compass/local_engine/time/local_time.dart';
import 'package:decision_compass/local_engine/vedic/vedic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Vedic Jyotish Module', () {
    test('Lahiri Ayanamsa computes valid astronomical offset', () {
      const j2000 = 946728000000.0;
      expect((ayanamsaLahiri(j2000) - 23.8617).abs(), lessThan(0.001));

      final ms2026 =
          DateTime.parse('2026-09-18T08:30:00Z').millisecondsSinceEpoch.toDouble();
      final a2026 = ayanamsaLahiri(ms2026);
      expect(a2026, greaterThan(24.2));
      expect(a2026, lessThan(24.3));
    });

    test('sidereal conversion maps tropical degrees within 0..360', () {
      expect(toSidereal(30, 24), 6);
      expect(toSidereal(10, 24), 346);
    });

    test('all 27 Nakshatras have valid normalized vectors', () {
      expect(nakshatraNames.length, 27);
      expect(nakshatraVectors.length, 27);
      for (var i = 0; i < 27; i++) {
        final v = nakshatraVectors[i];
        expect(v[0], inInclusiveRange(-1.0, 1.0));
        expect(v[1], inInclusiveRange(-1.0, 1.0));
      }
    });

    test('tithi vectors reward waxing purna and penalize rikta/amavasya', () {
      final purna = tithiVector(15);
      final rikta = tithiVector(4);
      final amavasya = tithiVector(30);
      expect(purna[0], greaterThan(rikta[0]));
      expect(purna[0], greaterThan(amavasya[0]));
      expect(rikta[0], lessThan(0));
      expect(amavasya[0], lessThan(0));
    });

    test('gochara Upachaya houses are positive and house 8 is cautionary', () {
      for (final h in [3, 6, 10, 11]) {
        expect(gocharaVector(h)[0], greaterThan(0));
      }
      expect(gocharaVector(8)[0], lessThan(0));
      expect(gocharaVector(12)[0], lessThan(0));
    });

    test('scoreVedic produces valid evidence and diagnostics', () {
      final birth = birthContext(
        birthDate: '1998-06-21',
        birthTime: '14:30',
        birthCountry: 'VN',
      );
      final natal = natalSky(birth);
      final now =
          DateTime.parse('2026-09-18T08:30:00Z').millisecondsSinceEpoch.toDouble();
      final res = scoreVedic(now, birth, natal);

      expect(res.status, 'calculated');
      expect(res.evidence.coverage, greaterThan(0));
      expect(res.evidence.coverage, lessThanOrEqualTo(1));
      expect(res.evidence.a, inInclusiveRange(-1.0, 1.0));
      expect(res.evidence.c, inInclusiveRange(-1.0, 1.0));
      expect(res.diagnostics['nakshatra'], isNotNull);
      final tithi = res.diagnostics['tithi']! as int;
      expect(tithi, inInclusiveRange(1, 30));
      final karana = res.diagnostics['karana']! as int;
      expect(karana, inInclusiveRange(1, 60));
      final gocharaHouse = res.diagnostics['gocharaHouse']! as int;
      expect(gocharaHouse, inInclusiveRange(1, 12));
    });
  });
}
