import 'package:decision_compass/app_locale.dart';
import 'package:decision_compass/data/action_guidance.dart';
import 'package:decision_compass/data/models/models.dart';
import 'package:decision_compass/data/action_guidance/action_guidance_en.dart';
import 'package:decision_compass/data/action_guidance/action_guidance_es.dart';
import 'package:decision_compass/data/action_guidance/action_guidance_hi.dart';
import 'package:decision_compass/data/action_guidance/action_guidance_ja.dart';
import 'package:decision_compass/data/action_guidance/action_guidance_ko.dart';
import 'package:decision_compass/data/action_guidance/action_guidance_th.dart';
import 'package:decision_compass/data/action_guidance/action_guidance_vi.dart';
import 'package:decision_compass/data/action_guidance/action_guidance_zh.dart';
import 'package:flutter_test/flutter_test.dart';

import 'data/fixture_loader.dart';

/// Builds a reading that differs from a fixture only in mode and winner, so a
/// guidance test can vary the one thing it is about.
ReadingResponse _reading(
  ReadingResponse base, {
  required DecisionMode mode,
  required String winner,
}) {
  final json = readFixture('ready_yes_no_now.json');
  json['mode'] = mode.wireValue;
  json['winner'] = winner;
  final percentages = <String, Object?>{};
  final labels = _pair[mode]!;
  percentages[labels.$1] = winner == labels.$1 ? 62.5 : 37.5;
  percentages[labels.$2] = winner == labels.$1 ? 37.5 : 62.5;
  json['percentages'] = percentages;
  final snapshot = Map<String, Object?>.from(json['inputSnapshot']! as JsonMap);
  snapshot['mode'] = mode.wireValue;
  json['inputSnapshot'] = snapshot;
  return ReadingResponse.fromJson(json);
}

const Map<DecisionMode, (String, String)> _pair =
    <DecisionMode, (String, String)>{
      DecisionMode.yesNo: ('YES', 'NO'),
      DecisionMode.actWait: ('ACT', 'WAIT'),
      DecisionMode.advanceRetreat: ('ADVANCE', 'RETREAT'),
      DecisionMode.stayGo: ('STAY', 'GO'),
      DecisionMode.keepLetGo: ('KEEP', 'LET GO'),
      DecisionMode.commitWithdraw: ('COMMIT', 'WITHDRAW'),
      DecisionMode.leftRight: ('LEFT', 'RIGHT'),
      DecisionMode.reasonEmotion: ('REASON', 'EMOTION'),
      DecisionMode.confrontAvoid: ('CONFRONT', 'AVOID'),
    };

/// The seven core modes that currently have dedicated action guidance dictionaries.
/// New modes (reasonEmotion, confrontAvoid) safely fall back to the balanced reflection.
const List<DecisionMode> _modesWithDedicatedGuidance = <DecisionMode>[
  DecisionMode.yesNo,
  DecisionMode.actWait,
  DecisionMode.advanceRetreat,
  DecisionMode.stayGo,
  DecisionMode.keepLetGo,
  DecisionMode.commitWithdraw,
  DecisionMode.leftRight,
];

