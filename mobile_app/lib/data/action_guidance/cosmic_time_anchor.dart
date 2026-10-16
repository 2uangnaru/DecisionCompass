import '../../app_locale.dart';
import '../../local_engine/astronomy/astronomy.dart';
import '../../local_engine/calendar/calendar.dart';
import '../../local_engine/colors.dart';
import '../../local_engine/time/local_time.dart';
import '../../models.dart' show zodiacForDate, ZodiacSign;
import '../models/models.dart';
import 'cosmic_headline_composer.dart';

/// Cultural heritage zone for smart adaptation.
enum HeritageZone {
  eastern,
  vedic,
  western,
}

/// Extracted and localized spiritual calculation anchors (transit & natal).
class CosmicTimeAnchor {
  const CosmicTimeAnchor({
    required this.locale,
    required this.period,
    required this.category,
    required this.lean,
    required this.heritageZone,
    this.dayText,
    this.officerText,
    this.elementText,
    this.moonPhaseText,
    this.zodiacText,
    this.pakshaText,
  });

  final AppLocale locale;
  final TimePeriod period;
  final ReadingCategory category;
  final CosmicLean lean;
  final HeritageZone heritageZone;

  final String? dayText;
  final String? officerText;
  final String? elementText;
  final String? moonPhaseText;
  final String? zodiacText;
  final String? pakshaText;

  /// Builds the spiritually grounded, concise context sentence (Sentence 1)
  /// seamlessly embedding transit, officer, and natal element/sign.
  String buildContextSentence() {
    switch (locale) {
      case AppLocale.vietnamese:
        return _buildVietnameseSentence();
      case AppLocale.english:
        return _buildEnglishSentence();
      case AppLocale.spanish:
        return _buildSpanishSentence();
      case AppLocale.simplifiedChinese:
        return _buildChineseSentence();
      case AppLocale.japanese:
        return _buildJapaneseSentence();
      case AppLocale.korean:
        return _buildKoreanSentence();
      case AppLocale.thai:
        return _buildThaiSentence();
      case AppLocale.hindi:
        return _buildHindiSentence();
    }
  }

  String _buildVietnameseSentence() {
    final pfx = switch (period) {
      TimePeriod.morning => 'Vào buổi sáng',
      TimePeriod.midday => 'Vào thời điểm giữa ngày',
      TimePeriod.afternoon => 'Trong buổi chiều',
      TimePeriod.evening => 'Vào buổi tối',
      TimePeriod.now => 'Vào thời điểm',
    };

    final cat = switch (category) {
      ReadingCategory.career => 'xét trong công việc',
      ReadingCategory.love => 'xét về mặt tình cảm',
      ReadingCategory.money => 'về mặt hoạch định nguồn lực',
      ReadingCategory.study => 'trong việc học tập',
      ReadingCategory.friends => 'trong các mối quan hệ',
      ReadingCategory.general => 'đối với dự định chung',
      ReadingCategory.other => 'với băn khoăn của bạn',
    };

    final transit = (dayText != null && officerText != null)
        ? 'ngày $dayText (Trực $officerText)'
        : 'hôm nay';

    final interaction = switch (lean) {
      CosmicLean.first => elementText != null
          ? 'thời vận tương sinh nâng đỡ bản mệnh $elementText của bạn rất thuận lợi'
          : 'thời vận ngày này rất thuận lợi để nâng đỡ các dự định của bạn',
      CosmicLean.second => elementText != null
          ? 'khí tiết nhắc nhở bản mệnh $elementText của bạn nên giữ sự điềm tĩnh và thận trọng'
          : 'khí tiết ngày này nhắc nhở bạn nên giữ sự điềm tĩnh và thận trọng',
      CosmicLean.balanced => elementText != null
          ? 'thời vận và bản mệnh $elementText của bạn đang ở trạng thái quân bình cần sự lắng lại'
          : 'thời vận ngày này đang ở trạng thái quân bình cần thêm khoảng lặng',
    };

    return '$pfx $transit, $cat, $interaction.';
  }

