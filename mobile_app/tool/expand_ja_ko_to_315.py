# coding: utf-8
"""
Expand and deduplicate Japanese (ja) and Korean (ko) action guidance to 315 keys.
"""
import json
import os
import sys
from collections import Counter

sys.stdout.reconfigure(encoding='utf-8')

TOOL_DIR = os.path.dirname(os.path.abspath(__file__))
if TOOL_DIR not in sys.path:
    sys.path.insert(0, TOOL_DIR)

from guidance_builder.ja_base import JA_BASE
from guidance_builder.ja_career import JA_CAREER
from guidance_builder.ja_love import JA_LOVE
from guidance_builder.ja_money import JA_MONEY
from guidance_builder.ja_study import JA_STUDY
from guidance_builder.ja_friends import JA_FRIENDS
from guidance_builder.ja_other import JA_OTHER

from guidance_builder.ko_base import KO_BASE
from guidance_builder.ko_career import KO_CAREER
from guidance_builder.ko_love import KO_LOVE
from guidance_builder.ko_money import KO_MONEY
from guidance_builder.ko_study import KO_STUDY
from guidance_builder.ko_friends import KO_FRIENDS
from guidance_builder.ko_other import KO_OTHER

# ==============================================================================
# 1. 30 NEW ENTRIES FOR JA_OTHER
# ==============================================================================
JA_OTHER_30 = {
    'other:advance_retreat:first': (
        'この状況において、シグナルは前向きに一歩を踏み出し新たな道を切り拓く側へと傾いています。',
        '最も有望な打開策を思い切って試し、好ましい変化を起こす好機を捉えましょう。',
        '失敗を恐れて過度にためらい、行動を起こす絶好の好機を逃してしまうこと。',
    ),
    'other:advance_retreat:first:v1': (
        '自身の課題において歩みを速め、独自の存在感を確立するのに適した時期です。',
        '具体的な段階ごとの道筋を整え、目の前の障壁を一つずつ着実に解消しましょう。',
        '代替案の準備を欠いたまま、衝動的に動いてしまうこと。',
    ),
    'other:advance_retreat:first:v2': (
        'この事柄においては、立ち止まるよりも着実に歩みを進める側へと傾いています。',
        'すでに整っている有利な条件を見極め、一歩ずつ堅実に前進しましょう。',
        '前進することを、状況に合わせて柔軟に調整できない固定的な縛りと誤解すること。',
    ),
    'other:advance_retreat:second': (
        'この状況において、シグナルは一歩退いて全体像を静観する側へと傾いています。',
        'リスクの高い行動を一時見合わせ、範囲を絞って危険の度合いを再評価しましょう。',
        '周囲の事実関係が十分に明らかになっていない中で、頑なに突き進むこと。',
    ),
    'other:advance_retreat:second:v1': (
        '安全な基盤を固め、既存の力を保全することがいま最も賢明な戦略です。',
        '当初の前提を洗い直し、客観的で偏りのない視点を取り入れましょう。',
        '立ち止まって観察する期間を、弱さや敗北の証拠と見なしてしまうこと。',
    ),
    'other:advance_retreat:second:v2': (
        'この事柄においては、慎重を期し必要な距離を保つ側へと傾いています。',
        '物事を多角的な視点から見つめ直すための時間を自分に与えましょう。',
        '深く考えるために時間が必要な自分を、不当に責めてしまうこと。',
    ),
    'other:stay_go:first': (
        'このような状況下では、現在の足場と立場を堅固に守る側へと傾いています。',
        '手元にある利点を最大限に活用し、慣れ親しんだ拠点を十分に活かしましょう。',
        '現在の安定が試される前に、焦って外の選択肢へと目移りすること。',
    ),
    'other:stay_go:first:v1': (
        '安定した基盤を守り抜くことが、この転換期を乗り越える極めて重要な鍵です。',
        '新たな計画に手を伸ばす前に、やり残した課題を深く掘り下げて完遂しましょう。',
        '穏やかな安定を、単なる停滞や立ち往生と思い違いすること。',
    ),
    'other:stay_go:first:v2': (
        'このような状況下では、安定した状態を静かに保つ側へと傾いています。',
        '現在の場所や環境がすでに自分にもたらしてくれている価値を再確認しましょう。',
        '一時的な焦りから、安定した確かな足場を軽率に放棄してしまうこと。',
    ),
    'other:stay_go:second': (
        'このような状況下では、思い切って新たな環境へと身を移す側へと傾いています。',
        '過去の文脈に区切りをつけ、前向きな新しい経験を積極的に求めましょう。',
        '新たな挑戦への恐れから、すでに役割を終えた習慣にしがみつくこと。',
    ),
    'other:stay_go:second:v1': (
        '視野を広げ、新たな成長の場へと踏み出すのに機が熟しています。',
        '心の準備を整え、秩序ある移行計画を丁寧に練り上げましょう。',
        '明確な目的意識もないまま、単に現実の摩擦から逃れるためだけに動くこと。',
    ),
    'other:stay_go:second:v2': (
        'このような状況下では、訪れつつある新たな変化を受け入れる側へと傾いています。',
        '新たな視野が自分の歩みにどのように役立つかを具体的に思い描きましょう。',
        '外の環境を変えることだけで、内面の課題が自然にすべて解決すると過信すること。',
    ),
    'other:keep_let_go:first': (
        'この事柄において、シグナルは大切にしてきた価値を守り抜く側へと傾いています。',
        '中核となる信条を堅持し、時間をかけて培ってきた精神的価値を慈しみましょう。',
        '周囲からの無理な要求に流され、安易に自己の芯を見失ってしまうこと。',
    ),
    'other:keep_let_go:first:v1': (
        '長期的に真の意義を持つものを育てるため、自らの力を注ぎ続けましょう。',
        '共に歩んできた信頼できるつながりを点検し、より強固に整えてください。',
        '本来の目的を見失ったまま、単なる惰性ですべてを抱え込み続けること。',
    ),
    'other:keep_let_go:first:v2': (
        'この事柄において、現在あるものを改めて深く重んじる側へと傾いています。',
        'これまでの軌跡を静かに振り返り、手の中にあるものの価値を見つめ直しましょう。',
        '現状に合わなくなった過去の思い込みに、頑なに固執してしまうこと。',
    ),
    'other:keep_let_go:second': (
        'この事柄において、身軽になるために不要なものを手放す好機が示されています。',
        '消耗を招くだけの余計な重荷を整理し、意識をすっきりと解放しましょう。',
        'もはや意味や生気を失ったものに未練を残し、引きずり続けること。',
    ),
    'other:keep_let_go:second:v1': (
        '新たな好機を迎え入れるために、日々の暮らしや優先順位を整理整頓しましょう。',
        'これまでの歩みに感謝しつつ、心穏やかに一つの節目を締めくくってください。',
        '自分に合わなくなったものを手放すことに対して、自責の念を抱くこと。',
    ),
    'other:keep_let_go:second:v2': (
        'この事柄において、無理なく静かに手放していく側へと傾いています。',
        '新しく生まれた心の余白を、自らを回復させる貴重な機会として捉えましょう。',
        '生まれた余白を埋めようと、焦って別の事柄に飛びついてしまうこと。',
    ),
    'other:commit_withdraw:first': (
        'この目標に関して、シグナルは意識を集中させ誠実に関わり続ける側へと傾いています。',
        '交わした約束を重んじ、共同の取り組みに熱意を持って力を注ぎましょう。',
        '中途半端な関わり方のままで、大きな実りを期待すること。',
    ),
    'other:commit_withdraw:first:v1': (
        '確かな意志で関わりを深めることが、この取り組みを結実させる土台となります。',
        '明確な節目を設け、互いの役割を率直かつ明快に分担しましょう。',
        '最初の意気込みだけで日々の着実な継続努力を怠ってしまうこと。',
    ),
    'other:commit_withdraw:first:v2': (
        'この目標に関して、持続的な献身を静かに保つ側へと傾いています。',
        '自らの人生全体を見渡し、長期的に両立できるかどうかを吟味しましょう。',
        '根本的な疑問が晴れないまま、性急に重い義務を引き受けてしまうこと。',
    ),
    'other:commit_withdraw:second': (
        'この目標に関して、シグナルは自律性を守るため綺麗に身を引く側へと傾いています。',
        '噛み合わない誘いには丁寧に断りを入れ、自分を守る境界線を明確にしましょう。',
        '他者の顔色を恐れるあまり、本心に反して無理に関わりを続けてしまうこと。',
    ),
    'other:commit_withdraw:second:v1': (
        '複雑に入り組んだ状況から自ら離れ、心の静けさと自由を取り戻しましょう。',
        '事前の合意には敬意を払い、礼儀正しく責任を持って距離を置いてください。',
        '理にかなった引き際を、個人の力不足や挫折と決めつけること。',
    ),
    'other:commit_withdraw:second:v2': (
        'この目標に関して、静かに退き自らを解き放つ側へと傾いています。',
        '適切な潮時を告げる内省のサインに素直に耳を傾けましょう。',
        '必要な区切りをつけることに対して、罪悪感を抱いてしまうこと。',
    ),
    'other:left_right:first': (
        'この特別な問いにおいて、シグナルは内なる直感と静かな感覚に耳を傾ける側へと傾いています。',
        '外に向けて何かを表現する前に、落ち着いた時間を設けて深く感じ取ってみましょう。',
        '象徴的な直観を、厳密な正確性や安全性が求められる物理的判断に用いること。',
    ),
    'other:left_right:first:v1': (
        '多角的な観察に集中し、表面下に隠された繊細な兆候を丁寧に捉えましょう。',
        '微細な気づきを記録し、客観的な事実と照らし合わせて検証してください。',
        '象徴的な直感を、事実確認を怠ったまま絶対的な真実と信じ込むこと。',
    ),
    'other:left_right:first:v2': (
        'この特別な問いにおいて、内向と静かな受容を重んじる側へと傾いています。',
        '言葉になっていない考えが、時間をかけて自然に輪郭を結ぶのを待ちましょう。',
        '漠然とした予感に惑わされ、基本的な慎重さの原則をないがしろにすること。',
    ),
    'other:left_right:second': (
        'この特別な問いにおいて、シグナルは率直に見解を表明し明確に行動する側へと傾いています。',
        '自らの考えを自信を持って明瞭に、かつ透明性を持って表に出しましょう。',
        '抽象的な象徴的指針を、複雑な実務的作業の処理に安易に当てはめること。',
    ),
    'other:left_right:second:v1': (
        '自らの意図を前向きに表明し、周囲との建設的な関わりを主導しましょう。',
        '望む方向性を、簡潔かつ具体的で建設的な言葉で分かりやすく伝えてください。',
        '明確な計画も持たないまま、気分次第で方針をふらふらと変更すること。',
    ),
    'other:left_right:second:v2': (
        'この特別な問いにおいて、積極的な表現と対話を促す側へと傾いています。',
        '信頼できる人々と胸の内を分かち合い、相互理解を深める機会をつくりましょう。',
        '状況が変化しているにもかかわらず、最初に決めた見解に頑固に固執すること。',
    ),
}

