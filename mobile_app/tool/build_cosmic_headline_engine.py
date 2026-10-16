# -*- coding: utf-8 -*-
"""
Validation and Builder script for CosmicHeadlineComposer in Dart.
Generates mobile_app/lib/data/action_guidance/cosmic_headline_composer.dart
Includes Smart Cultural Adaptor for English (Eastern Heritage & Vedic Heritage).
"""
import sys
import os
import re

sys.stdout.reconfigure(encoding='utf-8')

from cosmic_data_vi import VI_CONTEXTS, VI_MECHANISMS, VI_NEW_MODES_GUIDANCE
from cosmic_data_en_es import (
    EN_CONTEXTS, EN_MECHANISMS, EN_NEW_MODES_GUIDANCE,
    ES_CONTEXTS, ES_MECHANISMS, ES_NEW_MODES_GUIDANCE
)
from cosmic_data_east_asia import (
    ZH_CONTEXTS, ZH_MECHANISMS, ZH_NEW_MODES_GUIDANCE,
    JA_CONTEXTS, JA_MECHANISMS, JA_NEW_MODES_GUIDANCE,
    KO_CONTEXTS, KO_MECHANISMS, KO_NEW_MODES_GUIDANCE
)
from cosmic_data_south_asia import (
    TH_CONTEXTS, TH_MECHANISMS, TH_NEW_MODES_GUIDANCE,
    HI_CONTEXTS, HI_MECHANISMS, HI_NEW_MODES_GUIDANCE
)
from cosmic_data_en_heritage import (
    EN_EASTERN_HERITAGE_MECHANISMS,
    EN_VEDIC_HERITAGE_MECHANISMS
)

LOCALES = {
    'vietnamese': {
        'contexts': VI_CONTEXTS,
        'mechanisms': VI_MECHANISMS,
        'new_modes': VI_NEW_MODES_GUIDANCE,
        'sep': '; ',
        'forbidden': ['đầu tư', 'tiền', 'lương', 'vay', 'lợi nhuận', 'mua', 'bán', 'chia tay', 'ly hôn', 'nghỉ việc', 'người yêu', 'kết hôn'],
        'overclaims': ['hợp nhịp nhất', 'tốt nhất'],
    },
    'english': {
        'contexts': EN_CONTEXTS,
        'mechanisms': EN_MECHANISMS,
        'new_modes': EN_NEW_MODES_GUIDANCE,
        'sep': '; ',
        'forbidden': ['invest', 'money', 'salary', 'loan', 'profit', 'buy', 'sell', 'pay', 'relationship', 'partner', 'break up', 'walk away', 'leave them', 'quit', 'resign', 'marry', 'divorce'],
        'overclaims': ['most aligned', 'more aligned', 'best moment', 'reads as the most'],
    },
    'spanish': {
        'contexts': ES_CONTEXTS,
        'mechanisms': ES_MECHANISMS,
        'new_modes': ES_NEW_MODES_GUIDANCE,
        'sep': '; ',
        'forbidden': ['invertir', 'dinero', 'sueldo', 'préstamo', 'comprar', 'vender', 'relación', 'pareja', 'romper', 'renunciar', 'casarte', 'divorcio'],
        'overclaims': ['más alineado', 'mejor momento'],
    },
    'simplifiedChinese': {
        'contexts': ZH_CONTEXTS,
        'mechanisms': ZH_MECHANISMS,
        'new_modes': ZH_NEW_MODES_GUIDANCE,
        'sep': '；',
        'forbidden': ['投资', '钱', '工资', '贷款', '买', '卖', '恋人', '分手', '离婚', '辞职', '结婚'],
        'overclaims': ['最契合', '最好的时机'],
    },
    'japanese': {
        'contexts': JA_CONTEXTS,
        'mechanisms': JA_MECHANISMS,
        'new_modes': JA_NEW_MODES_GUIDANCE,
        'sep': '、',
        'forbidden': ['投資', 'お金', '給料', '借金', '買う', '売る', '恋人', '別れ', '離婚', '退職', '結婚'],
        'overclaims': ['最も調和', '最善の瞬間'],
    },
    'korean': {
        'contexts': KO_CONTEXTS,
        'mechanisms': KO_MECHANISMS,
        'new_modes': KO_NEW_MODES_GUIDANCE,
        'sep': ', ',
        'forbidden': ['투자', '돈', '급여', '대출', '구매', '사다', '팔다', '연인', '결혼', '이혼', '퇴사', '헤어지'],
        'overclaims': ['가장 부합', '가장 좋은 순간'],
    },
    'thai': {
        'contexts': TH_CONTEXTS,
        'mechanisms': TH_MECHANISMS,
        'new_modes': TH_NEW_MODES_GUIDANCE,
        'sep': ' ',
        'forbidden': ['ลงทุน', 'เงิน', 'เงินเดือน', 'กู้', 'ซื้อ', 'ขาย', 'แฟน', 'เลิกกัน', 'หย่า', 'ลาออก', 'แต่งงาน'],
        'overclaims': ['สอดคล้องที่สุด', 'ช่วงเวลาที่ดีที่สุด'],
    },
    'hindi': {
        'contexts': HI_CONTEXTS,
        'mechanisms': HI_MECHANISMS,
        'new_modes': HI_NEW_MODES_GUIDANCE,
        'sep': '; ',
        'forbidden': ['निवेश', 'पैसा', 'वेतन', 'कर्ज', 'खरीद', 'बेचें', 'बेचना', 'रिश्ता', 'साथी', 'तलाक', 'नौकरी छोड़', 'शादी'],
        'overclaims': ['सबसे अनुकूल', 'सर्वश्रेष्ठ समय'],
    },
}

