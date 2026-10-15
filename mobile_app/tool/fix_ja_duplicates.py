# coding: utf-8
"""
Fix all duplicates in Japanese (ja) guidance data.
"""
import sys
from collections import Counter
sys.stdout.reconfigure(encoding='utf-8')

TOOL_DIR = 'mobile_app/tool'
sys.path.insert(0, TOOL_DIR)

from guidance_builder.ja_base import JA_BASE
from guidance_builder.ja_career import JA_CAREER
from guidance_builder.ja_love import JA_LOVE
from guidance_builder.ja_money import JA_MONEY
from guidance_builder.ja_study import JA_STUDY
from guidance_builder.ja_friends import JA_FRIENDS
from guidance_builder.ja_other import JA_OTHER

# 1. Balanced avoids across categories:
JA_BASE['balanced'] = (
    JA_BASE['balanced'][0],
    JA_BASE['balanced'][1],
    '不安を解消したい一心で、納得のいく答えが出るまで問いを繰り返すこと。'
)
JA_CAREER['career:balanced'] = (
    JA_CAREER['career:balanced'][0],
    JA_CAREER['career:balanced'][1],
    '仕事の進路が揺らいでいる最中に、拙速に白黒をつけようと焦ること。'
)
JA_LOVE['love:balanced'] = (
    JA_LOVE['love:balanced'][0],
    JA_LOVE['love:balanced'][1],
    '相手の気持ちを確かめたいあまり、象徴の答えを何度も問い直すこと。'
)

JA_CAREER['career:balanced:v2'] = (
    JA_CAREER['career:balanced:v2'][0],
    JA_CAREER['career:balanced:v2'][1],
    '自分の望む職業上の結論が出るまで、同じ問いを繰り返すこと。'
)
JA_MONEY['money:balanced:v2'] = (
    JA_MONEY['money:balanced:v2'][0],
    JA_MONEY['money:balanced:v2'][1],
    '安心を得たいがために、予算の問いを何度も占い直すこと。'
)
JA_STUDY['study:balanced:v2'] = (
    JA_STUDY['study:balanced:v2'][0],
    JA_STUDY['study:balanced:v2'][1],
    '学習方針に迷った際、地道な努力を怠って占いの結果にすがり続けること。'
)
JA_FRIENDS['friends:balanced:v2'] = (
    JA_FRIENDS['friends:balanced:v2'][0],
    JA_FRIENDS['friends:balanced:v2'][1],
    '友人の真意を疑い、象徴の判断に答えを求め続けること。'
)
JA_OTHER['other:balanced:v2'] = (
    JA_OTHER['other:balanced:v2'][0],
    JA_OTHER['other:balanced:v2'][1],
    '漠然とした不安を紛らわせるために、無目的に同じ確認を繰り返すこと。'
)

