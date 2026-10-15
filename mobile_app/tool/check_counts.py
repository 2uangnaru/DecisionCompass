import glob
import re

for f in sorted(glob.glob('mobile_app/lib/data/action_guidance/action_guidance_*.dart')):
    content = open(f, encoding='utf-8').read()
    keys = re.findall(r"'([a-z0-9_:]+)':\s*\(", content)
    print(f"{f}: {len(keys)} entries")
