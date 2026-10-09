// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appName => 'AstraCue';

  @override
  String get analyticsConsentTitle => '이용 현황 분석 (선택)';

  @override
  String get analyticsConsentBody =>
      'AstraCue 서비스 품질 개선을 위해 Firebase 및 Google Analytics를 통한 이용 통계 수집을 허용합니다. 이름, 출생 정보, 개인 점술 내용은 일절 전송되지 않으며, \'안전한 이용\' 메뉴에서 언제든지 끌 수 있습니다.';

  @override
  String get analyticsConsentSaveFailed =>
      '설정을 저장하지 못했습니다. 이번 세션 동안 분석 기능이 꺼집니다.';

  @override
  String get continueAction => '계속하기';

  @override
  String get backAction => '뒤로';

  @override
  String get closeAction => '닫기';

  @override
  String get tryAgain => '다시 시도';

  @override
  String get responsibleUse => '안전한 이용 안내';

  @override
  String get history => '기록';

  @override
  String get onboardingTitle => '우주의 신호와 당신의 직관에 귀 기울여 보세요.';

  @override
  String get onboardingLanguageHint => '언어를 변경하려면 상단의 지구본 아이콘을 탭하세요.';

  @override
  String get yourProfile => '나의 프로필';

  @override
  String get signAfterBirthDate => '생년월일을 입력하면 별자리가 표시됩니다';

  @override
  String get buildPattern => '나만의 고유한 에너지를 발견해 보세요.';

  @override
  String get profileExplainer => '분석에 활용될 에너지 주기를 계산합니다.';

  @override
  String get nameField => '이름';

  @override
  String get dateOfBirth => '생년월일';

  @override
  String get selectBirthDate => '생년월일 선택';

  @override
  String get birthDateRequired => '계속하려면 생년월일을 선택해 주세요.';

  @override
  String get birthDay => '일';

  @override
  String get birthMonth => '월';

  @override
  String get birthYear => '년';

  @override
  String get birthDateScroll => '스크롤';

  @override
  String get birthDateType => '직접 입력';

  @override
  String get birthDateInvalid => '1900년부터 오늘 사이의 올바른 날짜를 입력해 주세요.';

  @override
  String get birthTimeUnknown => '출생 시간 모름';

  @override
  String get birthTimeUnknownDetail =>
      '출생 시간을 모르는 경우, 당신의 성향과 가장 가까운 시간대를 바탕으로 계산합니다.';

  @override
  String get timeOfBirth => '출생 시간';

  @override
  String get countryOfBirth => '출생 국가';

  @override
  String get selectBirthCountry => '국가 검색 및 선택';

  @override
  String get birthCountryRequired => '계속하려면 출생 국가를 선택해 주세요.';

  @override
  String get createCompass => '나의 나침반 만들기';

  @override
  String get birthPrivacyPrototype =>
      '이 체험 버전에서는 출생 정보가 외부에 공개되지 않고 안전하게 보호됩니다.';

  @override
  String get homeEyebrow => '당신을 이끄는 마음의 나침반';

  @override
  String get homeTitle => '선택 앞에서 망설이고 계신가요?';

  @override
  String get areaQuestion => '어떤 분야에 대한 고민인가요?';

  @override
  String get findDirection => '나아갈 방향 찾기';

  @override
  String get todaySignals => '오늘의 신호';

  @override
  String get dailyEnergy => '오늘의 에너지';

  @override
  String get yourColorsToday => '오늘의 색상:';

  @override
  String get luckyNumberToday => '오늘의 행운의 숫자:';

  @override
  String get categoryOverall => '종합';

  @override
  String get categoryLove => '사랑과 인연';

  @override
  String get categoryCareer => '커리어';

  @override
  String get categoryMoney => '재정';

  @override
  String get categoryStudy => '배움과 성장';

  @override
  String get categoryFriends => '친구';

  @override
  String get categoryOther => '기타';

  @override
  String get periodQuestion => '어느 시간대를 염두에 두고 계신가요?';

  @override
  String get periodNow => '지금';

  @override
  String get periodMorning => '아침';

  @override
  String get periodMidday => '낮';

  @override
  String get periodAfternoon => '오후';

  @override
  String get periodEvening => '저녁';

  @override
  String get periodPassed => '지남';

  @override
  String get periodTooLittleTime => '지남';

  @override
  String get periodCheckingTimezone => '시간대 확인 중';

  @override
  String get periodTimezoneUnknown => '시간대를 확인할 수 없습니다';

  @override
  String get timezoneUnavailableNotice => '시간대 정보를 불러올 수 없습니다. 기본 설정을 사용합니다.';

  @override
  String periodHasPassed(String period) {
    return '$period 시간이 지났습니다. 다른 시간대를 선택해 주세요.';
  }

  @override
  String periodNotEnoughTimeLeft(String period) {
    return '오늘 $period 시간이 얼마 남지 않았습니다. 다른 시간대를 선택해 주세요.';
  }

  @override
  String get reveal => '분석하기';

  @override
  String get aligning => '조율 중';

  @override
  String get tapWhenReady => '준비가 되면 탭하세요';

  @override
  String get keepChoiceInMind => '마음속에 고민을 선명히 떠올려 보세요.';

  @override
  String get ritualSafety => '마음 챙김 이용 안내';

  @override
  String get loadingLocalMoment => '현재 시간대의 기운을 읽는 중...';

  @override
  String get loadingReassurance => '정확한 상징 매칭을 위해 잠시 호흡을 가다듬으세요...';

  @override
  String readingForCategory(String category) {
    return '$category 점술';
  }

  @override
  String get yourDirection => '당신의 방향';

  @override
  String get resultBasis => '분석 기준';

  @override
  String get percentageCaveat => '백분율은 상징적인 지표이며, 절대적인 확률이 아닙니다.';

  @override
  String get balancedHeading => '두 흐름이 대등합니다';

  @override
  String get balancedResult => '균형을 이룸';

  @override
  String get balancedExplanation =>
      '어느 한쪽으로 기울지 않고 균형을 유지하고 있습니다. 내면의 소리에 조금 더 귀 기울여 보세요.';

  @override
  String get currentMoment => '지금 이 순간';

  @override
  String get luckyTimesCaveat => '상징적 지표이며 특정 사건을 보장하지 않습니다.';

  @override
  String get tryAnotherDirection => '다른 방향 탐색하기';

  @override
  String get viewHistory => '기록 보기';

  @override
  String get yourReadings => '나의 점술 기록';

  @override
  String get noReadings => '저장된 점술 기록이 없습니다.';

  @override
  String get historySnapshot => '점술 기록 스냅샷';

  @override
  String get everydayReflection => '일상의 성찰';

  @override
  String get luckyTimesMorning => '아침의 상서로운 시간';

  @override
  String get luckyTimesMidday => '낮의 상서로운 시간';

  @override
  String get luckyTimesAfternoon => '오후의 상서로운 시간';

  @override
  String get luckyTimesEvening => '저녁의 상서로운 시간';

  @override
  String get loadingLocalTime => '지역 시각 및 천체 좌표 동기화 중...';

  @override
  String get loadingBaZi => '사주 에너지 조율 중...';

  @override
  String get loadingZiWei => '자미두수 명반 배치 중...';

  @override
  String get loadingVedic => '베다 점성술 패턴 대조 중...';

  @override
  String get loadingNumerology => '수비학적 파동 계산 중...';

  @override
  String get loadingYinYang => '음양오행 균형 확인 중...';

  @override
  String get loadingModeYesNo => '선택의 양면성을 가만히 헤아려 보세요.';

  @override
  String get loadingModeActWait => '때를 기다림과 나아감의 리듬을 느껴보세요.';

  @override
  String get loadingModeAdvanceRetreat => '발걸음의 무게를 차분히 가늠해 보세요.';

  @override
  String get loadingModeStayGo => '머묾과 떠남 사이의 고요를 바라보세요.';

  @override
  String get loadingModeKeepLetGo => '마음속에 품을 것과 비울 것을 떠올려 보세요.';

  @override
  String get loadingModeForwardBackward => '시선의 방향을 조용히 바로잡아 보세요.';

  @override
  String get loadingModeCommitWithdraw => '몰입과 한 걸음 물러섬의 경계를 짚어보세요.';

  @override
  String get loadingModeLeftRight => '좌우의 갈림길을 편견 없이 바라보세요.';

  @override
  String get orbitMoment => '시간의 기운';

  @override
  String get orbitRhythm => '우주의 리듬';

  @override
  String get orbitBalance => '조화와 균형';

  @override
  String get orbitAlmanac => '역법';

  @override
  String get orbitBaZi => '사주팔자';

  @override
  String get orbitZiWei => '자미두수';

  @override
  String get orbitVedic => '베다 점성술';

  @override
  String get orbitNumerology => '수비학';

  @override
  String get orbitLunarPhase => '달의 위상';

  @override
  String get orbitPlanetary => '행성 운행';

  @override
  String get orbitYinYang => '음양의 조화';

  @override
  String get safetyHeading => '안전한 이용 수칙';

  @override
  String get safetyTitle => '안전 수칙';

  @override
  String get safetyIntro => 'AstraCue를 건강하고 지혜롭게 활용하는 방법입니다.';

  @override
  String get prohibitedUses => '금지된 이용 행위';

  @override
  String get harmTitle => '위해 및 위험 방지';

  @override
  String get harmDetail =>
      '자해, 타해, 범죄 행위 등 위험한 행동을 유도하거나 조장하는 용도로 본 서비스를 이용해서는 안 됩니다.';

  @override
  String get navigationTitle => '항해 및 이동 안전';

  @override
  String get navigationDetail =>
      '차량 운전, 선박 항해, 항공기 조종 등 실제 이동 안전에 나침반 결과를 의존해서는 안 됩니다.';

  @override
  String get politicsTitle => '선거 및 정치 관련 안내';

  @override
  String get politicsDetail =>
      '본 서비스는 정치적 견해나 선거 결과에 관여하지 않으며 관련 예측을 제공하지 않습니다.';

  @override
  String get medicalTitle => '의료 및 건강 관련 안내';

  @override
  String get medicalDetail =>
      'AstraCue는 의학적 진단, 치료, 처방을 대신하지 않습니다. 신체적·정신적 건강 문제는 반드시 전문 의료진과 상담하세요.';

  @override
  String get legalTitle => '법률 관련 안내';

  @override
  String get legalDetail =>
      'AstraCue는 법률적 자문이나 소송 관련 지침을 제공하지 않습니다. 법적 분쟁은 공인 법률 전문가와 상의하세요.';

  @override
  String get financeTitle => '재정 및 투자 관련 안내';

  @override
  String get financeDetail =>
      'AstraCue는 투자, 대출, 자산 거래 등 재정적 결정을 지시하지 않습니다. 금융 관련 결정은 공인 금융 전문가와 상의하세요.';

  @override
  String get consentTitle => '동의, 미성년자 및 관계에 관한 원칙';

  @override
  String get consentDetail =>
      '타인의 동의나 자율성을 침해하거나, 양육권 및 후견인 관련 중대한 결정에 본 서비스를 이용해서는 안 됩니다.';

  @override
  String get importantLimitsHeading => '중요한 한계점';

  @override
  String get importantLimitsBody =>
      '상징적 패턴은 직관적 영감을 주는 도구일 뿐, 미래의 확실한 사실을 보장하지 않습니다.';

  @override
  String get crisisSupport => '위기 상담 지원';

  @override
  String get acknowledge => '확인했습니다';

  @override
  String get acknowledgementOnce => '최초 1회만 확인하시면 됩니다.';

  @override
  String get safetyScrollToContinue => '계속하려면 아래로 스크롤하세요';

  @override
  String get knowBirthTime => '출생 시간을 알고 계신가요?';

  @override
  String get knowBirthTimeDetail => '출생 시간을 알면 더 정확한 주기와 시점을 분석할 수 있습니다.';

  @override
  String get selectBirthTime => '출생 시간 선택';

  @override
  String get birthTimeRequired => '출생 시간을 선택해 주세요.';

  @override
  String get languageSetting => '언어 설정';

  @override
  String get chooseLanguage => '언어 선택';

  @override
  String get changeLanguage => '언어 변경';

  @override
  String get languageNotSaved => '언어 설정을 저장하지 못했습니다';

  @override
  String get profileNotSaved => '프로필이 저장되지 않았습니다';

  @override
  String get choiceYes => '예';

  @override
  String get choiceNo => '아니오';

  @override
  String get choiceAct => '행동';

  @override
  String get choiceWait => '기다림';

  @override
  String get choiceAdvance => '전진';

  @override
  String get choiceRetreat => '후퇴';

  @override
  String get choiceStay => '유지';

  @override
  String get choiceGo => '이동';

  @override
  String get choiceKeep => '간직';

  @override
  String get choiceLetGo => '비우기';

  @override
  String get choiceForward => '앞으로';

  @override
  String get choiceBackward => '뒤로';

  @override
  String get choiceCommit => '전념';

  @override
  String get choiceWithdraw => '물러남';

  @override
  String get choiceLeft => '왼쪽';

  @override
  String get choiceRight => '오른쪽';

  @override
  String get energyLevelQuiet => '고요';

  @override
  String get energyLevelSoft => '부드러움';

  @override
  String get energyLevelSteady => '안정';

  @override
  String get energyLevelLively => '활기';

  @override
  String get energyLevelBright => '밝음';

  @override
  String get energyLevelRadiant => '찬란함';

  @override
  String get energyLevelFocused => '집중';

  @override
  String get energyLevelFlowing => '유려함';

  @override
  String get colorCedar => '삼나무색';

  @override
  String get colorJade => '옥색';

  @override
  String get colorSage => '세이지 그린';

  @override
  String get colorMint => '민트';

  @override
  String get colorEmber => '잉걸불색';

  @override
  String get colorSolarCoral => '솔라 코랄';

  @override
  String get colorRose => '로즈';

  @override
  String get colorBlossom => '꽃잎색';

  @override
  String get colorOchre => '황토색';

  @override
  String get colorAmber => '호박색';

  @override
  String get colorSand => '모래빛';

  @override
  String get colorClay => '점토색';

  @override
  String get colorSilver => '실버';

  @override
  String get colorSteel => '스틸';

  @override
  String get colorPearl => '펄';

  @override
  String get colorChampagne => '샴페인';

  @override
  String get colorOceanBlue => '오션 블루';

  @override
  String get colorAzure => '애저 블루';

  @override
  String get colorIndigo => '인디고';

  @override
  String get colorMistBlue => '안개 블루';

  @override
  String get homeDescription00 =>
      '오늘 우주는 당신에게 어떤 신호를 건네고 있을까요? 마음속 고민을 가만히 떠올리며 이 순간의 기운을 느껴보세요.';

  @override
  String get homeDescription01 =>
      '두 갈래 길 앞에서 망설이고 계신가요? 오늘의 우주적 신호가 선택을 바라보는 새로운 시각을 열어줄 수 있습니다.';

  @override
  String get homeDescription02 =>
      '별들이 당신 대신 결정을 내려주지는 않지만, 다음 발걸음을 비추는 뜻밖의 각도를 보여줄 수는 있습니다.';

  @override
  String get homeDescription03 =>
      '앞으로 나아갈 길이 흐릿할 때는 잠시 멈추어 서 보세요. 오늘의 신호는 무엇을 비추고 있나요?';

  @override
  String get homeDescription04 =>
      '모든 순간에는 그만의 고유한 에너지가 깃들어 있습니다. 고민을 떠올리며 이 순간이 이끄는 방향을 가만히 살펴보세요.';

  @override
  String get homeDescription05 =>
      '어쩌면 우주는 속도를 조금 늦추라고 속삭이는지도 모릅니다. 결정을 내리기 전, 오늘 건네는 신호에 귀 기울여 보세요.';

  @override
  String get homeDescription06 =>
      '갈림길에 서 계신가요? 오늘 하늘의 흐름이 당신의 마음에 어떤 울림을 주는지 살펴보세요.';

  @override
  String get homeDescription07 =>
      '이 순간의 리듬에 가만히 귀 기울여 보세요. 오늘의 상징이 깊이 생각해 볼 만한 방향을 조용히 일러줄 수 있습니다.';

  @override
  String get homeDescription08 =>
      '이 순간이 어떤 깨달음을 가져다줄까요? 신호를 살펴본 뒤, 당신의 내면을 믿고 담담히 나아가세요.';

  @override
  String get homeDescription09 =>
      '우주가 건네는 작은 통찰이 생각을 정돈하는 데 도움을 줄 수 있습니다. 오늘 중요한 선택을 떠올리며 신호의 방향을 살펴보세요.';

  @override
  String get homeDescription10 =>
      '같은 선택을 두고 오랫동안 고심하고 계신가요? 오늘의 우주 에너지가 어떤 본질을 조명하는지 살펴보세요.';

  @override
  String get homeDescription11 =>
      '생각은 한쪽으로, 직관은 다른 쪽으로 향할 때. 오늘 당신을 둘러싼 상징적 패턴들을 가만히 짚어보세요.';

  @override
  String get homeDescription12 =>
      '나아갈지, 기다릴지 망설여지시나요? 오늘의 흐름을 차분한 마음을 되찾기 위한 출발점으로 삼아보세요.';

  @override
  String get homeDescription13 =>
      '바라보는 각도를 바꾸는 것만으로도 명확함이 찾아올 수 있습니다. 오늘 하늘의 고요한 움직임에 시선을 두어 보세요.';

  @override
  String get homeDescription14 =>
      '자꾸만 마음에 맴도는 질문이 있나요? 오늘의 상징이 당신에게 무엇을 일깨워주는지 살펴보세요.';

  @override
  String get homeDescription15 =>
      '같은 선택이라도 때에 따라 무게가 다르게 느껴집니다. 결정을 굳히기 전, 이 순간의 에너지를 담담히 바라보세요.';

  @override
  String get homeDescription16 =>
      '지금은 길이 선명하게 보이지 않을 수 있습니다. 망설임 너머로 별들이 비추고 있는 것은 무엇일까요?';

  @override
  String get homeDescription17 =>
      '충동적으로 움직이기 전에 잠시 숨을 고르세요. 오늘의 우주 신호가 무엇을 가리키는지 차분히 살펴보세요.';

  @override
  String get homeDescription18 =>
      '모든 갈림길에서 서둘러 답을 내릴 필요는 없습니다. 오늘의 점술을 생각을 정리하는 여백으로 삼으세요.';

  @override
  String get homeDescription19 =>
      '지금이 적절한 때인지 고민되시나요? 오늘의 흐름을 짚어보며 한층 안정된 시선을 찾아보세요.';

  @override
  String get homeDescription20 =>
      '무엇이든 할 수 있을 것 같지만 확신이 서지 않을 때, 하늘의 배치가 새로운 시야를 열어줄 수 있습니다.';

  @override
  String get homeDescription21 =>
      '선택은 오직 당신의 몫입니다. 오늘의 신호는 정말 중요한 것이 무엇인지 깨닫도록 돕는 길잡이입니다.';

  @override
  String get homeDescription22 =>
      '망설임 탓에 다음 발걸음이 망설여질 때, 당신의 별자리와 오늘의 에너지가 무엇을 비추는지 살펴보세요.';

  @override
  String get homeDescription23 =>
      '더 강한 확답보다는, 오늘의 상징과 고요히 마주하는 작은 여유가 필요한 순간일 수 있습니다.';

  @override
  String get homeDescription24 =>
      '직관은 행동을 재촉하나요, 아니면 기다림을 권하나요? 오늘 우주의 리듬을 가만히 따라가 보세요.';

  @override
  String get homeDescription25 =>
      '바람과 두려움 사이에는 잠시 숨을 돌릴 여백이 있습니다. 오늘의 신호를 길잡이 삼아 마음을 다시 들여다보세요.';

  @override
  String get homeDescription26 =>
      '질문은 이미 당신 안에 있습니다. 이제 이 순간에 집중해 보세요. 오늘 천체의 신호는 무엇을 말하고 있나요?';

  @override
  String get homeDescription27 =>
      '결정이 복잡하게 느껴질 때, 오래된 상징과 오늘이라는 시간이 뜻밖의 명료함을 건넬 수 있습니다.';

  @override
  String get homeDescription28 =>
      '지금은 한 걸음 다가설 때일까요, 아니면 한 발 물러설 때일까요? 선택을 둘러싼 에너지의 결을 살펴보세요.';

  @override
  String get homeDescription29 =>
      '여기서 완벽한 확신을 얻지 않아도 괜찮습니다. 마음을 가라앉히고, 우주의 힌트와 함께 생각을 가다듬으세요.';

  @override
  String get energyQuiet00 => '오늘의 상징적 에너지는 내면으로 향하며, 조용히 돌아볼 여백을 만듭니다.';

  @override
  String get energyQuiet01 =>
      '오늘의 우주 리듬은 안으로 흐릅니다. 고요함 속에서 소음에 가려졌던 진심을 발견할 수 있습니다.';

  @override
  String get energyQuiet02 => '하늘에 정적의 기운이 머뭅니다. 생각이 자연스레 가라앉을 시간을 가져보세요.';

  @override
  String get energyQuiet03 => '은은한 평온이 흐르는 날입니다. 서두르기보다 주변의 기운을 차분히 관찰해 보세요.';

  @override
  String get energyQuiet04 => '오늘의 신호는 회고를 권합니다. 잠시 멈추어 서는 것도 나아가는 과정의 일부입니다.';

  @override
  String get energyQuiet05 => '마음이 차분해질수록, 당신 안의 나침반이 내는 소리가 더 또렷하게 들려옵니다.';

  @override
  String get energyQuiet06 => '오늘의 에너지는 성급히 답을 내리기 전에 귀를 기울일 넉넉한 틈을 선사합니다.';

  @override
  String get energyQuiet07 =>
      '신호가 늘 큰 소리로 다가오는 것은 아닙니다. 오늘은 천천히 걸을 때 더 잘 보입니다.';

  @override
  String get energySoft00 => '오늘의 상징적 에너지는 부드럽게 흐르며, 다정한 시선과 조심스러운 첫걸음을 품어줍니다.';

  @override
  String get energySoft01 => '마음의 긴장을 풀고 쉬어가기 좋은 날입니다. 작은 친절이 큰 힘이 되어줍니다.';

  @override
  String get energySoft02 => '유연한 흐름이 마음을 감쌉니다. 고집을 내려놓고 순리에 맡겨보세요.';

  @override
  String get energySoft03 => '따스한 햇살 같은 기운이 깃들어 있습니다. 스스로를 너그럽게 대하세요.';

  @override
  String get energySoft04 => '서두르지 않아도 모든 것은 제자리를 찾아갑니다. 마음의 여유를 지키세요.';

  @override
  String get energySoft05 => '부드러운 대화 속에서 오해가 풀릴 수 있습니다. 온화한 태도를 유지하세요.';

  @override
  String get energySoft06 => '감정의 날을 세우지 않고 둥글게 보듬기에 적합한 평화로운 날입니다.';

  @override
  String get energySoft07 => '조용한 위로가 마음에 머뭅니다. 작은 일상 속 따뜻함을 음미해 보세요.';

  @override
  String get energySteady00 => '오늘의 기운은 단단하고 안정적이어서, 차분한 판단과 묵직한 발걸음을 지탱해 줍니다.';

  @override
  String get energySteady01 =>
      '흔들리지 않는 대지처럼 마음이 평온합니다. 서두르지 않고 기본을 다지기에 적합합니다.';

  @override
  String get energySteady02 => '주변의 소음 속에서도 중심을 지키기 수월한 날입니다. 차분히 순서를 정해보세요.';

  @override
  String get energySteady03 => '안정된 흐름이 당신의 생각을 가지런히 정돈해 줍니다. 현실적인 시각을 유지하세요.';

  @override
  String get energySteady04 => '지속 가능한 힘이 내면에 머물고 있습니다. 긴 호흡으로 멀리 바라보세요.';

  @override
  String get energySteady05 => '뿌리가 깊은 나무처럼 안정감이 있습니다. 조급해하지 않아도 충분합니다.';

  @override
  String get energySteady06 => '평온함 속에서 일상의 리듬이 지켜집니다. 꾸준함이 가장 큰 힘입니다.';

  @override
  String get energySteady07 => '마음의 균형이 단단히 잡혀 있습니다. 계획한 바를 차분히 이어가세요.';

  @override
  String get energyLively00 => '활기찬 에너지가 가득 차올라, 생동감 넘치는 교류와 경쾌한 발걸음을 재촉합니다.';

  @override
  String get energyLively01 => '생동하는 기운이 마음에 활력을 불어넣습니다. 가벼운 마음으로 시작해 보세요.';

  @override
  String get energyLively02 => '새로운 아이디어가 샘솟는 날입니다. 주변과 긍정적인 자극을 주고받으세요.';

  @override
  String get energyLively03 => '발걸음이 한결 가볍습니다. 망설이던 일에 활기찬 활력을 불어넣어 보세요.';

  @override
  String get energyLively04 => '주변 사람들과의 소통 속에서 기분 좋은 활력이 피어납니다.';

  @override
  String get energyLively05 => '기분 좋은 호기심이 일어납니다. 새로운 시도를 두려워하지 마세요.';

  @override
  String get energyLively06 => '밝은 파동이 주변을 환하게 밝힙니다. 당신의 활기를 나누어 보세요.';

  @override
  String get energyLively07 => '활력이 넘치되 들뜨지 않도록 조절하세요. 즐거운 리듬을 만끽하세요.';

  @override
  String get energyBright00 => '하늘이 맑고 환한 빛으로 가득하여, 긍정적인 전망과 따뜻한 희망을 비춥니다.';

  @override
  String get energyBright01 => '구름이 걷히고 햇살이 비추듯 마음에 명료함이 깃듭니다.';

  @override
  String get energyBright02 => '낙관적인 시각이 힘을 발휘하는 날입니다. 긍정의 가능성을 열어두세요.';

  @override
  String get energyBright03 => '환한 빛 아래에서 의구심이 눈 녹듯 사라집니다. 자신감을 가지세요.';

  @override
  String get energyBright04 => '따뜻한 온기가 마음을 채웁니다. 감사한 마음으로 하루를 대하세요.';

  @override
  String get energyBright05 => '밝은 시야 속에서 새로운 기회가 눈에 띕니다. 시선을 넓게 두세요.';

  @override
  String get energyBright06 => '주변의 어둠을 밝히는 온화한 빛이 당신과 함께합니다.';

  @override
  String get energyBright07 => '희망적인 직관이 반짝입니다. 맑은 마음으로 결정을 마주하세요.';

  @override
  String get energyRadiant00 => '오늘의 상징적 에너지는 생동감 있게 빛나며, 자신감과 맑은 시야를 밝혀줍니다.';

  @override
  String get energyRadiant01 => '기운이 한껏 고조되는 날입니다. 내면의 맑은 빛에 집중하며 주위를 둘러보세요.';

  @override
  String get energyRadiant02 => '생명력이 넘쳐흐릅니다. 마음속 품어둔 뜻을 조심스레 펼쳐보기에 좋은 날입니다.';

  @override
  String get energyRadiant03 => '오늘의 하늘은 환한 명료함을 비춥니다. 의구심이 옅어지고 결의가 돋보입니다.';

  @override
  String get energyRadiant04 => '찬란한 흐름 속에서 당신의 긍정적인 파동이 주변과 조화롭게 공명합니다.';

  @override
  String get energyRadiant05 => '빛이 가장 밝을 때입니다. 명확한 시야를 바탕으로 다음 계획을 세워보세요.';

  @override
  String get energyRadiant06 => '마음속 열정이 따뜻하게 타오릅니다. 당신이 가진 긍정의 힘을 믿으세요.';

  @override
  String get energyRadiant07 => '환한 에너지 속에서 자연스러운 통찰이 피어납니다. 영감을 놓치지 마세요.';

  @override
  String get energyFocused00 => '에너지가 한 점으로 뚜렷이 모이며, 깊은 몰입과 명료한 주의 집중을 이끕니다.';

  @override
  String get energyFocused01 => '불필요한 잔가지가 쳐지고 본질이 선명해지는 날입니다. 핵심에 집중하세요.';

  @override
  String get energyFocused02 => '산만함이 줄어들고 마음의 과녁이 뚜렷해집니다. 우선순위를 먼저 매듭지으세요.';

  @override
  String get energyFocused03 => '깊이 파고들기에 최적의 기운입니다. 차분히 한 가지 일에 마음을 쏟아보세요.';

  @override
  String get energyFocused04 => '명확한 통찰이 찾아옵니다. 흐릿했던 문제의 본질을 꿰뚫어 볼 수 있습니다.';

  @override
  String get energyFocused05 => '집중력이 돋보이는 시간입니다. 중요한 과제를 해결하기에 좋은 흐름입니다.';

  @override
  String get energyFocused06 => '주의가 흩어지지 않도록 환경을 정돈하세요. 몰입의 결실이 큽니다.';

  @override
  String get energyFocused07 => '군더더기를 덜어내고 정말 중요한 목표 하나를 향해 나아가세요.';

  @override
  String get energyFlowing00 => '에너지가 막힘없이 유려하게 흐르며, 유연한 적응과 자연스러운 전환을 돕습니다.';

  @override
  String get energyFlowing01 => '강물이 바다로 흐르듯 자연스러운 전개가 이어집니다. 흐름에 몸을 맡기세요.';

  @override
  String get energyFlowing02 => '변화에 저항하기보다 유연하게 맞춰갈 때 가장 좋은 길이 열립니다.';

  @override
  String get energyFlowing03 => '막혔던 생각의 물꼬가 트이는 날입니다. 자유롭게 생각을 확장해 보세요.';

  @override
  String get energyFlowing04 => '순조로운 리듬이 유지됩니다. 억지로 힘을 주지 않아도 일이 자연스레 풀려갑니다.';

  @override
  String get energyFlowing05 => '유연한 태도가 뜻밖의 해결책을 가져다줍니다. 열린 마음을 가져보세요.';

  @override
  String get energyFlowing06 => '경직된 틀을 벗어나 가볍게 흘러가 보세요. 새로움이 당신을 반깁니다.';

  @override
  String get energyFlowing07 => '흐름을 타는 지혜가 빛을 발합니다. 순리를 믿고 유연하게 움직이세요.';

  @override
  String get defaultUserName => '여행자';

  @override
  String get searchCountries => '국가 검색';

  @override
  String get greetingMorning => '좋은 아침입니다,';

  @override
  String get greetingAfternoon => '좋은 오후입니다,';

  @override
  String get greetingEvening => '편안한 저녁입니다,';

  @override
  String get colorRoleLead => '주요 색상';

  @override
  String get colorRoleSupporting => '보조 색상';

  @override
  String colorRoleSemantics(String role, String name) {
    return '$role 색상, $name';
  }

  @override
  String colorRoleUnavailableSemantics(String role) {
    return '$role 색상을 아직 확인할 수 없습니다';
  }

  @override
  String readingAreaSemantics(String category) {
    return '점술 영역: $category';
  }

  @override
  String get energyInsightNewTooltip => '오늘의 새로운 에너지 통찰';

  @override
  String get energyInsightReadTooltip => '오늘의 에너지 통찰 읽기';

  @override
  String get energyInsightHideTooltip => '오늘의 에너지 의미 숨기기';

  @override
  String get energyInsightCoachMark => '매일 이곳에서 새로운 에너지 통찰을 만나보세요.';

  @override
  String get ritualLocked => '선택의 순간이 정해졌습니다.';

  @override
  String get periodPassedShort => '지남';

  @override
  String get errorNetworkHeadline => '연결 상태가 원활하지 않습니다.';

  @override
  String get errorNetworkDetail => '네트워크 연결을 확인한 후 다시 시도해 주세요.';

  @override
  String get errorServerHeadline => '지금은 점술을 완료할 수 없습니다.';

  @override
  String get errorServerDetail => '일시적인 서비스 지연입니다. 잠시 후 다시 시도해 주세요.';

  @override
  String get errorRejectedHeadline => '프로필 정보를 다시 확인해 주세요.';

  @override
  String get errorRejectedDetail => '출생 정보를 검토한 후 새로운 점술을 시작해 주세요.';

  @override
  String get errorInvalidHeadline => '결과를 불러올 수 없습니다.';

  @override
  String get errorInvalidDetail => '앱을 최신 버전으로 업데이트하면 정상 이용하실 수 있습니다.';

  @override
  String get errorConfigurationHeadline => '점술 서비스가 설정되지 않았습니다.';

  @override
  String get errorConfigurationDetail => '앱 빌드 설정을 확인해 주세요.';

  @override
  String get errorNothingRecorded => '기록된 점술이 없습니다.';

  @override
  String get insufficientHeading => '신호가 미약합니다';

  @override
  String get insufficientBody => '명확한 흐름을 읽어내기에 정보가 부족합니다. 조금 뒤에 다시 시도해 보세요.';

  @override
  String get periodElapsedHeading => '시간대가 지났습니다';

  @override
  String get periodElapsedBody =>
      '선택하신 시간대의 기운이 이미 흘러갔습니다. 현재 혹은 다가오는 시간대를 선택해 주세요.';

  @override
  String colorsToKeepNear(String first, String second) {
    return '가까이 두면 좋은 색상: $first, $second';
  }

  @override
  String colorToKeepNear(String name) {
    return '가까이 두면 좋은 색상: $name';
  }

  @override
  String get shareTooltip => '결과 공유';

  @override
  String get shareUnavailable => '공유 기능을 사용할 수 없습니다';

  @override
  String get shareDisclaimer => 'AstraCue 상징적 나침반 결과';

  @override
  String get backToHistory => '기록 목록으로 돌아가기';

  @override
  String get saveFailedRetry => '저장에 실패했습니다. 다시 시도해 주세요.';

  @override
  String get savingToHistory => '기록에 저장하는 중...';

  @override
  String get responsibleUseLink => '안전한 이용 안내 자세히 보기';

  @override
  String get historyToday => '오늘';

  @override
  String get historyCouldNotOpen => '기록을 열 수 없습니다';

  @override
  String get historyNotEnoughData => '데이터가 부족하여 열 수 없습니다';

  @override
  String get historyPeriodPassed => '이 시간대는 이미 지났습니다';

  @override
  String get zodiacAries => '양자리';

  @override
  String get zodiacTaurus => '황소자리';

  @override
  String get zodiacGemini => '쌍둥이자리';

  @override
  String get zodiacCancer => '게자리';

  @override
  String get zodiacLeo => '사자자리';

  @override
  String get zodiacVirgo => '처녀자리';

  @override
  String get zodiacLibra => '천칭자리';

  @override
  String get zodiacScorpio => '전갈자리';

  @override
  String get zodiacSagittarius => '사수자리';

  @override
  String get zodiacCapricorn => '염소자리';

  @override
  String get zodiacAquarius => '물병자리';

  @override
  String get zodiacPisces => '물고기자리';

  @override
  String zodiacAvatarSemantics(String sign) {
    return '$sign 별자리 아바타';
  }

  @override
  String get profileTitle => '프로필';

  @override
  String get openProfile => '프로필 열기';

  @override
  String get saveAction => '저장';

  @override
  String get cancelAction => '취소';

  @override
  String get profileSaved => '프로필이 저장되었습니다.';

  @override
  String profileBirthTimeLocked(String wait) {
    return '$wait 후에 출생 시간을 다시 변경할 수 있습니다.';
  }

  @override
  String profileBirthCountryLocked(String wait) {
    return '$wait 후에 출생 국가를 다시 변경할 수 있습니다.';
  }

  @override
  String profileWaitHoursMinutes(String hours, String minutes) {
    return '$hours시간 $minutes분';
  }

  @override
  String profileWaitMinutes(String minutes) {
    return '$minutes분';
  }

  @override
  String get profileConfirmTitle => '프로필 변경 확인';

  @override
  String get profileConfirmBirthTime => '변경 후 2시간 동안 출생 시간이 고정됩니다.';

  @override
  String get profileConfirmBirthCountry => '변경 후 1시간 동안 출생 국가가 고정됩니다.';

  @override
  String get profileBirthTimeUnknownValue => '모름';

  @override
  String get profileReadingsUnchanged => '기존에 저장된 점술 기록은 그대로 유지됩니다.';

  @override
  String profileBirthDateLocked(String wait) {
    return '$wait 후에 생년월일을 다시 변경할 수 있습니다.';
  }

  @override
  String get profileConfirmBirthDate => '변경 후 4시간 동안 생년월일이 고정됩니다.';

  @override
  String energyCooldownTitle(String countdown) {
    return '에너지 충전 중 ($countdown)';
  }

  @override
  String get dailyQuotaExhaustedTitle => '오늘 무료 점술 3회를 모두 사용했습니다';

  @override
  String get energyAccumulating => '우주의 에너지가 채워지고 있습니다';

  @override
  String get quotaExhaustedNotice => '오늘의 무료 점술 횟수를 모두 소진했습니다';

  @override
  String get watchAdPrompt => '동영상 광고를 시청하여 계속 진행할 수 있습니다';

  @override
  String get watchAdButton => '광고 시청';

  @override
  String get adUnlockedReward => '광고 시청 완료! 즉시 점술 1회 이용이 잠금 해제되었습니다';
}