# 2. Friends v2 ShouldDos & Avoids:
JA_FRIENDS['friends:act_wait:second:v2'] = (
    JA_FRIENDS['friends:act_wait:second:v2'][0],
    '互いの生活リズムを尊重し、連絡の返信を焦らずゆったり待ちましょう。',
    '相手が多忙な時に、即座の反応を強要して関係をぎくしゃくさせること。'
)
JA_FRIENDS['friends:advance_retreat:first:v2'] = (
    JA_FRIENDS['friends:advance_retreat:first:v2'][0],
    '共通の興味を持つ場に顔を出し、新たな共感の輪を広げてみましょう。',
    '知り合って間もない相手に対して、過度な期待を急激に寄せてしまうこと。'
)
JA_FRIENDS['friends:advance_retreat:second:v2'] = (
    JA_FRIENDS['friends:advance_retreat:second:v2'][0],
    '気心の知れた少人数の友人と、静かで落ち着いた時間を分かち合いましょう。',
    'グループ内の一時的なすれ違いを理由に、自ら心を閉ざして孤立すること。'
)
JA_FRIENDS['friends:stay_go:first:v2'] = (
    JA_FRIENDS['friends:stay_go:first:v2'][0],
    '変わらぬ友情を注いでくれる身近な人々へ、心からの感謝を伝えましょう。',
    '居心地の悪くなった関係に、昔の思い出への未練だけで執着し続けること。'
)
JA_FRIENDS['friends:stay_go:second:v2'] = (
    JA_FRIENDS['friends:stay_go:second:v2'][0],
    '新たな視点をもたらしてくれる知的な交流の場へ静かに足を踏み入れてみましょう。',
    '生活環境の変化による自然な疎遠を、相手の裏切りと決めつけること。'
)
JA_FRIENDS['friends:keep_let_go:first:v2'] = (
    JA_FRIENDS['friends:keep_let_go:first:v2'][0],
    '友人が困難にあるときは静かに寄り添い、無言の信頼で支えになりましょう。',
    '礼儀を欠いた言動を、友情への甘えとして見逃し続けること。'
)
JA_FRIENDS['friends:keep_let_go:second:v2'] = (
    JA_FRIENDS['friends:keep_let_go:second:v2'][0],
    '過去のわだかまりを寛大に水に流し、新たな気持ちで関係を捉え直しましょう。',
    '不満を心の中に溜め込み、対話を避けたまま距離を置いてしまうこと。'
)
JA_FRIENDS['friends:commit_withdraw:first:v2'] = (
    JA_FRIENDS['friends:commit_withdraw:first:v2'][0],
    '仲間の活動を陰ながら支え、互いの敬意を深める機会をつくりましょう。',
    '自らのキャパシティを超えて複数の集まりを引き受け、疲弊してしまうこと。'
)
JA_FRIENDS['friends:commit_withdraw:second:v2'] = (
    JA_FRIENDS['friends:commit_withdraw:second:v2'][0],
    '自らの休息を優先し、穏やかな気持ちを取り戻してから交流に臨みましょう。',
    '友人たちへの配慮を一言も示さずに、突然音信不通になること。'
)
JA_FRIENDS['friends:left_right:first'] = (
    JA_FRIENDS['friends:left_right:first'][0],
    '相手の話を先回しせずじっくり聞き、温かな受容の姿勢を保ちましょう。',
    '象徴的な暗示に頼り、他者の誠意や人格を一方的に決めつけること。'
)
JA_FRIENDS['friends:left_right:first:v1'] = (
    JA_FRIENDS['friends:left_right:first:v1'][0],
    JA_FRIENDS['friends:left_right:first:v1'][1],
    '友人の何気ない言動の裏に、勝手に不穏な動機を読み取ってしまうこと。'
)
JA_FRIENDS['friends:left_right:first:v2'] = (
    JA_FRIENDS['friends:left_right:first:v2'][0],
    '直接の対話を通じて相手の真意を確かめ、思い込みを手放しましょう。',
    '直感による思い込みを信じ込み、素直な対話の機会を避けること。'
)
JA_FRIENDS['friends:left_right:second'] = (
    JA_FRIENDS['friends:left_right:second'][0],
    '互いの立場を思いやりながら、自らの考えを率直かつ穏やかに伝えましょう。',
    '曖昧な印象を鵜呑みにして、周囲の人間関係に不要な猜疑心を抱くこと。'
)
JA_FRIENDS['friends:left_right:second:v1'] = (
    JA_FRIENDS['friends:left_right:second:v1'][0],
    JA_FRIENDS['friends:left_right:second:v1'][1],
    '相手が忙しくしているだけの時に、悪意を持って無視されていると誤解すること。'
)
JA_FRIENDS['friends:left_right:second:v2'] = (
    JA_FRIENDS['friends:left_right:second:v2'][0],
    '建設的な意見交換を通じて、より深みのある相互理解を築きましょう。',
    '一度のぎこちないやり取りから、関係性全体の破綻を連想すること。'
)

