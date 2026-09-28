# -*- coding: utf-8 -*-
"""Regenerates every localization source file the app compiles in.

    python mobile_app/tool/l10n/generate.py            # everything but CLDR
    python mobile_app/tool/l10n/generate.py --countries # also refetch CLDR

Inputs, all owned by Codex, in `handoff/localization/`:

  * `CORE_COPY*.md`, `SELECTOR_AND_TERMS.md`, `LUCKY_TIMES_HEADINGS.md`,
    `LOADING_COPY.md`, `SAFETY_COPY.md`  — pipe tables keyed by a stable id
  * `rotation_<locale>.json`             — 30 Home descriptions + 64 insights
  * `CLAUDE_DRAFT_ONBOARDING.md`         — the four strings Claude drafted

Outputs, all checked in:

  * `mobile_app/lib/l10n/app_*.arb`          — then `flutter gen-l10n`
  * `mobile_app/lib/localized_rotation.dart` — index-to-string lookups
  * `mobile_app/lib/data/country_names_data.dart` — with `--countries`

Nothing here invents a translation, and nothing here deletes one. The pack
owns the keys it supplies; every other key already in an ARB file is carried
over untouched, because Codex translates app-owned strings directly into
those files. `handoff/localization/MISSING_KEYS.md` is Codex's audit trail and
is not generated here.
"""
import collections
import io
import json
import os
import re
import sys
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
APP = os.path.abspath(os.path.join(HERE, '..', '..'))
REPO = os.path.abspath(os.path.join(APP, '..'))
HANDOFF = os.path.join(REPO, 'handoff', 'localization')
L10N = os.path.join(APP, 'lib', 'l10n')

LOCALES = ['en', 'vi', 'ja', 'es', 'th', 'hi_IN', 'zh_Hans_CN']

# gen_l10n insists that a locale carrying a script or country code has a
# base-language file to fall back to. These are exact copies.
BASE_ALIASES = {'hi_IN': ['hi'], 'zh_Hans_CN': ['zh', 'zh_Hans']}

HEADER_TO_LOCALE = {
    'en': 'en', 'english (`en`)': 'en', 'english': 'en',
    'vi': 'vi', 'vietnamese (`vi`)': 'vi', 'vietnamese': 'vi',
    'ja': 'ja', 'japanese (`ja`)': 'ja', 'japanese': 'ja',
    'es': 'es', 'spanish (`es`)': 'es', 'spanish': 'es',
    'th': 'th', 'thai (`th`)': 'th', 'thai': 'th',
    'hi-in': 'hi_IN', 'hindi (`hi-in`)': 'hi_IN', 'hindi': 'hi_IN',
    'zh-hans-cn': 'zh_Hans_CN', 'simplified chinese': 'zh_Hans_CN',
    'simplified chinese (`zh-hans-cn`)': 'zh_Hans_CN',
}

TABLE_FILES = [
    'CORE_COPY.md', 'CORE_COPY_VI.md', 'CORE_COPY_HI_ZH.md',
    'LUCKY_TIMES_HEADINGS.md', 'LOADING_COPY.md', 'SAFETY_COPY.md',
    'CLAUDE_DRAFT_ONBOARDING.md',
]

PLACEHOLDERS = {
    'periodHasPassed': {'period': 'Morning'},
    'readingForCategory': {'category': 'Career'},
}