  String _buildEnglishSentence() {
    final pfx = switch (period) {
      TimePeriod.morning => 'This morning',
      TimePeriod.midday => 'At midday',
      TimePeriod.afternoon => 'This afternoon',
      TimePeriod.evening => 'This evening',
      TimePeriod.now => 'At this moment',
    };

    final cat = switch (category) {
      ReadingCategory.career => 'in career matters',
      ReadingCategory.love => 'in emotional matters',
      ReadingCategory.money => 'in resource planning',
      ReadingCategory.study => 'in personal study',
      ReadingCategory.friends => 'in social connections',
      ReadingCategory.general => 'for your overall direction',
      ReadingCategory.other => 'for this inquiry',
    };

    if (heritageZone == HeritageZone.eastern) {
      final transit = (dayText != null && officerText != null)
          ? 'on this $dayText ($officerText Officer)'
          : 'in current cosmic timing';
      final interaction = switch (lean) {
        CosmicLean.first => elementText != null
            ? 'the transit harmoniously supports your $elementText element nature'
            : 'the transit harmoniously supports your endeavors',
        CosmicLean.second => elementText != null
            ? 'the transit advises your $elementText element nature to exercise calm composure'
            : 'the transit advises keeping steady composure and patience',
        CosmicLean.balanced => elementText != null
            ? 'cosmic currents and your $elementText element nature rest in steady equilibrium'
            : 'the surrounding currents rest in steady equilibrium',
      };
      return '$pfx $transit, $cat, $interaction.';
    } else if (heritageZone == HeritageZone.vedic) {
      final transit = (moonPhaseText != null && pakshaText != null)
          ? 'under $moonPhaseText ($pakshaText)'
          : 'in this cosmic phase';
      final interaction = switch (lean) {
        CosmicLean.first => zodiacText != null
            ? 'the cosmic transit aligns favorably with your $zodiacText disposition'
            : 'the cosmic transit aligns favorably with your natal disposition',
        CosmicLean.second => zodiacText != null
            ? 'the cosmic transit counsels your $zodiacText disposition to remain patient and reflective'
            : 'the cosmic transit counsels your inner self to remain patient and reflective',
        CosmicLean.balanced => zodiacText != null
            ? 'planetary energies and your $zodiacText disposition rest in quiet balance'
            : 'planetary energies and your inner self rest in quiet balance',
      };
      return '$pfx $transit, $cat, $interaction.';
    } else {
      final transit = moonPhaseText != null ? 'under $moonPhaseText' : 'in the current planetary transit';
      final interaction = switch (lean) {
        CosmicLean.first => zodiacText != null
            ? 'the planetary transit harmoniously supports your $zodiacText clarity'
            : 'the planetary transit harmoniously supports your clarity',
        CosmicLean.second => zodiacText != null
            ? 'the planetary transit invites your $zodiacText clarity to exercise calm patience'
            : 'the planetary transit invites exercising calm patience',
        CosmicLean.balanced => zodiacText != null
            ? 'cosmic signals and your $zodiacText clarity rest in steady balance'
            : 'cosmic signals rest in steady balance',
      };
      return '$pfx $transit, $cat, $interaction.';
    }
  }