# 3. Base Left/Right Avoids:
JA_BASE['left_right:first'] = (
    JA_BASE['left_right:first'][0],
    JA_BASE['left_right:first'][1],
    '象徴的な極性を、実際の道路交通や移動経路、身の安全の判断に用いること。'
)
JA_BASE['left_right:first:v1'] = (
    JA_BASE['left_right:first:v1'][0],
    JA_BASE['left_right:first:v1'][1],
    '抽象的なシンボルを、街中の交通や移動ルートの選定に当てはめること。'
)
JA_BASE['left_right:first:v2'] = (
    JA_BASE['left_right:first:v2'][0],
    JA_BASE['left_right:first:v2'][1],
    '象徴的な方角の直感を、現実の乗り物の運転や安全確認の代わりにすること。'
)
JA_BASE['left_right:second'] = (
    JA_BASE['left_right:second'][0],
    JA_BASE['left_right:second'][1],
    '象徴的な極性を、機械の操作や交通安全といった物理的判断に用いること。'
)
JA_BASE['left_right:second:v1'] = (
    JA_BASE['left_right:second:v1'][0],
    JA_BASE['left_right:second:v1'][1],
    '直感の方位感覚を、実際の移動や交通規則の遵守と混同すること。'
)
JA_BASE['left_right:second:v2'] = (
    JA_BASE['left_right:second:v2'][0],
    JA_BASE['left_right:second:v2'][1],
    '身の安全に関わる交通移動において、象徴的な印象を過信すること。'
)

# 4. Career Left/Right Avoids:
JA_CAREER['career:left_right:first'] = (
    JA_CAREER['career:left_right:first'][0],
    JA_CAREER['career:left_right:first'][1],
    '象徴的な直感を、技術的なシステムや設備の安全管理の根拠に流用すること。'
)
JA_CAREER['career:left_right:first:v1'] = (
    JA_CAREER['career:left_right:first:v1'][0],
    JA_CAREER['career:left_right:first:v1'][1],
    '客観的な仕様書の確認を怠り、抽象的な勘だけで現場作業を進めること。'
)
JA_CAREER['career:left_right:first:v2'] = (
    JA_CAREER['career:left_right:first:v2'][0],
    JA_CAREER['career:left_right:first:v2'][1],
    '業務上の手順を無視し、主観的なひらめきだけで作業を省略すること。'
)
JA_CAREER['career:left_right:second'] = (
    JA_CAREER['career:left_right:second'][0],
    JA_CAREER['career:left_right:second'][1],
    '象徴的な方位感覚を、業務上の安全基準や機器操作の判断基準にすること。'
)
JA_CAREER['career:left_right:second:v1'] = (
    JA_CAREER['career:left_right:second:v1'][0],
    JA_CAREER['career:left_right:second:v1'][1],
    '明確なリスク検証を経ずに、気分次第で技術的な進行方針を変更すること。'
)
JA_CAREER['career:left_right:second:v2'] = (
    JA_CAREER['career:left_right:second:v2'][0],
    JA_CAREER['career:left_right:second:v2'][1],
    '職場の安全確認において、具体的なデータよりも根拠なき予感を優先すること。'
)

# 5. Love Left/Right Avoids:
JA_LOVE['love:left_right:first'] = (
    JA_LOVE['love:left_right:first'][0],
    JA_LOVE['love:left_right:first'][1],
    '象徴的な暗示に頼り、相手の心情を独善的に決めつけること。'
)
JA_LOVE['love:left_right:first:v1'] = (
    JA_LOVE['love:left_right:first:v1'][0],
    JA_LOVE['love:left_right:first:v1'][1],
    '優しい対話を放棄し、抽象的な予感だけで相手との絆を値踏みすること。'
)
JA_LOVE['love:left_right:first:v2'] = (
    JA_LOVE['love:left_right:first:v2'][0],
    JA_LOVE['love:left_right:first:v2'][1],
    '根拠のない直感に振り回され、積み上げてきた信頼を揺るがすこと。'
)
JA_LOVE['love:left_right:second'] = (
    JA_LOVE['love:left_right:second'][0],
    JA_LOVE['love:left_right:second'][1],
    '一人で悲観的な推測を膨らませ、素直な対話を閉ざしてしまうこと。'
)
JA_LOVE['love:left_right:second:v1'] = (
    JA_LOVE['love:left_right:second:v1'][0],
    JA_LOVE['love:left_right:second:v1'][1],
    '象徴の傾きを決定的な判決と見なし、柔軟な対話の余地をなくすこと。'
)
JA_LOVE['love:left_right:second:v2'] = (
    JA_LOVE['love:left_right:second:v2'][0],
    JA_LOVE['love:left_right:second:v2'][1],
    '自分の気持ちを率直に告げないまま、相手が察してくれることばかり望むこと。'
)