# App-owned strings the editorial pack does not cover, with the English the
# app ships. These are **seed values only**: a locale that already has its own
# translation for one of them keeps it. Codex translates directly into the ARB
# files, so overwriting them here would delete that work.
# (key, english, where it is shown)
UNTRANSLATED = [
    ('defaultUserName', 'Explorer', 'Home — shown when the name was left blank'),
    ('searchCountries', 'Search countries', 'Onboarding — country picker search field'),
    ('greetingMorning', 'Good morning,', 'Home — header greeting'),
    ('greetingAfternoon', 'Good afternoon,', 'Home — header greeting'),
    ('greetingEvening', 'Good evening,', 'Home — header greeting'),
    ('colorRoleLead', 'Lead', 'Home — colour swatch role'),
    ('colorRoleSupporting', 'Supporting', 'Home — colour swatch role'),
    ('colorRoleSemantics', '{role} colour, {name}', 'Home — colour swatch screen-reader label'),
    ('colorRoleUnavailableSemantics', '{role} colour not available yet', 'Home — colour swatch screen-reader label'),
    ('readingAreaSemantics', 'Reading area: {category}', 'Ritual/Loading/Result — screen-reader label'),
    ('energyInsightNewTooltip', 'New energy insight today', 'Home/Result — ⓘ tooltip'),
    ('energyInsightReadTooltip', 'Read today’s energy insight', 'Home/Result — ⓘ tooltip'),
    ('energyInsightHideTooltip', 'Hide what today’s energy means', 'Home/Result — ⓘ tooltip'),
    ('energyInsightCoachMark', 'A new energy insight awaits here each day.', 'Home — one-time coach mark'),
    ('ritualLocked', 'Your moment is locked.', 'Ritual — after Reveal is tapped'),
    ('periodPassedShort', 'PASSED', 'Ritual — reveal circle when the period is over'),
    ('errorNetworkHeadline', 'The connection slipped out of alignment.', 'Loading — error state'),
    ('errorNetworkDetail', 'Check your connection, then try the reading again.', 'Loading — error state'),
    ('errorServerHeadline', 'The reading could not be completed right now.', 'Loading — error state'),
    ('errorServerDetail', 'The service is there but could not finish. Try again in a moment.', 'Loading — error state'),
    ('errorRejectedHeadline', 'Some profile details need attention.', 'Loading — error state'),
    ('errorRejectedDetail', 'Revisit your birth details, then start a new reading.', 'Loading — error state'),
    ('errorInvalidHeadline', 'This app version could not read the result.', 'Loading — error state'),
    ('errorInvalidDetail', 'Updating the app should restore readings.', 'Loading — error state'),
    ('errorConfigurationHeadline', 'This build has no reading service configured.', 'Loading — error state'),
    ('errorConfigurationDetail', 'Developer build: no calculation service is configured.', 'Loading — error state'),
    ('errorNothingRecorded', 'No reading was recorded for this attempt.', 'Loading — error state'),
    ('insufficientHeading', 'NOT ENOUGH TO READ', 'Result — insufficient_data status'),
    ('insufficientBody', 'Your profile does not yet contain enough detail for a direction on this one. Adding your birth time and country of birth gives the cycles more to work with.', 'Result — insufficient_data status'),
    ('periodElapsedHeading', 'THAT PERIOD HAS PASSED', 'Result — period_elapsed status'),
    ('periodElapsedBody', 'That period is already over where you are, so there is no window left to read. Pick a later period, or read your current moment instead — today’s reading is not rolled into tomorrow.', 'Result — period_elapsed status'),
    ('colorsToKeepNear', 'Colours to keep near you: {first} and {second}', 'Result — daily brief'),
    ('colorToKeepNear', 'Colour to keep near you: {name}', 'Result — daily brief, older saved snapshot'),
    ('shareTooltip', 'Share this reading', 'Result — share button'),
    ('shareUnavailable', 'Sharing is unavailable right now.', 'Result — share failure SnackBar'),
    ('shareDisclaimer', 'A symbolic perspective for everyday reflection, not a prediction or probability.', 'Result — shared text'),
    ('backToHistory', 'Back to History', 'Result — opened from History'),
    ('saveFailedRetry', 'Couldn’t save · Retry', 'Result — history save failed'),
    ('savingToHistory', 'Saving to History…', 'Result — history save in progress'),
    ('responsibleUseLink', 'Responsible Use & Safety Policy', 'Result — footer link'),
    ('historyToday', 'TODAY', 'History — date group heading'),
    ('historyCouldNotOpen', 'Your readings could not be opened.', 'History — load failure'),
    ('historyNotEnoughData', 'NOT ENOUGH DATA', 'History — row result column'),
    ('historyPeriodPassed', 'PERIOD PASSED', 'History — row result column'),
    ('zodiacAries', 'Aries', 'Onboarding/Home — zodiac avatar label'),
    ('zodiacTaurus', 'Taurus', 'Onboarding/Home — zodiac avatar label'),
    ('zodiacGemini', 'Gemini', 'Onboarding/Home — zodiac avatar label'),
    ('zodiacCancer', 'Cancer', 'Onboarding/Home — zodiac avatar label'),
    ('zodiacLeo', 'Leo', 'Onboarding/Home — zodiac avatar label'),
    ('zodiacVirgo', 'Virgo', 'Onboarding/Home — zodiac avatar label'),
    ('zodiacLibra', 'Libra', 'Onboarding/Home — zodiac avatar label'),
    ('zodiacScorpio', 'Scorpio', 'Onboarding/Home — zodiac avatar label'),
    ('zodiacSagittarius', 'Sagittarius', 'Onboarding/Home — zodiac avatar label'),
    ('zodiacCapricorn', 'Capricorn', 'Onboarding/Home — zodiac avatar label'),
    ('zodiacAquarius', 'Aquarius', 'Onboarding/Home — zodiac avatar label'),
    ('zodiacPisces', 'Pisces', 'Onboarding/Home — zodiac avatar label'),
    ('zodiacAvatarSemantics', '{sign} zodiac avatar', 'Onboarding/Home/Ritual/Loading — avatar screen-reader label'),
]

