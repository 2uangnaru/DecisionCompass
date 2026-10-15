import json
import sys

sys.stdout.reconfigure(encoding='utf-8')

with open('mobile_app/tool/action_guidance_vi_ref.json', encoding='utf-8') as f:
    d = json.load(f)

missing_prefixes = [
    'other:advance_retreat:',
    'other:stay_go:',
    'other:keep_let_go:',
    'other:commit_withdraw:',
    'other:left_right:',
]

for k in sorted(d.keys()):
    if any(k.startswith(p) for p in missing_prefixes):
        entry = d[k]
        print(f"[{k}]")
        print(f"  H: {entry['headline']}")
        print(f"  S: {entry['shouldDo']}")
        print(f"  A: {entry['avoid']}")
