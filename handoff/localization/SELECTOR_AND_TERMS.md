# Language selector and presentation terms

This file contains editorial names for stable engine/UI identifiers. These translations are **display only**; never change mode values, level values, color keys or zodiac calculations.

## First-launch language selector

The welcome screen shows a globe + current language (`🌐 English ▾` initially). Tapping opens a bottom sheet; no automatic startup popup. The seven options are always written in their own scripts so the selector stays usable before any translation is active:

| Locale | Native option label |
|---|---|
| `en` | English |
| `vi` | Tiếng Việt |
| `ja` | 日本語 |
| `es` | Español |
| `th` | ไทย |
| `hi-IN` | हिन्दी |
| `zh-Hans-CN` | 简体中文 |

| Key | en | vi | ja | es | th | hi-IN | zh-Hans-CN |
|---|---|---|---|---|---|---|---|
| languageSetting | Language | Ngôn ngữ | 言語 | Idioma | ภาษา | भाषा | 语言 |
| chooseLanguage | Choose your language | Chọn ngôn ngữ | 言語を選択 | Elige tu idioma | เลือกภาษา | अपनी भाषा चुनें | 选择语言 |
| changeLanguage | Change language | Đổi ngôn ngữ | 言語を変更 | Cambiar idioma | เปลี่ยนภาษา | भाषा बदलें | 切换语言 |

Do not infer the language from current country or birthplace. Store the chosen locale before creating a profile. The selected language rerenders the welcome screen, onboarding, date/time pickers and safety sheet immediately. Keep the same selector reachable from Home/profile settings after onboarding.

## Decision choices (result text and mode tiles)

Use one localized token for a choice everywhere, including Result and History. `ADVANCE/RETREAT` are strategic approach/pullback; `FORWARD/BACKWARD` are symbolic direction, **never physical navigation**.

| Stable choice | en | vi | ja | es | th | hi-IN | zh-Hans-CN |
|---|---|---|---|---|---|---|---|
| yes | YES | CÓ | はい | SÍ | ใช่ | हाँ | 是 |
| no | NO | KHÔNG | いいえ | NO | ไม่ | नहीं | 否 |
| act | ACT | HÀNH ĐỘNG | 行動する | ACTUAR | ลงมือ | कदम उठाएँ | 行动 |
| wait | WAIT | CHỜ ĐỢI | 待つ | ESPERAR | รอ | प्रतीक्षा करें | 等待 |
| advance | ADVANCE | TIẾN TỚI | 踏み込む | AVANZAR | รุก | आगे बढ़ें | 推进 |
| retreat | RETREAT | LÙI LẠI | 引く | RETIRARSE | ถอย | पीछे हटें | 退守 |
| stay | STAY | Ở LẠI | とどまる | QUEDARSE | อยู่ต่อ | रुकें | 留下 |
| go | GO | RỜI ĐI | 離れる | IRSE | ออกไป | चले जाएँ | 离开 |
| keep | KEEP | GIỮ LẠI | 持ち続ける | CONSERVAR | เก็บไว้ | रखें | 保留 |
| letGo | LET GO | BUÔNG BỎ | 手放す | SOLTAR | ปล่อยวาง | छोड़ दें | 放下 |
| forward | FORWARD | VỀ PHÍA TRƯỚC | 前へ | HACIA DELANTE | ไปข้างหน้า | आगे की ओर | 向前 |
| backward | BACKWARD | VỀ PHÍA SAU | 後ろへ | HACIA ATRÁS | ย้อนกลับ | पीछे की ओर | 向后 |
| left | LEFT | BÊN TRÁI | 左 | IZQUIERDA | ซ้าย | बाएँ | 左 |
| right | RIGHT | BÊN PHẢI | 右 | DERECHA | ขวา | दाएँ | 右 |

Do not reconstruct a mode label by English punctuation. Display localized first + localized slash + localized second; let the layout wrap or scale moderately on narrow screens. Keep the winning choice more prominent than its percent. The safety sheet must explain that LEFT/RIGHT and FORWARD/BACKWARD never direct driving or physical movement.

## Daily energy tone labels

