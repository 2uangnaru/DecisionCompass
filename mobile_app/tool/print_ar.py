import json
import sys

sys.stdout.reconfigure(encoding='utf-8')

with open('mobile_app/tool/action_guidance_vi_ref.json', encoding='utf-8') as f:
    d = json.load(f)

for k in sorted(d.keys()):
    if k.startswith('other:advance_retreat:'):
        entry = d[k]
        print(f"[{k}]")
        print(f"  H: {entry['headline']}")
        print(f"  S: {entry['shouldDo']}")
        print(f"  A: {entry['avoid']}")
