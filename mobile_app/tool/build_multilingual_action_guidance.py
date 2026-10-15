# coding: utf-8
"""
Build and validate expanded multilingual Action Guidance files for
Simplified Chinese (zh), Thai (th), and Hindi (hi).

Strict Requirements:
1. Exact 315 keys matching action_guidance_vi_ref.json.
2. Zero forbidden words for each language.
3. Natural, high-quality localization adhering to AstraCue's responsible use guidelines.
"""
import json
import os
import sys

# Ensure module import path
TOOL_DIR = os.path.dirname(os.path.abspath(__file__))
if TOOL_DIR not in sys.path:
    sys.path.insert(0, TOOL_DIR)

from action_guidance_expansion.universal_data import universal_data
from action_guidance_expansion.career_data import career_data
from action_guidance_expansion.love_data import love_data
from action_guidance_expansion.money_data import money_data
from action_guidance_expansion.study_data import study_data
from action_guidance_expansion.friends_data import friends_data
from action_guidance_expansion.other_data import other_data

FORBIDDEN_WORDS = {
    'zh': ['投资', '钱', '工资', '贷款', '买', '卖', '恋人', '分手', '离婚', '辞职', '结婚'],
    'th': ['ลงทุน', 'เงิน', 'เงินเดือน', 'กู้', 'ซื้อ', 'ขาย', 'แฟน', 'เลิกกัน', 'หย่า', 'ลาออก', 'แต่งงาน'],
    'hi': ['निवेश', 'पैसा', 'वेतन', 'कर्ज', 'खरीद', 'बेचें', 'बेचना', 'रिश्ता', 'साथी', 'तलाक', 'नौकरी छोड़', 'शादी']
}

LANG_CONFIG = {
    'zh': {
        'name': 'Simplified Chinese',
        'var_name': 'actionGuidanceZh',
        'file_name': 'action_guidance_zh.dart',
        'header_comment': """/// Simplified Chinese copy for Action Guidance.
///
/// Contains base reflections per decision mode plus context lenses for
/// career, love, finances (money), study, friends, and other.
/// Supports dynamic variants (:v1, :v2) and period lenses.
///
/// Adheres strictly to responsible use:
/// - Never tells the reader to buy, sell, quit, marry, or divorce.
/// - Free from forbidden words: '投资', '钱', '工资', '贷款', '买', '卖',
///   '恋人', '分手', '离婚', '辞职', '结婚'.
const Map<String, (String, String, String)> actionGuidanceZh =
    <String, (String, String, String)>{
""",
    },
    'th': {
        'name': 'Thai',
        'var_name': 'actionGuidanceTh',
        'file_name': 'action_guidance_th.dart',
        'header_comment': """/// Thai copy for Action Guidance.
///
/// Contains base reflections per decision mode plus context lenses for
/// career, love, finances (money), study, friends, and other.
/// Supports dynamic variants (:v1, :v2) and period lenses.
///
/// Adheres strictly to responsible use:
/// - Never tells the reader to buy, sell, quit, marry, or divorce.
/// - Free from forbidden words: 'ลงทุน', 'เงิน', 'เงินเดือน', 'กู้', 'ซื้อ',
///   'ขาย', 'แฟน', 'เลิกกัน', 'หย่า', 'ลาออก', 'แต่งงาน'.
const Map<String, (String, String, String)> actionGuidanceTh =
    <String, (String, String, String)>{
""",
    },
    'hi': {
        'name': 'Hindi',
        'var_name': 'actionGuidanceHi',
        'file_name': 'action_guidance_hi.dart',
        'header_comment': """/// Hindi copy for Action Guidance.
///
/// Contains base reflections per decision mode plus context lenses for
/// career, love, finances (money), study, friends, and other.
/// Supports dynamic variants (:v1, :v2) and period lenses.
///
/// Adheres strictly to responsible use:
/// - Never tells the reader to buy, sell, quit, marry, or divorce.
/// - Free from forbidden words: 'निवेश', 'पैसा', 'वेतन', 'कर्ज', 'खरीद',
///   'बेचें', 'बेचना', 'रिश्ता', 'साथी', 'तलाक', 'नौकरी छोड़', 'शादी'.
const Map<String, (String, String, String)> actionGuidanceHi =
    <String, (String, String, String)>{
""",
    },
}