  String _buildSpanishSentence() {
    final pfx = switch (period) {
      TimePeriod.morning => 'Esta mañana',
      TimePeriod.midday => 'Al mediodía',
      TimePeriod.afternoon => 'Esta tarde',
      TimePeriod.evening => 'Esta noche',
      TimePeriod.now => 'En este momento',
    };

    final cat = switch (category) {
      ReadingCategory.career => 'en el ámbito profesional',
      ReadingCategory.love => 'en el plano emocional',
      ReadingCategory.money => 'en la gestión de recursos',
      ReadingCategory.study => 'en el aprendizaje personal',
      ReadingCategory.friends => 'en tus vínculos cercanos',
      ReadingCategory.general => 'para tu dirección general',
      ReadingCategory.other => 'ante esta inquietud',
    };

    final transit = moonPhaseText != null ? 'bajo $moonPhaseText' : 'en el actual tránsito planetario';

    final interaction = switch (lean) {
      CosmicLean.first => zodiacText != null
          ? 'el tránsito planetario favorece con armonía tu claridad de $zodiacText'
          : 'el tránsito planetario favorece con armonía tu claridad de discernimiento',
      CosmicLean.second => zodiacText != null
          ? 'el tránsito planetario aconseja a tu claridad de $zodiacText mantener la calma y la paciencia'
          : 'el tránsito planetario aconseja mantener la calma y la prudencia',
      CosmicLean.balanced => zodiacText != null
          ? 'las señales planetarias y tu claridad de $zodiacText descansan en sereno equilibrio'
          : 'las señales planetarias descansan en sereno equilibrio',
    };

    return '$pfx $transit, $cat, $interaction.';
  }

  String _buildChineseSentence() {
    final pfx = switch (period) {
      TimePeriod.morning => '早晨',
      TimePeriod.midday => '正午',
      TimePeriod.afternoon => '午后',
      TimePeriod.evening => '傍晚',
      TimePeriod.now => '此时',
    };

    final cat = switch (category) {
      ReadingCategory.career => '在事业发展方面',
      ReadingCategory.love => '在情感维系方面',
      ReadingCategory.money => '在资源规划方面',
      ReadingCategory.study => '在学业精进方面',
      ReadingCategory.friends => '在人际交往方面',
      ReadingCategory.general => '就整体运势而言',
      ReadingCategory.other => '就当前考量而言',
    };

    final transit = (dayText != null && officerText != null)
        ? '$dayText（$officerText）'
        : '';

    final interaction = switch (lean) {
      CosmicLean.first => elementText != null
          ? '时运相生并助力您的$elementText特质'
          : '此时时运相生并助力您的当下前行',
      CosmicLean.second => elementText != null
          ? '时序提醒您的$elementText特质宜守从容沉稳'
          : '时序提醒此时宜守从容沉稳',
      CosmicLean.balanced => elementText != null
          ? '时运与您的$elementText特质正处于均势平和之境'
          : '此时时运正处于均势平和之境',
    };

    return '$transit$pfx，$cat，$interaction。';
  }

  String _buildJapaneseSentence() {
    final pfx = switch (period) {
      TimePeriod.morning => '朝の時間帯',
      TimePeriod.midday => '昼の時間帯',
      TimePeriod.afternoon => '午後の時間帯',
      TimePeriod.evening => '夜の時間帯',
      TimePeriod.now => '現在の時節',
    };

    final cat = switch (category) {
      ReadingCategory.career => '仕事や目標において',
      ReadingCategory.love => '心のご縁において',
      ReadingCategory.money => '計画や資源において',
      ReadingCategory.study => '学びの歩みにおいて',
      ReadingCategory.friends => '周囲との調和において',
      ReadingCategory.general => '全体の巡りにおいて',
      ReadingCategory.other => 'この問いかけにおいて',
    };

    final transit = (dayText != null && officerText != null)
        ? '$dayText（$officerText）の'
        : '';

    final interaction = switch (lean) {
      CosmicLean.first => elementText != null
          ? '時運が相生してあなたの$elementTextを心地よく後押ししています'
          : '時運が相生してあなたの歩みを心地よく後押ししています',
      CosmicLean.second => elementText != null
          ? '時節はあなたの$elementTextに落ち着きと慎重さを促しています'
          : '時節は落ち着きと慎重さを促しています',
      CosmicLean.balanced => elementText != null
          ? '時運とあなたの$elementTextは調和した均衡にあります'
          : '時運は調和した均衡にあります',
    };

    return '$transit$pfx、$cat、$interaction。';
  }

