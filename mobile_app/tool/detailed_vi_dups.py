import re
import sys
from collections import Counter

sys.stdout.reconfigure(encoding='utf-8')

content = open('mobile_app/lib/data/action_guidance/action_guidance_vi.dart', encoding='utf-8').read()

pattern = re.compile(
    r"'([a-z0-9_:]+)':\s*\(\s*'([^']*)',\s*'([^']*)',\s*'([^']*)',?\s*\)",
    re.MULTILINE
)

matches = pattern.findall(content)
print(f"Total entries parsed: {len(matches)}")

entries = {k: [h, s, a] for k, h, s, a in matches}

# Print duplicates
headlines = Counter(v[0] for v in entries.values())
should_dos = Counter(v[1] for v in entries.values())
avoids = Counter(v[2] for v in entries.values())

print("\n--- DUPLICATE HEADLINES ---")
for h, count in headlines.items():
    if count > 1:
        keys = [k for k, v in entries.items() if v[0] == h]
        print(f"[{count}x] '{h}'")
        for k in keys:
            print(f"   -> {k}")