def load_reference_keys():
    ref_path = os.path.join(TOOL_DIR, 'action_guidance_vi_ref.json')
    with open(ref_path, encoding='utf-8') as f:
        ref_data = json.load(f)
    return list(ref_data.keys()), ref_data

def assemble_dataset(lang):
    combined = {}
    for module_data in [
        universal_data,
        career_data,
        love_data,
        money_data,
        study_data,
        friends_data,
        other_data,
    ]:
        data_for_lang = module_data[lang]
        for k, v in data_for_lang.items():
            if k in combined:
                raise ValueError(f"Duplicate key '{k}' found in {lang} data.")
            combined[k] = v
    return combined

def validate_dataset(lang, data, ref_keys):
    ref_key_set = set(ref_keys)
    data_key_set = set(data.keys())

    missing = ref_key_set - data_key_set
    extra = data_key_set - ref_key_set

    if missing:
        raise ValueError(f"[{lang}] Missing {len(missing)} keys: {sorted(list(missing))[:10]}")
    if extra:
        raise ValueError(f"[{lang}] Extra {len(extra)} keys: {sorted(list(extra))[:10]}")

    forbidden_list = FORBIDDEN_WORDS[lang]
    violations = []

    for k, (headline, should_do, avoid) in data.items():
        if not headline.strip():
            raise ValueError(f"[{lang}] Key '{k}' has empty headline")
        if not should_do.strip():
            raise ValueError(f"[{lang}] Key '{k}' has empty should_do")
        if not avoid.strip():
            raise ValueError(f"[{lang}] Key '{k}' has empty avoid")

        combined_text = f"{headline} {should_do} {avoid}".lower()
        for word in forbidden_list:
            if word.lower() in combined_text:
                violations.append((k, word, headline, should_do, avoid))

    if violations:
        print(f"[{lang}] FORBIDDEN WORD VIOLATIONS DETECTED: {len(violations)}")
        for v in violations:
            print(f"  Key: {v[0]}, Word: '{v[1]}'")
            print(f"    h: {v[2]}")
            print(f"    s: {v[3]}")
            print(f"    a: {v[4]}")
        raise ValueError(f"[{lang}] Validation failed with {len(violations)} forbidden word violations.")

    print(f"[{lang}] Validation passed: Exact {len(data)} keys, 0 forbidden words, 0 empty strings.")

def generate_dart_code(lang, data, ref_keys):
    config = LANG_CONFIG[lang]
    lines = [config['header_comment']]

    for k in ref_keys:
        headline, should_do, avoid = data[k]
        h_esc = headline.replace("'", "\\'")
        s_esc = should_do.replace("'", "\\'")
        a_esc = avoid.replace("'", "\\'")

        lines.append(f"  '{k}': (")
        lines.append(f"    '{h_esc}',")
        lines.append(f"    '{s_esc}',")
        lines.append(f"    '{a_esc}',")
        lines.append("  ),")

    lines.append("};\n")
    return "\n".join(lines)

def main():
    print("=" * 60)
    print("Building and validating multilingual action guidance...")
    print("=" * 60)

    ref_keys, ref_data = load_reference_keys()
    print(f"Reference keys loaded: {len(ref_keys)} keys from action_guidance_vi_ref.json")

    output_dir = os.path.abspath(os.path.join(TOOL_DIR, '..', 'lib', 'data', 'action_guidance'))

    for lang in ['zh', 'th', 'hi']:
        print(f"\nProcessing {LANG_CONFIG[lang]['name']} ({lang})...")
        data = assemble_dataset(lang)
        validate_dataset(lang, data, ref_keys)

        dart_code = generate_dart_code(lang, data, ref_keys)
        target_path = os.path.join(output_dir, LANG_CONFIG[lang]['file_name'])

        with open(target_path, 'w', encoding='utf-8') as f:
            f.write(dart_code)

        print(f"Successfully generated: {target_path} ({len(data)} entries)")

    print("\n" + "=" * 60)
    print("All 3 Action Guidance files built and validated successfully!")
    print("=" * 60)

if __name__ == '__main__':
    main()
