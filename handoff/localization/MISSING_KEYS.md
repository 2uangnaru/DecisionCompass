# Localization key audit

Claude originally generated the list below from `mobile_app/untranslated.json`.
Codex translated all 57 keys on 2026-09-28 and regenerated Flutter localizations.
The current `mobile_app/untranslated.json` is `{}`. The table is retained as an
audit trail, **not** a list of outstanding fallback strings.

**0 keys** currently fall back to English. The 57 rows below were previously
missing in `es`, `hi`, `hi-IN`, `ja`, `th`, `vi`, `zh`, `zh-Hans`, and `zh-Hans-CN`.

The translated values now live in the corresponding `mobile_app/lib/l10n/app_*.arb`
files. This list records the original English source and call site only.

| Key | English source | First call site | Screen |
|---|---|---|---|
| `historyToday` | TODAY | `lib/pages/history_page.dart:229` | History — date group heading |
| `historyCouldNotOpen` | Your readings could not be opened. | `lib/pages/history_page.dart:82` | History — load failure |
| `historyNotEnoughData` | NOT ENOUGH DATA | `lib/pages/history_page.dart:162` | History — row result column |
| `historyPeriodPassed` | PERIOD PASSED | `lib/pages/history_page.dart:164` | History — row result column |
| `colorRoleLead` | Lead | `lib/pages/home_page.dart:501` | Home — colour swatch role |
| `colorRoleSupporting` | Supporting | `lib/pages/home_page.dart:509` | Home — colour swatch role |
| `colorRoleSemantics` | {role} colour, {name} | `lib/pages/home_page.dart:727` | Home — colour swatch screen-reader label |
| `colorRoleUnavailableSemantics` | {role} colour not available yet | `lib/pages/home_page.dart:726` | Home — colour swatch screen-reader label |
| `greetingAfternoon` | Good afternoon, | `lib/pages/home_page.dart:28` | Home — header greeting |
| `greetingEvening` | Good evening, | `lib/pages/home_page.dart:29` | Home — header greeting |
| `greetingMorning` | Good morning, | `lib/pages/home_page.dart:27` | Home — header greeting |
| `energyInsightCoachMark` | A new energy insight awaits here each day. | `lib/widgets/daily_energy_info.dart:245` | Home — one-time coach mark |
| `energyInsightHideTooltip` | Hide what today’s energy means | `lib/widgets/daily_energy_info.dart:269` | Home/Result — ⓘ tooltip |
| `energyInsightNewTooltip` | New energy insight today | `lib/widgets/daily_energy_info.dart:271` | Home/Result — ⓘ tooltip |
| `energyInsightReadTooltip` | Read today’s energy insight | `lib/widgets/daily_energy_info.dart:272` | Home/Result — ⓘ tooltip |
| `errorConfigurationDetail` | Developer build: no calculation service is configured. | `lib/pages/loading_page.dart:356` | Loading — error state |
| `errorConfigurationHeadline` | This build has no reading service configured. | `lib/pages/loading_page.dart:347` | Loading — error state |
| `errorInvalidDetail` | Updating the app should restore readings. | `lib/pages/loading_page.dart:355` | Loading — error state |
| `errorInvalidHeadline` | This app version could not read the result. | `lib/pages/loading_page.dart:346` | Loading — error state |
| `errorNetworkDetail` | Check your connection, then try the reading again. | `lib/pages/loading_page.dart:352` | Loading — error state |
| `errorNetworkHeadline` | The connection slipped out of alignment. | `lib/pages/loading_page.dart:343` | Loading — error state |
| `errorNothingRecorded` | No reading was recorded for this attempt. | `lib/pages/loading_page.dart:425` | Loading — error state |
| `errorRejectedDetail` | Revisit your birth details, then start a new reading. | `lib/pages/loading_page.dart:354` | Loading — error state |
| `errorRejectedHeadline` | Some profile details need attention. | `lib/pages/loading_page.dart:345` | Loading — error state |
| `errorServerDetail` | The service is there but could not finish. Try again in a moment. | `lib/pages/loading_page.dart:353` | Loading — error state |
| `errorServerHeadline` | The reading could not be completed right now. | `lib/pages/loading_page.dart:344` | Loading — error state |
| `searchCountries` | Search countries | `lib/pages/onboarding_page.dart:78` | Onboarding — country picker search field |
| `defaultUserName` | Explorer | `lib/pages/onboarding_page.dart:115` | Onboarding — name left blank |
| `zodiacAquarius` | Aquarius | `lib/localized_presentation.dart:217` | Onboarding/Home — zodiac avatar label |
| `zodiacAries` | Aries | `lib/localized_presentation.dart:207` | Onboarding/Home — zodiac avatar label |
| `zodiacCancer` | Cancer | `lib/localized_presentation.dart:210` | Onboarding/Home — zodiac avatar label |
| `zodiacCapricorn` | Capricorn | `lib/localized_presentation.dart:216` | Onboarding/Home — zodiac avatar label |
| `zodiacGemini` | Gemini | `lib/localized_presentation.dart:209` | Onboarding/Home — zodiac avatar label |
| `zodiacLeo` | Leo | `lib/localized_presentation.dart:211` | Onboarding/Home — zodiac avatar label |
| `zodiacLibra` | Libra | `lib/localized_presentation.dart:213` | Onboarding/Home — zodiac avatar label |
| `zodiacPisces` | Pisces | `lib/localized_presentation.dart:218` | Onboarding/Home — zodiac avatar label |
| `zodiacSagittarius` | Sagittarius | `lib/localized_presentation.dart:215` | Onboarding/Home — zodiac avatar label |
| `zodiacScorpio` | Scorpio | `lib/localized_presentation.dart:214` | Onboarding/Home — zodiac avatar label |
| `zodiacTaurus` | Taurus | `lib/localized_presentation.dart:208` | Onboarding/Home — zodiac avatar label |
| `zodiacVirgo` | Virgo | `lib/localized_presentation.dart:212` | Onboarding/Home — zodiac avatar label |
| `zodiacAvatarSemantics` | {sign} zodiac avatar | `lib/widgets/celestial_ui.dart:111` | Onboarding/Home/Ritual/Loading — avatar screen-reader label |
| `colorsToKeepNear` | Colours to keep near you: {first} and {second} | `lib/pages/result_page.dart:718` | Result — daily brief |
| `colorToKeepNear` | Colour to keep near you: {name} | `lib/pages/result_page.dart:717` | Result — daily brief, older saved snapshot |
| `responsibleUseLink` | Responsible Use & Safety Policy | `lib/pages/result_page.dart:386` | Result — footer link |
| `saveFailedRetry` | Couldn’t save · Retry | `lib/pages/result_page.dart:362` | Result — history save failed |
| `savingToHistory` | Saving to History… | `lib/pages/result_page.dart:364` | Result — history save in progress |
| `insufficientBody` | Your profile does not yet contain enough detail for a direction on this one. Adding your birth time and country of birth gives the cycles more to work with. | `lib/pages/result_page.dart:290` | Result — insufficient_data status |
| `insufficientHeading` | NOT ENOUGH TO READ | `lib/pages/result_page.dart:289` | Result — insufficient_data status |
| `backToHistory` | Back to History | `lib/pages/result_page.dart:360` | Result — opened from History |
| `periodElapsedBody` | That period is already over where you are, so there is no window left to read. Pick a later period, or read your current moment instead — today’s reading is not rolled into tomorrow. | `lib/pages/result_page.dart:299` | Result — period_elapsed status |
| `periodElapsedHeading` | THAT PERIOD HAS PASSED | `lib/pages/result_page.dart:298` | Result — period_elapsed status |
| `shareTooltip` | Share this reading | `lib/pages/result_page.dart:238` | Result — share button |
| `shareUnavailable` | Sharing is unavailable right now. | `lib/pages/result_page.dart:189` | Result — share failure SnackBar |
| `shareDisclaimer` | A symbolic perspective for everyday reflection, not a prediction or probability. | `lib/pages/result_page.dart:428` | Result — shared text |
| `ritualLocked` | Your moment is locked. | `lib/pages/ritual_page.dart:341` | Ritual — after Reveal is tapped |
| `periodPassedShort` | PASSED | `lib/pages/ritual_page.dart:314` | Ritual — reveal circle when the period is over |
| `readingAreaSemantics` | Reading area: {category} | `lib/pages/loading_page.dart:251` | Ritual/Loading/Result — screen-reader label |

