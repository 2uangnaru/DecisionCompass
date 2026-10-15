import re
import sys
from collections import defaultdict

sys.stdout.reconfigure(encoding='utf-8')
keys = re.findall(r"'([a-z0-9_:]+)':\s*\(", open('mobile_app/lib/data/action_guidance/action_guidance_vi.dart', encoding='utf-8').read())
cats = defaultdict(list)
for k in keys:
    parts = k.split(':')
    prefix = parts[0]
    cats[prefix].append(k)

for prefix, klist in sorted(cats.items()):
    print(f"{prefix}: {len(klist)} keys")
