import '../app_locale.dart';
import 'action_guidance/action_guidance_en.dart';
import 'action_guidance/action_guidance_es.dart';
import 'action_guidance/action_guidance_hi.dart';
import 'action_guidance/action_guidance_ja.dart';
import 'action_guidance/action_guidance_ko.dart';
import 'action_guidance/action_guidance_th.dart';
import 'action_guidance/action_guidance_vi.dart';
import 'action_guidance/action_guidance_zh.dart';
import 'action_guidance/cosmic_headline_composer.dart';
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

CosmicLean _leanOf(ReadingResponse reading) {
  if (reading.status == ReadingStatus.balanced || reading.winner == null) {
    return CosmicLean.balanced;
  }
  final labels = _englishPair[reading.mode];
  if (labels == null) return CosmicLean.balanced;
  if (reading.winner == labels.$1) return CosmicLean.first;
  if (reading.winner == labels.$2) return CosmicLean.second;
  // A winner the app does not recognise is not guessed at.
  return CosmicLean.balanced;
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
      DecisionMode.reasonEmotion: ('REASON', 'EMOTION'),
      DecisionMode.confrontAvoid: ('CONFRONT', 'AVOID'),
      DecisionMode.forwardBackward: ('FORWARD', 'BACKWARD'),
    };

int _resolveVariant(ReadingResponse reading) {
  final key = reading.readingKey ?? '';
  final cat = reading.category.wireValue;
  final isBalanced = reading.status == ReadingStatus.balanced ||
      reading.winner == null ||
      reading.mode.legacy;
  final mode = isBalanced ? _balancedKey : reading.mode.wireValue;
  final period = reading.period.wireValue;
  final instant = reading.context.instantMs;
  final seed = '$key|$cat|$mode|$period|${instant > 0 ? (instant ~/ 60000) : ''}';
  return _hashGuidanceKey(seed) % 3;
}

int _hashGuidanceKey(String s) {
  var hash = 0;
  for (var i = 0; i < s.length; i++) {
    hash = (hash * 31 + s.codeUnitAt(i)) & 0x7FFFFFFF;
  }
  return hash;
}

/// The guidance for one reading.
///
/// Deterministic: the same category, mode, and leaning always produce the same
/// three sentences. If a category provides a specialized contextual lens
/// (`category:mode:side`), it is used; otherwise it falls back to the universal
/// mode reflection (`mode:side`). Supports dynamic variants and time period lenses.
ActionGuidance resolveActionGuidance({
  required AppLocale locale,
  required ReadingResponse reading,
}) {
  final tags = _tagsFor(locale);
  final table = _copyFor(locale);
  final lean = _leanOf(reading);
  final category = reading.category;
  final period = reading.period.wireValue;
  final variant = _resolveVariant(reading);

  final profileRaw = reading.inputSnapshot.raw['profile'];
  final birthCountryCode =
      (profileRaw is Map ? profileRaw['birthCountry'] : null) as String?;

  final cosmicHeadline = composeCosmicHeadline(
    locale: locale,
    category: reading.category,
    period: reading.period,
    mode: reading.mode,
    lean: lean,
    variant: variant,
    birthCountryCode: birthCountryCode,
  );

  if (lean == CosmicLean.balanced || reading.mode.legacy) {
    final cat = category.wireValue;
    final hasExactPeriodKey =
        table.containsKey('$cat:$_balancedKey:$period:v$variant') ||
        table.containsKey('$cat:$_balancedKey:$period') ||
        table.containsKey('$_balancedKey:$period:v$variant') ||
        table.containsKey('$_balancedKey:$period');

    final entry = table['$cat:$_balancedKey:$period:v$variant'] ??
        table['$cat:$_balancedKey:$period'] ??
        table['$cat:$_balancedKey:v$variant'] ??
        table['$cat:$_balancedKey'] ??
        table['$_balancedKey:$period:v$variant'] ??
        table['$_balancedKey:$period'] ??
        table['$_balancedKey:v$variant'] ??
        table[_balancedKey]!;

    final localizedEntry = _localizePeriodGuidance(
      locale: locale,
      entry: entry,
      period: reading.period,
      hasExactPeriodKey: hasExactPeriodKey,
    );

    return ActionGuidance(
      title: tags.$1,
      shouldDoTag: tags.$2,
      avoidTag: tags.$3,
      headline: cosmicHeadline,
      shouldDo: localizedEntry.$2,
      avoid: localizedEntry.$3,
    );
  }

  final side = lean == CosmicLean.first ? 'first' : 'second';
  final cat = category.wireValue;
  final mode = reading.mode.wireValue;

  final hasExactPeriodKey =
      table.containsKey('$cat:$mode:$side:$period:v$variant') ||
      table.containsKey('$cat:$mode:$side:$period') ||
      table.containsKey('$mode:$side:$period:v$variant') ||
      table.containsKey('$mode:$side:$period');

  final baseEntry = table['$cat:$mode:$side:$period:v$variant'] ??
      table['$cat:$mode:$side:$period'] ??
      table['$cat:$mode:$side:v$variant'] ??
      table['$cat:$mode:$side'] ??
      table['$mode:$side:$period:v$variant'] ??
      table['$mode:$side:$period'] ??
      table['$mode:$side:v$variant'] ??
      table['$mode:$side'] ??
      table[_balancedKey]!;

  final dedicated = getDedicatedNewModeGuidance(
    locale: locale,
    mode: reading.mode,
    lean: lean,
  );

  final entry = dedicated != null
      ? (baseEntry.$1, dedicated.$1, dedicated.$2)
      : baseEntry;

  final localizedEntry = _localizePeriodGuidance(
    locale: locale,
    entry: entry,
    period: reading.period,
    hasExactPeriodKey: hasExactPeriodKey,
  );

  return ActionGuidance(
    title: tags.$1,
    shouldDoTag: tags.$2,
    avoidTag: tags.$3,
    headline: cosmicHeadline,
    shouldDo: localizedEntry.$2,
    avoid: localizedEntry.$3,
  );
}

