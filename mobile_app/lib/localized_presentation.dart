/// Turns the app's and the engine's stable identifiers into text the reader
/// can read, in whatever language is active.
///
/// This is the only bridge between the two. Wire values (`money`,
/// `forward_backward`, `evening`, `radiant`, `ocean_blue`), formulas, saved
/// reading snapshots, percentages and HEX colours never change with the
/// language — a result reopened from History after a switch still describes
/// the same reading, because every label is rebuilt from its key rather than
/// read back from the English text the engine happened to send.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'app_locale.dart';
import 'app_profile.dart';
import 'data/models/models.dart' as engine;
import 'l10n/app_localizations.dart';
import 'models.dart';

/// The active language. Falls back to English for a locale this build has no
/// entry for, which can only happen if the device resolves something outside
/// `AppLocale`.
AppLocale appLocaleOf(BuildContext context) =>
    AppLocale.forLocale(Localizations.localeOf(context)) ?? AppLocale.english;

/// The name `intl` wants for dates, times and numbers on this screen.
String intlLocaleOf(BuildContext context) => appLocaleOf(context).intlName;

/// Letter spacing, but only for the scripts that read better with it.
///
/// The design's wide-tracked, upper-case treatment belongs to Latin type.
/// Spreading Thai, Devanagari, kana, kanji or Han apart breaks the clusters
/// those scripts are read in, so they get none. Nothing is shrunk to make the
/// spacing fit — the spacing goes instead.
double trackingFor(BuildContext context, double latin) =>
    switch (appLocaleOf(context)) {
      AppLocale.thai ||
      AppLocale.hindi ||
      AppLocale.japanese ||
      AppLocale.simplifiedChinese => 0,
      AppLocale.english || AppLocale.vietnamese || AppLocale.spanish => latin,
    };

// ---------------------------------------------------------------------------
// The reader
// ---------------------------------------------------------------------------

/// What to call the reader.
///
/// A profile with no name carries null rather than a word, so the greeting is
/// resolved here, in whatever language is active now. Switching language
/// changes the default greeting immediately and permanently; it never touches
/// a name the reader typed.
String profileDisplayName(AppLocalizations l10n, AppProfile profile) =>
    profile.userName ?? l10n.defaultUserName;

// ---------------------------------------------------------------------------
// Categories
// ---------------------------------------------------------------------------

String categoryLabel(AppLocalizations l10n, engine.ReadingCategory category) =>
    switch (category) {
      engine.ReadingCategory.general => l10n.categoryOverall,
      engine.ReadingCategory.love => l10n.categoryLove,
      engine.ReadingCategory.career => l10n.categoryCareer,
      engine.ReadingCategory.money => l10n.categoryMoney,
      engine.ReadingCategory.study => l10n.categoryStudy,
      engine.ReadingCategory.friends => l10n.categoryFriends,
      engine.ReadingCategory.other => l10n.categoryOther,
    };

// ---------------------------------------------------------------------------
// Decision modes
// ---------------------------------------------------------------------------

/// The first choice of a pair — the one a `ready` reading names as its winner
/// when the score leans that way.
String modeFirstLabel(AppLocalizations l10n, DecisionMode mode) =>
    switch (mode) {
      DecisionMode.yesNo => l10n.choiceYes,
      DecisionMode.actWait => l10n.choiceAct,
      DecisionMode.advanceRetreat => l10n.choiceAdvance,
      DecisionMode.stayGo => l10n.choiceStay,
      DecisionMode.keepLetGo => l10n.choiceKeep,
      DecisionMode.commitWithdraw => l10n.choiceCommit,
      DecisionMode.leftRight => l10n.choiceLeft,
      DecisionMode.forwardBackward => l10n.choiceForward,
    };

String modeSecondLabel(AppLocalizations l10n, DecisionMode mode) =>
    switch (mode) {
      DecisionMode.yesNo => l10n.choiceNo,
      DecisionMode.actWait => l10n.choiceWait,
      DecisionMode.advanceRetreat => l10n.choiceRetreat,
      DecisionMode.stayGo => l10n.choiceGo,
      DecisionMode.keepLetGo => l10n.choiceLetGo,
      DecisionMode.commitWithdraw => l10n.choiceWithdraw,
      DecisionMode.leftRight => l10n.choiceRight,
      DecisionMode.forwardBackward => l10n.choiceBackward,
    };

/// `FIRST / SECOND`, built from two localized tokens and a separator rather
/// than from an English label, so no language has to parse English punctuation
/// to find its own words.
String modeLabel(AppLocalizations l10n, DecisionMode mode) =>
    '${modeFirstLabel(l10n, mode)} / ${modeSecondLabel(l10n, mode)}';