# ==============================================================================
# 2. 30 NEW ENTRIES FOR KO_OTHER
# ==============================================================================
KO_OTHER_30 = {
    'other:advance_retreat:first': (
        '이 상황에서는 주도적으로 발걸음을 내딛고 새로운 길을 열어가는 편이 좋습니다.',
        '가장 유망한 대안을 과감히 시도하며 긍정적인 전환점을 적극적으로 만들어 가세요.',
        '실패에 대한 막연한 두려움으로 망설이다가 결정적인 기회를 놓치는 것.',
    ),
    'other:advance_retreat:first:v1': (
        '속도를 높여 나만의 뚜렷한 발자취를 남기기에 매우 알맞은 시기입니다.',
        '단계별 추진 계획을 세우고 눈앞의 걸림돌을 하나씩 분명하게 해결해 나가세요.',
        '대비책도 갖추지 않은 채 충동적으로 밀어붙이는 것.',
    ),
    'other:advance_retreat:first:v2': (
        '이 사안에서는 멈추기보다 꾸준히 전진하는 방향에 무게가 실리고 있습니다.',
        '이미 마련된 유리한 조건들을 차분히 살피며 흔들림 없이 나아가세요.',
        '전진하는 선택을 상황 변화에 맞춰 유연하게 조율할 수 없는 구속으로 여기는 것.',
    ),
    'other:advance_retreat:second': (
        '이 상황에서는 한 걸음 물러서서 전체적인 국면을 조망하는 편이 현명합니다.',
        '무리한 행동을 잠시 멈추고 범위를 좁혀 위험 요소를 냉정하게 재평가해 보세요.',
        '주변의 사실관계가 미처 확인되지 않았는데 고집스럽게 돌진하는 것.',
    ),
    'other:advance_retreat:second:v1': (
        '안전한 발판을 다지고 기존 자원을 온전히 보전하는 것이 지금 최선의 전략입니다.',
        '처음 세웠던 가정을 꼼꼼히 점검하고 객관적인 제3자의 조언을 구해 보세요.',
        '잠시 멈추어 관찰하는 휴지기를 무기력함이나 패배로 단정하는 것.',
    ),
    'other:advance_retreat:second:v2': (
        '이 사안에서는 신중함을 지키며 적절한 거리를 유지하는 편이 유리합니다.',
        '다양한 각도에서 문제를 천천히 바라볼 수 있는 시간을 스스로에게 허락하세요.',
        '충분히 헤아리기 위해 시간이 필요한 자신을 자책하는 것.',
    ),
    'other:stay_go:first': (
        '이런 상황에서는 지금의 입장과 자리를 우직하게 지켜내는 편이 바람직합니다.',
        '이미 확보한 이점들을 적극적으로 활용하고 익숙한 기반을 든든한 버팀목으로 삼으세요.',
        '현재의 안정이 채 검증되기도 전에 조급하게 다른 대안을 기웃거리는 것.',
    ),
    'other:stay_go:first:v1': (
        '흔들리지 않는 단단한 토대를 보전하는 것이 이 전환기를 슬기롭게 건너는 열쇠입니다.',
        '새로운 시도를 벌이기 전에 미완으로 남아있던 과제들을 깊이 있게 마무리하세요.',
        '평온한 안정을 발전 없는 정체 상태로 오해하는 것.',
    ),
    'other:stay_go:first:v2': (
        '이런 상황에서는 현재의 안정적인 상태를 유지하는 편에 조언이 향하고 있습니다.',
        '지금의 자리와 환경이 이미 나에게 베풀어주고 있는 가치들을 온전히 인식해 보세요.',
        '순간의 답답함에 쫓겨 검증된 든든한 기반을 성급하게 내던지는 것.',
    ),
    'other:stay_go:second': (
        '이런 상황에서는 새로운 환경으로 용기 있게 이동해 보는 편을 권합니다.',
        '과거의 맥락을 깔끔하게 정리하고 자극이 되는 새로운 경험을 주도적으로 찾아 나서세요.',
        '새로운 도전에 맞닥뜨리기 두려워 낡은 습관에 집착하는 것.',
    ),
    'other:stay_go:second:v1': (
        '시야를 넓히고 새로운 성장의 장으로 옮겨가기에 무르익은 시간입니다.',
        '마음을 단단히 가다듬고 차분하고 체계적인 단계적 전환 계획을 세워보세요.',
        '단지 현실의 불편을 피하기 위해 뚜렷한 목표도 없이 서둘러 이동하는 것.',
    ),
    'other:stay_go:second:v2': (
        '이런 상황에서는 다가오는 새로운 변화를 열린 마음으로 맞이하는 편이 좋습니다.',
        '더 넓어진 시야가 나의 여정에 어떤 유익을 가져다줄지 차분히 그려보세요.',
        '외적인 환경만 바꾸면 마음속 깊은 고민까지 저절로 해결될 것이라 착각하는 것.',
    ),
    'other:keep_let_go:first': (
        '이 사안에서는 스스로 소중하게 여기는 가치를 지키고 보살피는 편이 어울립니다.',
        '핵심적인 원칙을 흔들림 없이 고수하고 정성껏 가꿔온 가치들을 소중히 품으세요.',
        '주변의 부당한 요구에 휩쓸려 나만의 본질과 색깔을 쉽게 잃어버리는 것.',
    ),
    'other:keep_let_go:first:v1': (
        '오랜 시간 온전한 의미를 품어낼 일에 꾸준히 집중력을 쏟아부으세요.',
        '오랜 시간 곁을 든든하게 지켜준 믿음직한 인연들을 돌아보고 결속을 다져보세요.',
        '원래의 목적은 잊어버린 채 그저 습관에 매여 모든 것을 쥐고 있으려는 것.',
    ),
    'other:keep_let_go:first:v2': (
        '이 사안에서는 이미 곁에 있는 소중한 것들을 귀하게 여기는 태도가 필요합니다.',
        '지나온 길을 차분히 되돌아보며 현재 손에 쥐고 있는 것들의 깊이를 음미해 보세요.',
        '현재와 동떨어진 과거의 낡은 편견에 방어적으로 매달리는 것.',
    ),
    'other:keep_let_go:second': (
        '이 사안에서는 가벼운 발걸음을 위해 묵은 짐을 내려놓을 때임을 알리고 있습니다.',
        '마음을 소모시키는 부질없는 번뇌를 단호히 정리하고 머릿속을 맑게 비워내세요.',
        '더는 생기나 기쁨을 주지 못하는 과거의 자취를 아쉬워하며 붙들고 있는 것.',
    ),
    'other:keep_let_go:second:v1': (
        '새롭고 신선한 기회를 맞이할 수 있도록 주변 환경과 생각을 말끔히 정리해 보세요.',
        '지나간 한 장을 감사한 마음으로 매듭짓고 홀가분한 평온을 맞이하세요.',
        '나와 더는 맞지 않는 것을 내려놓으면서 스스로를 책망하는 것.',
    ),

    'other:keep_let_go:second:v2': (
        '이 사안에서는 억지스러움 없이 자연스럽게 비워내는 태도가 도움이 됩니다.',
        '새롭게 생겨난 마음의 여백을 재충전의 소중한 기회로 삼아보세요.',
        '비워진 자리를 서둘러 채우려고 또 다른 일에 성급히 얽매이는 것.',
    ),
    'other:commit_withdraw:first': (
        '이 목표에 대해서는 초점을 하나로 모아 성실하게 전념하는 편이 좋습니다.',
        '함께 나눈 약속을 무겁게 받들고 공동의 결실을 위해 진심 어린 정성을 기울이세요.',
        '겉으로는 건성으로 임하면서 속으로는 커다란 결과를 바라는 것.',
    ),
    'other:commit_withdraw:first:v1': (
        '굳건한 참여 의지를 다지는 것이 이 계획을 알차게 꽃피우는 초석이 됩니다.',
        '명확한 이정표를 정하고 서로의 책임을 투명하고 명료하게 나누어 보세요.',
        '초기의 반짝이는 열정만 믿고 날마다 이어져야 할 꾸준함을 게을리하는 것.',
    ),
    'other:commit_withdraw:first:v2': (
        '이 목표에 대해서는 한결같은 헌신을 차분하게 이어가는 쪽에 힘이 실립니다.',
        '내 삶의 큰 그림 속에서 오랜 시간 감당할 수 있는 선택인지 깊이 숙고해 보세요.',
        '근본적인 의구심이 가시지 않았는데 덜컥 무거운 약속을 맺어버리는 것.',
    ),
    'other:commit_withdraw:second': (
        '이 목표에 대해서는 나만의 자율성을 지키기 위해 깔끔하게 물러서는 편이 현명합니다.',
        '어울리지 않는 제안은 정중히 사양하고 나를 지키는 경계선을 뚜렷하게 세우세요.',
        '남의 눈치를 보느라 억지로 승낙하거나 마지못해 끌려다니는 것.',
    ),
    'other:commit_withdraw:second:v1': (
        '복잡하게 얽힌 상황에서 스스로 거리를 두고 내면의 명료함과 자유를 되찾으세요.',
        '기존의 약속에는 도리를 다하되 정중하고 품위 있게 물러나세요.',
        '사리분별에 따른 합리적인 후퇴를 개인의 패배로 격하시키는 것.',
    ),
    'other:commit_withdraw:second:v2': (
        '이 목표에 대해서는 조용히 물러나 스스로를 놓아주는 태도가 알맞습니다.',
        '물러설 때를 일깨워주는 내면의 조용한 신호에 귀를 기울여 보세요.',
        '온당한 결단을 내리면서 불필요한 죄책감에 얽매이는 것.',
    ),
    'other:left_right:first': (
        '이 특별한 질문에서는 내면의 직관과 차분한 느낌에 귀를 기울이는 편이 좋습니다.',
        '겉으로 즉각 반응하기 전에 조용한 묵상의 시간을 갖고 깊이 느껴보세요.',
        '상징적인 감각을 물리적인 이동이나 안전이 요구되는 현장 판단에 끌어다 쓰는 것.',
    ),
    'other:left_right:first:v1': (
        '다각도로 상황을 관찰하며 표면 아래에 숨어있는 섬세한 흐름을 포착해 보세요.',
        '미세한 감각들을 메모해 두고 객관적인 사실들과 차분히 비교해 보세요.',
        '상징적인 예감을 객관적 검증 없이 맹신하는 것.',
    ),
    'other:left_right:first:v2': (
        '이 특별한 질문에서는 내적인 고요와 수용적인 태도에 조언의 초점이 맞추어져 있습니다.',
        '아직 다듬어지지 않은 생각들이 시간을 두고 제 형태를 갖추도록 기다려 주세요.',
        '단순한 예감에 홀려 기본적인 안전 수칙과 조심성을 내팽개치는 것.',
    ),
    'other:left_right:second': (
        '이 특별한 질문에서는 생각을 솔직하게 표현하고 명확하게 행동하는 편이 좋습니다.',
        '자신의 의견을 차분하고 당당하게 세상 밖으로 투명하게 드러내 보세요.',
        '추상적인 상징을 복잡한 실무적 문제 해결에 무작정 적용하는 것.',
    ),
    'other:left_right:second:v1': (
        '자신의 뜻을 자신감 있게 표현하며 주변과 생산적인 소통을 주도해 보세요.',
        '원하는 바를 간결하고 조리 있는 표현으로 전달하세요.',
        '명확한 계획도 없이 감정의 기복에 따라 진행 방향을 이리저리 바꾸는 것.',
    ),
    'other:left_right:second:v2': (
        '이 특별한 질문에서는 적극적인 표현과 열린 대화 쪽에 힘이 실리고 있습니다.',
        '마음속 생각을 신뢰할 수 있는 이들과 나누며 서로의 이해를 넓혀가세요.',
        '상황이 이미 달라졌음에도 처음에 내세운 주장에 완고하게 매달리는 것.',
    ),
}