# 6. Money Left/Right Avoids:
JA_MONEY['money:left_right:first'] = (
    JA_MONEY['money:left_right:first'][0],
    JA_MONEY['money:left_right:first'][1],
    '象徴的な直感を、投機や無謀な資金配分の決定に流用すること。'
)
JA_MONEY['money:left_right:first:v1'] = (
    JA_MONEY['money:left_right:first:v1'][0],
    JA_MONEY['money:left_right:first:v1'][1],
    '直感的な予感を、予算の安定や将来の安全の保証と取り違えること。'
)
JA_MONEY['money:left_right:first:v2'] = (
    JA_MONEY['money:left_right:first:v2'][0],
    JA_MONEY['money:left_right:first:v2'][1],
    '一時的な感情の昂ぶりから、毎月の支出管理をおろそかにすること。'
)
JA_MONEY['money:left_right:second'] = (
    JA_MONEY['money:left_right:second'][0],
    JA_MONEY['money:left_right:second'][1],
    '具体的な計算を行わず、直感だけに頼って備蓄を切り崩すこと。'
)
JA_MONEY['money:left_right:second:v1'] = (
    JA_MONEY['money:left_right:second:v1'][0],
    JA_MONEY['money:left_right:second:v1'][1],
    '必要経費の試算もせずに、思いつきで配分先を変更すること。'
)
JA_MONEY['money:left_right:second:v2'] = (
    JA_MONEY['money:left_right:second:v2'][0],
    JA_MONEY['money:left_right:second:v2'][1],
    '象徴的な極性を、現実の物理的・金銭的な博打に用いること。'
)

# 7. Study Left/Right Avoids:
JA_STUDY['study:left_right:first'] = (
    JA_STUDY['study:left_right:first'][0],
    JA_STUDY['study:left_right:first'][1],
    '象徴的な直感に頼り、実際の文献調査や論理的な思考を省くこと。'
)
JA_STUDY['study:left_right:first:v1'] = (
    JA_STUDY['study:left_right:first:v1'][0],
    JA_STUDY['study:left_right:first:v1'][1],
    '地道な演習を避け、試験でのひらめきや運だけに期待すること。'
)
JA_STUDY['study:left_right:first:v2'] = (
    JA_STUDY['study:left_right:first:v2'][0],
    JA_STUDY['study:left_right:first:v2'][1],
    '一度目を通しただけで理解した気になり、基礎の復習を軽視すること。'
)
JA_STUDY['study:left_right:second'] = (
    JA_STUDY['study:left_right:second'][0],
    JA_STUDY['study:left_right:second'][1],
    '体系的な学習を疎かにし、断片的な知識の暗記に終始すること。'
)
JA_STUDY['study:left_right:second:v1'] = (
    JA_STUDY['study:left_right:second:v1'][0],
    JA_STUDY['study:left_right:second:v1'][1],
    '実際に問題を解いて確かめる手間を省き、分かったつもりになること。'
)
JA_STUDY['study:left_right:second:v2'] = (
    JA_STUDY['study:left_right:second:v2'][0],
    JA_STUDY['study:left_right:second:v2'][1],
    '厳密な事実の検証を、あやふやなイメージの理解で置き換えること。'
)

# 8. Other Act/Wait Avoids:
JA_OTHER['other:act_wait:first:v2'] = (
    JA_OTHER['other:act_wait:first:v2'][0],
    JA_OTHER['other:act_wait:first:v2'][1],
    '手元のリソースを確認しないまま、焦って前進を強行すること。'
)
JA_OTHER['other:act_wait:second:v2'] = (
    JA_OTHER['other:act_wait:second:v2'][0],
    JA_OTHER['other:act_wait:second:v2'][1],
    '待つことのもどかしさに耐えかねて、不必要な口出しをしてしまうこと。'
)

print("Applied JA deduplication rules successfully.")