CATEGORIES = ['career', 'love', 'money', 'study', 'friends', 'general', 'other']
PERIODS = ['morning', 'midday', 'afternoon', 'evening', 'now']
MODES = [
    'yes_no', 'act_wait', 'advance_retreat', 'stay_go',
    'keep_let_go', 'commit_withdraw', 'left_right',
    'reason_emotion', 'confront_avoid'
]
SIDES = ['first', 'second']

print("=== STARTING COMPREHENSIVE VALIDATION ===")
all_clean = True

# Standard Locales Validation
for loc_name, loc_data in LOCALES.items():
    contexts = loc_data['contexts']
    mechanisms = loc_data['mechanisms']
    new_modes = loc_data['new_modes']
    sep = loc_data['sep']
    forbidden = loc_data['forbidden']
    overclaims = loc_data['overclaims']

    # 1. Count checks
    if len(contexts) != 35:
        print(f"[{loc_name}] ERROR: expected 35 contexts, got {len(contexts)}")
        all_clean = False
    if len(mechanisms) != 57:
        print(f"[{loc_name}] ERROR: expected 57 mechanisms, got {len(mechanisms)}")
        all_clean = False
    if len(new_modes) != 4:
        print(f"[{loc_name}] ERROR: expected 4 new_modes, got {len(new_modes)}")
        all_clean = False

    # 2. Distinctness check
    unique_contexts = set(contexts.values())
    if len(unique_contexts) != 35:
        print(f"[{loc_name}] ERROR: contexts have duplicates: {len(unique_contexts)}/35")
        all_clean = False

    unique_mechanisms = set(mechanisms.values())
    if len(unique_mechanisms) != 57:
        print(f"[{loc_name}] ERROR: mechanisms have duplicates: {len(unique_mechanisms)}/57")
        all_clean = False

    # 3. Forbidden words check
    for key, text in contexts.items():
        text_lower = text.lower()
        for f in forbidden:
            if f.lower() in text_lower:
                print(f"[{loc_name}] FORBIDDEN in context {key}: '{f}' in '{text}'")
                all_clean = False
        for oc in overclaims:
            if oc.lower() in text_lower:
                print(f"[{loc_name}] OVERCLAIM in context {key}: '{oc}' in '{text}'")
                all_clean = False
        if '%' in text or any(char.isdigit() for char in text):
            print(f"[{loc_name}] DIGIT/PERCENT in context {key}: '{text}'")
            all_clean = False

    for key, text in mechanisms.items():
        text_lower = text.lower()
        for f in forbidden:
            if f.lower() in text_lower:
                print(f"[{loc_name}] FORBIDDEN in mechanism {key}: '{f}' in '{text}'")
                all_clean = False
        for oc in overclaims:
            if oc.lower() in text_lower:
                print(f"[{loc_name}] OVERCLAIM in mechanism {key}: '{oc}' in '{text}'")
                all_clean = False
        if '%' in text or any(char.isdigit() for char in text):
            print(f"[{loc_name}] DIGIT/PERCENT in mechanism {key}: '{text}'")
            all_clean = False

    for key, (should_do, avoid) in new_modes.items():
        for t, label in [(should_do, 'shouldDo'), (avoid, 'avoid')]:
            t_lower = t.lower()
            for f in forbidden:
                if f.lower() in t_lower:
                    print(f"[{loc_name}] FORBIDDEN in new_mode {key} {label}: '{f}' in '{t}'")
                    all_clean = False

    # 4. Language specific test constraints
    if loc_name == 'vietnamese':
        for cat in CATEGORIES:
            m_text = contexts[(cat, 'morning')].lower()
            if 'sáng' not in m_text:
                print(f"[vietnamese] ERROR: morning context for {cat} missing 'sáng'")
                all_clean = False
            a_text = contexts[(cat, 'afternoon')].lower()
            if 'chiều' not in a_text:
                print(f"[vietnamese] ERROR: afternoon context for {cat} missing 'chiều'")
                all_clean = False
            e_text = contexts[(cat, 'evening')].lower()
            if 'tối' not in e_text:
                print(f"[vietnamese] ERROR: evening context for {cat} missing 'tối'")
                all_clean = False

    if loc_name == 'english':
        for cat in CATEGORIES:
            m_text = contexts[(cat, 'morning')].lower()
            if 'morning' not in m_text:
                print(f"[english] ERROR: morning context for {cat} missing 'morning'")
                all_clean = False
            a_text = contexts[(cat, 'afternoon')].lower()
            if 'afternoon' not in a_text:
                print(f"[english] ERROR: afternoon context for {cat} missing 'afternoon'")
                all_clean = False
            e_text = contexts[(cat, 'evening')].lower()
            if 'evening' not in e_text:
                print(f"[english] ERROR: evening context for {cat} missing 'evening'")
                all_clean = False

        for v in range(3):
            aw_first = mechanisms[('act_wait', 'first', v)].lower()
            if 'leans toward acting' not in aw_first:
                print(f"[english] ERROR: act_wait:first:v{v} missing 'leans toward acting'")
                all_clean = False
            if 'timing' not in aw_first:
                print(f"[english] ERROR: act_wait:first:v{v} missing 'timing'")
                all_clean = False
            if 'everything else' not in aw_first:
                print(f"[english] ERROR: act_wait:first:v{v} missing 'everything else'")
                all_clean = False

    # 5. Duplication test for full combinations
    composed_set = set()
    total_combinations = 0
    for (cat, per), ctx in contexts.items():
        for m in MODES:
            for s in SIDES:
                for v in range(3):
                    mech = mechanisms[(m, s, v)]
                    full = f"{ctx}{sep}{mech}"
                    composed_set.add(full)
                    total_combinations += 1
        for v in range(3):
            mech = mechanisms[('balanced', 'balanced', v)]
            full = f"{ctx}{sep}{mech}"
            composed_set.add(full)
            total_combinations += 1

    if len(composed_set) != total_combinations:
        print(f"[{loc_name}] ERROR: Composed set has collisions! {len(composed_set)} != {total_combinations}")
        all_clean = False
    else:
        print(f"[{loc_name}] OK: 100% UNIQUE! All {total_combinations} combinations are distinct.")

