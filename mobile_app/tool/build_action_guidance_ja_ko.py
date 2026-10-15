# coding: utf-8
"""
Builder and validator for Japanese (`ja`) and Korean (`ko`) Action Guidance.

Generates:
1. mobile_app/lib/data/action_guidance/action_guidance_ja.dart (actionGuidanceJa, 315 keys)
2. mobile_app/lib/data/action_guidance/action_guidance_ko.dart (actionGuidanceKo, 315 keys)
3. mobile_app/tool/action_guidance_ja_ref.json
4. mobile_app/tool/action_guidance_ko_ref.json

Adheres strictly to responsible use:
- 0 forbidden words in Japanese:
  ['投資', 'お金', '給料', '借金', '買う', '売る', '恋人', '別れ', '離婚', '退職', '結婚']
- 0 forbidden words in Korean:
  ['투자', '돈', '급여', '대출', '구매', '사다', '팔다', '연인', '결혼', '이혼', '퇴사', '헤어지']
- Exactly 315 keys matching action_guidance_vi_ref.json.
"""

import json
import os
import subprocess
import sys

# Ensure mobile_app/tool is on sys.path
TOOL_DIR = os.path.dirname(os.path.abspath(__file__))
if TOOL_DIR not in sys.path:
    sys.path.insert(0, TOOL_DIR)

from guidance_builder.ja_base import JA_BASE
from guidance_builder.ja_career import JA_CAREER
from guidance_builder.ja_love import JA_LOVE
from guidance_builder.ja_money import JA_MONEY
from guidance_builder.ja_study import JA_STUDY
from guidance_builder.ja_friends import JA_FRIENDS
from guidance_builder.ja_other import JA_OTHER

from guidance_builder.ko_base import KO_BASE
from guidance_builder.ko_career import KO_CAREER
from guidance_builder.ko_love import KO_LOVE
from guidance_builder.ko_money import KO_MONEY
from guidance_builder.ko_study import KO_STUDY
from guidance_builder.ko_friends import KO_FRIENDS
from guidance_builder.ko_other import KO_OTHER

KO_FORBIDDEN = [
    '투자', '돈', '급여', '대출', '구매', '사다', '팔다', '연인', '결혼', '이혼', '퇴사', '헤어지'
]
JA_FORBIDDEN = [
    '投資', 'お金', '給料', '借金', '買う', '売る', '恋人', '別れ', '離婚', '退職', '結婚'
]


def assemble_all():
    # Maintain strict category order
    ja_all = {}
    for mod in [JA_BASE, JA_CAREER, JA_LOVE, JA_MONEY, JA_STUDY, JA_FRIENDS, JA_OTHER]:
        ja_all.update(mod)

    ko_all = {}
    for mod in [KO_BASE, KO_CAREER, KO_LOVE, KO_MONEY, KO_STUDY, KO_FRIENDS, KO_OTHER]:
        ko_all.update(mod)

    return ja_all, ko_all


def validate_against_vi_ref(ja_all, ko_all, vi_ref_path):
    with open(vi_ref_path, 'r', encoding='utf-8') as f:
        vi_ref = json.load(f)

    vi_keys = list(vi_ref.keys())
    ja_keys = list(ja_all.keys())
    ko_keys = list(ko_all.keys())

    assert len(vi_keys) == 315, f"Expected 315 keys in vi_ref, got {len(vi_keys)}"
    assert len(ja_keys) == 315, f"Expected 315 keys in ja_all, got {len(ja_keys)}"
    assert len(ko_keys) == 315, f"Expected 315 keys in ko_all, got {len(ko_keys)}"

    # Check key equality
    if set(ja_keys) != set(vi_keys):
        missing = set(vi_keys) - set(ja_keys)
        extra = set(ja_keys) - set(vi_keys)
        raise ValueError(f"JA keys mismatch! Missing: {missing}, Extra: {extra}")

    if set(ko_keys) != set(vi_keys):
        missing = set(vi_keys) - set(ko_keys)
        extra = set(ko_keys) - set(vi_keys)
        raise ValueError(f"KO keys mismatch! Missing: {missing}, Extra: {extra}")

    print("SUCCESS: Exact 315 keys match action_guidance_vi_ref.json.")
    return vi_ref



def validate_forbidden_words(data, forbidden_words, lang_code):
    violations = []
    for k, (headline, should_do, avoid) in data.items():
        combined = f"{headline} {should_do} {avoid}"
        for fw in forbidden_words:
            if fw in combined:
                part = []
                if fw in headline:
                    part.append('headline')
                if fw in should_do:
                    part.append('should_do')
                if fw in avoid:
                    part.append('avoid')
                violations.append((k, fw, ','.join(part), combined))

    if violations:
        print(f"FAILED: {len(violations)} forbidden word violations found in {lang_code}:")
        for v in violations:
            print(f"  Key: {v[0]} | Forbidden: '{v[1]}' in {v[2]}")
        raise ValueError(f"Forbidden word violations in {lang_code}")
    else:
        print(f"SUCCESS: 0 forbidden words found in {lang_code} (tested {len(forbidden_words)} terms).")


