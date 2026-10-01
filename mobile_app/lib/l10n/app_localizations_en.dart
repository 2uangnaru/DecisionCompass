// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'AstraCue';

  @override
  String get continueAction => 'Continue';

  @override
  String get backAction => 'Back';

  @override
  String get closeAction => 'Close';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get responsibleUse => 'Responsible Use';

  @override
  String get history => 'History';

  @override
  String get onboardingTitle =>
      'Listen to the signals of the universe and your intuition.';

  @override
  String get onboardingLanguageHint =>
      'Tap the globe icon above to change language.';

  @override
  String get yourProfile => 'YOUR PROFILE';

  @override
  String get signAfterBirthDate => 'YOUR SIGN APPEARS AFTER YOUR BIRTH DATE';

  @override
  String get buildPattern => 'Discover your unique energy.';

  @override
  String get profileExplainer => 'Shapes the cycles used during analysis.';

  @override
  String get nameField => 'Name';

  @override
  String get dateOfBirth => 'Date of birth';

  @override
  String get selectBirthDate => 'Select your date of birth';

  @override
  String get birthDateRequired => 'Select your birth date to continue.';

  @override
  String get birthDay => 'Day';

  @override
  String get birthMonth => 'Month';

  @override
  String get birthYear => 'Year';

  @override
  String get birthDateInvalid => 'Enter a valid date from 1900 to today.';

  @override
  String get birthTimeUnknown => 'Birth time unknown';

  @override
  String get birthTimeUnknownDetail =>
      'If you don\'t know your birth time, the algorithm will use the time window closest to your personality.';

  @override
  String get timeOfBirth => 'Time of birth';

  @override
  String get countryOfBirth => 'Country of birth';

  @override
  String get selectBirthCountry => 'Search and select a country';

  @override
  String get birthCountryRequired =>
      'Select your country of birth to continue.';

  @override
  String get createCompass => 'Create My Compass';

  @override
  String get birthPrivacyPrototype =>
      'Your birth details remain private in this prototype.';

  @override
  String get homeEyebrow => 'A COMPASS TO GUIDE YOUR PATH';

  @override
  String get homeTitle => 'Caught between choices?';

  @override
  String get areaQuestion => 'What area is this about?';

  @override
  String get findDirection => 'Find Your Path';

  @override
  String get todaySignals => 'TODAY’S SIGNALS';

  @override
  String get dailyEnergy => 'Daily energy';

  @override
  String get yourColorsToday => 'Your colors today:';

  @override
  String get luckyNumberToday => 'Lucky number today:';

  @override
  String get categoryOverall => 'Overall';

  @override
  String get categoryLove => 'Love & Relationships';

  @override
  String get categoryCareer => 'Career';

  @override
  String get categoryMoney => 'Finances';

  @override
  String get categoryStudy => 'Study & Growth';

  @override
  String get categoryFriends => 'Friends';

  @override
  String get categoryOther => 'Something Else';

  @override
  String get periodQuestion => 'When are you considering it?';

  @override
  String get periodNow => 'NOW';

  @override
  String get periodMorning => 'Morning';

  @override
  String get periodMidday => 'Midday';

  @override
  String get periodAfternoon => 'Afternoon';

  @override
  String get periodEvening => 'Evening';

  @override
  String get periodPassed => 'Passed';

  @override
  String get periodTooLittleTime => 'Too little time';

  @override
  String get periodCheckingTimezone => 'Checking time zone';

  @override
  String get periodTimezoneUnknown => 'Time zone unknown';

  @override
  String get timezoneUnavailableNotice =>
      'Your time zone could not be read, so only NOW is available. Try again to choose a period.';

  @override
  String periodHasPassed(String period) {
    return '$period has passed. Choose another time.';
  }

  @override
  String periodNotEnoughTimeLeft(String period) {
    return 'There is not enough time left in $period today. Choose another time.';
  }

  @override
  String get reveal => 'ANALYZE';

  @override
  String get aligning => 'ALIGNING';

  @override
  String get tapWhenReady => 'Tap when you’re ready';

  @override
  String get keepChoiceInMind => 'Keep the choice clearly in your mind.';

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
    return 'Reading for $category';
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
  String get orbitAlmanac => 'ALMANAC';

  @override
  String get orbitBaZi => 'BAZI';

  @override
  String get orbitZiWei => 'ZI WEI';

  @override
  String get orbitVedic => 'VEDIC JYOTISH';

  @override
  String get orbitNumerology => 'NUMEROLOGY';

  @override
  String get orbitLunarPhase => 'LUNAR PHASE';

  @override
  String get orbitPlanetary => 'PLANETARY';

  @override
  String get orbitYinYang => 'YIN / YANG';

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
  String get choiceYes => 'YES';

  @override
  String get choiceNo => 'NO';

  @override
  String get choiceAct => 'ACT';

  @override
  String get choiceWait => 'WAIT';

  @override
  String get choiceAdvance => 'ADVANCE';

  @override
  String get choiceRetreat => 'RETREAT';

  @override
  String get choiceStay => 'STAY';

  @override
  String get choiceGo => 'GO';

  @override
  String get choiceKeep => 'KEEP';

  @override
  String get choiceLetGo => 'LET GO';

  @override
  String get choiceForward => 'FORWARD';

  @override
  String get choiceBackward => 'BACKWARD';

  @override
  String get choiceCommit => 'COMMIT';

  @override
  String get choiceWithdraw => 'WITHDRAW';

  @override
  String get choiceLeft => 'LEFT';

  @override
  String get choiceRight => 'RIGHT';

  @override
  String get energyLevelQuiet => 'QUIET';

  @override
  String get energyLevelSoft => 'SOFT';

  @override
  String get energyLevelSteady => 'STEADY';

  @override
  String get energyLevelLively => 'LIVELY';

  @override
  String get energyLevelBright => 'BRIGHT';

  @override
  String get energyLevelRadiant => 'RADIANT';

  @override
  String get energyLevelFocused => 'FOCUSED';

  @override
  String get energyLevelFlowing => 'FLOWING';

  @override
  String get colorCedar => 'Cedar';

  @override
  String get colorJade => 'Jade';

  @override
  String get colorSage => 'Sage';

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
  String get colorSand => 'Sand';

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
  String get colorIndigo => 'Indigo';

  @override
  String get colorMistBlue => 'Mist Blue';

  @override
  String get homeDescription00 =>
      'What might the universe be telling you today? Choose what’s on your mind and explore the signs around this moment.';

  @override
  String get homeDescription01 =>
      'Feeling pulled in two directions? Let today’s cosmic signals offer a new way to see your choice.';

  @override
  String get homeDescription02 =>
      'The stars may not decide for you—but their patterns might help you see your next step differently.';

  @override
  String get homeDescription03 =>
      'When your path feels unclear, pause and look closer. What do today’s signs suggest?';

  @override
  String get homeDescription04 =>
      'Every moment has its own energy. Choose what’s on your mind and discover the direction it may be pointing toward.';

  @override
  String get homeDescription05 =>
      'Perhaps the universe is asking you to slow down. Explore today’s signals before choosing your way.';

  @override
  String get homeDescription06 =>
      'At a crossroads? See how today’s celestial patterns align with the question on your mind.';

  @override
  String get homeDescription07 =>
      'Listen to the rhythm of this moment. Today’s symbols may reveal a direction worth considering.';

  @override
  String get homeDescription08 =>
      'What is this moment trying to show you? Explore the signs, then trust yourself to make the choice.';

  @override
  String get homeDescription09 =>
      'A little cosmic perspective can bring clarity. Choose what matters today and see where the signs point.';

  @override
  String get homeDescription10 =>
      'Still turning the same choice over in your mind? See what today’s cosmic energy brings into focus.';

  @override
  String get homeDescription11 =>
      'When your thoughts pull one way and your intuition another, explore the signals surrounding today.';

  @override
  String get homeDescription12 =>
      'Unsure whether to move or pause? Let the rhythm of this day offer a calmer starting point.';

  @override
  String get homeDescription13 =>
      'What if clarity begins with a different perspective? Look to today’s celestial patterns.';

  @override
  String get homeDescription14 =>
      'A question keeps returning to you. Discover what today’s symbols invite you to notice.';

  @override
  String get homeDescription15 =>
      'Some choices feel heavier at certain moments. Explore the energy of this one before you decide.';

  @override
  String get homeDescription16 =>
      'Your path may feel unclear right now. What might the stars illuminate beneath that doubt?';

  @override
  String get homeDescription17 =>
      'Before following a sudden impulse, take a breath and see what today’s cosmic signs suggest.';

  @override
  String get homeDescription18 =>
      'Not every crossroads needs an instant answer. Let today’s reading give you space to reflect.';

  @override
  String get homeDescription19 =>
      'Wondering whether the timing is right? Explore today’s patterns and find a steadier point of view.';

  @override
  String get homeDescription20 =>
      'When everything feels possible and nothing feels certain, let the sky’s patterns spark a fresh perspective.';

  @override
  String get homeDescription21 =>
      'The choice belongs to you. The signs of this day may help you understand what matters most.';

  @override
  String get homeDescription22 =>
      'When doubt clouds your next step, explore what your zodiac and today’s energy bring to light.';

  @override
  String get homeDescription23 =>
      'Maybe you don’t need a louder answer—just a quieter moment with today’s symbols.';

  @override
  String get homeDescription24 =>
      'Is your instinct asking you to act or wait? See what today’s cosmic rhythm might reflect.';

  @override
  String get homeDescription25 =>
      'Between what you want and what you fear, there’s room to pause. Let today’s signs help you look again.';

  @override
  String get homeDescription26 =>
      'You’ve noticed the question. Now notice the moment. What do today’s celestial signals suggest?';

  @override
  String get homeDescription27 =>
      'When a decision feels tangled, let ancient symbols and the timing of today reveal another angle.';

  @override
  String get homeDescription28 =>
      'Perhaps this is a moment to lean in—or give things space. Explore the energy around your choice.';

  @override
  String get homeDescription29 =>
      'You don’t have to find certainty here. Find a moment of calm, a cosmic cue, and a direction to consider.';

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
  String get energySteady00 =>
      'Today’s symbolic energy keeps an even, grounded rhythm.';

  @override
  String get energySteady01 =>
      'Today’s symbolic energy holds an even rhythm; trust the pace you can sustain.';

  @override
  String get energySteady02 =>
      'The cosmic pattern feels grounded, offering room to think and move deliberately.';

  @override
  String get energySteady03 =>
      'A steady current runs beneath this day; attention may serve you better than urgency.';

  @override
  String get energySteady04 =>
      'Today’s signs point toward balance, without asking you to stand still.';

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
  String get energyRadiant00 =>
      'Today’s symbolic energy reaches its fullest glow: open and expansive.';

  @override
  String get energyRadiant01 =>
      'Today’s symbolic energy opens wide, inviting you to see more than one possible path.';

  @override
  String get energyRadiant02 =>
      'A radiant current runs through this day; let possibility expand without losing your center.';

  @override
  String get energyRadiant03 =>
      'The cosmic pattern feels especially open; make room for what inspires you.';

  @override
  String get energyRadiant04 =>
      'A fuller glow colors today’s energy, bringing your possibilities into a wider view.';

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
  String get defaultUserName => 'Explorer';

  @override
  String get searchCountries => 'Search countries';

  @override
  String get greetingMorning => 'Good morning,';

  @override
  String get greetingAfternoon => 'Good afternoon,';

  @override
  String get greetingEvening => 'Good evening,';

  @override
  String get colorRoleLead => 'Lead';

  @override
  String get colorRoleSupporting => 'Supporting';

  @override
  String colorRoleSemantics(String role, String name) {
    return '$role colour, $name';
  }

  @override
  String colorRoleUnavailableSemantics(String role) {
    return '$role colour not available yet';
  }

  @override
  String readingAreaSemantics(String category) {
    return 'Reading area: $category';
  }

  @override
  String get energyInsightNewTooltip => 'New energy insight today';

  @override
  String get energyInsightReadTooltip => 'Read today’s energy insight';

  @override
  String get energyInsightHideTooltip => 'Hide what today’s energy means';

  @override
  String get energyInsightCoachMark =>
      'A new energy insight awaits here each day.';

  @override
  String get ritualLocked => 'Your moment is locked.';

  @override
  String get periodPassedShort => 'PASSED';

  @override
  String get errorNetworkHeadline => 'The connection slipped out of alignment.';

  @override
  String get errorNetworkDetail =>
      'Check your connection, then try the reading again.';

  @override
  String get errorServerHeadline =>
      'The reading could not be completed right now.';

  @override
  String get errorServerDetail =>
      'The service is there but could not finish. Try again in a moment.';

  @override
  String get errorRejectedHeadline => 'Some profile details need attention.';

  @override
  String get errorRejectedDetail =>
      'Revisit your birth details, then start a new reading.';

  @override
  String get errorInvalidHeadline =>
      'This app version could not read the result.';

  @override
  String get errorInvalidDetail => 'Updating the app should restore readings.';

  @override
  String get errorConfigurationHeadline =>
      'This build has no reading service configured.';

  @override
  String get errorConfigurationDetail =>
      'Developer build: no calculation service is configured.';

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
    return 'Colours to keep near you: $first and $second';
  }

  @override
  String colorToKeepNear(String name) {
    return 'Colour to keep near you: $name';
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
  String get zodiacAries => 'Aries';

  @override
  String get zodiacTaurus => 'Taurus';

  @override
  String get zodiacGemini => 'Gemini';

  @override
  String get zodiacCancer => 'Cancer';

  @override
  String get zodiacLeo => 'Leo';

  @override
  String get zodiacVirgo => 'Virgo';

  @override
  String get zodiacLibra => 'Libra';

  @override
  String get zodiacScorpio => 'Scorpio';

  @override
  String get zodiacSagittarius => 'Sagittarius';

  @override
  String get zodiacCapricorn => 'Capricorn';

  @override
  String get zodiacAquarius => 'Aquarius';

  @override
  String get zodiacPisces => 'Pisces';

  @override
  String zodiacAvatarSemantics(String sign) {
    return '$sign zodiac avatar';
  }
}