/// Words the guidance must never contain, per language.
///
/// The list is deliberately about *acting on the world*: telling a reader to
/// invest, pay out, quit or end a relationship. The app does not know what
/// anyone is deciding, so it cannot responsibly say any of these.
const Map<AppLocale, List<String>> _forbidden = <AppLocale, List<String>>{
  AppLocale.english: <String>[
    'invest',
    'money',
    'salary',
    'loan',
    'profit',
    'buy',
    'sell',
    'pay',
    'relationship',
    'partner',
    'break up',
    'walk away',
    'leave them',
    'quit',
    'resign',
    'marry',
    'divorce',
  ],
  AppLocale.vietnamese: <String>[
    'đầu tư',
    'tiền',
    'lương',
    'vay',
    'lợi nhuận',
    'mua',
    'bán',
    'chia tay',
    'ly hôn',
    'nghỉ việc',
    'người yêu',
    'kết hôn',
  ],
  AppLocale.spanish: <String>[
    'invertir',
    'dinero',
    'sueldo',
    'préstamo',
    'comprar',
    'vender',
    'relación',
    'pareja',
    'romper',
    'renunciar',
    'casarte',
    'divorcio',
  ],
  AppLocale.japanese: <String>[
    '投資',
    'お金',
    '給料',
    '借金',
    '買う',
    '売る',
    '恋人',
    '別れ',
    '離婚',
    '退職',
    '結婚',
  ],
  AppLocale.thai: <String>[
    'ลงทุน',
    'เงิน',
    'เงินเดือน',
    'กู้',
    'ซื้อ',
    'ขาย',
    'แฟน',
    'เลิกกัน',
    'หย่า',
    'ลาออก',
    'แต่งงาน',
  ],
  AppLocale.hindi: <String>[
    'निवेश',
    'पैसा',
    'वेतन',
    'कर्ज',
    'खरीद',
    'बेचें',
    'बेचना',
    'रिश्ता',
    'साथी',
    'तलाक',
    'नौकरी छोड़',
    'शादी',
  ],
  AppLocale.simplifiedChinese: <String>[
    '投资',
    '钱',
    '工资',
    '贷款',
    '买',
    '卖',
    '恋人',
    '分手',
    '离婚',
    '辞职',
    '结婚',
  ],
  AppLocale.korean: <String>[
    '투자',
    '돈',
    '급여',
    '대출',
    '구매',
    '사다',
    '팔다',
    '연인',
    '결혼',
    '이혼',
    '퇴사',
    '헤어지',
  ],
};