## Gaps that are not missing keys

These cannot be closed by adding a string to the pack.

### Country names in Vietnamese, Thai and Hindi

The birth-country picker gets its names from the `country_picker` package,
not from this pack. The package has **no Vietnamese and no Thai list at all**,
and it answers a Hindi locale with its **Nepali** list. Rather than present
Nepali as Hindi, the app reports country names as supported only for `en`,
`es`, `ja` and `zh`; the other three fall back to English country names.

Consequences, both deliberate:

- The birth-country step is a mixed-language screen in `vi`, `th` and `hi-IN`.
  It is the only one, and it must be closed before any of those three ships.
- Flutter prints one debug-mode warning per language switch —
  "This application's locale, th, is not supported by all of its localization
  delegates" — which is that same fact. It does not appear in a release build.

Closing it needs either a country-name list from Codex (about 250 entries per
language, keyed by ISO 3166-1 alpha-2) or a different package. It is not a
copy decision Claude should make alone.

### Not translated on purpose

- `AstraCue` — the brand name stays Latin in every language.
- Engine wire values (`money`, `forward_backward`, `evening`, `radiant`,
  `ocean_blue`), percentages, HEX colours, saved reading snapshots and the
  0-based deck indices. Translating any of these would change a reading.
- `assets/fonts/OFL-*.txt` — licence text, reproduced verbatim as the licence
  requires.

### Needs a native speaker, not a missing key

The whole pack is an editorial draft. Store-release age, privacy and legal
compliance, and native-speaker copy QA, remain separate checks.