# Update JA_OTHER and KO_OTHER
JA_OTHER.update(JA_OTHER_30)
KO_OTHER.update(KO_OTHER_30)

# DEDUPLICATE JA:
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
    '仕事の領域において、シグナルは静かな中立の均衡を保っています。',
    JA_CAREER['career:balanced:v2'][1],
    '自分の望む結論が出るまで、同じ職業上の問いを繰り返すこと。'
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
    'その他の個人的な問いにおいて、シグナルは静かな均衡を保っています。',
    JA_OTHER['other:balanced:v2'][1],
    '漠然とした不安を紛らわせるために、無目的に同じ確認を繰り返すこと。'
)

# JA Left/Right Avoids:
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

JA_FRIENDS['friends:commit_withdraw:first:v2'] = (
    'これからの週を見据えると、静かに心を配り信頼を育む側へと傾いています。',
    '仲間の活動を陰ながら支え、互いの敬意を深める機会をつくりましょう。',
    JA_FRIENDS['friends:commit_withdraw:first:v2'][2]
)
JA_FRIENDS['friends:commit_withdraw:second:v2'] = (
    'これからの週を見据えると、健全な距離感を保ち無理を避ける側へと傾いています。',
    '自らの休息を優先し、穏やかな気持ちを取り戻してから交流に臨みましょう。',
    JA_FRIENDS['friends:commit_withdraw:second:v2'][2]
)
JA_FRIENDS['friends:keep_let_go:first:v2'] = (
    '交友のあり方において、シグナルは歩んできた確かな歴史を慈しむ側へと傾いています。',
    JA_FRIENDS['friends:keep_let_go:first:v2'][1],
    JA_FRIENDS['friends:keep_let_go:first:v2'][2]
)
JA_FRIENDS['friends:keep_let_go:second:v2'] = (
    '交友のあり方において、シグナルは不要な気遣いや執着を静かに手放す側へと傾いています。',
    JA_FRIENDS['friends:keep_let_go:second:v2'][1],
    JA_FRIENDS['friends:keep_let_go:second:v2'][2]
)

