# coding: utf-8
"""
Build and validate Action Guidance files for English (en) and Spanish (es).
Generates:
1. mobile_app/lib/data/action_guidance/action_guidance_en.dart (actionGuidanceEn)
2. mobile_app/lib/data/action_guidance/action_guidance_es.dart (actionGuidanceEs)

Ensures exact 285 keys matching mobile_app/tool/action_guidance_vi_ref.json.
Enforces zero forbidden words, zero overclaims, and special constraints.
"""
import json
import os
import sys

from guidance_data_en import guidance_en
from guidance_data_es import guidance_es
from test_guidance_validator import (
    EN_FORBIDDEN,
    EN_OVERCLAIMS,
    ES_FORBIDDEN,
    ES_OVERCLAIMS,
    validate_guidance,
)

sys.stdout.reconfigure(encoding='utf-8')

TOOL_DIR = os.path.dirname(os.path.abspath(__file__))
ROOT_DIR = os.path.dirname(TOOL_DIR)
REF_JSON_PATH = os.path.join(TOOL_DIR, 'action_guidance_vi_ref.json')
TARGET_EN_DART = os.path.join(ROOT_DIR, 'lib', 'data', 'action_guidance', 'action_guidance_en.dart')
TARGET_ES_DART = os.path.join(ROOT_DIR, 'lib', 'data', 'action_guidance', 'action_guidance_es.dart')


def escape_dart_str(s: str) -> str:
    # Escape backslash first, then single quotes and dollar signs
    s = s.replace('\\', '\\\\')
    s = s.replace("'", "\\'")
    s = s.replace('$', '\\$')
    return s


def render_dart_file(map_name: str, doc_comment: str, entries: dict, ref_keys: list) -> str:
    lines = [
        doc_comment.strip(),
        f'const Map<String, (String, String, String)> {map_name} =',
        '    <String, (String, String, String)>{',
    ]

    current_cat = None
    for k in ref_keys:
        # Category headers for readability
        parts = k.split(':')
        cat = parts[0] if len(parts) > 1 and parts[0] in ['career', 'love', 'money', 'study', 'friends', 'other'] else 'general'
        if cat != current_cat:
            current_cat = cat
            header_titles = {
                'general': 'Base entries (General / Universal)',
                'career': 'Career Context Lens',
                'love': 'Love & Personal Connections Lens',
                'money': 'Money & Material Footing Lens',
                'study': 'Study & Learning Mastery Lens',
                'friends': 'Friends & Social Circles Lens',
                'other': 'Other & Ambiguous Context Lens',
            }
            lines.append('  // ---------------------------------------------------------------------------')
            lines.append(f'  // {header_titles.get(cat, cat.title())}')
            lines.append('  // ---------------------------------------------------------------------------')

        h, s, a = entries[k]
        lines.append(f"  '{k}': (")
        lines.append(f"    '{escape_dart_str(h)}',")
        lines.append(f"    '{escape_dart_str(s)}',")
        lines.append(f"    '{escape_dart_str(a)}',")
        lines.append('  ),')

    lines.append('};')
    lines.append('')
    return '\n'.join(lines)


def main():
    print("=== Starting Action Guidance Build & Validation ===")

    # 1. Load reference keys
    with open(REF_JSON_PATH, 'r', encoding='utf-8') as f:
        vi_ref = json.load(f)
    ref_keys = list(vi_ref.keys())
    print(f"Loaded {len(ref_keys)} reference keys from action_guidance_vi_ref.json")

    # 2. Run comprehensive validation
    errors = validate_guidance(ref_keys, guidance_en, guidance_es)
    if errors:
        print(f"\n[ERROR] Found {len(errors)} validation failure(s):")
        for err in errors:
            print(f"  - {err}")
        sys.exit(1)

    print("[SUCCESS] All 285 keys for both EN and ES passed validation:")
    print("  - Exact 285 keys matching action_guidance_vi_ref.json")
    print("  - 0 forbidden words in English")
    print("  - 0 forbidden words in Spanish")
    print("  - 0 overclaims in English headlines")
    print("  - 0 overclaims in Spanish headlines")
    print("  - Special constraints verified (act_wait:first, left_right:first/second)")

    # 3. Generate English Dart file
    en_doc = """
/// English copy for Action Guidance.
///
/// Contains base reflections per decision mode plus context lenses for
/// career, love, finances (money), study, friends, and other.
/// Supports dynamic variants (:v1, :v2) and period lenses.
///
/// Adheres strictly to responsible use:
/// - Never tells the reader to buy, sell, quit, marry, or divorce.
/// - Free from forbidden words: 'invest', 'money', 'salary', 'loan', 'profit',
///   'buy', 'sell', 'pay', 'relationship', 'partner', 'break up', 'walk away',
///   'leave them', 'quit', 'resign', 'marry', 'divorce'.
/// - Avoids overclaims like 'most aligned', 'more aligned', 'best moment',
///   'reads as the most'.
"""
    en_dart_code = render_dart_file('actionGuidanceEn', en_doc, guidance_en, ref_keys)
    with open(TARGET_EN_DART, 'w', encoding='utf-8', newline='\n') as f:
        f.write(en_dart_code)
    print(f"[SUCCESS] Wrote English Dart file: {TARGET_EN_DART} ({len(guidance_en)} entries)")

    # 4. Generate Spanish Dart file
    es_doc = """
/// Spanish copy for Action Guidance.
///
/// Contains base reflections per decision mode plus context lenses for
/// career, love, finances (money), study, friends, and other.
/// Supports dynamic variants (:v1, :v2) and period lenses.
///
/// Adheres strictly to responsible use:
/// - Never tells the reader to buy, sell, quit, marry, or divorce.
/// - Free from forbidden words: 'invertir', 'dinero', 'sueldo', 'préstamo',
///   'comprar', 'vender', 'relación', 'pareja', 'romper', 'renunciar',
///   'casarte', 'divorcio'.
/// - Avoids overclaims like 'más alineado', 'mejor momento'.
"""
    es_dart_code = render_dart_file('actionGuidanceEs', es_doc, guidance_es, ref_keys)
    with open(TARGET_ES_DART, 'w', encoding='utf-8', newline='\n') as f:
        f.write(es_dart_code)
    print(f"[SUCCESS] Wrote Spanish Dart file: {TARGET_ES_DART} ({len(guidance_es)} entries)")


if __name__ == '__main__':
    main()
