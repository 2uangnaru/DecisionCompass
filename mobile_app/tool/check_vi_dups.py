import re
import sys
from collections import Counter

sys.stdout.reconfigure(encoding='utf-8')

content = open('mobile_app/lib/data/action_guidance/action_guidance_vi.dart', encoding='utf-8').read()

# Pattern to extract key, headline, shouldDo, avoid
pattern = re.compile(
    r"'([a-z0-9_:]+)':\s*\(\s*'([^']*)',\s*'([^']*)',\s*'([^']*)',?\s*\)",
    re.MULTILINE
)

matches = pattern.findall(content)
print(f"Total entries parsed: {len(matches)}")

headlines = Counter()
should_dos = Counter()
avoids = Counter()
entries = {}

for k, h, s, a in matches:
    entries[k] = (h, s, a)
    headlines[h] += 1
    should_dos[s] += 1
    avoids[a] += 1

print("\nDuplicate headlines (>1 count):")
dup_h = {h: c for h, c in headlines.items() if c > 1}
print(f"Found {len(dup_h)} duplicate headlines")
for h, c in dup_h.items():
    matching_keys = [k for k, v in entries.items() if v[0] == h]
    print(f"  [{c}x] '{h}': {matching_keys}")

print("\nDuplicate avoids (>1 count):")
dup_a = {a: c for a, c in avoids.items() if c > 1}
print(f"Found {len(dup_a)} duplicate avoids")
for a, c in dup_a.items():
    matching_keys = [k for k, v in entries.items() if v[2] == a]
    print(f"  [{c}x] '{a}': {matching_keys}")

print("\nDuplicate should_dos (>1 count):")
dup_s = {s: c for s, c in should_dos.items() if c > 1}
print(f"Found {len(dup_s)} duplicate should_dos")
for s, c in dup_s.items():
    matching_keys = [k for k, v in entries.items() if v[1] == s]
    print(f"  [{c}x] '{s}': {matching_keys}")