JA_FRIENDS['friends:act_wait:second:v2'] = (
    JA_FRIENDS['friends:act_wait:second:v2'][0],
    '互いの生活リズムを尊重し、連絡の返信を焦らずゆったり待ちましょう。',
    JA_FRIENDS['friends:act_wait:second:v2'][2]
)
JA_FRIENDS['friends:advance_retreat:first:v2'] = (
    JA_FRIENDS['friends:advance_retreat:first:v2'][0],
    '共通の興味を持つ場に顔を出し、新たな共感の輪を広げてみましょう。',
    JA_FRIENDS['friends:advance_retreat:first:v2'][2]
)
JA_FRIENDS['friends:advance_retreat:second:v2'] = (
    JA_FRIENDS['friends:advance_retreat:second:v2'][0],
    '気心の知れた少人数の友人と、静かで落ち着いた時間を分かち合いましょう。',
    JA_FRIENDS['friends:advance_retreat:second:v2'][2]
)
JA_FRIENDS['friends:stay_go:first:v2'] = (
    JA_FRIENDS['friends:stay_go:first:v2'][0],
    '変わらぬ友情を注いでくれる身近な人々へ、心からの感謝を伝えましょう。',
    JA_FRIENDS['friends:stay_go:first:v2'][2]
)
JA_FRIENDS['friends:stay_go:second:v2'] = (
    JA_FRIENDS['friends:stay_go:second:v2'][0],
    '新たな視点をもたらしてくれる知的な交流の場へ静かに足を踏み入れてみましょう。',
    JA_FRIENDS['friends:stay_go:second:v2'][2]
)

