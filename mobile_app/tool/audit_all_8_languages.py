# coding: utf-8
import re
import os
import sys
from collections import Counter

sys.stdout.reconfigure(encoding='utf-8')

AG_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'lib', 'data', 'action_guidance')
LANGS = ['vi', 'en', 'es', 'ja', 'ko', 'zh', 'th', 'hi']

# Parser regex for Dart Map entries: 'key': ( ... , ... , ... ),
# We match line-by-line or entry block
entry_re = re.compile(
    r"'([^']+)'\s*:\s*\(\s*(?:r?'([\s\S]*?)'|r?\"\"\"([\s\S]*?)\"\"\")\s*,\s*(?:r?'([\s\S]*?)'|r?\"\"\"([\s\S]*?)\"\"\")\s*,\s*(?:r?'([\s\S]*?)'|r?\"\"\"([\s\S]*?)\"\"\")\s*\)\s*,",
    re.MULTILINE
)

all_maps = {}
for lang in LANGS:
    fpath = os.path.join(AG_DIR, f'action_guidance_{lang}.dart')
    with open(fpath, 'r', encoding='utf-8') as f:
        content = f.read()
    matches = entry_re.findall(content)
    parsed = {}
    for m in matches:
        k = m[0]
        h = (m[1] or m[2]).replace("\\'", "'")
        s = (m[3] or m[4]).replace("\\'", "'")
        a = (m[5] or m[6]).replace("\\'", "'")
        parsed[k] = (h, s, a)
    all_maps[lang] = parsed
    print(f'{lang}: {len(parsed)} entries parsed')

# 1. Verify key count and key identity across all languages
base_keys = set(all_maps['vi'].keys())
all_keys_match = True
for lang in LANGS:
    diff = base_keys.symmetric_difference(set(all_maps[lang].keys()))
    if diff:
        all_keys_match = False
        print(f'ERROR: {lang} key mismatch! Diff count: {len(diff)}')

# 2. Duplicate checking
total_dups = 0
for lang in LANGS:
    m = all_maps[lang]
    h_c = Counter(v[0] for v in m.values())
    s_c = Counter(v[1] for v in m.values())
    a_c = Counter(v[2] for v in m.values())
    dh = [k for k, v in h_c.items() if v > 1]
    ds = [k for k, v in s_c.items() if v > 1]
    da = [k for k, v in a_c.items() if v > 1]
    total_dups += len(dh) + len(ds) + len(da)
    print(f'{lang.upper():2s}: {len(m)} keys | Dup Headlines: {len(dh):2d} | Dup ShouldDos: {len(ds):2d} | Dup Avoids: {len(da):2d}')

# 3. Check forbidden words
FORBIDDEN = {
    'en': ['invest', 'money', 'salary', 'loan', 'profit', 'buy', 'sell', 'pay', 'relationship', 'partner', 'break up', 'walk away', 'leave them', 'quit', 'resign', 'marry', 'divorce'],
    'es': ['invertir', 'dinero', 'sueldo', 'préstamo', 'comprar', 'vender', 'relación', 'pareja', 'romper', 'renunciar', 'casarte', 'divorcio'],
    'vi': ['đầu tư', 'tiền bạc', 'tiền nong', 'dòng tiền', 'lợi nhuận', 'vay vốn', 'mua vào', 'bán ra', 'chia tay', 'kết hôn', 'ly hôn', 'nghỉ việc', 'từ chức'],
    'ja': ['投資', 'お金', '給料', '借金', '買う', '売る', '恋人', '別れ', '離婚', '退職', '結婚'],
    'ko': ['투자', '돈', '급여', '대출', '구매', '사다', '팔다', '연인', '결혼', '이혼', '퇴사', '헤어지'],
    'zh': ['投资', '钱', '工资', '贷款', '买', '卖', '恋人', '分手', '离婚', '辞职', '结婚'],
    'th': ['ลงทุน', 'เงิน', 'เงินเดือน', 'กู้', 'ซื้อ', 'ขาย', 'แฟน', 'เลิกกัน', 'หย่า', 'ลาออก', 'แต่งงาน'],
    'hi': ['निवेश', 'पैसा', 'वेतन', 'कर्ज', 'खरीद', 'बेचें', 'बेचना', 'रिश्ता', 'साथी', 'तलाक', 'नौकरी छोड़', 'शादी'],
}

OVERCLAIMS = {
    'en': ['most aligned', 'more aligned', 'best moment', 'reads as the most'],
    'es': ['más alineado', 'mejor momento'],
    'vi': ['tốt nhất', 'thời điểm hoàn hảo', 'hợp nhất'],
}

fb_hits_total = 0
for lang, words in FORBIDDEN.items():
    m = all_maps[lang]
    for k, (h, s, a) in m.items():
        text = f"{h} {s} {a}".lower() if lang in ['en', 'es'] else f"{h} {s} {a}"
        for w in words:
            # For EN 'quit', avoid false positive on 'equity'
            if w in text:
                print(f"FORBIDDEN: [{lang}] key '{k}' contains '{w}'")
                fb_hits_total += 1

print(f"\nAUDIT SUMMARY:")
print(f"All 8 languages have exactly 315 keys: {all_keys_match and all(len(m) == 315 for m in all_maps.values())}")
print(f"Total duplicates across all languages: {total_dups}")
print(f"Total forbidden words hits: {fb_hits_total}")
