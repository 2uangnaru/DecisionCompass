import '../app_locale.dart';
import 'action_guidance/action_guidance_en.dart';
import 'action_guidance/action_guidance_es.dart';
import 'action_guidance/action_guidance_hi.dart';
import 'action_guidance/action_guidance_ja.dart';
import 'action_guidance/action_guidance_ko.dart';
import 'action_guidance/action_guidance_th.dart';
import 'action_guidance/action_guidance_vi.dart';
import 'action_guidance/action_guidance_zh.dart';
import 'models/models.dart';

/// The short reflection shown beneath a reading result.
///
/// It reflects the **decision mode, winning side, and category context lens**,
/// offering mindful discernment tailored to the user's inquiry area without
/// dispensing rigid or risky real-world commands.
class ActionGuidance {
  const ActionGuidance({
    required this.title,
    required this.headline,
    required this.shouldDo,
    required this.avoid,
    required this.shouldDoTag,
    required this.avoidTag,
  });

  /// Section title, e.g. "COSMIC GUIDANCE", "CHỈ DẪN HÀNH ĐỘNG".
  final String title;

  /// What the reading leaned toward, contextualized by mode and category.
  final String headline;

  /// Something to turn over. Never an instruction to act recklessly in the world.
  final String shouldDo;

  /// A way of misreading this that is worth naming.
  final String avoid;

  /// Localized label for [shouldDo], e.g. "Do:", "宜:", "Nên:", "Suy ngẫm:".
  final String shouldDoTag;

  /// Localized label for [avoid], e.g. "Avoid:", "忌:", "Tránh:", "Lưu ý:".
  final String avoidTag;
}

/// Which side of the pair a reading named.
enum _Lean { first, second, balanced }

_Lean _leanOf(ReadingResponse reading) {
  if (reading.status == ReadingStatus.balanced || reading.winner == null) {
    return _Lean.balanced;
  }
  final labels = _englishPair[reading.mode];
  if (labels == null) return _Lean.balanced;
  if (reading.winner == labels.$1) return _Lean.first;
  if (reading.winner == labels.$2) return _Lean.second;
  // A winner the app does not recognise is not guessed at.
  return _Lean.balanced;
}

/// The engine's own wire labels, used only to tell the two sides apart.
const Map<DecisionMode, (String, String)> _englishPair =
    <DecisionMode, (String, String)>{
      DecisionMode.yesNo: ('YES', 'NO'),
      DecisionMode.actWait: ('ACT', 'WAIT'),
      DecisionMode.advanceRetreat: ('ADVANCE', 'RETREAT'),
      DecisionMode.stayGo: ('STAY', 'GO'),
      DecisionMode.keepLetGo: ('KEEP', 'LET GO'),
      DecisionMode.commitWithdraw: ('COMMIT', 'WITHDRAW'),
      DecisionMode.leftRight: ('LEFT', 'RIGHT'),
      DecisionMode.forwardBackward: ('FORWARD', 'BACKWARD'),
    };

/// The guidance for one reading.
///
/// Deterministic: the same category, mode, and leaning always produce the same
/// three sentences. If a category provides a specialized contextual lens
/// (`category:mode:side`), it is used; otherwise it falls back to the universal
/// mode reflection (`mode:side`).
ActionGuidance resolveActionGuidance({
  required AppLocale locale,
  required ReadingResponse reading,
}) {
  final tags = _tagsFor(locale);
  final table = _copyFor(locale);
  final lean = _leanOf(reading);
  final category = reading.category;

  if (lean == _Lean.balanced || reading.mode.legacy) {
    final categoryBalancedKey = '${category.wireValue}:$_balancedKey';
    final entry = table[categoryBalancedKey] ?? table[_balancedKey]!;
    return ActionGuidance(
      title: tags.$1,
      shouldDoTag: tags.$2,
      avoidTag: tags.$3,
      headline: entry.$1,
      shouldDo: entry.$2,
      avoid: entry.$3,
    );
  }

  final side = lean == _Lean.first ? 'first' : 'second';
  final specificKey = '${category.wireValue}:${reading.mode.wireValue}:$side';
  final modeKey = '${reading.mode.wireValue}:$side';
  final entry = table[specificKey] ?? table[modeKey] ?? table[_balancedKey]!;

  return ActionGuidance(
    title: tags.$1,
    shouldDoTag: tags.$2,
    avoidTag: tags.$3,
    headline: entry.$1,
    shouldDo: entry.$2,
    avoid: entry.$3,
  );
}

const String _balancedKey = 'balanced';

/// (title, shouldDoTag, avoidTag)
(String, String, String) _tagsFor(AppLocale locale) => switch (locale) {
  AppLocale.english => ('COSMIC GUIDANCE', 'Consider:', 'Watch for:'),
  AppLocale.vietnamese => ('CHỈ DẪN HÀNH ĐỘNG', 'Suy ngẫm:', 'Lưu ý:'),
  AppLocale.spanish => ('GUÍA SIMBÓLICA', 'Para pensar:', 'Ojo con:'),
  AppLocale.japanese => ('今日の指針', '考えること:', '気をつけること:'),
  AppLocale.korean => ('우주의 안내', '생각해 볼 점:', '주의할 점:'),
  AppLocale.thai => ('แนวทางเชิงสัญลักษณ์', 'ลองพิจารณา:', 'ระวัง:'),
  AppLocale.hindi => ('प्रतीकात्मक मार्गदर्शन', 'सोचें:', 'ध्यान रखें:'),
  AppLocale.simplifiedChinese => ('象征指引', '可以想想:', '留意:'),
};

Map<String, (String, String, String)> _copyFor(AppLocale locale) =>
    switch (locale) {
      AppLocale.english => actionGuidanceEn,
      AppLocale.vietnamese => actionGuidanceVi,
      AppLocale.spanish => actionGuidanceEs,
      AppLocale.japanese => actionGuidanceJa,
      AppLocale.korean => actionGuidanceKo,
      AppLocale.thai => actionGuidanceTh,
      AppLocale.hindi => actionGuidanceHi,
      AppLocale.simplifiedChinese => actionGuidanceZh,
    };