def generate_dart_file(data, output_path, map_name, lang_name, forbidden_words):
    fw_str = ", ".join(f"'{w}'" for w in forbidden_words)
    dart_code = f"""/// {lang_name} copy for Action Guidance.
///
/// Contains base reflections per decision mode plus context lenses for
/// career, love, finances (money), study, friends, and other.
/// Supports dynamic variants (:v1, :v2) and period lenses.
///
/// Adheres strictly to responsible use:
/// - Never tells the reader to buy, sell, quit, marry, or divorce.
/// - Free from forbidden words: {fw_str}.
const Map<String, (String, String, String)> {map_name} =
    <String, (String, String, String)>{{
"""

    for k, (h, s, a) in data.items():
        h_esc = h.replace("'", "\\'")
        s_esc = s.replace("'", "\\'")
        a_esc = a.replace("'", "\\'")
        dart_code += f"  '{k}': (\n"
        dart_code += f"    '{h_esc}',\n"
        dart_code += f"    '{s_esc}',\n"
        dart_code += f"    '{a_esc}',\n"
        dart_code += "  ),\n"

    dart_code += "};\n"

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(dart_code)

    print(f"SUCCESS: Generated {output_path} ({len(data)} entries).")


def generate_json_ref(data, output_path):
    ref_dict = {
        k: {
            "headline": v[0],
            "should_do": v[1],
            "avoid": v[2],
        }
        for k, v in data.items()
    }
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(ref_dict, f, ensure_ascii=False, indent=2)
    print(f"SUCCESS: Exported {output_path} ({len(ref_dict)} entries).")


def main():
    root_dir = os.path.dirname(os.path.dirname(TOOL_DIR))
    mobile_app_dir = os.path.join(root_dir, 'mobile_app')
    if not os.path.exists(mobile_app_dir):
        # We might already be in root or mobile_app
        if os.path.exists('mobile_app'):
            mobile_app_dir = os.path.abspath('mobile_app')
        else:
            mobile_app_dir = os.path.abspath(os.path.join(TOOL_DIR, '..'))

    vi_ref_path = os.path.join(mobile_app_dir, 'tool', 'action_guidance_vi_ref.json')
    ja_dart_path = os.path.join(mobile_app_dir, 'lib', 'data', 'action_guidance', 'action_guidance_ja.dart')
    ko_dart_path = os.path.join(mobile_app_dir, 'lib', 'data', 'action_guidance', 'action_guidance_ko.dart')
    ja_json_path = os.path.join(mobile_app_dir, 'tool', 'action_guidance_ja_ref.json')
    ko_json_path = os.path.join(mobile_app_dir, 'tool', 'action_guidance_ko_ref.json')

    print("=" * 60)
    print("Action Guidance JA & KO Builder & Validator")
    print("=" * 60)

    # 1. Assemble
    ja_all, ko_all = assemble_all()

    # 2. Validate against VI ref
    validate_against_vi_ref(ja_all, ko_all, vi_ref_path)

    # 3. Validate forbidden words
    validate_forbidden_words(ja_all, JA_FORBIDDEN, 'Japanese')
    validate_forbidden_words(ko_all, KO_FORBIDDEN, 'Korean')

    # 4. Generate Dart files
    generate_dart_file(ja_all, ja_dart_path, 'actionGuidanceJa', 'Japanese', JA_FORBIDDEN)
    generate_dart_file(ko_all, ko_dart_path, 'actionGuidanceKo', 'Korean', KO_FORBIDDEN)

    # 5. Generate JSON reference files
    generate_json_ref(ja_all, ja_json_path)
    generate_json_ref(ko_all, ko_json_path)

    # 6. Analyze with dart analyze
    print("-" * 60)
    print("Running dart analyze...")
    rel_ja = os.path.relpath(ja_dart_path, mobile_app_dir)
    rel_ko = os.path.relpath(ko_dart_path, mobile_app_dir)
    cmd = ["dart", "analyze", rel_ja, rel_ko]
    try:
        proc = subprocess.run(cmd, cwd=mobile_app_dir, capture_output=True, text=True, check=True, shell=True)
        print("dart analyze output:")
        print(proc.stdout.strip())
        print("SUCCESS: dart analyze passed with 0 issues!")
    except subprocess.CalledProcessError as e:
        print("ERROR: dart analyze failed:")
        print(e.stdout)
        print(e.stderr)
        sys.exit(1)

    print("=" * 60)
    print("BUILD & VALIDATION COMPLETE!")
    print("=" * 60)


if __name__ == '__main__':
    main()