# KO Avoids & ShouldDos:
KO_FRIENDS['friends:stay_go:first:v2'] = (
    KO_FRIENDS['friends:stay_go:first:v2'][0],
    '오랫동안 변함없이 곁을 지켜준 소중한 인연들에게 따뜻한 고마움을 전해 보세요.',
    KO_FRIENDS['friends:stay_go:first:v2'][2]
)

KO_BASE['left_right:first'] = (
    KO_BASE['left_right:first'][0],
    KO_BASE['left_right:first'][1],
    '상징적인 방향성을 실제 도로 교통이나 이동 경로, 신체 안전의 판단에 적용하는 것.'
)
KO_BASE['left_right:first:v1'] = (
    KO_BASE['left_right:first:v1'][0],
    KO_BASE['left_right:first:v1'][1],
    '추상적인 나침반 감각을 보행이나 도로 주행의 길잡이로 삼는 것.'
)
KO_BASE['left_right:second'] = (
    KO_BASE['left_right:second'][0],
    KO_BASE['left_right:second'][1],
    '상징적인 극성을 차량 운전이나 기계 조작 같은 물리적 안전 판단에 대입하는 것.'
)
KO_BASE['left_right:second:v1'] = (
    KO_BASE['left_right:second:v1'][0],
    KO_BASE['left_right:second:v1'][1],
    '실제 도로 표지판이나 교통 법규를 무시하고 막연한 기분에 의존하는 것.'
)

