import json
import sys
from collections import Counter

sys.stdout.reconfigure(encoding='utf-8')

from guidance_data_en import guidance_en
from guidance_data_es import guidance_es

for lang, data in [('EN', guidance_en), ('ES', guidance_es)]:
    print(f"\n--- {lang} (total: {len(data)}) ---")
    h_c = Counter(v[0] for v in data.values())
    s_c = Counter(v[1] for v in data.values())
    a_c = Counter(v[2] for v in data.values())
    dup_h = {h: c for h, c in h_c.items() if c > 1}
    dup_s = {s: c for s, c in s_c.items() if c > 1}
    dup_a = {a: c for a, c in a_c.items() if c > 1}
    print(f"  {lang} duplicate headlines: {len(dup_h)}")
    for h, c in dup_h.items():
        keys = [k for k, v in data.items() if v[0] == h]
        print(f"    [{c}x] '{h}': {keys}")
    print(f"  {lang} duplicate should_dos: {len(dup_s)}")
    for s, c in dup_s.items():
        keys = [k for k, v in data.items() if v[1] == s]
        print(f"    [{c}x] '{s}': {keys}")
    print(f"  {lang} duplicate avoids: {len(dup_a)}")
    for a, c in dup_a.items():
        keys = [k for k, v in data.items() if v[2] == a]
        print(f"    [{c}x] '{a}': {keys}")
