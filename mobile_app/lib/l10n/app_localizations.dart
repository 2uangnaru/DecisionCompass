import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_th.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('hi'),
    Locale('hi', 'IN'),
    Locale('ja'),
    Locale('th'),
    Locale('vi'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    Locale.fromSubtags(
      languageCode: 'zh',
      countryCode: 'CN',
      scriptCode: 'Hans',
    ),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'AstraCue'**
  String get appName;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @backAction.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backAction;

  /// No description provided for @closeAction.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeAction;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @responsibleUse.
  ///
  /// In en, this message translates to:
  /// **'Responsible Use'**
  String get responsibleUse;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Listen to the signals of the universe and your intuition.'**
  String get onboardingTitle;

  /// No description provided for @onboardingLanguageHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the globe icon above to change language.'**
  String get onboardingLanguageHint;

  /// No description provided for @yourProfile.
  ///
  /// In en, this message translates to:
  /// **'YOUR PROFILE'**
  String get yourProfile;

  /// No description provided for @signAfterBirthDate.
  ///
  /// In en, this message translates to:
  /// **'YOUR SIGN APPEARS AFTER YOUR BIRTH DATE'**
  String get signAfterBirthDate;

  /// No description provided for @buildPattern.
  ///
  /// In en, this message translates to:
  /// **'Discover your unique energy.'**
  String get buildPattern;

  /// No description provided for @profileExplainer.
  ///
  /// In en, this message translates to:
  /// **'Shapes the cycles used during analysis.'**
  String get profileExplainer;

  /// No description provided for @nameField.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameField;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get dateOfBirth;

  /// No description provided for @selectBirthDate.
  ///
  /// In en, this message translates to:
  /// **'Select your date of birth'**
  String get selectBirthDate;

  /// No description provided for @birthDateRequired.
  ///
  /// In en, this message translates to:
  /// **'Select your birth date to continue.'**
  String get birthDateRequired;

  /// No description provided for @birthDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get birthDay;

  /// No description provided for @birthMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get birthMonth;

  /// No description provided for @birthYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get birthYear;

  /// No description provided for @birthDateInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid date from 1900 to today.'**
  String get birthDateInvalid;

  /// No description provided for @birthTimeUnknown.
  ///
  /// In en, this message translates to:
  /// **'Birth time unknown'**
  String get birthTimeUnknown;

  /// No description provided for @birthTimeUnknownDetail.
  ///
  /// In en, this message translates to:
  /// **'If you don\'t know your birth time, the algorithm will use the time window closest to your personality.'**
  String get birthTimeUnknownDetail;

  /// No description provided for @timeOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Time of birth'**
  String get timeOfBirth;

  /// No description provided for @countryOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Country of birth'**
  String get countryOfBirth;

  /// No description provided for @selectBirthCountry.
  ///
  /// In en, this message translates to:
  /// **'Search and select a country'**
  String get selectBirthCountry;

  /// No description provided for @birthCountryRequired.
  ///
  /// In en, this message translates to:
  /// **'Select your country of birth to continue.'**
  String get birthCountryRequired;

  /// No description provided for @createCompass.
  ///
  /// In en, this message translates to:
  /// **'Create My Compass'**
  String get createCompass;

  /// No description provided for @birthPrivacyPrototype.
  ///
  /// In en, this message translates to:
  /// **'Your birth details remain private in this prototype.'**
  String get birthPrivacyPrototype;

  /// No description provided for @homeEyebrow.
  ///
  /// In en, this message translates to:
  /// **'A COMPASS TO GUIDE YOUR PATH'**
  String get homeEyebrow;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Caught between choices?'**
  String get homeTitle;

  /// No description provided for @areaQuestion.
  ///
  /// In en, this message translates to:
  /// **'What area is this about?'**
  String get areaQuestion;

  /// No description provided for @findDirection.
  ///
  /// In en, this message translates to:
  /// **'Find Your Path'**
  String get findDirection;

  /// No description provided for @todaySignals.
  ///
  /// In en, this message translates to:
  /// **'TODAY’S SIGNALS'**
  String get todaySignals;

  /// No description provided for @dailyEnergy.
  ///
  /// In en, this message translates to:
  /// **'Daily energy'**
  String get dailyEnergy;

  /// No description provided for @yourColorsToday.
  ///
  /// In en, this message translates to:
  /// **'Your colors today:'**
  String get yourColorsToday;

  /// No description provided for @luckyNumberToday.
  ///
  /// In en, this message translates to:
  /// **'Lucky number today:'**
  String get luckyNumberToday;

  /// No description provided for @categoryOverall.
  ///
  /// In en, this message translates to:
  /// **'Overall'**
  String get categoryOverall;

  /// No description provided for @categoryLove.
  ///
  /// In en, this message translates to:
  /// **'Love & Relationships'**
  String get categoryLove;

  /// No description provided for @categoryCareer.
  ///
  /// In en, this message translates to:
  /// **'Career'**
  String get categoryCareer;

  /// No description provided for @categoryMoney.
  ///
  /// In en, this message translates to:
  /// **'Finances'**
  String get categoryMoney;

  /// No description provided for @categoryStudy.
  ///
  /// In en, this message translates to:
  /// **'Study & Growth'**
  String get categoryStudy;

  /// No description provided for @categoryFriends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get categoryFriends;

  /// No description provided for @categoryOther.
  ///
  /// In en, this message translates to:
  /// **'Something Else'**
  String get categoryOther;

  /// No description provided for @periodQuestion.
  ///
  /// In en, this message translates to:
  /// **'When are you considering it?'**
  String get periodQuestion;

  /// No description provided for @periodNow.
  ///
  /// In en, this message translates to:
  /// **'NOW'**
  String get periodNow;

  /// No description provided for @periodMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get periodMorning;

  /// No description provided for @periodMidday.
  ///
  /// In en, this message translates to:
  /// **'Midday'**
  String get periodMidday;

  /// No description provided for @periodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get periodAfternoon;

  /// No description provided for @periodEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get periodEvening;

  /// No description provided for @periodPassed.
  ///
  /// In en, this message translates to:
  /// **'Passed'**
  String get periodPassed;

  /// No description provided for @periodTooLittleTime.
  ///
  /// In en, this message translates to:
  /// **'Too little time'**
  String get periodTooLittleTime;

  /// No description provided for @periodHasPassed.
  ///
  /// In en, this message translates to:
  /// **'{period} has passed. Choose another time.'**
  String periodHasPassed(String period);

  /// No description provided for @periodNotEnoughTimeLeft.
  ///
  /// In en, this message translates to:
  /// **'There is not enough time left in {period} today. Choose another time.'**
  String periodNotEnoughTimeLeft(String period);

  /// No description provided for @reveal.
  ///
  /// In en, this message translates to:
  /// **'ANALYZE'**
  String get reveal;

  /// No description provided for @aligning.
  ///
  /// In en, this message translates to:
  /// **'ALIGNING'**
  String get aligning;

  /// No description provided for @tapWhenReady.
  ///
  /// In en, this message translates to:
  /// **'Tap when you’re ready'**
  String get tapWhenReady;

  /// No description provided for @keepChoiceInMind.
  ///
  /// In en, this message translates to:
  /// **'Keep the choice clearly in your mind.'**
  String get keepChoiceInMind;

  /// No description provided for @ritualSafety.
  ///
  /// In en, this message translates to:
  /// **'For everyday reflection only • Never for medical, investing, borrowing, political, or harmful choices.'**
  String get ritualSafety;

  /// No description provided for @loadingLocalMoment.
  ///
  /// In en, this message translates to:
  /// **'READING YOUR LOCAL MOMENT'**
  String get loadingLocalMoment;

  /// No description provided for @loadingReassurance.
  ///
  /// In en, this message translates to:
  /// **'Please wait a moment — cosmic signals are coming into focus.'**
  String get loadingReassurance;

  /// No description provided for @readingForCategory.
  ///
  /// In en, this message translates to:
  /// **'Reading for {category}'**
  String readingForCategory(String category);

  /// No description provided for @yourDirection.
  ///
  /// In en, this message translates to:
  /// **'YOUR DIRECTION'**
  String get yourDirection;

  /// No description provided for @resultBasis.
  ///
  /// In en, this message translates to:
  /// **'Based on the cosmic energy and signals aligned with you at this moment.'**
  String get resultBasis;

  /// No description provided for @percentageCaveat.
  ///
  /// In en, this message translates to:
  /// **'Percentages show symbolic alignment, not a real-world probability.'**
  String get percentageCaveat;

  /// No description provided for @balancedHeading.
  ///
  /// In en, this message translates to:
  /// **'EVENLY BALANCED'**
  String get balancedHeading;

  /// No description provided for @balancedResult.
  ///
  /// In en, this message translates to:
  /// **'BALANCED'**
  String get balancedResult;

  /// No description provided for @balancedExplanation.
  ///
  /// In en, this message translates to:
  /// **'Neither side leads right now. This is a reading of balance, not a hidden answer.'**
  String get balancedExplanation;

  /// No description provided for @currentMoment.
  ///
  /// In en, this message translates to:
  /// **'This reading reflects your current moment.'**
  String get currentMoment;

  /// No description provided for @luckyTimesCaveat.
  ///
  /// In en, this message translates to:
  /// **'Each percentage is a symbolic timing alignment score, not a probability or chance of success. The windows are scored independently, so they do not add up to 100%.'**
  String get luckyTimesCaveat;

  /// No description provided for @tryAnotherDirection.
  ///
  /// In en, this message translates to:
  /// **'Try Another Direction'**
  String get tryAnotherDirection;

  /// No description provided for @viewHistory.
  ///
  /// In en, this message translates to:
  /// **'View in History'**
  String get viewHistory;

  /// No description provided for @yourReadings.
  ///
  /// In en, this message translates to:
  /// **'Your readings'**
  String get yourReadings;

  /// No description provided for @noReadings.
  ///
  /// In en, this message translates to:
  /// **'No readings yet. Reveal your first direction to start your history.'**
  String get noReadings;

  /// No description provided for @historySnapshot.
  ///
  /// In en, this message translates to:
  /// **'Results are saved as snapshots and never rerolled.'**
  String get historySnapshot;

  /// No description provided for @everydayReflection.
  ///
  /// In en, this message translates to:
  /// **'For everyday reflection only. Important decisions need real information and qualified help.'**
  String get everydayReflection;

  /// No description provided for @luckyTimesMorning.
  ///
  /// In en, this message translates to:
  /// **'Your luckiest times this morning'**
  String get luckyTimesMorning;

  /// No description provided for @luckyTimesMidday.
  ///
  /// In en, this message translates to:
  /// **'Your luckiest times around midday'**
  String get luckyTimesMidday;

  /// No description provided for @luckyTimesAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Your luckiest times this afternoon'**
  String get luckyTimesAfternoon;

  /// No description provided for @luckyTimesEvening.
  ///
  /// In en, this message translates to:
  /// **'Your luckiest times this evening'**
  String get luckyTimesEvening;

  /// No description provided for @loadingLocalTime.
  ///
  /// In en, this message translates to:
  /// **'Synchronizing with your local time and hour'**
  String get loadingLocalTime;

  /// No description provided for @loadingBaZi.
  ///
  /// In en, this message translates to:
  /// **'Reading your BaZi elemental balance'**
  String get loadingBaZi;

  /// No description provided for @loadingZiWei.
  ///
  /// In en, this message translates to:
  /// **'Mapping Zi Wei cycles around this moment'**
  String get loadingZiWei;

  /// No description provided for @loadingVedic.
  ///
  /// In en, this message translates to:
  /// **'Aligning Vedic Nakshatras and lunar mansions'**
  String get loadingVedic;

  /// No description provided for @loadingNumerology.
  ///
  /// In en, this message translates to:
  /// **'Tracing numerology, lunar and planetary rhythms'**
  String get loadingNumerology;

  /// No description provided for @loadingYinYang.
  ///
  /// In en, this message translates to:
  /// **'Balancing Yin and Yang signals into one direction'**
  String get loadingYinYang;

  /// No description provided for @loadingModeYesNo.
  ///
  /// In en, this message translates to:
  /// **'Testing openness against resistance'**
  String get loadingModeYesNo;

  /// No description provided for @loadingModeActWait.
  ///
  /// In en, this message translates to:
  /// **'Balancing momentum against patience'**
  String get loadingModeActWait;

  /// No description provided for @loadingModeAdvanceRetreat.
  ///
  /// In en, this message translates to:
  /// **'Measuring today\'s push against the last few days'**
  String get loadingModeAdvanceRetreat;

  /// No description provided for @loadingModeStayGo.
  ///
  /// In en, this message translates to:
  /// **'Comparing roots with movement'**
  String get loadingModeStayGo;

  /// No description provided for @loadingModeKeepLetGo.
  ///
  /// In en, this message translates to:
  /// **'Weighing continuity against release'**
  String get loadingModeKeepLetGo;

  /// No description provided for @loadingModeForwardBackward.
  ///
  /// In en, this message translates to:
  /// **'Tracing forward motion against returning energy'**
  String get loadingModeForwardBackward;

  /// No description provided for @loadingModeCommitWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Balancing commitment against withdrawal'**
  String get loadingModeCommitWithdraw;

  /// No description provided for @loadingModeLeftRight.
  ///
  /// In en, this message translates to:
  /// **'Balancing receptive and expressive polarity'**
  String get loadingModeLeftRight;

  /// No description provided for @orbitMoment.
  ///
  /// In en, this message translates to:
  /// **'MOMENT'**
  String get orbitMoment;

  /// No description provided for @orbitRhythm.
  ///
  /// In en, this message translates to:
  /// **'RHYTHM'**
  String get orbitRhythm;

  /// No description provided for @orbitBalance.
  ///
  /// In en, this message translates to:
  /// **'BALANCE'**
  String get orbitBalance;

  /// No description provided for @orbitAlmanac.
  ///
  /// In en, this message translates to:
  /// **'ALMANAC'**
  String get orbitAlmanac;

  /// No description provided for @orbitBaZi.
  ///
  /// In en, this message translates to:
  /// **'BAZI'**
  String get orbitBaZi;

  /// No description provided for @orbitZiWei.
  ///
  /// In en, this message translates to:
  /// **'ZI WEI'**
  String get orbitZiWei;

  /// No description provided for @orbitVedic.
  ///
  /// In en, this message translates to:
  /// **'VEDIC JYOTISH'**
  String get orbitVedic;

  /// No description provided for @orbitNumerology.
  ///
  /// In en, this message translates to:
  /// **'NUMEROLOGY'**
  String get orbitNumerology;

  /// No description provided for @orbitLunarPhase.
  ///
  /// In en, this message translates to:
  /// **'LUNAR PHASE'**
  String get orbitLunarPhase;

  /// No description provided for @orbitPlanetary.
  ///
  /// In en, this message translates to:
  /// **'PLANETARY'**
  String get orbitPlanetary;

  /// No description provided for @orbitYinYang.
  ///
  /// In en, this message translates to:
  /// **'YIN / YANG'**
  String get orbitYinYang;

  /// No description provided for @safetyHeading.
  ///
  /// In en, this message translates to:
  /// **'BOUNDARIES & RESPONSIBLE USE'**
  String get safetyHeading;

  /// No description provided for @safetyTitle.
  ///
  /// In en, this message translates to:
  /// **'A Mirror for Everyday Moments'**
  String get safetyTitle;

  /// No description provided for @safetyIntro.
  ///
  /// In en, this message translates to:
  /// **'AstraCue offers symbolic perspectives drawn from astronomical rhythms and personal cycles. It is for everyday reflection and entertainment, not a command, prediction, or factual certainty.'**
  String get safetyIntro;

  /// No description provided for @prohibitedUses.
  ///
  /// In en, this message translates to:
  /// **'PROHIBITED USES'**
  String get prohibitedUses;

  /// No description provided for @harmTitle.
  ///
  /// In en, this message translates to:
  /// **'Harm & Self-Violence'**
  String get harmTitle;

  /// No description provided for @harmDetail.
  ///
  /// In en, this message translates to:
  /// **'Never use for self-harm, suicide, physical violence, or endangering yourself or anyone else.'**
  String get harmDetail;

  /// No description provided for @navigationTitle.
  ///
  /// In en, this message translates to:
  /// **'Driving & Physical Navigation'**
  String get navigationTitle;

  /// No description provided for @navigationDetail.
  ///
  /// In en, this message translates to:
  /// **'LEFT / RIGHT and ADVANCE / RETREAT are symbolic choices only. Never use them for traffic, driving, route-finding, or physical safety.'**
  String get navigationDetail;

  /// No description provided for @politicsTitle.
  ///
  /// In en, this message translates to:
  /// **'Politics & Social Conflicts'**
  String get politicsTitle;

  /// No description provided for @politicsDetail.
  ///
  /// In en, this message translates to:
  /// **'Never use for political campaigning, electoral decisions, civil unrest, or extremist activities.'**
  String get politicsDetail;

  /// No description provided for @medicalTitle.
  ///
  /// In en, this message translates to:
  /// **'Health, Medical & Emergencies'**
  String get medicalTitle;

  /// No description provided for @medicalDetail.
  ///
  /// In en, this message translates to:
  /// **'Not a substitute for licensed medical care, mental health treatment, medication, or emergency response.'**
  String get medicalDetail;

  /// No description provided for @legalTitle.
  ///
  /// In en, this message translates to:
  /// **'Legal, Criminal & High-Stakes Contracts'**
  String get legalTitle;

  /// No description provided for @legalDetail.
  ///
  /// In en, this message translates to:
  /// **'Never use for criminal conduct, court proceedings, testimony, or binding high-stakes legal contracts.'**
  String get legalDetail;

  /// No description provided for @financeTitle.
  ///
  /// In en, this message translates to:
  /// **'Financial Investments & Gambling'**
  String get financeTitle;

  /// No description provided for @financeDetail.
  ///
  /// In en, this message translates to:
  /// **'Finances is for reflecting on small, routine purchases only. Never use a reading for investing, borrowing, crypto bets, gambling, or major financial decisions.'**
  String get financeDetail;

  /// No description provided for @consentTitle.
  ///
  /// In en, this message translates to:
  /// **'Consent, Minors & Relationships'**
  String get consentTitle;

  /// No description provided for @consentDetail.
  ///
  /// In en, this message translates to:
  /// **'Never use to override another person\'s consent or autonomy, or for child custody and guardianship decisions.'**
  String get consentDetail;

  /// No description provided for @importantLimitsHeading.
  ///
  /// In en, this message translates to:
  /// **'IMPORTANT LIMITS'**
  String get importantLimitsHeading;

  /// No description provided for @importantLimitsBody.
  ///
  /// In en, this message translates to:
  /// **'AstraCue is not designed for children. It does not provide medical, legal, or financial advice. For important decisions, use reliable information and appropriate professional help. You remain in control of your choices.'**
  String get importantLimitsBody;

  /// No description provided for @crisisSupport.
  ///
  /// In en, this message translates to:
  /// **'If you or someone else is in immediate danger or emotional crisis, contact local emergency services or a trusted local crisis helpline now.'**
  String get crisisSupport;

  /// No description provided for @acknowledge.
  ///
  /// In en, this message translates to:
  /// **'I Understand & Agree'**
  String get acknowledge;

  /// No description provided for @acknowledgementOnce.
  ///
  /// In en, this message translates to:
  /// **'This acknowledgement appears once before your first reading.'**
  String get acknowledgementOnce;

  /// No description provided for @knowBirthTime.
  ///
  /// In en, this message translates to:
  /// **'I know my birth time'**
  String get knowBirthTime;

  /// No description provided for @knowBirthTimeDetail.
  ///
  /// In en, this message translates to:
  /// **'An exact time sharpens the hour-based cycles.'**
  String get knowBirthTimeDetail;

  /// No description provided for @selectBirthTime.
  ///
  /// In en, this message translates to:
  /// **'Select your time of birth'**
  String get selectBirthTime;

  /// No description provided for @birthTimeRequired.
  ///
  /// In en, this message translates to:
  /// **'Select your time of birth to continue, or turn this off if you do not know it.'**
  String get birthTimeRequired;

  /// No description provided for @languageSetting.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSetting;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get chooseLanguage;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change language'**
  String get changeLanguage;

  /// No description provided for @choiceYes.
  ///
  /// In en, this message translates to:
  /// **'YES'**
  String get choiceYes;

  /// No description provided for @choiceNo.
  ///
  /// In en, this message translates to:
  /// **'NO'**
  String get choiceNo;

  /// No description provided for @choiceAct.
  ///
  /// In en, this message translates to:
  /// **'ACT'**
  String get choiceAct;

  /// No description provided for @choiceWait.
  ///
  /// In en, this message translates to:
  /// **'WAIT'**
  String get choiceWait;

  /// No description provided for @choiceAdvance.
  ///
  /// In en, this message translates to:
  /// **'ADVANCE'**
  String get choiceAdvance;

  /// No description provided for @choiceRetreat.
  ///
  /// In en, this message translates to:
  /// **'RETREAT'**
  String get choiceRetreat;

  /// No description provided for @choiceStay.
  ///
  /// In en, this message translates to:
  /// **'STAY'**
  String get choiceStay;

  /// No description provided for @choiceGo.
  ///
  /// In en, this message translates to:
  /// **'GO'**
  String get choiceGo;

  /// No description provided for @choiceKeep.
  ///
  /// In en, this message translates to:
  /// **'KEEP'**
  String get choiceKeep;

  /// No description provided for @choiceLetGo.
  ///
  /// In en, this message translates to:
  /// **'LET GO'**
  String get choiceLetGo;

  /// No description provided for @choiceForward.
  ///
  /// In en, this message translates to:
  /// **'FORWARD'**
  String get choiceForward;

  /// No description provided for @choiceBackward.
  ///
  /// In en, this message translates to:
  /// **'BACKWARD'**
  String get choiceBackward;

  /// No description provided for @choiceCommit.
  ///
  /// In en, this message translates to:
  /// **'COMMIT'**
  String get choiceCommit;

  /// No description provided for @choiceWithdraw.
  ///
  /// In en, this message translates to:
  /// **'WITHDRAW'**
  String get choiceWithdraw;

  /// No description provided for @choiceLeft.
  ///
  /// In en, this message translates to:
  /// **'LEFT'**
  String get choiceLeft;

  /// No description provided for @choiceRight.
  ///
  /// In en, this message translates to:
  /// **'RIGHT'**
  String get choiceRight;

  /// No description provided for @energyLevelQuiet.
  ///
  /// In en, this message translates to:
  /// **'QUIET'**
  String get energyLevelQuiet;

  /// No description provided for @energyLevelSoft.
  ///
  /// In en, this message translates to:
  /// **'SOFT'**
  String get energyLevelSoft;

  /// No description provided for @energyLevelSteady.
  ///
  /// In en, this message translates to:
  /// **'STEADY'**
  String get energyLevelSteady;

  /// No description provided for @energyLevelLively.
  ///
  /// In en, this message translates to:
  /// **'LIVELY'**
  String get energyLevelLively;

  /// No description provided for @energyLevelBright.
  ///
  /// In en, this message translates to:
  /// **'BRIGHT'**
  String get energyLevelBright;

  /// No description provided for @energyLevelRadiant.
  ///
  /// In en, this message translates to:
  /// **'RADIANT'**
  String get energyLevelRadiant;

  /// No description provided for @energyLevelFocused.
  ///
  /// In en, this message translates to:
  /// **'FOCUSED'**
  String get energyLevelFocused;

  /// No description provided for @energyLevelFlowing.
  ///
  /// In en, this message translates to:
  /// **'FLOWING'**
  String get energyLevelFlowing;

  /// No description provided for @colorCedar.
  ///
  /// In en, this message translates to:
  /// **'Cedar'**
  String get colorCedar;

  /// No description provided for @colorJade.
  ///
  /// In en, this message translates to:
  /// **'Jade'**
  String get colorJade;

  /// No description provided for @colorSage.
  ///
  /// In en, this message translates to:
  /// **'Sage'**
  String get colorSage;

  /// No description provided for @colorMint.
  ///
  /// In en, this message translates to:
  /// **'Mint'**
  String get colorMint;

  /// No description provided for @colorEmber.
  ///
  /// In en, this message translates to:
  /// **'Ember'**
  String get colorEmber;

  /// No description provided for @colorSolarCoral.
  ///
  /// In en, this message translates to:
  /// **'Solar Coral'**
  String get colorSolarCoral;

  /// No description provided for @colorRose.
  ///
  /// In en, this message translates to:
  /// **'Rose'**
  String get colorRose;

  /// No description provided for @colorBlossom.
  ///
  /// In en, this message translates to:
  /// **'Blossom'**
  String get colorBlossom;

  /// No description provided for @colorOchre.
  ///
  /// In en, this message translates to:
  /// **'Ochre'**
  String get colorOchre;

  /// No description provided for @colorAmber.
  ///
  /// In en, this message translates to:
  /// **'Amber'**
  String get colorAmber;

  /// No description provided for @colorSand.
  ///
  /// In en, this message translates to:
  /// **'Sand'**
  String get colorSand;

  /// No description provided for @colorClay.
  ///
  /// In en, this message translates to:
  /// **'Clay'**
  String get colorClay;

  /// No description provided for @colorSilver.
  ///
  /// In en, this message translates to:
  /// **'Silver'**
  String get colorSilver;

  /// No description provided for @colorSteel.
  ///
  /// In en, this message translates to:
  /// **'Steel'**
  String get colorSteel;

  /// No description provided for @colorPearl.
  ///
  /// In en, this message translates to:
  /// **'Pearl'**
  String get colorPearl;

  /// No description provided for @colorChampagne.
  ///
  /// In en, this message translates to:
  /// **'Champagne'**
  String get colorChampagne;

  /// No description provided for @colorOceanBlue.
  ///
  /// In en, this message translates to:
  /// **'Ocean Blue'**
  String get colorOceanBlue;

  /// No description provided for @colorAzure.
  ///
  /// In en, this message translates to:
  /// **'Azure'**
  String get colorAzure;

  /// No description provided for @colorIndigo.
  ///
  /// In en, this message translates to:
  /// **'Indigo'**
  String get colorIndigo;

  /// No description provided for @colorMistBlue.
  ///
  /// In en, this message translates to:
  /// **'Mist Blue'**
  String get colorMistBlue;

  /// No description provided for @homeDescription00.
  ///
  /// In en, this message translates to:
  /// **'What might the universe be telling you today? Choose what’s on your mind and explore the signs around this moment.'**
  String get homeDescription00;

  /// No description provided for @homeDescription01.
  ///
  /// In en, this message translates to:
  /// **'Feeling pulled in two directions? Let today’s cosmic signals offer a new way to see your choice.'**
  String get homeDescription01;

  /// No description provided for @homeDescription02.
  ///
  /// In en, this message translates to:
  /// **'The stars may not decide for you—but their patterns might help you see your next step differently.'**
  String get homeDescription02;

  /// No description provided for @homeDescription03.
  ///
  /// In en, this message translates to:
  /// **'When your path feels unclear, pause and look closer. What do today’s signs suggest?'**
  String get homeDescription03;

  /// No description provided for @homeDescription04.
  ///
  /// In en, this message translates to:
  /// **'Every moment has its own energy. Choose what’s on your mind and discover the direction it may be pointing toward.'**
  String get homeDescription04;

  /// No description provided for @homeDescription05.
  ///
  /// In en, this message translates to:
  /// **'Perhaps the universe is asking you to slow down. Explore today’s signals before choosing your way.'**
  String get homeDescription05;

  /// No description provided for @homeDescription06.
  ///
  /// In en, this message translates to:
  /// **'At a crossroads? See how today’s celestial patterns align with the question on your mind.'**
  String get homeDescription06;

  /// No description provided for @homeDescription07.
  ///
  /// In en, this message translates to:
  /// **'Listen to the rhythm of this moment. Today’s symbols may reveal a direction worth considering.'**
  String get homeDescription07;

  /// No description provided for @homeDescription08.
  ///
  /// In en, this message translates to:
  /// **'What is this moment trying to show you? Explore the signs, then trust yourself to make the choice.'**
  String get homeDescription08;

  /// No description provided for @homeDescription09.
  ///
  /// In en, this message translates to:
  /// **'A little cosmic perspective can bring clarity. Choose what matters today and see where the signs point.'**
  String get homeDescription09;

  /// No description provided for @homeDescription10.
  ///
  /// In en, this message translates to:
  /// **'Still turning the same choice over in your mind? See what today’s cosmic energy brings into focus.'**
  String get homeDescription10;

  /// No description provided for @homeDescription11.
  ///
  /// In en, this message translates to:
  /// **'When your thoughts pull one way and your intuition another, explore the signals surrounding today.'**
  String get homeDescription11;

  /// No description provided for @homeDescription12.
  ///
  /// In en, this message translates to:
  /// **'Unsure whether to move or pause? Let the rhythm of this day offer a calmer starting point.'**
  String get homeDescription12;

  /// No description provided for @homeDescription13.
  ///
  /// In en, this message translates to:
  /// **'What if clarity begins with a different perspective? Look to today’s celestial patterns.'**
  String get homeDescription13;

  /// No description provided for @homeDescription14.
  ///
  /// In en, this message translates to:
  /// **'A question keeps returning to you. Discover what today’s symbols invite you to notice.'**
  String get homeDescription14;

  /// No description provided for @homeDescription15.
  ///
  /// In en, this message translates to:
  /// **'Some choices feel heavier at certain moments. Explore the energy of this one before you decide.'**
  String get homeDescription15;

  /// No description provided for @homeDescription16.
  ///
  /// In en, this message translates to:
  /// **'Your path may feel unclear right now. What might the stars illuminate beneath that doubt?'**
  String get homeDescription16;

  /// No description provided for @homeDescription17.
  ///
  /// In en, this message translates to:
  /// **'Before following a sudden impulse, take a breath and see what today’s cosmic signs suggest.'**
  String get homeDescription17;

  /// No description provided for @homeDescription18.
  ///
  /// In en, this message translates to:
  /// **'Not every crossroads needs an instant answer. Let today’s reading give you space to reflect.'**
  String get homeDescription18;

  /// No description provided for @homeDescription19.
  ///
  /// In en, this message translates to:
  /// **'Wondering whether the timing is right? Explore today’s patterns and find a steadier point of view.'**
  String get homeDescription19;

  /// No description provided for @homeDescription20.
  ///
  /// In en, this message translates to:
  /// **'When everything feels possible and nothing feels certain, let the sky’s patterns spark a fresh perspective.'**
  String get homeDescription20;

  /// No description provided for @homeDescription21.
  ///
  /// In en, this message translates to:
  /// **'The choice belongs to you. The signs of this day may help you understand what matters most.'**
  String get homeDescription21;

  /// No description provided for @homeDescription22.
  ///
  /// In en, this message translates to:
  /// **'When doubt clouds your next step, explore what your zodiac and today’s energy bring to light.'**
  String get homeDescription22;

  /// No description provided for @homeDescription23.
  ///
  /// In en, this message translates to:
  /// **'Maybe you don’t need a louder answer—just a quieter moment with today’s symbols.'**
  String get homeDescription23;

  /// No description provided for @homeDescription24.
  ///
  /// In en, this message translates to:
  /// **'Is your instinct asking you to act or wait? See what today’s cosmic rhythm might reflect.'**
  String get homeDescription24;

  /// No description provided for @homeDescription25.
  ///
  /// In en, this message translates to:
  /// **'Between what you want and what you fear, there’s room to pause. Let today’s signs help you look again.'**
  String get homeDescription25;

  /// No description provided for @homeDescription26.
  ///
  /// In en, this message translates to:
  /// **'You’ve noticed the question. Now notice the moment. What do today’s celestial signals suggest?'**
  String get homeDescription26;

  /// No description provided for @homeDescription27.
  ///
  /// In en, this message translates to:
  /// **'When a decision feels tangled, let ancient symbols and the timing of today reveal another angle.'**
  String get homeDescription27;

  /// No description provided for @homeDescription28.
  ///
  /// In en, this message translates to:
  /// **'Perhaps this is a moment to lean in—or give things space. Explore the energy around your choice.'**
  String get homeDescription28;

  /// No description provided for @homeDescription29.
  ///
  /// In en, this message translates to:
  /// **'You don’t have to find certainty here. Find a moment of calm, a cosmic cue, and a direction to consider.'**
  String get homeDescription29;

  /// No description provided for @energyQuiet00.
  ///
  /// In en, this message translates to:
  /// **'Today’s symbolic energy turns inward, making space for quiet reflection.'**
  String get energyQuiet00;

  /// No description provided for @energyQuiet01.
  ///
  /// In en, this message translates to:
  /// **'Today’s cosmic rhythm turns inward; stillness may reveal what noise has been hiding.'**
  String get energyQuiet01;

  /// No description provided for @energyQuiet02.
  ///
  /// In en, this message translates to:
  /// **'The sky’s symbolic tone is hushed today; give your thoughts room to settle.'**
  String get energyQuiet02;

  /// No description provided for @energyQuiet03.
  ///
  /// In en, this message translates to:
  /// **'A quieter current runs through this day, inviting you to notice rather than rush.'**
  String get energyQuiet03;

  /// No description provided for @energyQuiet04.
  ///
  /// In en, this message translates to:
  /// **'Today’s signs suggest reflection; a pause can still be part of moving forward.'**
  String get energyQuiet04;

  /// No description provided for @energyQuiet05.
  ///
  /// In en, this message translates to:
  /// **'When the day feels subdued, your inner compass may speak more clearly.'**
  String get energyQuiet05;

  /// No description provided for @energyQuiet06.
  ///
  /// In en, this message translates to:
  /// **'The energy of this day leaves space to listen before naming an answer.'**
  String get energyQuiet06;

  /// No description provided for @energyQuiet07.
  ///
  /// In en, this message translates to:
  /// **'Not every signal arrives loudly; today’s may be easier to notice when you slow down.'**
  String get energyQuiet07;

  /// No description provided for @energySoft00.
  ///
  /// In en, this message translates to:
  /// **'Today’s symbolic energy moves gently, with room for care and small steps.'**
  String get energySoft00;

  /// No description provided for @energySoft01.
  ///
  /// In en, this message translates to:
  /// **'A gentle cosmic current moves through today; small steps may feel more natural than big leaps.'**
  String get energySoft01;

  /// No description provided for @energySoft02.
  ///
  /// In en, this message translates to:
  /// **'Today’s energy leaves room for care; approach your choice without pressing for certainty.'**
  String get energySoft02;

  /// No description provided for @energySoft03.
  ///
  /// In en, this message translates to:
  /// **'The day’s softer rhythm may help you begin with what feels manageable.'**
  String get energySoft03;

  /// No description provided for @energySoft04.
  ///
  /// In en, this message translates to:
  /// **'A gentler approach can still be strong today; notice where you need ease, not pressure.'**
  String get energySoft04;

  /// No description provided for @energySoft05.
  ///
  /// In en, this message translates to:
  /// **'Today’s signs suggest a light touch: enough movement to begin, without forcing the pace.'**
  String get energySoft05;

  /// No description provided for @energySoft06.
  ///
  /// In en, this message translates to:
  /// **'The current is subtle today; simple, thoughtful actions may carry more meaning.'**
  String get energySoft06;

  /// No description provided for @energySoft07.
  ///
  /// In en, this message translates to:
  /// **'Even a small opening can matter; today’s gentle pattern leaves space to explore it.'**
  String get energySoft07;

  /// No description provided for @energySteady00.
  ///
  /// In en, this message translates to:
  /// **'Today’s symbolic energy keeps an even, grounded rhythm.'**
  String get energySteady00;

  /// No description provided for @energySteady01.
  ///
  /// In en, this message translates to:
  /// **'Today’s symbolic energy holds an even rhythm; trust the pace you can sustain.'**
  String get energySteady01;

  /// No description provided for @energySteady02.
  ///
  /// In en, this message translates to:
  /// **'The cosmic pattern feels grounded, offering room to think and move deliberately.'**
  String get energySteady02;

  /// No description provided for @energySteady03.
  ///
  /// In en, this message translates to:
  /// **'A steady current runs beneath this day; attention may serve you better than urgency.'**
  String get energySteady03;

  /// No description provided for @energySteady04.
  ///
  /// In en, this message translates to:
  /// **'Today’s signs point toward balance, without asking you to stand still.'**
  String get energySteady04;

  /// No description provided for @energySteady05.
  ///
  /// In en, this message translates to:
  /// **'There is strength in consistency; notice which next step still makes sense after a pause.'**
  String get energySteady05;

  /// No description provided for @energySteady06.
  ///
  /// In en, this message translates to:
  /// **'The day carries a measured energy, giving your choice room to take shape.'**
  String get energySteady06;

  /// No description provided for @energySteady07.
  ///
  /// In en, this message translates to:
  /// **'A calm rhythm can be its own guide; progress need not be dramatic today.'**
  String get energySteady07;

  /// No description provided for @energyLively00.
  ///
  /// In en, this message translates to:
  /// **'A playful spark stirs today’s symbolic energy, bringing curiosity and motion.'**
  String get energyLively00;

  /// No description provided for @energyLively01.
  ///
  /// In en, this message translates to:
  /// **'A curious spark stirs today’s symbolic energy; a fresh angle may be worth exploring.'**
  String get energyLively01;

  /// No description provided for @energyLively02.
  ///
  /// In en, this message translates to:
  /// **'The day feels more animated; notice what catches your attention without rushing toward it.'**
  String get energyLively02;

  /// No description provided for @energyLively03.
  ///
  /// In en, this message translates to:
  /// **'Today’s cosmic rhythm invites discovery, with space to stay discerning.'**
  String get energyLively03;

  /// No description provided for @energyLively04.
  ///
  /// In en, this message translates to:
  /// **'A playful current moves through this day; possibilities may appear in unexpected places.'**
  String get energyLively04;

  /// No description provided for @energyLively05.
  ///
  /// In en, this message translates to:
  /// **'Curiosity may be a useful signal today; notice where it points before you commit.'**
  String get energyLively05;

  /// No description provided for @energyLively06.
  ///
  /// In en, this message translates to:
  /// **'There is motion in today’s signs; you can explore without committing too quickly.'**
  String get energyLively06;

  /// No description provided for @energyLively07.
  ///
  /// In en, this message translates to:
  /// **'The energy feels lively; let it widen your options before narrowing them.'**
  String get energyLively07;

  /// No description provided for @energyBright00.
  ///
  /// In en, this message translates to:
  /// **'Today’s symbolic energy shines with momentum and room for expression.'**
  String get energyBright00;

  /// No description provided for @energyBright01.
  ///
  /// In en, this message translates to:
  /// **'Today’s symbolic energy brings more light to what you want to express.'**
  String get energyBright01;

  /// No description provided for @energyBright02.
  ///
  /// In en, this message translates to:
  /// **'A brighter cosmic current may help you see which possibility deserves attention.'**
  String get energyBright02;

  /// No description provided for @energyBright03.
  ///
  /// In en, this message translates to:
  /// **'The signs of this day feel open; your next step may become easier to name.'**
  String get energyBright03;

  /// No description provided for @energyBright04.
  ///
  /// In en, this message translates to:
  /// **'Today carries momentum for expression; share what matters when the moment feels right.'**
  String get energyBright04;

  /// No description provided for @energyBright05.
  ///
  /// In en, this message translates to:
  /// **'An opening in today’s rhythm may encourage clarity without demanding haste.'**
  String get energyBright05;

  /// No description provided for @energyBright06.
  ///
  /// In en, this message translates to:
  /// **'The day’s energy feels outward-facing; notice what you’re ready to bring forward.'**
  String get energyBright06;

  /// No description provided for @energyBright07.
  ///
  /// In en, this message translates to:
  /// **'A touch of brightness can shift perspective; today’s patterns invite you to look ahead.'**
  String get energyBright07;

  /// No description provided for @energyRadiant00.
  ///
  /// In en, this message translates to:
  /// **'Today’s symbolic energy reaches its fullest glow: open and expansive.'**
  String get energyRadiant00;

  /// No description provided for @energyRadiant01.
  ///
  /// In en, this message translates to:
  /// **'Today’s symbolic energy opens wide, inviting you to see more than one possible path.'**
  String get energyRadiant01;

  /// No description provided for @energyRadiant02.
  ///
  /// In en, this message translates to:
  /// **'A radiant current runs through this day; let possibility expand without losing your center.'**
  String get energyRadiant02;

  /// No description provided for @energyRadiant03.
  ///
  /// In en, this message translates to:
  /// **'The cosmic pattern feels especially open; make room for what inspires you.'**
  String get energyRadiant03;

  /// No description provided for @energyRadiant04.
  ///
  /// In en, this message translates to:
  /// **'A fuller glow colors today’s energy, bringing your possibilities into a wider view.'**
  String get energyRadiant04;

  /// No description provided for @energyRadiant05.
  ///
  /// In en, this message translates to:
  /// **'Today’s signs carry an expansive tone; it may be easier to imagine what comes next.'**
  String get energyRadiant05;

  /// No description provided for @energyRadiant06.
  ///
  /// In en, this message translates to:
  /// **'Let the day’s warmth widen your view while keeping the final choice in your hands.'**
  String get energyRadiant06;

  /// No description provided for @energyRadiant07.
  ///
  /// In en, this message translates to:
  /// **'The sky’s symbolic rhythm feels generous; welcome possibilities with grounded judgment.'**
  String get energyRadiant07;

  /// No description provided for @energyFocused00.
  ///
  /// In en, this message translates to:
  /// **'Today’s symbolic energy gathers around a clear direction; the action signal takes the lead.'**
  String get energyFocused00;

  /// No description provided for @energyFocused01.
  ///
  /// In en, this message translates to:
  /// **'Today’s action signal comes into focus; notice the one step that feels intentional.'**
  String get energyFocused01;

  /// No description provided for @energyFocused02.
  ///
  /// In en, this message translates to:
  /// **'The symbolic current leans toward doing, but you can choose the pace.'**
  String get energyFocused02;

  /// No description provided for @energyFocused03.
  ///
  /// In en, this message translates to:
  /// **'A sense of direction runs through today; attend to what you can actually influence.'**
  String get energyFocused03;

  /// No description provided for @energyFocused04.
  ///
  /// In en, this message translates to:
  /// **'When options compete, today’s signs invite you to center on one practical move.'**
  String get energyFocused04;

  /// No description provided for @energyFocused05.
  ///
  /// In en, this message translates to:
  /// **'Today’s signs gather around one intention; give it your attention without rushing.'**
  String get energyFocused05;

  /// No description provided for @energyFocused06.
  ///
  /// In en, this message translates to:
  /// **'Action has a stronger symbolic pull today; keep your reasons clear before moving.'**
  String get energyFocused06;

  /// No description provided for @energyFocused07.
  ///
  /// In en, this message translates to:
  /// **'This is a day for intention, not intensity; let your chosen direction take shape.'**
  String get energyFocused07;

  /// No description provided for @energyFlowing00.
  ///
  /// In en, this message translates to:
  /// **'Today’s symbolic energy moves with the tide; the change signal takes the lead.'**
  String get energyFlowing00;

  /// No description provided for @energyFlowing01.
  ///
  /// In en, this message translates to:
  /// **'Today’s change signal comes forward; allow your plans a little room to bend.'**
  String get energyFlowing01;

  /// No description provided for @energyFlowing02.
  ///
  /// In en, this message translates to:
  /// **'A shifting cosmic current runs through the day; adaptability may reveal another path.'**
  String get energyFlowing02;

  /// No description provided for @energyFlowing03.
  ///
  /// In en, this message translates to:
  /// **'The energy of change is more noticeable; stay open to what a new angle shows you.'**
  String get energyFlowing03;

  /// No description provided for @energyFlowing04.
  ///
  /// In en, this message translates to:
  /// **'Today’s signs speak of movement between possibilities, not a fixed destination.'**
  String get energyFlowing04;

  /// No description provided for @energyFlowing05.
  ///
  /// In en, this message translates to:
  /// **'When circumstances shift, a flexible response may serve you better than a rigid plan.'**
  String get energyFlowing05;

  /// No description provided for @energyFlowing06.
  ///
  /// In en, this message translates to:
  /// **'A flowing rhythm moves through this day; notice what can evolve without forcing an answer.'**
  String get energyFlowing06;

  /// No description provided for @energyFlowing07.
  ///
  /// In en, this message translates to:
  /// **'The symbolic current leans toward transition; you can move with it at your own pace.'**
  String get energyFlowing07;

  /// No description provided for @defaultUserName.
  ///
  /// In en, this message translates to:
  /// **'Explorer'**
  String get defaultUserName;

  /// No description provided for @searchCountries.
  ///
  /// In en, this message translates to:
  /// **'Search countries'**
  String get searchCountries;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning,'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon,'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening,'**
  String get greetingEvening;

  /// No description provided for @colorRoleLead.
  ///
  /// In en, this message translates to:
  /// **'Lead'**
  String get colorRoleLead;

  /// No description provided for @colorRoleSupporting.
  ///
  /// In en, this message translates to:
  /// **'Supporting'**
  String get colorRoleSupporting;

  /// No description provided for @colorRoleSemantics.
  ///
  /// In en, this message translates to:
  /// **'{role} colour, {name}'**
  String colorRoleSemantics(String role, String name);

  /// No description provided for @colorRoleUnavailableSemantics.
  ///
  /// In en, this message translates to:
  /// **'{role} colour not available yet'**
  String colorRoleUnavailableSemantics(String role);

  /// No description provided for @readingAreaSemantics.
  ///
  /// In en, this message translates to:
  /// **'Reading area: {category}'**
  String readingAreaSemantics(String category);

  /// No description provided for @energyInsightNewTooltip.
  ///
  /// In en, this message translates to:
  /// **'New energy insight today'**
  String get energyInsightNewTooltip;

  /// No description provided for @energyInsightReadTooltip.
  ///
  /// In en, this message translates to:
  /// **'Read today’s energy insight'**
  String get energyInsightReadTooltip;

  /// No description provided for @energyInsightHideTooltip.
  ///
  /// In en, this message translates to:
  /// **'Hide what today’s energy means'**
  String get energyInsightHideTooltip;

  /// No description provided for @energyInsightCoachMark.
  ///
  /// In en, this message translates to:
  /// **'A new energy insight awaits here each day.'**
  String get energyInsightCoachMark;

  /// No description provided for @ritualLocked.
  ///
  /// In en, this message translates to:
  /// **'Your moment is locked.'**
  String get ritualLocked;

  /// No description provided for @periodPassedShort.
  ///
  /// In en, this message translates to:
  /// **'PASSED'**
  String get periodPassedShort;

  /// No description provided for @errorNetworkHeadline.
  ///
  /// In en, this message translates to:
  /// **'The connection slipped out of alignment.'**
  String get errorNetworkHeadline;

  /// No description provided for @errorNetworkDetail.
  ///
  /// In en, this message translates to:
  /// **'Check your connection, then try the reading again.'**
  String get errorNetworkDetail;

  /// No description provided for @errorServerHeadline.
  ///
  /// In en, this message translates to:
  /// **'The reading could not be completed right now.'**
  String get errorServerHeadline;

  /// No description provided for @errorServerDetail.
  ///
  /// In en, this message translates to:
  /// **'The service is there but could not finish. Try again in a moment.'**
  String get errorServerDetail;

  /// No description provided for @errorRejectedHeadline.
  ///
  /// In en, this message translates to:
  /// **'Some profile details need attention.'**
  String get errorRejectedHeadline;

  /// No description provided for @errorRejectedDetail.
  ///
  /// In en, this message translates to:
  /// **'Revisit your birth details, then start a new reading.'**
  String get errorRejectedDetail;

  /// No description provided for @errorInvalidHeadline.
  ///
  /// In en, this message translates to:
  /// **'This app version could not read the result.'**
  String get errorInvalidHeadline;

  /// No description provided for @errorInvalidDetail.
  ///
  /// In en, this message translates to:
  /// **'Updating the app should restore readings.'**
  String get errorInvalidDetail;

  /// No description provided for @errorConfigurationHeadline.
  ///
  /// In en, this message translates to:
  /// **'This build has no reading service configured.'**
  String get errorConfigurationHeadline;

  /// No description provided for @errorConfigurationDetail.
  ///
  /// In en, this message translates to:
  /// **'Developer build: no calculation service is configured.'**
  String get errorConfigurationDetail;

  /// No description provided for @errorNothingRecorded.
  ///
  /// In en, this message translates to:
  /// **'No reading was recorded for this attempt.'**
  String get errorNothingRecorded;

  /// No description provided for @insufficientHeading.
  ///
  /// In en, this message translates to:
  /// **'NOT ENOUGH TO READ'**
  String get insufficientHeading;

  /// No description provided for @insufficientBody.
  ///
  /// In en, this message translates to:
  /// **'Your profile does not yet contain enough detail for a direction on this one. Adding your birth time and country of birth gives the cycles more to work with.'**
  String get insufficientBody;

  /// No description provided for @periodElapsedHeading.
  ///
  /// In en, this message translates to:
  /// **'THAT PERIOD HAS PASSED'**
  String get periodElapsedHeading;

  /// No description provided for @periodElapsedBody.
  ///
  /// In en, this message translates to:
  /// **'That period is already over where you are, so there is no window left to read. Pick a later period, or read your current moment instead — today’s reading is not rolled into tomorrow.'**
  String get periodElapsedBody;

  /// No description provided for @colorsToKeepNear.
  ///
  /// In en, this message translates to:
  /// **'Colours to keep near you: {first} and {second}'**
  String colorsToKeepNear(String first, String second);

  /// No description provided for @colorToKeepNear.
  ///
  /// In en, this message translates to:
  /// **'Colour to keep near you: {name}'**
  String colorToKeepNear(String name);

  /// No description provided for @shareTooltip.
  ///
  /// In en, this message translates to:
  /// **'Share this reading'**
  String get shareTooltip;

  /// No description provided for @shareUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Sharing is unavailable right now.'**
  String get shareUnavailable;

  /// No description provided for @shareDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'A symbolic perspective for everyday reflection, not a prediction or probability.'**
  String get shareDisclaimer;

  /// No description provided for @backToHistory.
  ///
  /// In en, this message translates to:
  /// **'Back to History'**
  String get backToHistory;

  /// No description provided for @saveFailedRetry.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t save · Retry'**
  String get saveFailedRetry;

  /// No description provided for @savingToHistory.
  ///
  /// In en, this message translates to:
  /// **'Saving to History…'**
  String get savingToHistory;

  /// No description provided for @responsibleUseLink.
  ///
  /// In en, this message translates to:
  /// **'Responsible Use & Safety Policy'**
  String get responsibleUseLink;

  /// No description provided for @historyToday.
  ///
  /// In en, this message translates to:
  /// **'TODAY'**
  String get historyToday;

  /// No description provided for @historyCouldNotOpen.
  ///
  /// In en, this message translates to:
  /// **'Your readings could not be opened.'**
  String get historyCouldNotOpen;

  /// No description provided for @historyNotEnoughData.
  ///
  /// In en, this message translates to:
  /// **'NOT ENOUGH DATA'**
  String get historyNotEnoughData;

  /// No description provided for @historyPeriodPassed.
  ///
  /// In en, this message translates to:
  /// **'PERIOD PASSED'**
  String get historyPeriodPassed;

  /// No description provided for @zodiacAries.
  ///
  /// In en, this message translates to:
  /// **'Aries'**
  String get zodiacAries;

  /// No description provided for @zodiacTaurus.
  ///
  /// In en, this message translates to:
  /// **'Taurus'**
  String get zodiacTaurus;

  /// No description provided for @zodiacGemini.
  ///
  /// In en, this message translates to:
  /// **'Gemini'**
  String get zodiacGemini;

  /// No description provided for @zodiacCancer.
  ///
  /// In en, this message translates to:
  /// **'Cancer'**
  String get zodiacCancer;

  /// No description provided for @zodiacLeo.
  ///
  /// In en, this message translates to:
  /// **'Leo'**
  String get zodiacLeo;

  /// No description provided for @zodiacVirgo.
  ///
  /// In en, this message translates to:
  /// **'Virgo'**
  String get zodiacVirgo;

  /// No description provided for @zodiacLibra.
  ///
  /// In en, this message translates to:
  /// **'Libra'**
  String get zodiacLibra;

  /// No description provided for @zodiacScorpio.
  ///
  /// In en, this message translates to:
  /// **'Scorpio'**
  String get zodiacScorpio;

  /// No description provided for @zodiacSagittarius.
  ///
  /// In en, this message translates to:
  /// **'Sagittarius'**
  String get zodiacSagittarius;

  /// No description provided for @zodiacCapricorn.
  ///
  /// In en, this message translates to:
  /// **'Capricorn'**
  String get zodiacCapricorn;

  /// No description provided for @zodiacAquarius.
  ///
  /// In en, this message translates to:
  /// **'Aquarius'**
  String get zodiacAquarius;

  /// No description provided for @zodiacPisces.
  ///
  /// In en, this message translates to:
  /// **'Pisces'**
  String get zodiacPisces;

  /// No description provided for @zodiacAvatarSemantics.
  ///
  /// In en, this message translates to:
  /// **'{sign} zodiac avatar'**
  String zodiacAvatarSemantics(String sign);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'en',
    'es',
    'hi',
    'ja',
    'th',
    'vi',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script+country codes are specified.
  switch (locale.toString()) {
    case 'zh_Hans_CN':
      return AppLocalizationsZhHansCn();
  }

  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hans':
            return AppLocalizationsZhHans();
        }
        break;
      }
  }

  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'hi':
      {
        switch (locale.countryCode) {
          case 'IN':
            return AppLocalizationsHiIn();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'hi':
      return AppLocalizationsHi();
    case 'ja':
      return AppLocalizationsJa();
    case 'th':
      return AppLocalizationsTh();
    case 'vi':
      return AppLocalizationsVi();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