KO_CAREER['career:left_right:first'] = (
    KO_CAREER['career:left_right:first'][0],
    KO_CAREER['career:left_right:first'][1],
    '상징적인 직관을 기술 시스템이나 현장 장비의 안전 판단 근거로 삼는 것.'
)
KO_CAREER['career:left_right:first:v1'] = (
    KO_CAREER['career:left_right:first:v1'][0],
    KO_CAREER['career:left_right:first:v1'][1],
    '실무 지침을 건너뛰고 단순한 주관적 느낌만으로 업무상 조작을 감행하는 것.'
)
KO_CAREER['career:left_right:second'] = (
    KO_CAREER['career:left_right:second'][0],
    KO_CAREER['career:left_right:second'][1],
    '상징적인 극성을 직무상의 물리적 작업이나 기계 설비 안전에 끌어다 쓰는 것.'
)
KO_CAREER['career:left_right:second:v1'] = (
    KO_CAREER['career:left_right:second:v1'][0],
    KO_CAREER['career:left_right:second:v1'][1],
    '객관적인 위험 평가를 거치지 않고 직관에 기대어 기술적 방향을 바꾸는 것.'
)

KO_LOVE['love:left_right:first'] = (
    KO_LOVE['love:left_right:first'][0],
    KO_LOVE['love:left_right:first'][1],
    '상징적인 예감에 의존해 상대의 진심 어린 마음을 제멋대로 단정하는 것.'
)
KO_LOVE['love:left_right:first:v1'] = (
    KO_LOVE['love:left_right:first:v1'][0],
    KO_LOVE['love:left_right:first:v1'][1],
    '서로 나누는 따뜻한 대화 대신 추상적인 상징을 들이대며 결론을 내리는 것.'
)
KO_LOVE['love:left_right:second'] = (
    KO_LOVE['love:left_right:second'][0],
    KO_LOVE['love:left_right:second'][1],
    '혼자만의 상징적 추측으로 부정적인 이야기를 꾸며내어 신뢰를 흔드는 것.'
)
KO_LOVE['love:left_right:second:v1'] = (
    KO_LOVE['love:left_right:second:v1'][0],
    KO_LOVE['love:left_right:second:v1'][1],
    '조용한 성찰을 위한 비유를 확정된 사실처럼 오해하여 상대를 압박하는 것.'
)