  String _buildKoreanSentence() {
    final pfx = switch (period) {
      TimePeriod.morning => '아침 시간',
      TimePeriod.midday => '한낮 시간',
      TimePeriod.afternoon => '오후 시간',
      TimePeriod.evening => '저녁 시간',
      TimePeriod.now => '지금의 흐름',
    };

    final cat = switch (category) {
      ReadingCategory.career => '일과 목표의 영역에서',
      ReadingCategory.love => '마음과 인연의 측면에서',
      ReadingCategory.money => '자원과 계획의 측면에서',
      ReadingCategory.study => '배움과 성장의 영역에서',
      ReadingCategory.friends => '사람과의 관계에서',
      ReadingCategory.general => '전반적인 흐름에서',
      ReadingCategory.other => '현재 마주한 사안에서',
    };

    final transit = (dayText != null && officerText != null)
        ? '$dayText($officerText) '
        : '';

    final interaction = switch (lean) {
      CosmicLean.first => elementText != null
          ? '시운이 상생하며 당신의 $elementText을 순조롭게 뒷받침합니다'
          : '시운이 상생하며 당신의 발걸음을 순조롭게 뒷받침합니다',
      CosmicLean.second => elementText != null
          ? '시운은 당신의 $elementText에 차분함과 신중함을 권합니다'
          : '시운은 차분함과 신중함을 권합니다',
      CosmicLean.balanced => elementText != null
          ? '시운과 당신의 $elementText은 평온한 균형을 이루고 있습니다'
          : '시운은 평온한 균형을 이루고 있습니다',
    };

    return '$transit$pfx, $cat $interaction.';
  }

  String _buildThaiSentence() {
    final pfx = switch (period) {
      TimePeriod.morning => 'ในช่วงเช้าวันนี้',
      TimePeriod.midday => 'ในช่วงกลางวันนี้',
      TimePeriod.afternoon => 'ในช่วงบ่ายวันนี้',
      TimePeriod.evening => 'ในช่วงค่ำวันนี้',
      TimePeriod.now => 'ในเวลานี้',
    };

    final cat = switch (category) {
      ReadingCategory.career => 'ในด้านหน้าที่การงาน',
      ReadingCategory.love => 'ในด้านความรู้สึกผูกพัน',
      ReadingCategory.money => 'ในด้านการบริหารจัดการทรัพยากร',
      ReadingCategory.study => 'ในด้านการเรียนรู้และพัฒนาตนเอง',
      ReadingCategory.friends => 'ในด้านความสัมพันธ์กับผู้อื่น',
      ReadingCategory.general => 'ในภาพรวมของทิศทางชีวิต',
      ReadingCategory.other => 'ในประเด็นที่คุณกำลังพิจารณา',
    };

    final transit = moonPhaseText != null ? 'ท่ามกลาง$moonPhaseText' : '';

    final interaction = switch (lean) {
      CosmicLean.first => elementText != null
          ? 'กระแสเวลาช่วยส่งเสริม$elementTextของคุณอย่างราบรื่น'
          : 'กระแสเวลาช่วยส่งเสริมการก้าวไปข้างหน้าของคุณอย่างราบรื่น',
      CosmicLean.second => elementText != null
          ? 'กระแสเวลาเตือนให้$elementTextของคุณรักษาความสุขุมและรอบคอบ'
          : 'กระแสเวลาเตือนให้รักษาความสุขุมและรอบคอบ',
      CosmicLean.balanced => elementText != null
          ? 'พลังแห่งกาลเวลาและ$elementTextของคุณอยู่ในภาวะสมดุลอันสงบนิ่ง'
          : 'พลังแห่งกาลเวลาอยู่ในภาวะสมดุลอันสงบนิ่ง',
    };

    return transit.isNotEmpty
        ? '$pfx $transit $cat $interaction'
        : '$pfx $cat $interaction';
  }

