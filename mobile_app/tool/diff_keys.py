import re

vi_content = open('mobile_app/lib/data/action_guidance/action_guidance_vi.dart', encoding='utf-8').read()
en_content = open('mobile_app/lib/data/action_guidance/action_guidance_en.dart', encoding='utf-8').read()

vi_keys = set(re.findall(r"'([a-z0-9_:]+)':\s*\(", vi_content))
en_keys = set(re.findall(r"'([a-z0-9_:]+)':\s*\(", en_content))

diff = vi_keys - en_keys
print(f"VI total: {len(vi_keys)}")
print(f"EN total: {len(en_keys)}")
print(f"Missing in EN ({len(diff)} keys):")
for k in sorted(diff):
    print(" ", k)
