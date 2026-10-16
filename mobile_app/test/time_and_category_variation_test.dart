// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:decision_compass/app_locale.dart';
import 'package:decision_compass/data/action_guidance.dart';
import 'package:decision_compass/data/models/models.dart';
import 'package:decision_compass/local_engine/local_reading_engine.dart';

void main() {
  final profile = <String, Object?>{
    'birthDate': '1990-05-15',
    'birthTime': '08:00',
    'birthCountry': 'VN',
    'traditionalProfile': 'male',
    'revision': 1,
  };

  test('verify distinct categories produce distinct guidance for the same profile', () {
    final context = <String, Object?>{
      'instantUtc': '2026-10-16T01:30:00.000Z', // 08:30 AM VN
      'deviceTimezone': 'Asia/Ho_Chi_Minh',
    };

    final categories = ['career', 'money', 'love', 'study', 'friends', 'general'];
    final headlines = <String>{};
    final shouldDos = <String>{};
    final avoids = <String>{};

    print('\n================ CÙNG 1 HỒ SƠ - CÁC LĨNH VỰC KHÁC NHAU ================');
    for (final cat in categories) {
      final res = calculateReading(
        profile: profile,
        context: context,
        period: 'morning',
        mode: 'act_wait',
        category: cat,
      );
      final reading = ReadingResponse.fromJson(res);
      final guidance = resolveActionGuidance(locale: AppLocale.vietnamese, reading: reading);

      print('\nLĩnh vực [$cat]:');
      print('Quẻ: ${reading.winner} - Điểm: ${reading.percentages?[reading.winner ?? '']}%');
      print('Bối cảnh: ${guidance.headline}');
      print('Nên: ${guidance.shouldDo}');
      print('Tránh: ${guidance.avoid}');

      headlines.add(guidance.headline);
      shouldDos.add(guidance.shouldDo);
      avoids.add(guidance.avoid);
    }

    // All categories must produce distinct headlines
    expect(headlines.length, equals(categories.length),
        reason: 'Every category must have a distinct headline');
  });

  test('verify distinct time periods produce distinct guidance for the same profile', () {
    // Test different time slots on the same day
    final times = [
      ('morning', '2026-10-16T01:30:00.000Z'), // 08:30 AM VN
      ('afternoon', '2026-10-16T07:30:00.000Z'), // 14:30 PM VN
      ('evening', '2026-10-16T13:00:00.000Z'), // 20:00 PM VN
      ('now', '2026-10-16T03:00:00.000Z'), // 10:00 AM VN
    ];

    final headlines = <String>{};
    final shouldDos = <String>{};
    final avoids = <String>{};

    print('\n================ CÙNG 1 HỒ SƠ - CÁC THỜI GIAN KHÁC NHAU ================');
    for (final (period, instant) in times) {
      final context = <String, Object?>{
        'instantUtc': instant,
        'deviceTimezone': 'Asia/Ho_Chi_Minh',
      };

      final res = calculateReading(
        profile: profile,
        context: context,
        period: period,
        mode: 'act_wait',
        category: 'career',
      );
      final reading = ReadingResponse.fromJson(res);
      final guidance = resolveActionGuidance(locale: AppLocale.vietnamese, reading: reading);

      print('\nThời gian [$period]:');
      print('Quẻ: ${reading.winner} - Điểm: ${reading.percentages?[reading.winner ?? '']}%');
      print('Bối cảnh: ${guidance.headline}');
      print('Nên: ${guidance.shouldDo}');
      print('Tránh: ${guidance.avoid}');

      headlines.add(guidance.headline);
      shouldDos.add(guidance.shouldDo);
      avoids.add(guidance.avoid);
    }

    // All time periods must produce distinct headlines
    expect(headlines.length, equals(times.length),
        reason: 'Every time period must have a distinct headline');
    // Period prefixes in shouldDo and avoid must differentiate them
    expect(shouldDos.length, equals(times.length),
        reason: 'Time-of-day lenses must provide distinct shouldDos');
    expect(avoids.length, equals(times.length),
        reason: 'Time-of-day lenses must provide distinct avoids');
  });

  test('verify distinct calendar days produce distinct spiritual transit anchors', () {
    // 2 consecutive days: 2026-10-16 (Quý Hợi) and 2026-10-17 (Giáp Tý)
    final day1Context = <String, Object?>{
      'instantUtc': '2026-10-16T01:30:00.000Z',
      'deviceTimezone': 'Asia/Ho_Chi_Minh',
    };
    final day2Context = <String, Object?>{
      'instantUtc': '2026-10-17T01:30:00.000Z',
      'deviceTimezone': 'Asia/Ho_Chi_Minh',
    };

    final res1 = calculateReading(
      profile: profile,
      context: day1Context,
      period: 'morning',
      mode: 'act_wait',
      category: 'career',
    );
    final res2 = calculateReading(
      profile: profile,
      context: day2Context,
      period: 'morning',
      mode: 'act_wait',
      category: 'career',
    );

    final g1 = resolveActionGuidance(locale: AppLocale.vietnamese, reading: ReadingResponse.fromJson(res1));
    final g2 = resolveActionGuidance(locale: AppLocale.vietnamese, reading: ReadingResponse.fromJson(res2));

    print('\n================ CÙNG 1 HỒ SƠ - 2 NGÀY LIÊN TIẾP ================');
    print('Ngày 16/10:\n${g1.headline}');
    print('Ngày 17/10:\n${g2.headline}');

    expect(g1.headline, isNot(g2.headline));
    expect(g1.headline, contains('Quý Hợi'));
    expect(g2.headline, contains('Giáp Tý'));
  });
}