# Validate Heritage English datasets
print("\n--- Validating Heritage English datasets ---")
heritage_datasets = {
    'english_eastern_heritage': EN_EASTERN_HERITAGE_MECHANISMS,
    'english_vedic_heritage': EN_VEDIC_HERITAGE_MECHANISMS,
}
en_forbidden = LOCALES['english']['forbidden']
en_overclaims = LOCALES['english']['overclaims']

for h_name, h_mechanisms in heritage_datasets.items():
    if len(h_mechanisms) != 57:
        print(f"[{h_name}] ERROR: expected 57 mechanisms, got {len(h_mechanisms)}")
        all_clean = False

    unique_h = set(h_mechanisms.values())
    if len(unique_h) != 57:
        print(f"[{h_name}] ERROR: duplicates in mechanisms: {len(unique_h)}/57")
        all_clean = False

    for key, text in h_mechanisms.items():
        text_lower = text.lower()
        for f in en_forbidden:
            if f.lower() in text_lower:
                print(f"[{h_name}] FORBIDDEN in {key}: '{f}' in '{text}'")
                all_clean = False
        for oc in en_overclaims:
            if oc.lower() in text_lower:
                print(f"[{h_name}] OVERCLAIM in {key}: '{oc}' in '{text}'")
                all_clean = False
        if '%' in text or any(char.isdigit() for char in text):
            print(f"[{h_name}] DIGIT/PERCENT in {key}: '{text}'")
            all_clean = False

    for v in range(3):
        aw_first = h_mechanisms[('act_wait', 'first', v)].lower()
        if 'leans toward acting' not in aw_first:
            print(f"[{h_name}] ERROR: act_wait:first:v{v} missing 'leans toward acting'")
            all_clean = False
        if 'timing' not in aw_first:
            print(f"[{h_name}] ERROR: act_wait:first:v{v} missing 'timing'")
            all_clean = False
        if 'everything else' not in aw_first:
            print(f"[{h_name}] ERROR: act_wait:first:v{v} missing 'everything else'")
            all_clean = False

    # Combinations distinctness with EN_CONTEXTS
    h_composed = set()
    h_total = 0
    for (cat, per), ctx in EN_CONTEXTS.items():
        for m in MODES:
            for s in SIDES:
                for v in range(3):
                    mech = h_mechanisms[(m, s, v)]
                    h_composed.add(f"{ctx}; {mech}")
                    h_total += 1
        for v in range(3):
            mech = h_mechanisms[('balanced', 'balanced', v)]
            h_composed.add(f"{ctx}; {mech}")
            h_total += 1

    if len(h_composed) != h_total:
        print(f"[{h_name}] ERROR: collisions in composed set: {len(h_composed)} != {h_total}")
        all_clean = False
    else:
        print(f"[{h_name}] OK: 100% UNIQUE! All {h_total} combinations are distinct.")

