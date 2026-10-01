import 'package:decision_compass/app_locale.dart';
import 'package:decision_compass/data/action_guidance.dart';
import 'package:decision_compass/data/models/models.dart';
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
    };

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
        for (final mode in DecisionMode.selectable) {
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
        for (final mode in DecisionMode.selectable) {
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
        for (final mode in DecisionMode.selectable) {
          headlines.add(
            resolveActionGuidance(
              locale: locale,
              reading: _reading(base, mode: mode, winner: _pair[mode]!.$1),
            ).headline,
          );
        }
        expect(
          headlines.length,
          DecisionMode.selectable.length,
          reason: '${locale.tag}: two modes share a headline',
        );
      }
    });
  });

  group('what it must never say', () {
    test('no language tells the reader to act on money or a relationship', () {
      for (final entry in _forbidden.entries) {
        final locale = entry.key;
        for (final mode in DecisionMode.selectable) {
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
        for (final mode in DecisionMode.selectable) {
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
      final balancedText = resolveActionGuidance(
        locale: AppLocale.english,
        reading: balanced,
      );
      expect(guidance.headline, isNot(commit.headline));
      expect(guidance.headline, balancedText.headline);
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
}
