import os
import sys
from collections import Counter
sys.stdout.reconfigure(encoding='utf-8')

TOOL_DIR = 'mobile_app/tool'
sys.path.insert(0, TOOL_DIR)

from build_multilingual_action_guidance import assemble_dataset, FORBIDDEN_WORDS

for lang in ['zh', 'th', 'hi']:
    data = assemble_dataset(lang)
    forbidden = FORBIDDEN_WORDS[lang]
    print(f"\n--- {lang.upper()} (total: {len(data)}) ---")
    h_c = Counter(v[0] for v in data.values())
    s_c = Counter(v[1] for v in data.values())
    a_c = Counter(v[2] for v in data.values())
    dup_h = {h: c for h, c in h_c.items() if c > 1}
    dup_s = {s: c for s, c in s_c.items() if c > 1}
    dup_a = {a: c for a, c in a_c.items() if c > 1}
    print(f"  {lang} duplicate headlines: {len(dup_h)}")
    for h, c in list(dup_h.items())[:5]:
        keys = [k for k, v in data.items() if v[0] == h]
        print(f"    [{c}x] '{h}': {keys}")
    print(f"  {lang} duplicate should_dos: {len(dup_s)}")
    for s, c in list(dup_s.items())[:5]:
        keys = [k for k, v in data.items() if v[1] == s]
        print(f"    [{c}x] '{s}': {keys}")
    print(f"  {lang} duplicate avoids: {len(dup_a)}")
    for a, c in list(dup_a.items())[:5]:
        keys = [k for k, v in data.items() if v[2] == a]
        print(f"    [{c}x] '{a}': {keys}")

    fb_hits = []
    for k, (h, s, a) in data.items():
        text = f"{h} {s} {a}"
        for w in forbidden:
            if w in text:
                fb_hits.append((k, w))
    print(f"  {lang} forbidden hits: {len(fb_hits)}")
    for f in fb_hits:
        print(f"    {f}")