  String _buildHindiSentence() {
    final pfx = switch (period) {
      TimePeriod.morning => 'आज सुबह के समय',
      TimePeriod.midday => 'दोपहर के समय',
      TimePeriod.afternoon => 'अपराह्न के समय',
      TimePeriod.evening => 'शाम के समय',
      TimePeriod.now => 'इस समय',
    };

    final cat = switch (category) {
      ReadingCategory.career => 'कार्य और प्रगति के संदर्भ में',
      ReadingCategory.love => 'भावनाओं और जुड़ाव के संदर्भ में',
      ReadingCategory.money => 'संसाधनों के नियोजन के संदर्भ में',
      ReadingCategory.study => 'ज्ञानार्जन और स्वाध्याय के संदर्भ में',
      ReadingCategory.friends => 'सामाजिक संपर्कों के संदर्भ में',
      ReadingCategory.general => 'समग्र जीवन दिशा के संदर्भ में',
      ReadingCategory.other => 'इस परिस्थिति के संदर्भ में',
    };

    final transit = pakshaText != null ? '$pakshaText के प्रभाव में' : '';

    final interaction = switch (lean) {
      CosmicLean.first => zodiacText != null
          ? 'यह ग्रह गोचर आपकी $zodiacText प्रकृति को अनुकूल सहारा दे रहा है'
          : 'यह ग्रह गोचर आपके प्रयासों को अनुकूल सहारा दे रहा है',
      CosmicLean.second => zodiacText != null
          ? 'यह ग्रह गोचर आपकी $zodiacText प्रकृति को संयम और धैर्य रखने की प्रेरणा देता है'
          : 'यह ग्रह गोचर संयम और धैर्य रखने की प्रेरणा देता है',
      CosmicLean.balanced => zodiacText != null
          ? 'ग्रहों का प्रभाव और आपकी $zodiacText प्रकृति शांत संतुलन में हैं'
          : 'ग्रहों का प्रभाव इस समय शांत संतुलन में है',
    };

    return transit.isNotEmpty
        ? '$pfx $transit, $cat, $interaction।'
        : '$pfx, $cat, $interaction।';
  }
}

/// Safely extracts and localizes the spiritual time anchor for a reading.
CosmicTimeAnchor extractCosmicAnchor({
  required ReadingResponse reading,
  required AppLocale locale,
  required CosmicLean lean,
}) {
  final profileRaw = reading.inputSnapshot.raw['profile'];
  final birthCountryCode =
      (profileRaw is Map ? profileRaw['birthCountry'] : null) as String?;
  final birthDateStr =
      (profileRaw is Map ? profileRaw['birthDate'] : null) as String?;

  final heritage = _resolveHeritageZone(locale, birthCountryCode);

  String? dayText;
  String? officerText;
  String? elementText;
  String? moonPhaseText;
  String? zodiacText;
  String? pakshaText;

  try {
    final instantMs = reading.context.instantMs.toDouble();
    final tz = validZone(reading.context.timezone)
        ? reading.context.timezone
        : 'UTC';

    if (instantMs > 0) {
      final cal = calendarAt(instantMs, tz);
      final alm = almanac(cal);
      final officerId = alm.diagnostics['officer'] as String? ?? 'open';

      dayText = _localizeDayText(locale, heritage, cal.day.stem, cal.day.branch);
      officerText = _localizeOfficer(locale, heritage, officerId);

      // Astronomy & Moon phase
      final sky = skyAt(instantMs);
      final phi = (sky.positions['moon']! - sky.positions['sun']!) % 360;
      final phaseKind = (phi < 150) ? 'waxing' : (phi < 210 ? 'full' : 'waning');

      moonPhaseText = _localizeMoonPhase(locale, phaseKind);
      pakshaText = _localizePaksha(locale, phaseKind);
    }
  } catch (_) {
    // Graceful fallback on calendar calculation error
  }

  try {
    if (birthDateStr != null && birthDateStr.isNotEmpty) {
      final birthDate = DateTime.tryParse(birthDateStr);
      if (birthDate != null) {
        final dateOnly = birthDateStr.contains('T')
            ? birthDateStr.split('T').first
            : (birthDateStr.length >= 10 ? birthDateStr.substring(0, 10) : birthDateStr);
        final birthCal = civilCalendar(dateOnly);
        final natalStem = birthCal.day.stem;
        final elem = stemElements[natalStem];
        elementText = _localizeElement(locale, elem);

        final zodiac = zodiacForDate(birthDate);
        zodiacText = _localizeZodiac(locale, zodiac);
      }
    }
  } catch (_) {
    // Graceful fallback on birth date calculation error
  }

  return CosmicTimeAnchor(
    locale: locale,
    period: reading.period,
    category: reading.category,
    lean: lean,
    heritageZone: heritage,
    dayText: dayText,
    officerText: officerText,
    elementText: elementText,
    moonPhaseText: moonPhaseText,
    zodiacText: zodiacText,
    pakshaText: pakshaText,
  );
}