UNTRANSLATED_PLACEHOLDERS = {
    'colorRoleSemantics': {'role': 'Lead', 'name': 'Jade'},
    'colorRoleUnavailableSemantics': {'role': 'Lead'},
    'readingAreaSemantics': {'category': 'Career'},
    'colorsToKeepNear': {'first': 'Jade', 'second': 'Ember'},
    'colorToKeepNear': {'name': 'Jade'},
    'zodiacAvatarSemantics': {'sign': 'Aries'},
}

# Drafted by Claude rather than Codex; see CLAUDE_DRAFT_ONBOARDING.md. Listed
# here so the four are easy to find and replace once Codex has reviewed them.
CLAUDE_DRAFTED = {
    'knowBirthTime', 'knowBirthTimeDetail', 'selectBirthTime',
    'birthTimeRequired',
}

BRACED = re.compile(r'\{(\w+)\}')
ENERGY_LEVELS = ['quiet', 'soft', 'steady', 'lively', 'bright', 'radiant',
                 'focused', 'flowing']


# --------------------------------------------------------------------------
# Reading the handoff
# --------------------------------------------------------------------------

def read(name):
    with io.open(os.path.join(HANDOFF, name), encoding='utf-8') as handle:
        return handle.read()


def tables(text):
    """Yields (header_cells, [row_cells]) for every pipe table in `text`."""
    header = rows = None
    for line in text.splitlines():
        stripped = line.strip()
        if stripped.startswith('|') and stripped.endswith('|'):
            cells = [c.strip() for c in stripped[1:-1].split('|')]
            if header is None:
                header, rows = cells, []
                continue
            if set(''.join(cells)) <= set('-: '):
                continue
            rows.append(cells)
        else:
            if header is not None and rows:
                yield header, rows
            header = rows = None
    if header is not None and rows:
        yield header, rows


def collect(text, rename=lambda k: k, into=None):
    out = into if into is not None else {loc: {} for loc in LOCALES}
    for header, rows in tables(text):
        columns = {}
        for index, cell in enumerate(header):
            if index == 0:
                continue
            locale = HEADER_TO_LOCALE.get(cell.strip().lower())
            if locale:
                columns[index] = locale
        if not columns:
            continue
        for row in rows:
            key = rename(row[0].strip())
            if not key:
                continue
            for index, locale in columns.items():
                if index < len(row) and row[index].strip():
                    out[locale][key] = row[index].strip()
    return out


def camel(snake):
    head, *tail = snake.split('_')
    return head + ''.join(word.capitalize() for word in tail)