/// The loading phrase for the selected mode.
String modeLoadingPhrase(AppLocalizations l10n, DecisionMode mode) =>
    switch (mode) {
      DecisionMode.yesNo => l10n.loadingModeYesNo,
      DecisionMode.actWait => l10n.loadingModeActWait,
      DecisionMode.advanceRetreat => l10n.loadingModeAdvanceRetreat,
      DecisionMode.stayGo => l10n.loadingModeStayGo,
      DecisionMode.keepLetGo => l10n.loadingModeKeepLetGo,
      DecisionMode.commitWithdraw => l10n.loadingModeCommitWithdraw,
      DecisionMode.leftRight => l10n.loadingModeLeftRight,
      DecisionMode.forwardBackward => l10n.loadingModeForwardBackward,
    };

/// The winner a response names, translated by the mode it belongs to.
///
/// The engine returns its own English token (`YES`, `LET GO`); matching it
/// against the mode's own first label is what keeps a saved reading readable
/// after a language switch. An unrecognised token is shown as the engine sent
/// it rather than being guessed at.
String localizedChoice(
  AppLocalizations l10n,
  DecisionMode mode,
  String engineLabel,
) {
  final english = englishChoiceLabels[mode]!;
  if (engineLabel == english.first) return modeFirstLabel(l10n, mode);
  if (engineLabel == english.second) return modeSecondLabel(l10n, mode);
  return engineLabel;
}

// ---------------------------------------------------------------------------
// Periods
// ---------------------------------------------------------------------------

String periodLabel(AppLocalizations l10n, TimePeriod period) =>
    switch (period) {
      TimePeriod.now => l10n.periodNow,
      TimePeriod.morning => l10n.periodMorning,
      TimePeriod.midday => l10n.periodMidday,
      TimePeriod.afternoon => l10n.periodAfternoon,
      TimePeriod.evening => l10n.periodEvening,
    };

/// One complete heading per period, never a translated chip label dropped into
/// an English frame: "in Morning" and its equivalents are ungrammatical in
/// several of these languages.
///
/// Null for NOW, which has no windows to head.
String? luckyTimesHeading(AppLocalizations l10n, TimePeriod period) =>
    switch (period) {
      TimePeriod.now => null,
      TimePeriod.morning => l10n.luckyTimesMorning,
      TimePeriod.midday => l10n.luckyTimesMidday,
      TimePeriod.afternoon => l10n.luckyTimesAfternoon,
      TimePeriod.evening => l10n.luckyTimesEvening,
    };

// ---------------------------------------------------------------------------
// Daily energy
// ---------------------------------------------------------------------------

/// The public name of a tone. `unavailable`, and any level a later engine adds
/// before this build knows it, has no name — the caller shows its own
/// placeholder rather than an English word in a translated screen.
String? energyLevelLabel(AppLocalizations l10n, String? level) =>
    switch (level) {
      'quiet' => l10n.energyLevelQuiet,
      'soft' => l10n.energyLevelSoft,
      'steady' => l10n.energyLevelSteady,
      'lively' => l10n.energyLevelLively,
      'bright' => l10n.energyLevelBright,
      'radiant' => l10n.energyLevelRadiant,
      'focused' => l10n.energyLevelFocused,
      'flowing' => l10n.energyLevelFlowing,
      _ => null,
    };

// ---------------------------------------------------------------------------
// Colours
// ---------------------------------------------------------------------------

/// The editorial name for one of the engine's twenty shades, by its stable
/// key. The key and the hex are the engine's and never change; only the name
/// does. A key this build does not know falls back to the name the engine
/// sent, which is the only honest answer available.
String dailyColorName(AppLocalizations l10n, engine.DailyColor color) =>
    switch (color.key) {
      'cedar' => l10n.colorCedar,
      'jade' => l10n.colorJade,
      'sage' => l10n.colorSage,
      'mint' => l10n.colorMint,
      'ember' => l10n.colorEmber,
      'solar_coral' => l10n.colorSolarCoral,
      'rose' => l10n.colorRose,
      'blossom' => l10n.colorBlossom,
      'ochre' => l10n.colorOchre,
      'amber' => l10n.colorAmber,
      'sand' => l10n.colorSand,
      'clay' => l10n.colorClay,
      'silver' => l10n.colorSilver,
      'steel' => l10n.colorSteel,
      'pearl' => l10n.colorPearl,
      'champagne' => l10n.colorChampagne,
      'ocean_blue' => l10n.colorOceanBlue,
      'azure' => l10n.colorAzure,
      'indigo' => l10n.colorIndigo,
      'mist_blue' => l10n.colorMistBlue,
      _ => color.name,
    };