HeritageZone _resolveHeritageZone(AppLocale locale, String? birthCountry) {
  if (locale == AppLocale.english) {
    if (birthCountry != null) {
      final upper = birthCountry.toUpperCase();
      if (_easternCountries.contains(upper)) return HeritageZone.eastern;
      if (_vedicCountries.contains(upper)) return HeritageZone.vedic;
    }
    return HeritageZone.western;
  }
  if (locale == AppLocale.hindi) return HeritageZone.vedic;
  if (locale == AppLocale.vietnamese ||
      locale == AppLocale.simplifiedChinese ||
      locale == AppLocale.japanese ||
      locale == AppLocale.korean) {
    return HeritageZone.eastern;
  }
  return HeritageZone.western;
}

const Set<String> _easternCountries = {
  'VN', 'CN', 'HK', 'TW', 'MO', 'JP', 'KR', 'SG', 'MY',
};

const Set<String> _vedicCountries = {
  'IN', 'NP', 'LK', 'BD', 'PK', 'BT',
};

// =============================================================================
// Localizers (100% free of forbidden words, overclaims, and digits)
// =============================================================================

const List<String> _stemsVi = [
  'Giáp', 'Ất', 'Bính', 'Đinh', 'Mậu', 'Kỷ', 'Canh', 'Tân', 'Nhâm', 'Quý',
];
const List<String> _branchesVi = [
  'Tý', 'Sửu', 'Dần', 'Mão', 'Thìn', 'Tỵ', 'Ngọ', 'Mùi', 'Thân', 'Dậu', 'Tuất', 'Hợi',
];

const List<String> _stemsZh = [
  '甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸',
];
const List<String> _branchesZh = [
  '子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥',
];

const List<String> _stemsKo = [
  '갑', '을', '병', '정', '무', '기', '경', '신', '임', '계',
];
const List<String> _branchesKo = [
  '자', '축', '인', '묘', '진', '사', '오', '미', '신', '유', '술', '해',
];

const List<String> _stemElementsEn = [
  'Wood', 'Wood', 'Fire', 'Fire', 'Earth', 'Earth', 'Metal', 'Metal', 'Water', 'Water',
];
const List<String> _branchAnimalsEn = [
  'Rat', 'Ox', 'Tiger', 'Rabbit', 'Dragon', 'Snake', 'Horse', 'Goat', 'Monkey', 'Rooster', 'Dog', 'Pig',
];

String _localizeDayText(AppLocale locale, HeritageZone heritage, int stem, int branch) {
  final s = stem % 10;
  final b = branch % 12;
  switch (locale) {
    case AppLocale.vietnamese:
      return '${_stemsVi[s]} ${_branchesVi[b]}';
    case AppLocale.simplifiedChinese:
      return '${_stemsZh[s]}${_branchesZh[b]}日';
    case AppLocale.japanese:
      return '${_stemsZh[s]}${_branchesZh[b]}の日';
    case AppLocale.korean:
      return '${_stemsKo[s]}${_branchesKo[b]}일';
    case AppLocale.english:
      if (heritage == HeritageZone.eastern) {
        return '${_stemElementsEn[s]}-${_branchAnimalsEn[b]} day';
      }
      return 'favorable day';
    default:
      return '${_stemsVi[s]} ${_branchesVi[b]}';
  }
}