KO_MONEY['money:left_right:first'] = (
    KO_MONEY['money:left_right:first'][0],
    KO_MONEY['money:left_right:first'][1],
    '상징적인 직관을 무모한 자원 지출이나 위험한 계약 결정에 적용하는 것.'
)
KO_MONEY['money:left_right:first:v1'] = (
    KO_MONEY['money:left_right:first:v1'][0],
    KO_MONEY['money:left_right:first:v1'][1],
    '단순한 기분을 자산의 안전을 보장하는 증거로 맹신하는 것.'
)
KO_MONEY['money:left_right:second'] = (
    KO_MONEY['money:left_right:second'][0],
    KO_MONEY['money:left_right:second'][1],
    '구체적인 수치 계산을 생략한 채 막연한 예감만 믿고 예산을 운용하는 것.'
)
KO_MONEY['money:left_right:second:v1'] = (
    KO_MONEY['money:left_right:second:v1'][0],
    KO_MONEY['money:left_right:second:v1'][1],
    '비상 자금의 완충력을 갖추지 않고 충동적인 지출 변경을 시도하는 것.'
)

KO_STUDY['study:left_right:first'] = (
    KO_STUDY['study:left_right:first'][0],
    KO_STUDY['study:left_right:first'][1],
    '상징적인 예감에 의존하여 실제 문헌 조사와 논리적 사유를 생략하는 것.'
)
KO_STUDY['study:left_right:first:v1'] = (
    KO_STUDY['study:left_right:first:v1'][0],
    KO_STUDY['study:left_right:first:v1'][1],
    '체계적인 복습 대신 시험에서의 운이나 요행을 바라는 것.'
)
KO_STUDY['study:left_right:second'] = (
    KO_STUDY['study:left_right:second'][0],
    KO_STUDY['study:left_right:second'][1],
    '기본적인 학술 개념을 온전히 이해하지 않고 직관만으로 답을 속단하는 것.'
)
KO_STUDY['study:left_right:second:v1'] = (
    KO_STUDY['study:left_right:second:v1'][0],
    KO_STUDY['study:left_right:second:v1'][1],
    '직접 풀어보는 실습 과정을 건너뛰고 눈으로만 대충 훑어보는 것.'
)

KO_FRIENDS['friends:commit_withdraw:second:v2'] = (
    KO_FRIENDS['friends:commit_withdraw:second:v2'][0],
    KO_FRIENDS['friends:commit_withdraw:second:v2'][1],
    '부탁을 거절했다고 해서 스스로를 비정하고 이기적인 사람으로 몰아세우는 것.'
)
KO_FRIENDS['friends:left_right:first:v1'] = (
    KO_FRIENDS['friends:left_right:first:v1'][0],
    KO_FRIENDS['friends:left_right:first:v1'][1],
    '친구의 사소한 말실수나 연락 지연 뒤에 숨은 악의를 제멋대로 짐작하는 것.'
)
KO_FRIENDS['friends:left_right:second'] = (
    KO_FRIENDS['friends:left_right:second'][0],
    KO_FRIENDS['friends:left_right:second'][1],
    '막연한 상징적 인상에 휘둘려 모임 구성원 사이에 불필요한 의심을 품는 것.'
)
KO_FRIENDS['friends:left_right:second:v1'] = (
    KO_FRIENDS['friends:left_right:second:v1'][0],
    KO_FRIENDS['friends:left_right:second:v1'][1],
    '친구가 바쁜 일상을 보내고 있을 뿐인데 고의로 멀리한다고 오해하는 것.'
)

import fix_ja_duplicates


# Re-assemble JA & KO

ja_all = {}
for mod in [JA_BASE, JA_CAREER, JA_LOVE, JA_MONEY, JA_STUDY, JA_FRIENDS, JA_OTHER]:
    ja_all.update(mod)

ko_all = {}
for mod in [KO_BASE, KO_CAREER, KO_LOVE, KO_MONEY, KO_STUDY, KO_FRIENDS, KO_OTHER]:
    ko_all.update(mod)

# Validate JA & KO
for lang, data, forbidden in [('JA', ja_all, ['投資', 'お金', '給料', '借金', '買う', '売る', '恋人', '別れ', '離婚', '退職', '結婚']),
                              ('KO', ko_all, ['투자', '돈', '급여', '대출', '구매', '사다', '팔다', '연인', '결혼', '이혼', '퇴사', '헤어지'])]:
    print(f"\n--- {lang} Validation (Total: {len(data)}) ---")
    h_c = Counter(v[0] for v in data.values())
    s_c = Counter(v[1] for v in data.values())
    a_c = Counter(v[2] for v in data.values())
    dup_h = [h for h, c in h_c.items() if c > 1]
    dup_s = [s for s, c in s_c.items() if c > 1]
    dup_a = [a for a, c in a_c.items() if c > 1]
    print(f"  {lang} duplicate headlines: {len(dup_h)}")
    for h in dup_h:
        print(f"    H: {h}")
    print(f"  {lang} duplicate should_dos: {len(dup_s)}")
    for s in dup_s:
        print(f"    S: {s}")
    print(f"  {lang} duplicate avoids: {len(dup_a)}")
    for a in dup_a:
        print(f"    A: {a}")

    fb_hits = []
    for k, (h, s, a) in data.items():
        text = f"{h} {s} {a}"
        for w in forbidden:
            if w in text:
                fb_hits.append((k, w))
    print(f"  {lang} forbidden hits: {len(fb_hits)}")
    for f in fb_hits:
        print(f"    {f}")

    if dup_h or dup_s or dup_a or fb_hits:
        print(f"ERROR: {lang} validation failed!")
        sys.exit(1)