if not all_clean:
    print("VALIDATION FAILED! Aborting code generation.")
    sys.exit(1)

print("\n=== ALL DATASETS PASSED VALIDATION PERFECTLY! ===")
print("Generating mobile_app/lib/data/action_guidance/cosmic_headline_composer.dart ...")

def escape_dart_str(s):
    return s.replace('\\', '\\\\').replace("'", "\\'").replace('$', '\\$')

lines = []
lines.append("// GENERATED FILE - DO NOT EDIT MANUALLY")
lines.append("// Cosmic Headline Composer across 8 languages with Smart Cultural Adaptor")
lines.append("// Cultural zones: Western (en, es), East Asian (vi, zh, ja, ko), South/SE Asian (th, hi)")
lines.append("")
lines.append("import '../../app_locale.dart';")
lines.append("import '../models/models.dart';")
lines.append("")
lines.append("/// Lean direction of the decision reading.")
lines.append("enum CosmicLean { first, second, balanced }")
lines.append("")
lines.append("/// Composes the unified cosmic headline directly combining")
lines.append("/// the cultural context lens [Category x Period] with the planetary mechanism [Mode x Side x Variant].")
lines.append("/// When [locale] is English, [birthCountryCode] is used by the Smart Cultural Adaptor")
lines.append("/// to tailor the philosophical resonance (Eastern Heritage, Vedic Cosmic, or Western Classical).")
lines.append("String composeCosmicHeadline({")
lines.append("  required AppLocale locale,")
lines.append("  required ReadingCategory category,")
lines.append("  required TimePeriod period,")
lines.append("  required DecisionMode mode,")
lines.append("  required CosmicLean lean,")
lines.append("  required int variant,")
lines.append("  String? birthCountryCode,")
lines.append("}) {")
lines.append("  final catKey = category.wireValue;")
lines.append("  final perKey = period.wireValue;")
lines.append("  final modKey = (lean == CosmicLean.balanced || mode.legacy) ? 'balanced' : mode.wireValue;")
lines.append("  final sideKey = (lean == CosmicLean.balanced || mode.legacy)")
lines.append("      ? 'balanced'")
lines.append("      : (lean == CosmicLean.first ? 'first' : 'second');")
lines.append("  final v = variant % 3;")
lines.append("")
lines.append("  final ctxTable = _contextTableFor(locale);")
lines.append("  final mechTable = _mechanismTableFor(locale, birthCountryCode);")
lines.append("  final sep = _separatorFor(locale);")
lines.append("")
lines.append("  final contextClause = ctxTable['$catKey:$perKey'] ?? ctxTable['general:now']!;")
lines.append("  final mechanismClause = mechTable['$modKey:$sideKey:$v'] ??")
lines.append("      mechTable['balanced:balanced:$v'] ??")
lines.append("      mechTable['balanced:balanced:0']!;")
lines.append("")
lines.append("  return '$contextClause$sep$mechanismClause';")
lines.append("}")
lines.append("")
lines.append("/// Returns dedicated (shouldDo, avoid) for new modes: reasonEmotion & confrontAvoid.")
lines.append("(String, String)? getDedicatedNewModeGuidance({")
lines.append("  required AppLocale locale,")
lines.append("  required DecisionMode mode,")
lines.append("  required CosmicLean lean,")
lines.append("}) {")
lines.append("  if (lean == CosmicLean.balanced) return null;")
lines.append("  final sideKey = lean == CosmicLean.first ? 'first' : 'second';")
lines.append("  final key = '${mode.wireValue}:$sideKey';")
lines.append("  final table = _newModesGuidanceFor(locale);")
lines.append("  return table[key];")
lines.append("}")
lines.append("")

