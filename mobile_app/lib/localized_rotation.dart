// GENERATED-STYLE LOOKUPS — edit the ARB files, not the cases below.
//
// The decks persist a 0-based index, never a sentence: switching language has
// to show the *translation of the same sentence*, without reshuffling and
// without touching a saved reading. These two functions are the only place an
// index becomes text.
library;

import 'daily_energy_messages.dart';
import 'home_descriptions.dart';
import 'l10n/app_localizations.dart';

/// The Home description the deck dealt for a day, in the current language.
///
/// [index] comes from the saved deck, which validates it against
/// [homeDescriptions] before it can be stored, so the fallback below is
/// unreachable in a sound record — it exists so a damaged one cannot take the
/// screen down.
String homeDescriptionAt(AppLocalizations l10n, int index) {
  assert(index >= 0 && index < homeDescriptions.length);
  return switch (index) {
    0 => l10n.homeDescription00,
    1 => l10n.homeDescription01,
    2 => l10n.homeDescription02,
    3 => l10n.homeDescription03,
    4 => l10n.homeDescription04,
    5 => l10n.homeDescription05,
    6 => l10n.homeDescription06,
    7 => l10n.homeDescription07,
    8 => l10n.homeDescription08,
    9 => l10n.homeDescription09,
    10 => l10n.homeDescription10,
    11 => l10n.homeDescription11,
    12 => l10n.homeDescription12,
    13 => l10n.homeDescription13,
    14 => l10n.homeDescription14,
    15 => l10n.homeDescription15,
    16 => l10n.homeDescription16,
    17 => l10n.homeDescription17,
    18 => l10n.homeDescription18,
    19 => l10n.homeDescription19,
    20 => l10n.homeDescription20,
    21 => l10n.homeDescription21,
    22 => l10n.homeDescription22,
    23 => l10n.homeDescription23,
    24 => l10n.homeDescription24,
    25 => l10n.homeDescription25,
    26 => l10n.homeDescription26,
    27 => l10n.homeDescription27,
    28 => l10n.homeDescription28,
    29 => l10n.homeDescription29,
    _ => l10n.homeDescription00,
  };
}

/// The insight dealt for a tone and index, in the current language.
///
/// The engine owns [level]; this only resolves the sentence the deck already
/// chose. A tone this build does not know returns null, so the caller can
/// withhold the ⓘ rather than show an apology.
String? dailyEnergyInsightAt(AppLocalizations l10n, String level, int index) {
  assert(index >= 0 && index < dailyEnergyPoolSize);
  return switch ('$level.$index') {
    'quiet.0' => l10n.energyQuiet00,
    'quiet.1' => l10n.energyQuiet01,
    'quiet.2' => l10n.energyQuiet02,
    'quiet.3' => l10n.energyQuiet03,
    'quiet.4' => l10n.energyQuiet04,
    'quiet.5' => l10n.energyQuiet05,
    'quiet.6' => l10n.energyQuiet06,
    'quiet.7' => l10n.energyQuiet07,
    'soft.0' => l10n.energySoft00,
    'soft.1' => l10n.energySoft01,
    'soft.2' => l10n.energySoft02,
    'soft.3' => l10n.energySoft03,
    'soft.4' => l10n.energySoft04,
    'soft.5' => l10n.energySoft05,
    'soft.6' => l10n.energySoft06,
    'soft.7' => l10n.energySoft07,
    'steady.0' => l10n.energySteady00,
    'steady.1' => l10n.energySteady01,
    'steady.2' => l10n.energySteady02,
    'steady.3' => l10n.energySteady03,
    'steady.4' => l10n.energySteady04,
    'steady.5' => l10n.energySteady05,
    'steady.6' => l10n.energySteady06,
    'steady.7' => l10n.energySteady07,
    'lively.0' => l10n.energyLively00,
    'lively.1' => l10n.energyLively01,
    'lively.2' => l10n.energyLively02,
    'lively.3' => l10n.energyLively03,
    'lively.4' => l10n.energyLively04,
    'lively.5' => l10n.energyLively05,
    'lively.6' => l10n.energyLively06,
    'lively.7' => l10n.energyLively07,
    'bright.0' => l10n.energyBright00,
    'bright.1' => l10n.energyBright01,
    'bright.2' => l10n.energyBright02,
    'bright.3' => l10n.energyBright03,
    'bright.4' => l10n.energyBright04,
    'bright.5' => l10n.energyBright05,
    'bright.6' => l10n.energyBright06,
    'bright.7' => l10n.energyBright07,
    'radiant.0' => l10n.energyRadiant00,
    'radiant.1' => l10n.energyRadiant01,
    'radiant.2' => l10n.energyRadiant02,
    'radiant.3' => l10n.energyRadiant03,
    'radiant.4' => l10n.energyRadiant04,
    'radiant.5' => l10n.energyRadiant05,
    'radiant.6' => l10n.energyRadiant06,
    'radiant.7' => l10n.energyRadiant07,
    'focused.0' => l10n.energyFocused00,
    'focused.1' => l10n.energyFocused01,
    'focused.2' => l10n.energyFocused02,
    'focused.3' => l10n.energyFocused03,
    'focused.4' => l10n.energyFocused04,
    'focused.5' => l10n.energyFocused05,
    'focused.6' => l10n.energyFocused06,
    'focused.7' => l10n.energyFocused07,
    'flowing.0' => l10n.energyFlowing00,
    'flowing.1' => l10n.energyFlowing01,
    'flowing.2' => l10n.energyFlowing02,
    'flowing.3' => l10n.energyFlowing03,
    'flowing.4' => l10n.energyFlowing04,
    'flowing.5' => l10n.energyFlowing05,
    'flowing.6' => l10n.energyFlowing06,
    'flowing.7' => l10n.energyFlowing07,
    _ => null,
  };
}