// ---------------------------------------------------------------------------
// Zodiac
// ---------------------------------------------------------------------------

String zodiacLabel(AppLocalizations l10n, ZodiacSign sign) => switch (sign) {
  ZodiacSign.aries => l10n.zodiacAries,
  ZodiacSign.taurus => l10n.zodiacTaurus,
  ZodiacSign.gemini => l10n.zodiacGemini,
  ZodiacSign.cancer => l10n.zodiacCancer,
  ZodiacSign.leo => l10n.zodiacLeo,
  ZodiacSign.virgo => l10n.zodiacVirgo,
  ZodiacSign.libra => l10n.zodiacLibra,
  ZodiacSign.scorpio => l10n.zodiacScorpio,
  ZodiacSign.sagittarius => l10n.zodiacSagittarius,
  ZodiacSign.capricorn => l10n.zodiacCapricorn,
  ZodiacSign.aquarius => l10n.zodiacAquarius,
  ZodiacSign.pisces => l10n.zodiacPisces,
};

// ---------------------------------------------------------------------------
// Loading narration and orbit badges
// ---------------------------------------------------------------------------

/// The seven loading lines, in order, with the selected mode's phrase in the
/// place it has always occupied.
List<String> loadingPhrases(AppLocalizations l10n, DecisionMode mode) => [
  l10n.loadingLocalTime,
  l10n.loadingBaZi,
  l10n.loadingZiWei,
  l10n.loadingVedic,
  l10n.loadingNumerology,
  modeLoadingPhrase(l10n, mode),
  l10n.loadingYinYang,
];

/// The welcome screen's four orbit badges.
List<String> welcomeOrbitLabels(AppLocalizations l10n) => [
  l10n.orbitMoment,
  l10n.orbitRhythm,
  l10n.orbitBalance,
  l10n.orbitAlmanac,
];

/// The loading screen's eight orbit badges.
List<String> loadingOrbitLabels(AppLocalizations l10n) => [
  l10n.orbitBaZi,
  l10n.orbitZiWei,
  l10n.orbitAlmanac,
  l10n.orbitVedic,
  l10n.orbitNumerology,
  l10n.orbitLunarPhase,
  l10n.orbitPlanetary,
  l10n.orbitYinYang,
];

// ---------------------------------------------------------------------------
// Numbers, dates and times
// ---------------------------------------------------------------------------

/// A symbolic alignment score, to one decimal, in the reader's own number
/// format. Only the separator changes: the value itself is never rescaled,
/// rounded differently or re-derived per locale.
String formatScore(String localeName, double percent) =>
    NumberFormat.decimalPatternDigits(
      locale: localeName,
      decimalDigits: 1,
    ).format(percent);

/// A whole number — a window's score, or the day's lucky number.
String formatWholeNumber(String localeName, num value) =>
    NumberFormat.decimalPattern(localeName).format(value);

/// A wall-clock time the engine already resolved for the reader's zone, in
/// their own clock convention (24-hour where that is the norm, AM/PM where it
/// is not). The offset is deliberately not re-applied.
String formatClock(String localeName, int hour, int minute) =>
    DateFormat.jm(localeName).format(DateTime(2000, 1, 1, hour, minute));

/// A calendar date, spelled the way the reader's language spells one.
String formatDate(String localeName, DateTime date) =>
    DateFormat.yMMMd(localeName).format(date);

/// The short day-and-month stamp on the Today's signals card.
String formatShortDate(String localeName, DateTime date) =>
    DateFormat.MMMd(localeName).format(date);

// ---------------------------------------------------------------------------
// Profile edit cooldowns
// ---------------------------------------------------------------------------

/// How long a reader still has to wait, in their own language.
///
/// Rounded *up* to the whole minute. A remainder of twelve seconds is still a
/// wait, and rounding it down would print "0 min" beside a field that refuses
/// to open — which reads as a bug rather than as a countdown.
///
/// The numbers go through [formatWholeNumber] rather than `toString`, so a
/// locale that writes its own digits gets them.
String formatEditWait(
  AppLocalizations l10n,
  String localeName,
  Duration remaining,
) {
  final minutes = (remaining.inSeconds / 60).ceil();
  final hours = minutes ~/ 60;
  if (hours == 0) {
    return l10n.profileWaitMinutes(formatWholeNumber(localeName, minutes));
  }
  return l10n.profileWaitHoursMinutes(
    formatWholeNumber(localeName, hours),
    formatWholeNumber(localeName, minutes % 60),
  );
}