def editorial_strings():
    strings = {loc: {} for loc in LOCALES}
    for name in TABLE_FILES:
        collect(read(name), into=strings)

    for header, rows in tables(read('SELECTOR_AND_TERMS.md')):
        first = header[0].strip().lower()
        if first == 'key':
            rename = lambda k: k  # noqa: E731
        elif first == 'stable choice':
            rename = lambda k: 'choice' + camel(k)[0].upper() + camel(k)[1:]  # noqa: E731
        elif first == 'engine level':
            rename = lambda k: 'energyLevel' + k.capitalize()  # noqa: E731
        elif first == 'color key':
            rename = lambda k: 'color' + ''.join(w.capitalize() for w in k.split('_'))  # noqa: E731
        else:
            continue
        chunk = '\n'.join(
            ['|' + '|'.join(header) + '|',
             '|' + '|'.join('---' for _ in header) + '|'] +
            ['|' + '|'.join(r) + '|' for r in rows])
        collect(chunk, rename=rename, into=strings)

    for locale in LOCALES:
        path = os.path.join(HANDOFF, 'rotation_%s.json' % locale)
        with io.open(path, encoding='utf-8') as handle:
            strings[locale].update(json.load(handle))
    return strings


# --------------------------------------------------------------------------
# Writing the ARB files
# --------------------------------------------------------------------------

def existing_arb(name):
    """What `app_<name>.arb` holds today, or {} the first time."""
    path = os.path.join(L10N, 'app_%s.arb' % name)
    if not os.path.exists(path):
        return {}
    with io.open(path, encoding='utf-8') as handle:
        return json.load(handle)


def write_arb():
    strings = editorial_strings()
    english_only = collections.OrderedDict((k, v) for k, v, _ in UNTRANSLATED)
    for key in english_only:
        assert key not in strings['en'], 'duplicate key %s' % key

    ordered = list(strings['en']) + list(english_only)
    for locale in LOCALES:
        current = existing_arb(locale)
        doc = collections.OrderedDict()
        doc['@@locale'] = locale
        source = dict(strings[locale])
        # The pack owns its own keys. Everything else — the app-owned strings,
        # whether still English or since translated by Codex — is carried over
        # from the file as it stands, so regenerating never loses a
        # translation this script did not write.
        for key, value in current.items():
            if key.startswith('@') or key in strings['en']:
                continue
            source.setdefault(key, value)
        if locale == 'en':
            for key, value in english_only.items():
                source.setdefault(key, value)
        for key in ordered:
            if key not in source:
                continue
            doc[key] = source[key]
            if locale != 'en':
                continue
            placeholders = (PLACEHOLDERS.get(key) or
                            UNTRANSLATED_PLACEHOLDERS.get(key))
            found = set(BRACED.findall(source[key]))
            assert set(placeholders or {}) == found, (key, found, placeholders)
            if placeholders:
                doc['@' + key] = {'placeholders': {
                    name: {'type': 'String', 'example': example}
                    for name, example in placeholders.items()}}
        if locale != 'en':
            for key, placeholders in PLACEHOLDERS.items():
                if key in doc:
                    assert set(BRACED.findall(doc[key])) == set(placeholders), \
                        (locale, key)
        # Anything the file had that this script does not know about at all
        # stays, at the end, rather than being dropped.
        for key, value in current.items():
            if key.startswith('@') or key in doc:
                continue
            doc[key] = value

        for name in [locale] + BASE_ALIASES.get(locale, []):
            copy = collections.OrderedDict(doc)
            copy['@@locale'] = name
            path = os.path.join(L10N, 'app_%s.arb' % name)
            with io.open(path, 'w', encoding='utf-8', newline='\n') as handle:
                handle.write(json.dumps(copy, ensure_ascii=False, indent=2))
                handle.write('\n')
    print('wrote %d ARB files' % (len(LOCALES) + 3))


# --------------------------------------------------------------------------
# Writing the rotation lookups
# --------------------------------------------------------------------------