# Separator function
lines.append("String _separatorFor(AppLocale locale) => switch (locale) {")
lines.append("  AppLocale.vietnamese => '; ',")
lines.append("  AppLocale.english => '; ',")
lines.append("  AppLocale.spanish => '; ',")
lines.append("  AppLocale.simplifiedChinese => '；',")
lines.append("  AppLocale.japanese => '、',")
lines.append("  AppLocale.korean => ', ',")
lines.append("  AppLocale.thai => ' ',")
lines.append("  AppLocale.hindi => '; ',")
lines.append("};")
lines.append("")

# Context table selector
lines.append("Map<String, String> _contextTableFor(AppLocale locale) => switch (locale) {")
lines.append("  AppLocale.vietnamese => _viContexts,")
lines.append("  AppLocale.english => _enContexts,")
lines.append("  AppLocale.spanish => _esContexts,")
lines.append("  AppLocale.simplifiedChinese => _zhContexts,")
lines.append("  AppLocale.japanese => _jaContexts,")
lines.append("  AppLocale.korean => _koContexts,")
lines.append("  AppLocale.thai => _thContexts,")
lines.append("  AppLocale.hindi => _hiContexts,")
lines.append("};")
lines.append("")

# Mechanism table selector with Smart Cultural Adaptor for English
lines.append("Map<String, String> _mechanismTableFor(AppLocale locale, String? birthCountryCode) => switch (locale) {")
lines.append("  AppLocale.vietnamese => _viMechanisms,")
lines.append("  AppLocale.english => _selectEnglishMechanisms(birthCountryCode),")
lines.append("  AppLocale.spanish => _esMechanisms,")
lines.append("  AppLocale.simplifiedChinese => _zhMechanisms,")
lines.append("  AppLocale.japanese => _jaMechanisms,")
lines.append("  AppLocale.korean => _koMechanisms,")
lines.append("  AppLocale.thai => _thMechanisms,")
lines.append("  AppLocale.hindi => _hiMechanisms,")
lines.append("};")
lines.append("")

