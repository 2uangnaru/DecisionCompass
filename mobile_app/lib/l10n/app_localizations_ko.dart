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
  String get periodTimezoneUnknown => 'Time zone unknown';

  @override
  String get timezoneUnavailableNotice =>
      'Your time zone could not be read, so only NOW is available. Try again to choose a period.';

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
  String get ritualSafety =>
      'For everyday reflection only • Never for medical, investing, borrowing, political, or harmful choices.';

  @override
  String get loadingLocalMoment => 'READING YOUR LOCAL MOMENT';

  @override
  String get loadingReassurance =>
      'Please wait a moment — cosmic signals are coming into focus.';

  @override
  String readingForCategory(String category) {
    return '$category 점술';
  }

  @override
  String get yourDirection => 'YOUR DIRECTION';

  @override
  String get resultBasis =>
      'Based on the cosmic energy and signals aligned with you at this moment.';

  @override
  String get percentageCaveat =>
      'Percentages show symbolic alignment, not a real-world probability.';

  @override
  String get balancedHeading => 'EVENLY BALANCED';

  @override
  String get balancedResult => 'BALANCED';

  @override
  String get balancedExplanation =>
      'Neither side leads right now. This is a reading of balance, not a hidden answer.';

  @override
  String get currentMoment => 'This reading reflects your current moment.';

  @override
  String get luckyTimesCaveat =>
      'Each percentage is a symbolic timing alignment score, not a probability or chance of success. The windows are scored independently, so they do not add up to 100%.';

  @override
  String get tryAnotherDirection => 'Try Another Direction';

  @override
  String get viewHistory => 'View in History';

  @override
  String get yourReadings => 'Your readings';

  @override
  String get noReadings =>
      'No readings yet. Reveal your first direction to start your history.';

  @override
  String get historySnapshot =>
      'Results are saved as snapshots and never rerolled.';

  @override
  String get everydayReflection =>
      'For everyday reflection only. Important decisions need real information and qualified help.';

  @override
  String get luckyTimesMorning => 'Your luckiest times this morning';

  @override
  String get luckyTimesMidday => 'Your luckiest times around midday';

  @override
  String get luckyTimesAfternoon => 'Your luckiest times this afternoon';

  @override
  String get luckyTimesEvening => 'Your luckiest times this evening';

  @override
  String get loadingLocalTime => 'Synchronizing with your local time and hour';

  @override
  String get loadingBaZi => 'Reading your BaZi elemental balance';

  @override
  String get loadingZiWei => 'Mapping Zi Wei cycles around this moment';

  @override
  String get loadingVedic => 'Aligning Vedic Nakshatras and lunar mansions';

  @override
  String get loadingNumerology =>
      'Tracing numerology, lunar and planetary rhythms';

  @override
  String get loadingYinYang =>
      'Balancing Yin and Yang signals into one direction';

  @override
  String get loadingModeYesNo => 'Testing openness against resistance';

  @override
  String get loadingModeActWait => 'Balancing momentum against patience';

  @override
  String get loadingModeAdvanceRetreat =>
      'Measuring today\'s push against the last few days';

  @override
  String get loadingModeStayGo => 'Comparing roots with movement';

  @override
  String get loadingModeKeepLetGo => 'Weighing continuity against release';

  @override
  String get loadingModeForwardBackward =>
      'Tracing forward motion against returning energy';

  @override
  String get loadingModeCommitWithdraw =>
      'Balancing commitment against withdrawal';

  @override
  String get loadingModeLeftRight =>
      'Balancing receptive and expressive polarity';

  @override
  String get orbitMoment => 'MOMENT';

  @override
  String get orbitRhythm => 'RHYTHM';

  @override
  String get orbitBalance => 'BALANCE';

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
  String get safetyHeading => 'BOUNDARIES & RESPONSIBLE USE';

  @override
  String get safetyTitle => 'A Mirror for Everyday Moments';

  @override
  String get safetyIntro =>
      'AstraCue offers symbolic perspectives drawn from astronomical rhythms and personal cycles. It is for everyday reflection and entertainment, not a command, prediction, or factual certainty.';

  @override
  String get prohibitedUses => 'PROHIBITED USES';

  @override
  String get harmTitle => 'Harm & Self-Violence';

  @override
  String get harmDetail =>
      'Never use for self-harm, suicide, physical violence, or endangering yourself or anyone else.';

  @override
  String get navigationTitle => 'Driving & Physical Navigation';

  @override
  String get navigationDetail =>
      'LEFT / RIGHT and ADVANCE / RETREAT are symbolic choices only. Never use them for traffic, driving, route-finding, or physical safety.';

  @override
  String get politicsTitle => 'Politics & Social Conflicts';

  @override
  String get politicsDetail =>
      'Never use for political campaigning, electoral decisions, civil unrest, or extremist activities.';

  @override
  String get medicalTitle => 'Health, Medical & Emergencies';

  @override
  String get medicalDetail =>
      'Not a substitute for licensed medical care, mental health treatment, medication, or emergency response.';

  @override
  String get legalTitle => 'Legal, Criminal & High-Stakes Contracts';

  @override
  String get legalDetail =>
      'Never use for criminal conduct, court proceedings, testimony, or binding high-stakes legal contracts.';

  @override
  String get financeTitle => 'Financial Investments & Gambling';

  @override
  String get financeDetail =>
      'Finances is for reflecting on small, routine purchases only. Never use a reading for investing, borrowing, crypto bets, gambling, or major financial decisions.';

  @override
  String get consentTitle => 'Consent, Minors & Relationships';

  @override
  String get consentDetail =>
      'Never use to override another person\'s consent or autonomy, or for child custody and guardianship decisions.';

  @override
  String get importantLimitsHeading => 'IMPORTANT LIMITS';

  @override
  String get importantLimitsBody =>
      'AstraCue is not designed for children. It does not provide medical, legal, or financial advice. For important decisions, use reliable information and appropriate professional help. You remain in control of your choices.';

  @override
  String get crisisSupport =>
      'If you or someone else is in immediate danger or emotional crisis, contact local emergency services or a trusted local crisis helpline now.';

  @override
  String get acknowledge => 'I Understand & Agree';

  @override
  String get acknowledgementOnce =>
      'This acknowledgement appears once before your first reading.';

  @override
  String get safetyScrollToContinue =>
      'Scroll to the end and read everything to continue.';

  @override
  String get knowBirthTime => 'I know my birth time';

  @override
  String get knowBirthTimeDetail =>
      'An exact time sharpens the hour-based cycles.';

  @override
  String get selectBirthTime => 'Select your time of birth';

  @override
  String get birthTimeRequired =>
      'Select your time of birth to continue, or turn this off if you do not know it.';

  @override
  String get languageSetting => 'Language';

  @override
  String get chooseLanguage => 'Choose your language';

  @override
  String get changeLanguage => 'Change language';

  @override
  String get languageNotSaved =>
      'Your language preference could not be saved, so it may not be remembered next time.';

  @override
  String get profileNotSaved =>
      'Your profile could not be saved. Please try again.';

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
  String get choiceForward => 'FORWARD';

  @override
  String get choiceBackward => 'BACKWARD';

  @override
  String get choiceCommit => '전념';

  @override
  String get choiceWithdraw => '물러남';

  @override
  String get choiceLeft => '왼쪽';

  @override
  String get choiceRight => '오른쪽';

  @override
  String get energyLevelQuiet => 'QUIET';

  @override
  String get energyLevelSoft => 'SOFT';

  @override
  String get energyLevelSteady => '안정';

  @override
  String get energyLevelLively => 'LIVELY';

  @override
  String get energyLevelBright => 'BRIGHT';

  @override
  String get energyLevelRadiant => '찬란함';

  @override
  String get energyLevelFocused => 'FOCUSED';

  @override
  String get energyLevelFlowing => 'FLOWING';

  @override
  String get colorCedar => 'Cedar';

  @override
  String get colorJade => '옥색';

  @override
  String get colorSage => '세이지 그린';

  @override
  String get colorMint => 'Mint';

  @override
  String get colorEmber => 'Ember';

  @override
  String get colorSolarCoral => 'Solar Coral';

  @override
  String get colorRose => 'Rose';

  @override
  String get colorBlossom => 'Blossom';

  @override
  String get colorOchre => 'Ochre';

  @override
  String get colorAmber => 'Amber';

  @override
  String get colorSand => '모래빛';

  @override
  String get colorClay => 'Clay';

  @override
  String get colorSilver => 'Silver';

  @override
  String get colorSteel => 'Steel';

  @override
  String get colorPearl => 'Pearl';

  @override
  String get colorChampagne => 'Champagne';

  @override
  String get colorOceanBlue => 'Ocean Blue';

  @override
  String get colorAzure => 'Azure';

  @override
  String get colorIndigo => '인디고';

  @override
  String get colorMistBlue => 'Mist Blue';

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
  String get energyQuiet00 =>
      'Today’s symbolic energy turns inward, making space for quiet reflection.';

  @override
  String get energyQuiet01 =>
      'Today’s cosmic rhythm turns inward; stillness may reveal what noise has been hiding.';

  @override
  String get energyQuiet02 =>
      'The sky’s symbolic tone is hushed today; give your thoughts room to settle.';

  @override
  String get energyQuiet03 =>
      'A quieter current runs through this day, inviting you to notice rather than rush.';

  @override
  String get energyQuiet04 =>
      'Today’s signs suggest reflection; a pause can still be part of moving forward.';

  @override
  String get energyQuiet05 =>
      'When the day feels subdued, your inner compass may speak more clearly.';

  @override
  String get energyQuiet06 =>
      'The energy of this day leaves space to listen before naming an answer.';

  @override
  String get energyQuiet07 =>
      'Not every signal arrives loudly; today’s may be easier to notice when you slow down.';

  @override
  String get energySoft00 =>
      'Today’s symbolic energy moves gently, with room for care and small steps.';

  @override
  String get energySoft01 =>
      'A gentle cosmic current moves through today; small steps may feel more natural than big leaps.';

  @override
  String get energySoft02 =>
      'Today’s energy leaves room for care; approach your choice without pressing for certainty.';

  @override
  String get energySoft03 =>
      'The day’s softer rhythm may help you begin with what feels manageable.';

  @override
  String get energySoft04 =>
      'A gentler approach can still be strong today; notice where you need ease, not pressure.';

  @override
  String get energySoft05 =>
      'Today’s signs suggest a light touch: enough movement to begin, without forcing the pace.';

  @override
  String get energySoft06 =>
      'The current is subtle today; simple, thoughtful actions may carry more meaning.';

  @override
  String get energySoft07 =>
      'Even a small opening can matter; today’s gentle pattern leaves space to explore it.';

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
  String get energySteady05 =>
      'There is strength in consistency; notice which next step still makes sense after a pause.';

  @override
  String get energySteady06 =>
      'The day carries a measured energy, giving your choice room to take shape.';

  @override
  String get energySteady07 =>
      'A calm rhythm can be its own guide; progress need not be dramatic today.';

  @override
  String get energyLively00 =>
      'A playful spark stirs today’s symbolic energy, bringing curiosity and motion.';

  @override
  String get energyLively01 =>
      'A curious spark stirs today’s symbolic energy; a fresh angle may be worth exploring.';

  @override
  String get energyLively02 =>
      'The day feels more animated; notice what catches your attention without rushing toward it.';

  @override
  String get energyLively03 =>
      'Today’s cosmic rhythm invites discovery, with space to stay discerning.';

  @override
  String get energyLively04 =>
      'A playful current moves through this day; possibilities may appear in unexpected places.';

  @override
  String get energyLively05 =>
      'Curiosity may be a useful signal today; notice where it points before you commit.';

  @override
  String get energyLively06 =>
      'There is motion in today’s signs; you can explore without committing too quickly.';

  @override
  String get energyLively07 =>
      'The energy feels lively; let it widen your options before narrowing them.';

  @override
  String get energyBright00 =>
      'Today’s symbolic energy shines with momentum and room for expression.';

  @override
  String get energyBright01 =>
      'Today’s symbolic energy brings more light to what you want to express.';

  @override
  String get energyBright02 =>
      'A brighter cosmic current may help you see which possibility deserves attention.';

  @override
  String get energyBright03 =>
      'The signs of this day feel open; your next step may become easier to name.';

  @override
  String get energyBright04 =>
      'Today carries momentum for expression; share what matters when the moment feels right.';

  @override
  String get energyBright05 =>
      'An opening in today’s rhythm may encourage clarity without demanding haste.';

  @override
  String get energyBright06 =>
      'The day’s energy feels outward-facing; notice what you’re ready to bring forward.';

  @override
  String get energyBright07 =>
      'A touch of brightness can shift perspective; today’s patterns invite you to look ahead.';

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
  String get energyRadiant05 =>
      'Today’s signs carry an expansive tone; it may be easier to imagine what comes next.';

  @override
  String get energyRadiant06 =>
      'Let the day’s warmth widen your view while keeping the final choice in your hands.';

  @override
  String get energyRadiant07 =>
      'The sky’s symbolic rhythm feels generous; welcome possibilities with grounded judgment.';

  @override
  String get energyFocused00 =>
      'Today’s symbolic energy gathers around a clear direction; the action signal takes the lead.';

  @override
  String get energyFocused01 =>
      'Today’s action signal comes into focus; notice the one step that feels intentional.';

  @override
  String get energyFocused02 =>
      'The symbolic current leans toward doing, but you can choose the pace.';

  @override
  String get energyFocused03 =>
      'A sense of direction runs through today; attend to what you can actually influence.';

  @override
  String get energyFocused04 =>
      'When options compete, today’s signs invite you to center on one practical move.';

  @override
  String get energyFocused05 =>
      'Today’s signs gather around one intention; give it your attention without rushing.';

  @override
  String get energyFocused06 =>
      'Action has a stronger symbolic pull today; keep your reasons clear before moving.';

  @override
  String get energyFocused07 =>
      'This is a day for intention, not intensity; let your chosen direction take shape.';

  @override
  String get energyFlowing00 =>
      'Today’s symbolic energy moves with the tide; the change signal takes the lead.';

  @override
  String get energyFlowing01 =>
      'Today’s change signal comes forward; allow your plans a little room to bend.';

  @override
  String get energyFlowing02 =>
      'A shifting cosmic current runs through the day; adaptability may reveal another path.';

  @override
  String get energyFlowing03 =>
      'The energy of change is more noticeable; stay open to what a new angle shows you.';

  @override
  String get energyFlowing04 =>
      'Today’s signs speak of movement between possibilities, not a fixed destination.';

  @override
  String get energyFlowing05 =>
      'When circumstances shift, a flexible response may serve you better than a rigid plan.';

  @override
  String get energyFlowing06 =>
      'A flowing rhythm moves through this day; notice what can evolve without forcing an answer.';

  @override
  String get energyFlowing07 =>
      'The symbolic current leans toward transition; you can move with it at your own pace.';

  @override
  String get defaultUserName => '여행자';

  @override
  String get searchCountries => 'Search countries';

  @override
  String get greetingMorning => 'Good morning,';

  @override
  String get greetingAfternoon => 'Good afternoon,';

  @override
  String get greetingEvening => 'Good evening,';

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
  String get errorNothingRecorded =>
      'No reading was recorded for this attempt.';

  @override
  String get insufficientHeading => 'NOT ENOUGH TO READ';

  @override
  String get insufficientBody =>
      'Your profile does not yet contain enough detail for a direction on this one. Adding your birth time and country of birth gives the cycles more to work with.';

  @override
  String get periodElapsedHeading => 'THAT PERIOD HAS PASSED';

  @override
  String get periodElapsedBody =>
      'That period is already over where you are, so there is no window left to read. Pick a later period, or read your current moment instead — today’s reading is not rolled into tomorrow.';

  @override
  String colorsToKeepNear(String first, String second) {
    return '가까이 두면 좋은 색상: $first, $second';
  }

  @override
  String colorToKeepNear(String name) {
    return '가까이 두면 좋은 색상: $name';
  }

  @override
  String get shareTooltip => 'Share this reading';

  @override
  String get shareUnavailable => 'Sharing is unavailable right now.';

  @override
  String get shareDisclaimer =>
      'A symbolic perspective for everyday reflection, not a prediction or probability.';

  @override
  String get backToHistory => 'Back to History';

  @override
  String get saveFailedRetry => 'Couldn’t save · Retry';

  @override
  String get savingToHistory => 'Saving to History…';

  @override
  String get responsibleUseLink => 'Responsible Use & Safety Policy';

  @override
  String get historyToday => 'TODAY';

  @override
  String get historyCouldNotOpen => 'Your readings could not be opened.';

  @override
  String get historyNotEnoughData => 'NOT ENOUGH DATA';

  @override
  String get historyPeriodPassed => 'PERIOD PASSED';

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
  String get profileTitle => 'Profile';

  @override
  String get openProfile => 'Open your profile';

  @override
  String get saveAction => 'Save';

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
  String get profileConfirmTitle => 'Save these changes?';

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
  String dailyQuotaExhaustedTitle(String countdown) {
    return '오늘 무료 점술 3회를 모두 사용했습니다 ($countdown)';
  }

  @override
  String get energyAccumulating => 'Energy is gathering';

  @override
  String get quotaExhaustedNotice => 'Daily free readings used up';

  @override
  String get watchAdPrompt => 'You can watch a video ad to continue';

  @override
  String get watchAdButton => 'Watch ad';

  @override
  String get adUnlockedReward => '✨ Ad watched! 1 instant reading unlocked';
}