(String, String, String) _localizePeriodGuidance({
  required AppLocale locale,
  required (String, String, String) entry,
  required TimePeriod period,
  required bool hasExactPeriodKey,
}) {
  if (period == TimePeriod.now || hasExactPeriodKey) {
    return entry;
  }

  final headlinePrefix = switch (locale) {
    AppLocale.vietnamese => switch (period) {
      TimePeriod.morning => 'Buổi sáng hôm nay, ',
      TimePeriod.midday => 'Vào thời điểm giữa ngày, ',
      TimePeriod.afternoon => 'Trong buổi chiều hôm nay, ',
      TimePeriod.evening => 'Khi chiều tối buông xuống, ',
      TimePeriod.now => '',
    },
    AppLocale.english => switch (period) {
      TimePeriod.morning => 'This morning, ',
      TimePeriod.midday => 'At midday, ',
      TimePeriod.afternoon => 'This afternoon, ',
      TimePeriod.evening => 'As evening settles, ',
      TimePeriod.now => '',
    },
    AppLocale.spanish => switch (period) {
      TimePeriod.morning => 'Esta mañana, ',
      TimePeriod.midday => 'Hacia el mediodía, ',
      TimePeriod.afternoon => 'Esta tarde, ',
      TimePeriod.evening => 'Al caer la tarde, ',
      TimePeriod.now => '',
    },
    AppLocale.japanese => switch (period) {
      TimePeriod.morning => '今日の朝の時間帯は、',
      TimePeriod.midday => '日中の時間帯は、',
      TimePeriod.afternoon => '午後の時間帯は、',
      TimePeriod.evening => '夕暮れから夜にかけては、',
      TimePeriod.now => '',
    },
    AppLocale.korean => switch (period) {
      TimePeriod.morning => '오늘 아침 시간대에는 ',
      TimePeriod.midday => '한낮의 시간대에는 ',
      TimePeriod.afternoon => '오늘 오후 시간대에는 ',
      TimePeriod.evening => '저녁이 깊어가는 시간에는 ',
      TimePeriod.now => '',
    },
    AppLocale.thai => switch (period) {
      TimePeriod.morning => 'ในช่วงเช้าวันนี้ ',
      TimePeriod.midday => 'ในช่วงกลางวันนี้ ',
      TimePeriod.afternoon => 'ในช่วงบ่ายวันนี้ ',
      TimePeriod.evening => 'เมื่อเข้าสู่ช่วงค่ำ ',
      TimePeriod.now => '',
    },
    AppLocale.hindi => switch (period) {
      TimePeriod.morning => 'आज सुबह के समय, ',
      TimePeriod.midday => 'दोपहर के समय, ',
      TimePeriod.afternoon => 'आज दोपहर बाद, ',
      TimePeriod.evening => 'शाम के समय, ',
      TimePeriod.now => '',
    },
    AppLocale.simplifiedChinese => switch (period) {
      TimePeriod.morning => '今日清晨时段，',
      TimePeriod.midday => '正午时段，',
      TimePeriod.afternoon => '午后时段，',
      TimePeriod.evening => '暮色降临时，',
      TimePeriod.now => '',
    },
  };

  final shouldDoPrefix = switch (locale) {
    AppLocale.vietnamese => switch (period) {
      TimePeriod.morning => 'Đầu ngày: ',
      TimePeriod.midday => 'Giữa ngày: ',
      TimePeriod.afternoon => 'Buổi chiều: ',
      TimePeriod.evening => 'Cuối ngày: ',
      TimePeriod.now => '',
    },
    AppLocale.english => switch (period) {
      TimePeriod.morning => 'Morning focus: ',
      TimePeriod.midday => 'Midday check: ',
      TimePeriod.afternoon => 'Afternoon rhythm: ',
      TimePeriod.evening => 'Evening reflection: ',
      TimePeriod.now => '',
    },
    AppLocale.spanish => switch (period) {
      TimePeriod.morning => 'Inicio del día: ',
      TimePeriod.midday => 'Pausa del mediodía: ',
      TimePeriod.afternoon => 'Ritmo de la tarde: ',
      TimePeriod.evening => 'Cierre del día: ',
      TimePeriod.now => '',
    },
    AppLocale.japanese => switch (period) {
      TimePeriod.morning => '朝の起点: ',
      TimePeriod.midday => '日中の点検: ',
      TimePeriod.afternoon => '午後の推進: ',
      TimePeriod.evening => '一日の振り返り: ',
      TimePeriod.now => '',
    },
    AppLocale.korean => switch (period) {
      TimePeriod.morning => '하루의 시작: ',
      TimePeriod.midday => '한낮의 점검: ',
      TimePeriod.afternoon => '오후의 흐름: ',
      TimePeriod.evening => '하루의 마무리: ',
      TimePeriod.now => '',
    },
    AppLocale.thai => switch (period) {
      TimePeriod.morning => 'จุดเริ่มต้นยามเช้า: ',
      TimePeriod.midday => 'ทบทวนช่วงกลางวัน: ',
      TimePeriod.afternoon => 'จังหวะช่วงบ่าย: ',
      TimePeriod.evening => 'สรุปบทเรียนยามค่ำ: ',
      TimePeriod.now => '',
    },
    AppLocale.hindi => switch (period) {
      TimePeriod.morning => 'सुबह की शुरुआत: ',
      TimePeriod.midday => 'दोपहर का ठहराव: ',
      TimePeriod.afternoon => 'दोपहर बाद का तालमेल: ',
      TimePeriod.evening => 'दिन का समापन: ',
      TimePeriod.now => '',
    },
    AppLocale.simplifiedChinese => switch (period) {
      TimePeriod.morning => '晨间焦点：',
      TimePeriod.midday => '午间梳理：',
      TimePeriod.afternoon => '午后节奏：',
      TimePeriod.evening => '暮间沉淀：',
      TimePeriod.now => '',
    },
  };

  final avoidSuffix = switch (locale) {
    AppLocale.vietnamese => switch (period) {
      TimePeriod.morning => ' (tránh để sự chậm trễ đầu ngày kéo theo cả ngày).',
      TimePeriod.midday => ' (tránh phản ứng vội vã dưới áp lực giữa ngày).',
      TimePeriod.afternoon => ' (tránh dồn việc chưa xong sang tối muộn).',
      TimePeriod.evening => ' (tránh quyết định bốc đồng khi tâm trí đã mệt).',
      TimePeriod.now => '',
    },
    AppLocale.english => switch (period) {
      TimePeriod.morning => ' (avoid letting early hesitation derail your day).',
      TimePeriod.midday => ' (avoid hasty reactions under midday pressure).',
      TimePeriod.afternoon => ' (avoid pushing unfinished matters into the night).',
      TimePeriod.evening => ' (avoid impulsive choices when mentally tired).',
      TimePeriod.now => '',
    },
    AppLocale.spanish => switch (period) {
      TimePeriod.morning => ' (evita que la duda inicial frene todo el día).',
      TimePeriod.midday => ' (evita reacciones apresuradas bajo la prisa del mediodía).',
      TimePeriod.afternoon => ' (evita arrastrar asuntos pendientes a la noche).',
      TimePeriod.evening => ' (evita decisiones impulsivas con el cansancio acumulado).',
      TimePeriod.now => '',
    },
    AppLocale.japanese => switch (period) {
      TimePeriod.morning => '（朝の迷いで一日のリズムを崩さないこと）。',
      TimePeriod.midday => '（日中の慌ただしさに流されて拙速に動かないこと）。',
      TimePeriod.afternoon => '（未完了の課題を夜遅くまで引きずらないこと）。',
      TimePeriod.evening => '（心身が疲れている時間帯に衝動的に決めないこと）。',
      TimePeriod.now => '',
    },
    AppLocale.korean => switch (period) {
      TimePeriod.morning => ' (아침의 망설임으로 하루 전체의 흐름을 흩뜨리지 말 것).',
      TimePeriod.midday => ' (한낮의 분주함 속에서 섣불리 반응하지 말 것).',
      TimePeriod.afternoon => ' (미완의 과제를 늦은 밤까지 끌고 가지 말 것).',
      TimePeriod.evening => ' (피로가 쌓인 밤 시간에 충동적으로 결정하지 말 것).',
      TimePeriod.now => '',
    },
    AppLocale.thai => switch (period) {
      TimePeriod.morning => ' (ระวังอย่าให้ความลังเลตอนเช้าทำให้เสียจังหวะทั้งวัน).',
      TimePeriod.midday => ' (ระวังการตอบสนองที่เร่งรีบตามความวุ่นวายช่วงกลางวัน).',
      TimePeriod.afternoon => ' (ระวังการสะสมงานคั่งค้างไปจนถึงช่วงค่ำ).',
      TimePeriod.evening => ' (ระวังการตัดสินใจตามอารมณ์ในยามที่เหนื่อยล้า).',
      TimePeriod.now => '',
    },
    AppLocale.hindi => switch (period) {
      TimePeriod.morning => ' (सुबह के संकोच से पूरे दिन की गति बाधित न होने दें)।',
      TimePeriod.midday => ' (दोपहर की व्यस्तता में बिना सोचे प्रतिक्रिया न दें)।',
      TimePeriod.afternoon => ' (अधूरे कार्यों को देर रात तक न टालें)।',
      TimePeriod.evening => ' (थके हुए मन से कोई जल्दबाजी भरा निर्णय न लें)।',
      TimePeriod.now => '',
    },
    AppLocale.simplifiedChinese => switch (period) {
      TimePeriod.morning => '（切勿因清晨的迟疑打乱全天节奏）。',
      TimePeriod.midday => '（切勿在午间繁忙中做出草率回应）。',
      TimePeriod.afternoon => '（切勿将未结事项拖延至深夜）。',
      TimePeriod.evening => '（切勿在身心疲惫时意气用事）。',
      TimePeriod.now => '',
    },
  };

  var baseHeadline = entry.$1;
  if (locale == AppLocale.english && baseHeadline.isNotEmpty && !baseHeadline.startsWith('I ')) {
    baseHeadline = '${baseHeadline[0].toLowerCase()}${baseHeadline.substring(1)}';
  } else if (locale == AppLocale.vietnamese && baseHeadline.startsWith('Hôm nay ')) {
    baseHeadline = baseHeadline.substring('Hôm nay '.length);
  } else if (locale == AppLocale.vietnamese && baseHeadline.isNotEmpty) {
    baseHeadline = '${baseHeadline[0].toLowerCase()}${baseHeadline.substring(1)}';
  }

  final updatedHeadline = headlinePrefix.isNotEmpty ? '$headlinePrefix$baseHeadline' : baseHeadline;
  final updatedShouldDo = shouldDoPrefix.isNotEmpty ? '$shouldDoPrefix${entry.$2}' : entry.$2;

  var baseAvoid = entry.$3.trim();
  while (baseAvoid.endsWith('.') || baseAvoid.endsWith('。') || baseAvoid.endsWith('!')) {
    baseAvoid = baseAvoid.substring(0, baseAvoid.length - 1);
  }
  final updatedAvoid = avoidSuffix.isNotEmpty ? '$baseAvoid$avoidSuffix' : entry.$3;

  return (updatedHeadline, updatedShouldDo, updatedAvoid);
}


const String _balancedKey = 'balanced';

/// (title, shouldDoTag, avoidTag)
(String, String, String) _tagsFor(AppLocale locale) => switch (locale) {
  AppLocale.english => ('COSMIC GUIDANCE', 'Consider:', 'Watch for:'),
  AppLocale.vietnamese => ('CHỈ DẪN HÀNH ĐỘNG', 'Nên:', 'Tránh:'),
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