String _localizeOfficer(AppLocale locale, HeritageZone heritage, String officerId) {
  switch (locale) {
    case AppLocale.vietnamese:
      return switch (officerId) {
        'establish' => 'Kiến',
        'remove' => 'Trừ',
        'full' => 'Mãn',
        'balance' => 'Bình',
        'stable' => 'Định',
        'hold' => 'Chấp',
        'break' => 'Phá',
        'danger' => 'Nguy',
        'success' => 'Thành',
        'receive' => 'Thu',
        'open' => 'Khai',
        'close' => 'Bế',
        _ => 'Khai',
      };
    case AppLocale.simplifiedChinese:
      return switch (officerId) {
        'establish' => '建日',
        'remove' => '除日',
        'full' => '满日',
        'balance' => '平日',
        'stable' => '定日',
        'hold' => '执日',
        'break' => '破日',
        'danger' => '危日',
        'success' => '成日',
        'receive' => '收日',
        'open' => '开日',
        'close' => '闭日',
        _ => '开日',
      };
    case AppLocale.japanese:
      return switch (officerId) {
        'establish' => '建の日',
        'remove' => '除の日',
        'full' => '満の日',
        'balance' => '平の日',
        'stable' => '定の日',
        'hold' => '執の日',
        'break' => '破の日',
        'danger' => '危の日',
        'success' => '成の日',
        'receive' => '納の日',
        'open' => '開の日',
        'close' => '閉の日',
        _ => '開の日',
      };
    case AppLocale.korean:
      return switch (officerId) {
        'establish' => '건일',
        'remove' => '제일',
        'full' => '만일',
        'balance' => '평일',
        'stable' => '정일',
        'hold' => '집일',
        'break' => '파일',
        'danger' => '위일',
        'success' => '성일',
        'receive' => '수일',
        'open' => '개일',
        'close' => '폐일',
        _ => '개일',
      };
    case AppLocale.english:
      return switch (officerId) {
        'establish' => 'Establish',
        'remove' => 'Clearing',
        'full' => 'Full',
        'balance' => 'Balance',
        'stable' => 'Stable',
        'hold' => 'Resolve',
        'break' => 'Breakthrough',
        'danger' => 'Mindful',
        'success' => 'Success',
        'receive' => 'Harvest',
        'open' => 'Open',
        'close' => 'Reflective',
        _ => 'Open',
      };
    default:
      return 'Open';
  }
}

String _localizeElement(AppLocale locale, String elem) {
  switch (locale) {
    case AppLocale.vietnamese:
      return switch (elem) {
        'wood' => 'Mộc',
        'fire' => 'Hỏa',
        'earth' => 'Thổ',
        'metal' => 'Kim',
        'water' => 'Thủy',
        _ => 'Mộc',
      };
    case AppLocale.simplifiedChinese:
      return switch (elem) {
        'wood' => '木命',
        'fire' => '火命',
        'earth' => '土命',
        'metal' => '金命',
        'water' => '水命',
        _ => '木命',
      };
    case AppLocale.japanese:
      return switch (elem) {
        'wood' => '木性',
        'fire' => '火性',
        'earth' => '土性',
        'metal' => '金性',
        'water' => '水性',
        _ => '木性',
      };
    case AppLocale.korean:
      return switch (elem) {
        'wood' => '목 기운',
        'fire' => '화 기운',
        'earth' => '토 기운',
        'metal' => '금 기운',
        'water' => '수 기운',
        _ => '목 기운',
      };
    case AppLocale.english:
      return switch (elem) {
        'wood' => 'Wood',
        'fire' => 'Fire',
        'earth' => 'Earth',
        'metal' => 'Metal',
        'water' => 'Water',
        _ => 'Wood',
      };
    case AppLocale.thai:
      return switch (elem) {
        'wood' => 'ธาตุไม้',
        'fire' => 'ธาตุไฟ',
        'earth' => 'ธาตุดิน',
        'metal' => 'ธาตุทอง',
        'water' => 'ธาตุน้ำ',
        _ => 'ธาตุไม้',
      };
    default:
      return elem;
  }
}

