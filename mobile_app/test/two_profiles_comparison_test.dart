// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:decision_compass/app_locale.dart';
import 'package:decision_compass/data/action_guidance.dart';
import 'package:decision_compass/data/models/models.dart';
import 'package:decision_compass/local_engine/local_reading_engine.dart';

void main() {
  test('compare real engine readings across two distinct profiles', () {
    final context = <String, Object?>{
      'instantUtc': '2026-10-16T01:30:00.000Z',
      'deviceTimezone': 'Asia/Ho_Chi_Minh',
    };

    // Profile 1: 1990-05-15 (Canh Ngọ / Nam)
    final res1 = calculateReading(
      profile: {
        'birthDate': '1990-05-15',
        'birthTime': '08:00',
        'birthCountry': 'VN',
        'traditionalProfile': 'male',
        'revision': 1,
      },
      context: context,
      period: 'morning',
      mode: 'act_wait',
      category: 'career',
    );
    final r1 = ReadingResponse.fromJson(res1);
    final g1 = resolveActionGuidance(locale: AppLocale.vietnamese, reading: r1);

    // Profile 2: 1997-10-24 (Đinh Sửu / Nữ)
    final res2 = calculateReading(
      profile: {
        'birthDate': '1997-10-24',
        'birthTime': '15:30',
        'birthCountry': 'VN',
        'traditionalProfile': 'female',
        'revision': 1,
      },
      context: context,
      period: 'morning',
      mode: 'act_wait',
      category: 'career',
    );
    final r2 = ReadingResponse.fromJson(res2);
    final g2 = resolveActionGuidance(locale: AppLocale.vietnamese, reading: r2);

    print('\n============================================================');
    print('HỒ SƠ 1: Sinh 15/05/1990 (Nam)');
    print('Kết quả quẻ: ${r1.winner} (${r1.percentages?[r1.winner ?? '']}%) - readingKey: ${r1.readingKey}');
    print('【BỐI CẢNH VẬN TRÌNH】\n${g1.headline}');
    print('【CHỈ DẪN HÀNH ĐỘNG】');
    print('• Nên: ${g1.shouldDo}');
    print('• Tránh: ${g1.avoid}');

    print('\n============================================================');
    print('HỒ SƠ 2: Sinh 24/10/1997 (Nữ)');
    print('Kết quả quẻ: ${r2.winner} (${r2.percentages?[r2.winner ?? '']}%) - readingKey: ${r2.readingKey}');
    print('【BỐI CẢNH VẬN TRÌNH】\n${g2.headline}');
    print('【CHỈ DẪN HÀNH ĐỘNG】');
    print('• Nên: ${g2.shouldDo}');
    print('• Tránh: ${g2.avoid}');

    expect(g1.headline, isNot(g2.headline));
    expect(g1.shouldDo, isNot(g2.shouldDo));
    expect(g1.avoid, isNot(g2.avoid));
    expect(g1.headline, contains('Kim'));
    expect(g2.headline, contains('Thổ'));
  });

  test('compare english readings across two distinct profiles (Zodiac differentiation)', () {
    final context = <String, Object?>{
      'instantUtc': '2026-10-16T13:00:00.000Z',
      'deviceTimezone': 'America/New_York',
    };

    // Profile 1: May 15 (Taurus)
    final res1 = calculateReading(
      profile: {
        'birthDate': '1990-05-15',
        'birthTime': '08:00',
        'birthCountry': 'US',
        'traditionalProfile': 'male',
        'revision': 1,
      },
      context: context,
      period: 'morning',
      mode: 'act_wait',
      category: 'career',
    );
    final r1 = ReadingResponse.fromJson(res1);
    final g1 = resolveActionGuidance(locale: AppLocale.english, reading: r1);

    // Profile 2: Oct 24 (Scorpio)
    final res2 = calculateReading(
      profile: {
        'birthDate': '1997-10-24',
        'birthTime': '15:30',
        'birthCountry': 'US',
        'traditionalProfile': 'female',
        'revision': 1,
      },
      context: context,
      period: 'morning',
      mode: 'act_wait',
      category: 'career',
    );
    final r2 = ReadingResponse.fromJson(res2);
    final g2 = resolveActionGuidance(locale: AppLocale.english, reading: r2);

    print('EN r1 status: ${r1.status}, winner: ${r1.winner}, key: ${r1.readingKey}');
    print('EN r1 guidance:\n${g1.headline}\n${g1.shouldDo}\n${g1.avoid}');
    print('EN r2 status: ${r2.status}, winner: ${r2.winner}, key: ${r2.readingKey}');
    print('EN r2 guidance:\n${g2.headline}\n${g2.shouldDo}\n${g2.avoid}');

    expect(g1.headline, isNot(g2.headline));
    expect(g1.headline, contains('Taurus'));
    expect(g2.headline, contains('Scorpio'));
    expect(g1.shouldDo, isNot(g2.shouldDo));
    expect(g1.avoid, isNot(g2.avoid));
  });
}