print("\nSUCCESS: Both JA and KO have exactly 315 keys, 0 duplicates, 0 forbidden words!")

# Write ja_other.py and ko_other.py
def write_dict_to_file(path, var_name, data, doc_comment):
    lines = [
        "# coding: utf-8",
        f'"""\n{doc_comment}\n"""',
        "",
        f"{var_name} = {{",
    ]
    for k in sorted(data.keys()):
        h, s, a = data[k]
        lines.append(f"    '{k}': (")
        lines.append(f"        {repr(h)},")
        lines.append(f"        {repr(s)},")
        lines.append(f"        {repr(a)},")
        lines.append("    ),")
    lines.append("}")
    lines.append("")
    with open(path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines))

write_dict_to_file(
    os.path.join(TOOL_DIR, 'guidance_builder', 'ja_other.py'),
    'JA_OTHER',
    JA_OTHER,
    'Japanese Action Guidance - Other / General Situation Category (45 keys)'
)
write_dict_to_file(
    os.path.join(TOOL_DIR, 'guidance_builder', 'ko_other.py'),
    'KO_OTHER',
    KO_OTHER,
    'Korean Action Guidance - Other / General Situation Category (45 keys)'
)

# Also rewrite the updated ja_base, career, love, money, study, friends and ko_base, career, love, money, study, friends
modules = [
    (os.path.join(TOOL_DIR, 'guidance_builder', 'ja_base.py'), 'JA_BASE', JA_BASE, 'Japanese Base Guidance (45 keys)'),
    (os.path.join(TOOL_DIR, 'guidance_builder', 'ja_career.py'), 'JA_CAREER', JA_CAREER, 'Japanese Career Guidance (45 keys)'),
    (os.path.join(TOOL_DIR, 'guidance_builder', 'ja_love.py'), 'JA_LOVE', JA_LOVE, 'Japanese Love Guidance (45 keys)'),
    (os.path.join(TOOL_DIR, 'guidance_builder', 'ja_money.py'), 'JA_MONEY', JA_MONEY, 'Japanese Money Guidance (45 keys)'),
    (os.path.join(TOOL_DIR, 'guidance_builder', 'ja_study.py'), 'JA_STUDY', JA_STUDY, 'Japanese Study Guidance (45 keys)'),
    (os.path.join(TOOL_DIR, 'guidance_builder', 'ja_friends.py'), 'JA_FRIENDS', JA_FRIENDS, 'Japanese Friends Guidance (45 keys)'),
    (os.path.join(TOOL_DIR, 'guidance_builder', 'ko_base.py'), 'KO_BASE', KO_BASE, 'Korean Base Guidance (45 keys)'),
    (os.path.join(TOOL_DIR, 'guidance_builder', 'ko_career.py'), 'KO_CAREER', KO_CAREER, 'Korean Career Guidance (45 keys)'),
    (os.path.join(TOOL_DIR, 'guidance_builder', 'ko_love.py'), 'KO_LOVE', KO_LOVE, 'Korean Love Guidance (45 keys)'),
    (os.path.join(TOOL_DIR, 'guidance_builder', 'ko_money.py'), 'KO_MONEY', KO_MONEY, 'Korean Money Guidance (45 keys)'),
    (os.path.join(TOOL_DIR, 'guidance_builder', 'ko_study.py'), 'KO_STUDY', KO_STUDY, 'Korean Study Guidance (45 keys)'),
    (os.path.join(TOOL_DIR, 'guidance_builder', 'ko_friends.py'), 'KO_FRIENDS', KO_FRIENDS, 'Korean Friends Guidance (45 keys)'),
]
for p, var_name, data, doc in modules:
    write_dict_to_file(p, var_name, data, doc)

print("Saved all updated JA and KO modules.")

# Now update build_action_guidance_ja_ko.py to assert 315 keys instead of 285
bg_path = os.path.join(TOOL_DIR, 'build_action_guidance_ja_ko.py')
with open(bg_path, 'r', encoding='utf-8') as f:
    bg_content = f.read()
bg_content = bg_content.replace('assert len(vi_keys) == 285', 'assert len(vi_keys) == 315')
bg_content = bg_content.replace('assert len(ja_keys) == 285', 'assert len(ja_keys) == 315')
bg_content = bg_content.replace('assert len(ko_keys) == 285', 'assert len(ko_keys) == 315')
bg_content = bg_content.replace('285 keys', '315 keys')
with open(bg_path, 'w', encoding='utf-8') as f:
    f.write(bg_content)

# Run build_action_guidance_ja_ko.py
import build_action_guidance_ja_ko
build_action_guidance_ja_ko.main()
print("JA & KO build completed successfully!")
