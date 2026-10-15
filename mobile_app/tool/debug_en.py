import json
import re

ref = json.load(open('mobile_app/tool/action_guidance_vi_ref.json', encoding='utf-8'))
en_content = open('mobile_app/lib/data/action_guidance/action_guidance_en.dart', encoding='utf-8').read()
en_keys = set(re.findall(r"'([a-z0-9_:]+)':\s*\(", en_content))
missing = set(ref.keys()) - en_keys
print(f"Ref total: {len(ref)}")
print(f"EN total: {len(en_keys)}")
print(f"Missing in EN ({len(missing)}):")
for m in sorted(missing):
    print(" ", m)