ROTATION = '''// GENERATED-STYLE LOOKUPS — edit the ARB files, not the cases below.
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
%s
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
%s
    _ => null,
  };
}
'''


def write_rotation():
    home = '\n'.join('    %d => l10n.homeDescription%02d,' % (i, i)
                     for i in range(30))
    energy = '\n'.join(
        "    '%s.%d' => l10n.energy%s%02d," % (level, i, level.capitalize(), i)
        for level in ENERGY_LEVELS for i in range(8))
    path = os.path.join(APP, 'lib', 'localized_rotation.dart')
    with io.open(path, 'w', encoding='utf-8', newline='\n') as handle:
        handle.write(ROTATION % (home, energy))
    print('wrote localized_rotation.dart')


# --------------------------------------------------------------------------
# Writing the bundled country names
# --------------------------------------------------------------------------

CLDR = ('https://raw.githubusercontent.com/unicode-org/cldr-json/main/'
        'cldr-json/cldr-localenames-full/main/%s/territories.json')
CLDR_LOCALES = [('VI', 'vi', 'Vietnamese'), ('TH', 'th', 'Thai'),
                ('HI', 'hi', 'Hindi')]


def picker_codes():
    """Every ISO 3166-1 alpha-2 code `country_picker` offers."""
    root = os.path.expanduser('~/AppData/Local/Pub/Cache/hosted/pub.dev')
    package = None
    for name in sorted(os.listdir(root)):
        if name.startswith('country_picker-'):
            package = os.path.join(root, name)
    assert package, 'country_picker is not in the pub cache; run pub get'
    path = os.path.join(package, 'lib', 'src', 'res', 'country_codes.dart')
    with io.open(path, encoding='utf-8') as handle:
        return sorted(set(re.findall(r'"iso2_cc"\s*:\s*"([A-Z]{2})"',
                                     handle.read())))


def write_country_names():
    codes = picker_codes()
    lines = [
        '// GENERATED from Unicode CLDR — do not edit by hand.',
        '//',
        '// Run: python mobile_app/tool/l10n/generate.py --countries',
        '//',
        '// Territory display names for the three languages `country_picker`',
        '// cannot serve: it has no Vietnamese or Thai list at all, and answers',
        '// a Hindi locale with its Nepali one. CLDR is the same data ICU,',
        '// Android and iOS use, so a country reads here the way it reads',
        "// everywhere else on the reader's phone.",
        '//',
        '// Source: unicode-org/cldr-json, cldr-localenames-full.',
        '// Unicode License V3 — see assets/licenses/UNICODE-LICENSE.txt.',
        'library;',
        '',
    ]
    for suffix, tag, english in CLDR_LOCALES:
        with urllib.request.urlopen(CLDR % tag, timeout=60) as response:
            data = json.load(response)
        main = data['main'][tag]['localeDisplayNames']['territories']
        # CLDR carries alternates such as `US-alt-short`; the plain key is the
        # everyday name, which is what a picker should show.
        names = {k: v for k, v in main.items() if '-alt-' not in k}
        missing = [c for c in codes if c not in names]
        assert not missing, 'CLDR %s is missing %s' % (tag, missing)
        lines.append('/// ISO 3166-1 alpha-2 to the %s name.' % english)
        lines.append('const countryNames%s = <String, String>{' % suffix)
        for code in codes:
            lines.append("  '%s': '%s'," % (code, names[code].replace("'", r"\'")))
        lines.append('};')
        lines.append('')
    path = os.path.join(APP, 'lib', 'data', 'country_names_data.dart')
    with io.open(path, 'w', encoding='utf-8', newline='\n') as handle:
        handle.write('\n'.join(lines))
    print('wrote country_names_data.dart (%d codes x 3)' % len(codes))


# --------------------------------------------------------------------------
# Writing the missing-key manifest
# --------------------------------------------------------------------------

if __name__ == '__main__':
    if '--countries' in sys.argv:
        write_country_names()
    write_arb()
    write_rotation()
    print('\nnow run: flutter gen-l10n')