| Engine level | en | vi | ja | es | th | hi-IN | zh-Hans-CN |
|---|---|---|---|---|---|---|---|
| quiet | QUIET | TĨNH LẶNG | 静穏 | SERENA | สงบ | शांत | 宁静 |
| soft | SOFT | DỊU NHẸ | やわらか | SUAVE | อ่อนโยน | कोमल | 柔和 |
| steady | STEADY | ỔN ĐỊNH | 安定 | ESTABLE | มั่นคง | स्थिर | 平稳 |
| lively | LIVELY | SÔI NỔI | 活発 | VIVA | มีชีวิตชีวา | जीवंत | 活跃 |
| bright | BRIGHT | TƯƠI SÁNG | 明るい | LUMINOSA | สดใส | उज्ज्वल | 明亮 |
| radiant | RADIANT | RỰC RỠ | 輝き | RADIANTE | เปล่งประกาย | दीप्तिमान | 璀璨 |
| focused | FOCUSED | TẬP TRUNG | 集中 | ENFOCADA | มุ่งมั่น | केंद्रित | 专注 |
| flowing | FLOWING | LINH HOẠT | 流動 | FLUIDA | ลื่นไหล | प्रवाहमान | 流动 |

`unavailable` has no public label or insight; show the existing unavailable state. The level is a symbolic tone, not a physical measurement or probability. Avoid forced all-caps/letter spacing for Japanese, Thai, Hindi and Chinese.

## Twenty color names (stable `DailyColor.key`)

| Color key | en | vi | ja | es | th | hi-IN | zh-Hans-CN |
|---|---|---|---|---|---|---|---|
| cedar | Cedar | Tuyết tùng | シダー | Cedro | ซีดาร์ | देवदार | 雪松 |
| jade | Jade | Ngọc bích | 翡翠 | Jade | หยก | जेड | 翡翠 |
| sage | Sage | Xanh xô thơm | セージ | Salvia | เขียวเสจ | सेज | 鼠尾草绿 |
| mint | Mint | Xanh bạc hà | ミント | Menta | เขียวมิ้นต์ | पुदीना | 薄荷绿 |
| ember | Ember | Than hồng | 残り火 | Brasa | ถ่านแดง | अंगारा | 余烬 |
| solar_coral | Solar Coral | San hô nắng | サンコーラル | Coral solar | ปะการังแดด | धूपिया मूँगा | 阳光珊瑚 |
| rose | Rose | Hồng phấn | ローズ | Rosa | กุหลาบ | गुलाबी | 玫瑰粉 |
| blossom | Blossom | Hồng cánh hoa | ブロッサムピンク | Floración | ชมพูดอกไม้ | फूलों सा गुलाबी | 花瓣粉 |
| ochre | Ochre | Đất son | オーカー | Ocre | เหลืองดิน | गेरू | 赭石 |
| amber | Amber | Hổ phách | 琥珀 | Ámbar | อำพัน | अंबर | 琥珀 |
| sand | Sand | Cát | サンド | Arena | ทราย | रेत | 沙色 |
| clay | Clay | Đất nung | クレイ | Arcilla | ดินเผา | चिकनी मिट्टी | 陶土色 |
| silver | Silver | Bạc | シルバー | Plata | เงิน | चाँदी | 银色 |
| steel | Steel | Thép | スチール | Acero | เหล็ก | इस्पात | 钢蓝 |
| pearl | Pearl | Ngọc trai | パール | Perla | ไข่มุก | मोती | 珍珠白 |
| champagne | Champagne | Sâm panh | シャンパン | Champán | แชมเปญ | शैम्पेन | 香槟色 |
| ocean_blue | Ocean Blue | Xanh đại dương | オーシャンブルー | Azul océano | ฟ้าน้ำทะเล | समुद्री नीला | 海洋蓝 |
| azure | Azure | Xanh thiên thanh | アジュール | Azul celeste | ฟ้าคราม | आसमानी नीला | 天青蓝 |
| indigo | Indigo | Chàm | インディゴ | Índigo | คราม | नील | 靛蓝 |
| mist_blue | Mist Blue | Xanh sương mù | ミストブルー | Azul bruma | ฟ้าหมอก | धुँधला नीला | 雾蓝 |

Color names are **editorial** labels for hex shades, not personal favorable-element or Yong Shen claims. The color key and hex stay unchanged. QA should compare the displayed label against its actual swatch; a native reviewer may refine shade naming without touching calculations.
