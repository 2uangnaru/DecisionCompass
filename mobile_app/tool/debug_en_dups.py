from collections import Counter
from guidance_data_en import guidance_en

h_c = Counter(v[0] for v in guidance_en.values())
s_c = Counter(v[1] for v in guidance_en.values())
a_c = Counter(v[2] for v in guidance_en.values())

print("EN Duplicate Headlines:")
for h, c in h_c.items():
    if c > 1:
        print(f"  [{c}x] '{h}': {[k for k, v in guidance_en.items() if v[0] == h]}")

print("EN Duplicate Should_Dos:")
for s, c in s_c.items():
    if c > 1:
        print(f"  [{c}x] '{s}': {[k for k, v in guidance_en.items() if v[1] == s]}")

print("EN Duplicate Avoids:")
for a, c in a_c.items():
    if c > 1:
        print(f"  [{c}x] '{a}': {[k for k, v in guidance_en.items() if v[2] == a]}")