lines.append("Map<String, String> _selectEnglishMechanisms(String? countryCode) {")
lines.append("  if (countryCode == null) return _enMechanisms;")
lines.append("  final code = countryCode.trim().toUpperCase();")
lines.append("  const easternCodes = {'VN', 'CN', 'JP', 'KR', 'TW', 'SG', 'HK', 'MO'};")
lines.append("  const vedicCodes = {'IN', 'NP', 'LK', 'BD', 'PK', 'BT'};")
lines.append("  if (easternCodes.contains(code)) return _enEasternHeritageMechanisms;")
lines.append("  if (vedicCodes.contains(code)) return _enVedicHeritageMechanisms;")
lines.append("  return _enMechanisms;")
lines.append("}")
lines.append("")

# New modes guidance selector
lines.append("Map<String, (String, String)> _newModesGuidanceFor(AppLocale locale) => switch (locale) {")
lines.append("  AppLocale.vietnamese => _viNewModes,")
lines.append("  AppLocale.english => _enNewModes,")
lines.append("  AppLocale.spanish => _esNewModes,")
lines.append("  AppLocale.simplifiedChinese => _zhNewModes,")
lines.append("  AppLocale.japanese => _jaNewModes,")
lines.append("  AppLocale.korean => _koNewModes,")
lines.append("  AppLocale.thai => _thNewModes,")
lines.append("  AppLocale.hindi => _hiNewModes,")
lines.append("};")
lines.append("")

loc_prefix_map = {
    'vietnamese': '_vi',
    'english': '_en',
    'spanish': '_es',
    'simplifiedChinese': '_zh',
    'japanese': '_ja',
    'korean': '_ko',
    'thai': '_th',
    'hindi': '_hi',
}

for loc_name, loc_data in LOCALES.items():
    prefix = loc_prefix_map[loc_name]
    contexts = loc_data['contexts']
    mechanisms = loc_data['mechanisms']
    new_modes = loc_data['new_modes']

    # Contexts Map
    lines.append(f"const Map<String, String> {prefix}Contexts = <String, String>{{")
    for (cat, per), text in sorted(contexts.items()):
        escaped = escape_dart_str(text)
        lines.append(f"  '{cat}:{per}': '{escaped}',")
    lines.append("};")
    lines.append("")

    # Mechanisms Map
    lines.append(f"const Map<String, String> {prefix}Mechanisms = <String, String>{{")
    for (m, s, v), text in sorted(mechanisms.items()):
        escaped = escape_dart_str(text)
        lines.append(f"  '{m}:{s}:{v}': '{escaped}',")
    lines.append("};")
    lines.append("")

    # New modes Map
    lines.append(f"const Map<String, (String, String)> {prefix}NewModes = <String, (String, String)>{{")
    for k, (should_do, avoid) in sorted(new_modes.items()):
        sd_esc = escape_dart_str(should_do)
        av_esc = escape_dart_str(avoid)
        lines.append(f"  '{k}': ('{sd_esc}', '{av_esc}'),")
    lines.append("};")
    lines.append("")

# Heritage English Maps
lines.append("const Map<String, String> _enEasternHeritageMechanisms = <String, String>{")
for (m, s, v), text in sorted(EN_EASTERN_HERITAGE_MECHANISMS.items()):
    escaped = escape_dart_str(text)
    lines.append(f"  '{m}:{s}:{v}': '{escaped}',")
lines.append("};")
lines.append("")

lines.append("const Map<String, String> _enVedicHeritageMechanisms = <String, String>{")
for (m, s, v), text in sorted(EN_VEDIC_HERITAGE_MECHANISMS.items()):
    escaped = escape_dart_str(text)
    lines.append(f"  '{m}:{s}:{v}': '{escaped}',")
lines.append("};")
lines.append("")

output_path = os.path.join(
    os.path.dirname(__file__),
    '..', 'lib', 'data', 'action_guidance', 'cosmic_headline_composer.dart'
)
output_path = os.path.abspath(output_path)

with open(output_path, 'w', encoding='utf-8') as f:
    f.write("\n".join(lines) + "\n")

print(f"SUCCESS: Generated {output_path}")