String _localizeMoonPhase(AppLocale locale, String phaseKind) {
  switch (locale) {
    case AppLocale.english:
      return switch (phaseKind) {
        'waxing' => 'the waxing moon',
        'full' => 'the full moon',
        'waning' => 'the waning moon',
        _ => 'the waxing moon',
      };
    case AppLocale.spanish:
      return switch (phaseKind) {
        'waxing' => 'la luna creciente',
        'full' => 'la luna llena',
        'waning' => 'la luna menguante',
        _ => 'la luna creciente',
      };
    case AppLocale.thai:
      return switch (phaseKind) {
        'waxing' => 'ช่วงข้างขึ้น',
        'full' => 'ช่วงจันทร์เพ็ญ',
        'waning' => 'ช่วงข้างแรม',
        _ => 'ช่วงข้างขึ้น',
      };
    default:
      return 'the waxing moon';
  }
}

String _localizePaksha(AppLocale locale, String phaseKind) {
  switch (locale) {
    case AppLocale.hindi:
      return switch (phaseKind) {
        'waxing' => 'शुक्ल पक्ष',
        'full' => 'पूर्णिमा काल',
        'waning' => 'कृष्ण पक्ष',
        _ => 'शुक्ल पक्ष',
      };
    case AppLocale.english:
      return switch (phaseKind) {
        'waxing' => 'Shukla Paksha',
        'full' => 'Purnima',
        'waning' => 'Krishna Paksha',
        _ => 'Shukla Paksha',
      };
    default:
      return 'Shukla Paksha';
  }
}

String _localizeZodiac(AppLocale locale, ZodiacSign sign) {
  switch (locale) {
    case AppLocale.spanish:
      return switch (sign) {
        ZodiacSign.aries => 'Aries',
        ZodiacSign.taurus => 'Tauro',
        ZodiacSign.gemini => 'Géminis',
        ZodiacSign.cancer => 'Cáncer',
        ZodiacSign.leo => 'Leo',
        ZodiacSign.virgo => 'Virgo',
        ZodiacSign.libra => 'Libra',
        ZodiacSign.scorpio => 'Escorpio',
        ZodiacSign.sagittarius => 'Sagitario',
        ZodiacSign.capricorn => 'Capricornio',
        ZodiacSign.aquarius => 'Acuario',
        ZodiacSign.pisces => 'Piscis',
      };
    case AppLocale.hindi:
      return switch (sign) {
        ZodiacSign.aries => 'मेष',
        ZodiacSign.taurus => 'वृषभ',
        ZodiacSign.gemini => 'मिथुन',
        ZodiacSign.cancer => 'कर्क',
        ZodiacSign.leo => 'सिंह',
        ZodiacSign.virgo => 'कन्या',
        ZodiacSign.libra => 'तुला',
        ZodiacSign.scorpio => 'वृश्चिक',
        ZodiacSign.sagittarius => 'धनु',
        ZodiacSign.capricorn => 'मकर',
        ZodiacSign.aquarius => 'कुंभ',
        ZodiacSign.pisces => 'मीन',
      };
    default:
      return switch (sign) {
        ZodiacSign.aries => 'Aries',
        ZodiacSign.taurus => 'Taurus',
        ZodiacSign.gemini => 'Gemini',
        ZodiacSign.cancer => 'Cancer',
        ZodiacSign.leo => 'Leo',
        ZodiacSign.virgo => 'Virgo',
        ZodiacSign.libra => 'Libra',
        ZodiacSign.scorpio => 'Scorpio',
        ZodiacSign.sagittarius => 'Sagittarius',
        ZodiacSign.capricorn => 'Capricorn',
        ZodiacSign.aquarius => 'Aquarius',
        ZodiacSign.pisces => 'Pisces',
      };
  }
}
