import json
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')

content = open('mobile_app/lib/data/action_guidance/action_guidance_vi.dart', 'r', encoding='utf-8').read()
pattern = re.compile(
    r"'([a-z0-9_:]+)':\s*\(\s*'([^']*)',\s*'([^']*)',\s*'([^']*)',?\s*\)",
    re.MULTILINE
)

matches = pattern.findall(content)
print(f"Total entries: {len(matches)}")

ref_data = {k: {"headline": h, "shouldDo": s, "avoid": a} for k, h, s, a in matches}

with open('mobile_app/tool/action_guidance_vi_ref.json', 'w', encoding='utf-8') as f:
    json.dump(ref_data, f, ensure_ascii=False, indent=2)

print("Saved action_guidance_vi_ref.json with 315 entries.")