void main() {
  late ReadingResponse base;
  late ReadingResponse balanced;

  setUpAll(() {
    base = ReadingResponse.fromJson(readFixture('ready_yes_no_now.json'));
    balanced = ReadingResponse.fromJson(readFixture('synthetic_balanced.json'));
  });

  group('every mode and side is covered, in every language', () {
    test('no combination falls back to the balanced text by accident', () {
      for (final locale in AppLocale.values) {
        final balancedText = resolveActionGuidance(
          locale: locale,
          reading: balanced,
        );
        for (final mode in _modesWithDedicatedGuidance) {
          for (final winner in <String>[_pair[mode]!.$1, _pair[mode]!.$2]) {
            final guidance = resolveActionGuidance(
              locale: locale,
              reading: _reading(base, mode: mode, winner: winner),
            );
            for (final text in <String>[
              guidance.title,
              guidance.headline,
              guidance.shouldDo,
              guidance.avoid,
              guidance.shouldDoTag,
              guidance.avoidTag,
            ]) {
              expect(
                text.trim(),
                isNotEmpty,
                reason: '${locale.tag} ${mode.wireValue} $winner',
              );
            }
            expect(
              guidance.headline,
              isNot(balancedText.headline),
              reason:
                  '${locale.tag} ${mode.wireValue} $winner fell through to '
                  'the balanced entry',
            );
          }
        }
      }
    });

    test('the two sides of a pair never say the same thing', () {
      for (final locale in AppLocale.values) {
        for (final mode in _modesWithDedicatedGuidance) {
          final first = resolveActionGuidance(
            locale: locale,
            reading: _reading(base, mode: mode, winner: _pair[mode]!.$1),
          );
          final second = resolveActionGuidance(
            locale: locale,
            reading: _reading(base, mode: mode, winner: _pair[mode]!.$2),
          );
          expect(
            first.headline,
            isNot(second.headline),
            reason: '${locale.tag} ${mode.wireValue}',
          );
          expect(first.shouldDo, isNot(second.shouldDo));
        }
      }
    });

    test('the wording follows the mode, not just the winning side', () {
      // The defect this replaced: every mode produced the same sentences
      // because only the category and the polarity were consulted.
      for (final locale in AppLocale.values) {
        final headlines = <String>{};
        for (final mode in _modesWithDedicatedGuidance) {
          headlines.add(
            resolveActionGuidance(
              locale: locale,
              reading: _reading(base, mode: mode, winner: _pair[mode]!.$1),
            ).headline,
          );
        }
        expect(
          headlines.length,
          _modesWithDedicatedGuidance.length,
          reason: '${locale.tag}: two modes share a headline',
        );
      }
    });
  });

  group('what it must never say', () {
    test('no language tells the reader to act on money or a relationship', () {
      for (final entry in _forbidden.entries) {
        final locale = entry.key;
        for (final mode in _modesWithDedicatedGuidance) {
          for (final winner in <String>[_pair[mode]!.$1, _pair[mode]!.$2]) {
            final guidance = resolveActionGuidance(
              locale: locale,
              reading: _reading(base, mode: mode, winner: winner),
            );
            final body = <String>[
              guidance.headline,
              guidance.shouldDo,
              guidance.avoid,
            ].join(' ').toLowerCase();
            for (final word in entry.value) {
              expect(
                body.contains(word.toLowerCase()),
                isFalse,
                reason:
                    '${locale.tag} ${mode.wireValue} $winner contains '
                    '"$word": $body',
              );
            }
          }
        }
      }
    });

    test('the balanced reflection is clean in every language too', () {
      for (final entry in _forbidden.entries) {
        final guidance = resolveActionGuidance(
          locale: entry.key,
          reading: balanced,
        );
        final body = <String>[
          guidance.headline,
          guidance.shouldDo,
          guidance.avoid,
        ].join(' ').toLowerCase();
        for (final word in entry.value) {
          expect(
            body.contains(word.toLowerCase()),
            isFalse,
            reason: '${entry.key.tag} balanced contains "$word": $body',
          );
        }
      }
    });

    test('LEFT/RIGHT keeps its physical-navigation warning', () {
      for (final winner in <String>['LEFT', 'RIGHT']) {
        final guidance = resolveActionGuidance(
          locale: AppLocale.english,
          reading: _reading(base, mode: DecisionMode.leftRight, winner: winner),
        );
        expect(guidance.avoid.toLowerCase(), contains('traffic'));
      }
    });
  });

  group('it only claims what the reading established', () {
    /// Phrases that assert the direction of one signal. A mode score is a
    /// mixture, so the winning side does not establish any of these.
    const overclaims = <AppLocale, List<String>>{
      AppLocale.english: <String>[
        'most aligned',
        'more aligned',
        'best moment',
        'reads as the most',
      ],
      AppLocale.vietnamese: <String>['hợp nhịp nhất', 'tốt nhất'],
      AppLocale.spanish: <String>['más alineado', 'mejor momento'],
    };

    test('no headline claims a single signal it cannot know', () {
      for (final entry in overclaims.entries) {
        for (final mode in _modesWithDedicatedGuidance) {
          for (final winner in <String>[_pair[mode]!.$1, _pair[mode]!.$2]) {
            final headline = resolveActionGuidance(
              locale: entry.key,
              reading: _reading(base, mode: mode, winner: winner),
            ).headline.toLowerCase();
            for (final phrase in entry.value) {
              expect(
                headline.contains(phrase.toLowerCase()),
                isFalse,
                reason:
                    '${entry.key.tag} ${mode.wireValue} $winner claims '
                    '"$phrase": $headline',
              );
            }
          }
        }
      }
    });

    test('ACT/WAIT says the reading leaned, not that the moment is best', () {
      // ACT can win on a negative timing signal — the engine tests pin a real
      // instant where it does — so the headline must describe the mixture.
      final act = resolveActionGuidance(
        locale: AppLocale.english,
        reading: _reading(base, mode: DecisionMode.actWait, winner: 'ACT'),
      ).headline;
      expect(act.toLowerCase(), contains('leans toward acting'));
      expect(act.toLowerCase(), contains('timing'));
      // It names timing as one input among others rather than as the verdict.
      expect(act.toLowerCase(), contains('everything else'));
    });
  });

  group('resolution rules', () {
    test('a balanced reading gets the balanced reflection', () {
      for (final locale in AppLocale.values) {
        final guidance = resolveActionGuidance(
          locale: locale,
          reading: balanced,
        );
        expect(guidance.headline.trim(), isNotEmpty);
        expect(guidance.shouldDo.trim(), isNotEmpty);
      }
    });

    test('a retired mode borrows nobody else\'s words', () {
      // A saved FORWARD/BACKWARD reading has no guidance of its own. It must
      // not be handed COMMIT/WITHDRAW's, which is a different question.
      final legacy = ReadingResponse.fromJson(
        readFixture('legacy_forward_backward_reading.json'),
      );
      final guidance = resolveActionGuidance(
        locale: AppLocale.english,
        reading: legacy,
      );
      final commit = resolveActionGuidance(
        locale: AppLocale.english,
        reading: _reading(
          base,
          mode: DecisionMode.commitWithdraw,
          winner: 'COMMIT',
        ),
      );
      final balancedJson = readFixture('synthetic_balanced.json');
      balancedJson['readingKey'] = legacy.readingKey;
      balancedJson['period'] = legacy.period.wireValue;
      balancedJson['context'] = legacy.context.toJson();
      final balancedForLegacy = resolveActionGuidance(
        locale: AppLocale.english,
        reading: ReadingResponse.fromJson(balancedJson),
      );
      expect(guidance.headline, isNot(commit.headline));
      expect(guidance.headline, balancedForLegacy.headline);
    });

    test('it is deterministic — the same reading gives the same words', () {
      final reading = _reading(
        base,
        mode: DecisionMode.keepLetGo,
        winner: 'LET GO',
      );
      final first = resolveActionGuidance(
        locale: AppLocale.vietnamese,
        reading: reading,
      );
      final again = resolveActionGuidance(
        locale: AppLocale.vietnamese,
        reading: reading,
      );
      expect(first.headline, again.headline);
      expect(first.shouldDo, again.shouldDo);
      expect(first.avoid, again.avoid);
    });
  });

  group('category context lenses differentiate reflections and respect safety', () {
    ReadingResponse readingWithCategory({
      required DecisionMode mode,
      required String winner,
      required ReadingCategory category,
    }) {
      final json = readFixture('ready_yes_no_now.json');
      json['mode'] = mode.wireValue;
      json['winner'] = winner;
      json['category'] = category.wireValue;
      final percentages = <String, Object?>{};
      final labels = _pair[mode]!;
      percentages[labels.$1] = winner == labels.$1 ? 62.5 : 37.5;
      percentages[labels.$2] = winner == labels.$1 ? 37.5 : 62.5;
      json['percentages'] = percentages;
      final snapshot =
          Map<String, Object?>.from(json['inputSnapshot']! as JsonMap);
      snapshot['mode'] = mode.wireValue;
      snapshot['category'] = category.wireValue;
      json['inputSnapshot'] = snapshot;
      return ReadingResponse.fromJson(json);
    }

    test('categories produce differentiated advice from general overview', () {
      for (final locale in [
        AppLocale.vietnamese,
        AppLocale.english,
        AppLocale.spanish,
        AppLocale.japanese,
        AppLocale.simplifiedChinese,
      ]) {
        final generalReading = readingWithCategory(
          mode: DecisionMode.yesNo,
          winner: 'YES',
          category: ReadingCategory.general,
        );
        final generalGuidance = resolveActionGuidance(
          locale: locale,
          reading: generalReading,
        );

        for (final category in [
          ReadingCategory.career,
          ReadingCategory.love,
          ReadingCategory.money,
        ]) {
          final catReading = readingWithCategory(
            mode: DecisionMode.yesNo,
            winner: 'YES',
            category: category,
          );
          final catGuidance = resolveActionGuidance(
            locale: locale,
            reading: catReading,
          );

          expect(
            catGuidance.headline,
            isNot(generalGuidance.headline),
            reason: '${locale.tag} ${category.wireValue} headline matched general',
          );
          expect(
            catGuidance.shouldDo,
            isNot(generalGuidance.shouldDo),
            reason: '${locale.tag} ${category.wireValue} shouldDo matched general',
          );
        }
      }
    });

    test('no category lens ever uses forbidden words in any language', () {
      for (final entry in _forbidden.entries) {
        final locale = entry.key;
        for (final category in ReadingCategory.values) {
          final reading = readingWithCategory(
            mode: DecisionMode.yesNo,
            winner: 'YES',
            category: category,
          );
          final guidance = resolveActionGuidance(
            locale: locale,
            reading: reading,
          );
          final body = <String>[
            guidance.headline,
            guidance.shouldDo,
            guidance.avoid,
          ].join(' ').toLowerCase();

          for (final word in entry.value) {
            expect(
              body.contains(word.toLowerCase()),
              isFalse,
              reason:
                  '${locale.tag} ${category.wireValue} contains forbidden "$word": $body',
            );
          }
        }
      }
    });
  });

  group('period awareness and decisive variant rotation', () {
    test('Vietnamese guidance uses action tags Nên and Tránh', () {
      final guidance = resolveActionGuidance(
        locale: AppLocale.vietnamese,
        reading: base,
      );
      expect(guidance.title, 'CHỈ DẪN HÀNH ĐỘNG');
      expect(guidance.shouldDoTag, 'Nên:');
      expect(guidance.avoidTag, 'Tránh:');
    });

    test('headline incorporates time period for non-now periods across languages', () {
      for (final period in [
        TimePeriod.morning,
        TimePeriod.afternoon,
        TimePeriod.evening,
      ]) {
        final json = readFixture('ready_yes_no_now.json');
        json['period'] = period.wireValue;
        final reading = ReadingResponse.fromJson(json);

        final viGuidance = resolveActionGuidance(
          locale: AppLocale.vietnamese,
          reading: reading,
        );
        final enGuidance = resolveActionGuidance(
          locale: AppLocale.english,
          reading: reading,
        );

        expect(viGuidance.headline.isNotEmpty, isTrue);
        expect(enGuidance.headline.isNotEmpty, isTrue);

        if (period == TimePeriod.morning) {
          expect(viGuidance.headline.toLowerCase(), contains('sáng'));
          expect(enGuidance.headline.toLowerCase(), contains('morning'));
        } else if (period == TimePeriod.afternoon) {
          expect(viGuidance.headline.toLowerCase(), contains('chiều'));
          expect(enGuidance.headline.toLowerCase(), contains('afternoon'));
        } else if (period == TimePeriod.evening) {
          expect(viGuidance.headline.toLowerCase(), contains('tối'));
          expect(enGuidance.headline.toLowerCase(), contains('evening'));
        }
      }
    });

    test('readingKey rotation produces non-repetitive variants', () {
      final json = readFixture('ready_career_now.json');
      final variants = <String>{};

      for (var i = 0; i < 5; i++) {
        json['readingKey'] = 'sample_reading_key_$i';
        final reading = ReadingResponse.fromJson(json);
        final guidance = resolveActionGuidance(
          locale: AppLocale.vietnamese,
          reading: reading,
        );
        variants.add(guidance.headline);
      }

      expect(variants.length, greaterThan(1));
    });

    test('all 8 languages have exactly 315 keys matching vi', () {
      expect(actionGuidanceVi.length, 315);
      expect(actionGuidanceEn.length, 315);
      expect(actionGuidanceEs.length, 315);
      expect(actionGuidanceJa.length, 315);
      expect(actionGuidanceKo.length, 315);
      expect(actionGuidanceZh.length, 315);
      expect(actionGuidanceTh.length, 315);
      expect(actionGuidanceHi.length, 315);
      expect(actionGuidanceEn.keys.toSet(), actionGuidanceVi.keys.toSet());
      expect(actionGuidanceEs.keys.toSet(), actionGuidanceVi.keys.toSet());
      expect(actionGuidanceJa.keys.toSet(), actionGuidanceVi.keys.toSet());
      expect(actionGuidanceKo.keys.toSet(), actionGuidanceVi.keys.toSet());
      expect(actionGuidanceZh.keys.toSet(), actionGuidanceVi.keys.toSet());
      expect(actionGuidanceTh.keys.toSet(), actionGuidanceVi.keys.toSet());
      expect(actionGuidanceHi.keys.toSet(), actionGuidanceVi.keys.toSet());
    });

    test('zh, th, and hi readingKey rotation produces variants', () {
      final json = readFixture('ready_career_now.json');
      for (final locale in [
        AppLocale.simplifiedChinese,
        AppLocale.thai,
        AppLocale.hindi,
      ]) {
        final variants = <String>{};
        for (var i = 0; i < 5; i++) {
          json['readingKey'] = 'sample_reading_key_$i';
          final reading = ReadingResponse.fromJson(json);
          final guidance = resolveActionGuidance(
            locale: locale,
            reading: reading,
          );
          variants.add(guidance.headline);
        }
        expect(variants.length, greaterThan(1), reason: '${locale.tag} variant rotation');
      }
    });
  });

  group('modes pending dedicated guidance', () {
    test('safely resolves with non-empty guidance in every language', () {
      for (final locale in AppLocale.values) {
        for (final mode in [
          DecisionMode.reasonEmotion,
          DecisionMode.confrontAvoid,
        ]) {
          final pair = _pair[mode]!;
          for (final winner in [pair.$1, pair.$2]) {
            final guidance = resolveActionGuidance(
              locale: locale,
              reading: _reading(base, mode: mode, winner: winner),
            );
            expect(guidance.title.trim().isNotEmpty, isTrue);
            expect(guidance.headline.trim().isNotEmpty, isTrue);
            expect(guidance.shouldDo.trim().isNotEmpty, isTrue);
            expect(guidance.avoid.trim().isNotEmpty, isTrue);
            expect(guidance.shouldDoTag.trim().isNotEmpty, isTrue);
            expect(guidance.avoidTag.trim().isNotEmpty, isTrue);
          }
        }
      }
    });

    test('new modes differentiate first vs second side and balanced', () {
      for (final locale in AppLocale.values) {
        final balancedGuidance = resolveActionGuidance(
          locale: locale,
          reading: balanced,
        );
        for (final mode in [
          DecisionMode.reasonEmotion,
          DecisionMode.confrontAvoid,
        ]) {
          final pair = _pair[mode]!;
          final first = resolveActionGuidance(
            locale: locale,
            reading: _reading(base, mode: mode, winner: pair.$1),
          );
          final second = resolveActionGuidance(
            locale: locale,
            reading: _reading(base, mode: mode, winner: pair.$2),
          );

          expect(first.headline, isNot(second.headline),
              reason: '${locale.tag} ${mode.wireValue} headline symmetry');
          expect(first.shouldDo, isNot(second.shouldDo),
              reason: '${locale.tag} ${mode.wireValue} shouldDo symmetry');
          expect(first.headline, isNot(balancedGuidance.headline),
              reason: '${locale.tag} ${mode.wireValue} first fell into balanced');
          expect(second.headline, isNot(balancedGuidance.headline),
              reason: '${locale.tag} ${mode.wireValue} second fell into balanced');
        }
      }
    });

    test('new modes respect forbidden word restrictions in all languages', () {
      for (final entry in _forbidden.entries) {
        final locale = entry.key;
        for (final mode in [
          DecisionMode.reasonEmotion,
          DecisionMode.confrontAvoid,
        ]) {
          final pair = _pair[mode]!;
          for (final winner in [pair.$1, pair.$2]) {
            final guidance = resolveActionGuidance(
              locale: locale,
              reading: _reading(base, mode: mode, winner: winner),
            );
            final body = <String>[
              guidance.headline,
              guidance.shouldDo,
              guidance.avoid,
            ].join(' ').toLowerCase();

            for (final word in entry.value) {
              expect(
                body.contains(word.toLowerCase()),
                isFalse,
                reason:
                    '${locale.tag} ${mode.wireValue} $winner contains forbidden "$word": $body',
              );
            }
          }
        }
      }
    });
  });

  group('cosmic headline properties', () {
    test('headlines never mention percentages or raw numbers', () {
      for (final locale in AppLocale.values) {
        for (final mode in DecisionMode.values) {
          if (mode == DecisionMode.forwardBackward) continue;
          final pair = _pair[mode]!;
          for (final winner in [pair.$1, pair.$2]) {
            for (final cat in ReadingCategory.values) {
              final json = readFixture('ready_yes_no_now.json');
              json['mode'] = mode.wireValue;
              json['winner'] = winner;
              json['category'] = cat.wireValue;
              final percentages = <String, Object?>{};
              percentages[pair.$1] = winner == pair.$1 ? 62.5 : 37.5;
              percentages[pair.$2] = winner == pair.$1 ? 37.5 : 62.5;
              json['percentages'] = percentages;
              final reading = ReadingResponse.fromJson(json);

              final guidance = resolveActionGuidance(
                locale: locale,
                reading: reading,
              );

              expect(guidance.headline.contains('%'), isFalse,
                  reason: '${locale.tag} contains %');
              expect(guidance.headline.contains(RegExp(r'\d')), isFalse,
                  reason: '${locale.tag} contains digits: ${guidance.headline}');
            }
          }
        }
      }
    });

    test('Smart Cultural Adaptor adjusts English headline based on birth country', () {
      ReadingResponse readingWithCountry(String? country) {
        final json = readFixture('ready_yes_no_now.json');
        final profile = Map<String, Object?>.from(
            (json['inputSnapshot'] as Map<String, Object?>)['profile'] as Map<String, Object?>);
        profile['birthCountry'] = country;
        final snapshot = Map<String, Object?>.from(json['inputSnapshot'] as Map<String, Object?>);
        snapshot['profile'] = profile;
        json['inputSnapshot'] = snapshot;
        return ReadingResponse.fromJson(json);
      }

      final vnReading = readingWithCountry('VN');
      final inReading = readingWithCountry('IN');
      final usReading = readingWithCountry('US');

      final vnGuidance = resolveActionGuidance(
        locale: AppLocale.english,
        reading: vnReading,
      );
      final inGuidance = resolveActionGuidance(
        locale: AppLocale.english,
        reading: inReading,
      );
      final usGuidance = resolveActionGuidance(
        locale: AppLocale.english,
        reading: usReading,
      );

      expect(vnGuidance.headline.isNotEmpty, isTrue);
      expect(inGuidance.headline.isNotEmpty, isTrue);
      expect(usGuidance.headline.isNotEmpty, isTrue);

      expect(vnGuidance.headline, isNot(inGuidance.headline));
      expect(vnGuidance.headline, isNot(usGuidance.headline));
      expect(inGuidance.headline, isNot(usGuidance.headline));
    });

    test('Option B 2-tier guidance decomposes cosmic reason and clean action headline', () {
      for (final locale in AppLocale.values) {
        for (final mode in _modesWithDedicatedGuidance) {
          final guidance = resolveActionGuidance(
            locale: locale,
            reading: _reading(base, mode: mode, winner: _pair[mode]!.$1),
          );
          expect(guidance.cosmicReason, isNotNull, reason: '${locale.tag} ${mode.wireValue}');
          expect(guidance.cosmicReason!.trim(), isNotEmpty);
          expect(guidance.actionHeadline, isNotNull);
          expect(guidance.actionHeadline!.trim(), isNotEmpty);
          // Action headline in Option B must never have semicolons
          expect(
            guidance.actionHeadline!.contains(';'),
            isFalse,
            reason: '${locale.tag} ${mode.wireValue} action headline contains semicolon: ${guidance.actionHeadline}',
          );
        }
      }
    });
  });
}

