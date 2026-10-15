import sys
from collections import Counter
sys.stdout.reconfigure(encoding='utf-8')

TOOL_DIR = 'mobile_app/tool'
sys.path.insert(0, TOOL_DIR)

from guidance_builder.ja_base import JA_BASE
from guidance_builder.ja_career import JA_CAREER
from guidance_builder.ja_love import JA_LOVE
from guidance_builder.ja_money import JA_MONEY
from guidance_builder.ja_study import JA_STUDY
from guidance_builder.ja_friends import JA_FRIENDS
from guidance_builder.ja_other import JA_OTHER

ja_all = {}
for mod in [JA_BASE, JA_CAREER, JA_LOVE, JA_MONEY, JA_STUDY, JA_FRIENDS, JA_OTHER]:
    ja_all.update(mod)

s_c = Counter(v[1] for v in ja_all.values())
a_c = Counter(v[2] for v in ja_all.values())

print("JA Dup ShouldDos:")
for s, c in s_c.items():
    if c > 1:
        print(f"  [{c}x] '{s}': {[k for k, v in ja_all.items() if v[1] == s]}")

print("\nJA Dup Avoids:")
for a, c in a_c.items():
    if c > 1:
        print(f"  [{c}x] '{a}': {[k for k, v in ja_all.items() if v[2] == a]}")
