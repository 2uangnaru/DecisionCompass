# Decision Compass — UX/UI Specification v1

Phiên bản: 1.1 • 21/09/2026  
Thị trường: Global, ưu tiên Tier 1  
Nền tảng: Mobile portrait, iOS + Android  
Định vị hình ảnh: **Celestial Observatory — mystical, modern, calm, trustworthy**

## 1. Nguyên tắc sản phẩm

App không yêu cầu người dùng mô tả vấn đề. Nó đọc hồ sơ cá nhân và khoảnh khắc hiện tại,
sau đó đưa ra một hướng nghiêng biểu tượng giữa hai lựa chọn.

Trải nghiệm phải đạt bốn cảm giác theo đúng thứ tự:

1. **Curiosity:** “App đang đọc khoảnh khắc của riêng mình.”
2. **Control:** Người dùng chủ động chọn cặp quyết định và thời điểm.
3. **Ritual:** Chạm một lần và xem quá trình phân tích ngắn, có chiều sâu.
4. **Clarity:** Kết quả xuất hiện rõ trong một giây, không buộc đọc bài luận dài.

Không dùng hình ảnh sòng bạc, vòng quay may mắn, hòm quà rung, đồng hồ đếm ngược giả
hoặc biểu tượng “AI”. Không dùng sọ người, máu, lửa, quỷ, lời nguyền hoặc các thuật ngữ
gây sợ hãi. Bí ẩn đến từ chuyển động, chiều sâu, ánh sáng và hình học thiên văn.

## 2. Hướng nghệ thuật

### 2.1 Chủ đề

Không gian nền là bầu trời đêm sâu kết hợp đường quỹ đạo mảnh, vòng thiên thể,
chấm sao và các nút dữ liệu nhỏ. Hình học phong thủy chỉ xuất hiện như họa tiết trừu tượng;
không sử dụng la bàn nhà cửa vì module phong thủy không gian đã bị loại khỏi MVP.

Avatar cung hoàng đạo là huy hiệu tròn tối giản, nét kim loại mờ, có một dải sáng chuyển động
rất chậm. Mỗi cung có biểu tượng riêng nhưng dùng cùng một hệ hình học để app thống nhất.

### 2.2 Bảng màu

| Token | Màu | Mục đích |
|---|---|---|
| `bg/deep` | `#0A1020` | Nền sâu nhất, đã nâng sáng cho màn OLED/LCD |
| `bg/raised` | `#111B2E` | Card và bottom sheet |
| `surface/glass` | `#1A2943` at 89% | Panel nổi, blur nhẹ |
| `line/subtle` | `#35496A` | Viền/quỹ đạo |
| `text/primary` | `#F4F7FC` | Tiêu đề, kết quả |
| `text/secondary` | `#BAC6DB` | Mô tả |
| `text/muted` | `#8795AE` | Metadata |
| `accent/gold` | `#D8B66A` | Chi tiết huyền bí, không dùng cho CTA chính |
| `accent/violet` | `#786FE8` | Trạng thái phân tích |
| `yes/base` | `#2477C9` | YES/action tích cực |
| `yes/light` | `#62B7E8` | Ánh sáng và gradient YES |
| `no/base` | `#B95F62` | NO/caution thân thiện |
| `no/light` | `#D98A7C` | Ánh sáng và gradient NO |
| `success` | `#4EBB91` | Hoàn tất thao tác, không dùng thay YES |
| `warning` | `#D6A45D` | Thiếu dữ liệu nhẹ |

YES luôn là xanh nước biển. NO là đỏ đất/terracotta, tránh đỏ báo động `#FF0000`.
Mọi trạng thái đều có icon và text; không truyền nghĩa chỉ bằng màu.

### 2.3 Gradient

- Nền mặc định: `#0A1020 → #18243C`, từ trên xuống dưới.
- YES result: `#071729 → #103B68 → #2477C9`, glow xanh nhạt quanh tâm.
- NO result: `#1A1018 → #552D36 → #A9575C`, glow coral mờ.
- Balanced: `#101429 → #272659 → #786FE8`.

### 2.4 Typography

- Display/headline: serif thanh lịch, nét tương phản vừa phải; dùng cho tên kết quả và headline.
- UI/body/numbers: sans-serif hình học, dễ đọc; dùng tab, form và phần trăm.
- Số phần trăm dùng tabular numerals để animation không rung chiều rộng.
- Không dùng font “phù thủy”, chữ rune hoặc chữ viết tay cho nội dung chức năng.

Scale đề xuất trên khung 390×844:

| Style | Size/line | Weight |
|---|---:|---:|
| Result hero | 64/68 | 600 |
| Display | 36/42 | 500 |
| H1 | 28/34 | 600 |
| H2 | 22/28 | 600 |
| Body | 16/24 | 400 |
| Label | 14/20 | 600 |
| Caption | 12/16 | 500 |

### 2.5 Spacing và hình dạng

- Grid cơ sở 4 px; khoảng cách chính 8/12/16/24/32.
- Lề màn hình 20 px; vùng chạm tối thiểu 44×44 px.
- Card radius 20 px; button radius 18–24 px; chip radius 999 px.
- Viền 1 px, opacity thấp. Shadow mềm, không dùng drop shadow đen dày.
- Nội dung chính nằm trong safe area; CTA dưới cách home indicator ít nhất 12 px.

## 3. Information architecture

Bottom navigation sau onboarding gồm ba mục:

1. **Today:** Daily Brief, decision modes và thời điểm.
2. **History:** Kết quả đã xem, không reroll.
3. **Profile:** Hồ sơ sinh, location permission, subscription và settings.

Paywall mở bằng sheet hoặc full-screen modal, không có tab riêng.

## 4. Luồng lần đầu mở app

### Screen O1 — Location pre-permission

Hiện ngay lần mở đầu theo yêu cầu sản phẩm, trước system permission.

**Visual:** quả cầu nhỏ hoặc vòng quỹ đạo đặt trên chấm sáng định vị; nền sao chuyển rất chậm.

**English copy:**

```text
Set your local timing

Your current location helps align today’s reading
with your local date and time zone.

[ Continue ]
[ Use device time zone ]
```

Footnote: `Used only to determine your current region and time zone.`

- `Continue`: gọi system permission `When In Use`/foreground; approximate location được chấp nhận.
- `Use device time zone`: không gọi permission, tiếp tục onboarding.
- Denied/timeout/location off: toast nhẹ `Using your device time zone instead.` rồi tiếp tục.
- Không hiện lại pre-permission mỗi lần mở. Settings có nút bật lại quyền.

### Screen O2 — Value proposition

```text
Clarity for the moment you’re in

Your personal cycles, today’s timing and celestial patterns
come together in one simple direction.

[ Begin ]
```

Ba motif nhỏ, không phải feature list dài: `Personal cycles` • `Current timing` • `One clear direction`.

### Screen O3 — Name

```text
What should we call you?
[ Name or nickname                         ]
[ Continue ]
```

Tên dùng cho header và notification; 1–30 ký tự. Cho phép Unicode. Không bắt họ tên thật.

### Screen O4 — Birth date

```text
When were you born?
Your date shapes your personal cycles.

[ Month ] [ Day ] [ Year ]
[ Continue ]
```

Thứ tự hiển thị theo locale, nhưng JSON luôn `YYYY-MM-DD`. Không cho ngày tương lai.

### Screen O5 — Birth time

```text
Do you know your birth time?

[ 2:30 PM                         ]
[ I don’t know my birth time     ]
```

Nếu không biết: helper text `That’s okay. We’ll use only the parts that stay consistent.`
Không cảnh báo đỏ hoặc tạo cảm giác hồ sơ “kém”.

### Screen O6 — Birth country

```text
Where were you born?
[ Search country                         ]
```

- Search theo tên tiếng Anh, tên bản địa và ISO code.
- Suggest quốc gia thiết bị ở đầu danh sách nhưng user phải xác nhận.
- Nếu quốc gia có nhiều birth timezone, engine giữ các ứng viên. MVP không hỏi thành phố.
- Helper: `We won’t use your current location as your birthplace.`

### Screen O7 — Traditional chart setting

Copy global, trung tính:

```text
Traditional chart setting

Some traditional systems calculate personal cycles using
one of two historical conventions. Choose the one that applies to you.

[ Male convention ]
[ Female convention ]
[ Prefer not to say ]
```

Nếu skip: engine xét các kịch bản phù hợp và giảm data coverage. Không hỏi lại trước mỗi reading.

### Screen O8 — Profile created

Vòng zodiac avatar được dựng từ birth date; các vòng quỹ đạo khóa vào vị trí với haptic nhẹ.

```text
Your compass is ready

[ Enter today’s reading ]
```

Không hiện kết quả bói hoặc paywall ở đây.

## 5. Today/Home

### 5.1 Header

```text
[Zodiac avatar]  Good evening, Alex        [streak optional]
                 Sep 19 • Ho Chi Minh City
```

Nếu không có reverse-geocoded city, chỉ hiện `Local time • UTC+7`; không bịa tên thành phố.

### 5.2 Daily Brief card

Card ngang có nền glass:

```text
TODAY’S SIGNALS

[color swatch] Ocean Blue       Lucky number  7
Daily energy  Steady
```

`Daily energy` chỉ là nhãn ánh xạ từ điểm tổng hợp: `Reflective / Steady / Open / Active`.
Không dùng `Bad day`, `Danger` hoặc `Guaranteed luck`.

### 5.3 Main prompt

Headline:

```text
A choice is on your mind.
Choose the direction you need.
```

Mode cards dạng grid 2 cột; YES/NO chiếm full width ở trên vì là core action:

```text
[        YES  /  NO        ]
[ STAY / GO ] [ ACT / WAIT ]
[ KEEP / LET GO ] [ ADVANCE / RETREAT ]
[ FORWARD / BACKWARD ] [ LEFT / RIGHT ]
```

Card có hai nửa cân bằng, icon trừu tượng, không dùng icon thumbs up/down. Selected card có viền xanh-violet,
glow nhỏ và scale 1.01. Không tính kết quả khi chỉ chọn card.

### 5.3.1 Ma trận bảy Decision Mode

Tất cả mode dùng chung engine và cùng cấu trúc kết quả; chỉ thay trục diễn giải, nhãn và màu. Không mode nào
được mô tả là “đúng/sai” hoặc “tốt/xấu”.

| Mode | Trục nội bộ | Vế thứ nhất | Vế thứ hai | Màu đề xuất |
|---|---|---|---|---|
| `YES / NO` | Action alignment | `YES` | `NO` | Ocean blue / terracotta |
| `ACT / WAIT` | Action timing | `ACT` | `WAIT` | Teal-blue / warm amber |
| `ADVANCE / RETREAT` | Momentum | `ADVANCE` | `RETREAT` | Celestial blue / muted plum |
| `STAY / GO` | Change alignment | `STAY` | `GO` | Indigo / teal |
| `KEEP / LET GO` | Attachment alignment | `KEEP` | `LET GO` | Deep blue / soft coral |
| `FORWARD / BACKWARD` | Temporal momentum | `FORWARD` | `BACKWARD` | Celestial blue / muted violet |
| `LEFT / RIGHT` | Symbolic polarity | `LEFT` | `RIGHT` | Moon blue / solar gold |

- Kết quả luôn hiện cả hai vế và hai phần trăm cộng thành 100.
- `WAIT`, `RETREAT`, `STAY` và `LET GO` là các hướng hợp lệ, không dùng màu/lời rung báo động.
- CTA dùng thống nhất `Find My Direction`; screen reader đọc đúng mode đang chọn.
- Loading có một câu ritual riêng theo mode; module nền vẫn dựa trên cùng profile + moment snapshot.
- `FORWARD/BACKWARD` thiên về chuyển động qua thời gian; `LEFT/RIGHT` là polarity biểu tượng
  (LEFT tiếp nhận/hướng nội, RIGHT biểu đạt/hướng ngoại). Không tái sử dụng nguyên điểm YES/NO.

### 5.4 Time selector

Label global:

```text
When are you considering it?

[ NOW ] [ Morning ] [ Midday ] [ Afternoon ] [ Evening ]
```

- `NOW` mặc định, không hiện giờ cụ thể trên chip.
- Chip đã qua trong ngày chuyển disabled 50% opacity; tap mở tooltip `This time has already passed today.`
- Buổi đang diễn ra vẫn chọn được; Top 2 chỉ xét phần thời gian còn lại.
- Buổi tương lai có icon khóa nếu chưa free/unlocked.

### 5.5 CTA

Sau khi chọn mode:

```text
[ Find My Direction ]
```

Đây là copy CTA chính. Tránh `Predict My Future`, `Ask Fate`, `Get the Truth` vì tạo kỳ vọng quá mức.

Nếu period bị khóa, CTA trở thành:

```text
[ Watch to Unlock ]  ▶
```

Subtext: `Unlocks this time period for today.` Quảng cáo chạy trước ritual/loading.

## 6. Reading ritual

### Screen R1 — One-tap ritual

Layout tập trung, không bottom nav:

```text
YES  /  NO

        [ zodiac avatar ]
     [ circular reveal button ]

Tap when you’re ready
Focus on the choice in your mind.

NOW • Local timing
```

- Một lần chạm duy nhất. Button nén xuống `0.96` trong 100–120 ms, phát một xung sáng hướng tâm và khóa quỹ đạo
  trong khoảng 350 ms; haptic nhẹ xác nhận đã nhận lệnh.
- Khóa button ngay ở pointer-down hợp lệ, bỏ qua double tap và không cho gửi hai request.
- Chốt profile, mode, period, location/timezone và local timestamp tại lần chạm đó. Không đổi snapshot trong loading.
- Nếu cần Rewarded Ad, quảng cáo phải hoàn tất trước khi vào màn ritual; lần chạm không bao giờ bất ngờ mở quảng cáo.
- Đây là button tiêu chuẩn cho accessibility, không có long-press/hold. Screen reader label mẫu:
  `Find my direction for YES or NO, now.`

### Screen R2 — Analysis/loading

Thời lượng mục tiêu 4.2–5.2 giây, lấy ngẫu nhiên có kiểm soát trong khoảng này để chuyển động không máy móc.
Engine có thể chạy trước; animation không kéo quá 5.2 giây trừ khi đang chờ dữ liệu thật.

**Centerpiece:** zodiac avatar ở giữa; ba vòng khác tốc độ quay chậm, các điểm dữ liệu lần lượt khóa vào vòng.
Một đường quét mảnh đi qua avatar; không dùng spinner hệ thống.

Loading chia thành sáu pha chính, mỗi pha khoảng 650–750 ms. Copy dùng hai lớp độc lập:

1. **Verified module layer:** tên hệ thống thực sự tham gia tính toán, xuất hiện nhỏ trên quỹ đạo.
2. **Ritual narrative layer:** câu chữ biểu tượng tạo cảm giác đang diễn giải sâu; được chọn ngẫu nhiên từ copy pool,
   không cần ánh xạ 1–1 với module nhưng không được giả là một phép đo khoa học hoặc một khả năng app không có.

Verified module layer:

| Module thực chạy | Copy được phép hiện |
|---|---|
| Bát Tự | `Reading your BaZi elemental balance` |
| Tử Vi | `Mapping your Zi Wei cycles` |
| Can Chi + lịch ngày/giờ | `Checking today’s Can Chi and hour` |
| Thần số học | `Tracing your numerology rhythm` |
| Western astrology | `Comparing your planetary transits` |
| Moon/planetary state | `Reading the Moon’s current phase` / `Tracking planetary motion` |
| Fusion engine | `Balancing Yin and Yang signals` / `Bringing the patterns into alignment` |

Ritual narrative pool dùng cho center copy:

| Pha | Copy có thể luân phiên |
|---|---|
| 1 — Enter the moment | `Centering on your present moment` • `Opening the pattern around this choice` • `Synchronizing with your local time` |
| 2 — Personal rhythm | `Listening to your inner rhythm` • `Tracing the cycle surrounding you` • `Reading the balance between impulse and intuition` |
| 3 — Cosmic context | `Following today’s celestial rhythm` • `Reading the space between timing and intention` • `Aligning personal and universal cycles` |
| 4 — Synthesis | `Letting the strongest pattern surface` • `Finding where the moment leans` • `Bringing hidden tensions into balance` • `Preparing your direction` |

Pha 3 có thêm một câu riêng theo Decision Mode:

| Mode | Mode-specific ritual copy |
|---|---|
| YES / NO | `Testing openness against resistance` |
| ACT / WAIT | `Balancing momentum against patience` |
| ADVANCE / RETREAT | `Reading expansion against withdrawal` |
| STAY / GO | `Comparing roots with movement` |
| KEEP / LET GO | `Weighing continuity against release` |
| FORWARD / BACKWARD | `Tracing forward motion against returning energy` |
| LEFT / RIGHT | `Balancing receptive and expressive polarity` |

Center chỉ hiện sáu câu lớn để vẫn đọc được trong 4.2–5.2 giây. Đồng thời 6–8 node nhỏ khóa dần vào quỹ đạo.
Node kỹ thuật có thể là `BAZI`, `ZI WEI`, `CAN CHI`, `NUMEROLOGY`, `LUNAR PHASE`, `PLANETARY MOTION`,
`FUSION`; node không kỹ thuật dùng các từ trừu tượng `INTENTION`, `MOMENT`, `RHYTHM`, `BALANCE`, `MOTION`,
`STILLNESS`. Nhờ vậy loading trông nhiều lớp mà không bắt người dùng đọc một danh sách dài.

UI nhận `analysisTrace[]` từ engine; mỗi phần tử tối thiểu có `moduleKey`, `status`, `copyKey` và `completedAt`.
`analysisTrace` chỉ điều khiển verified module layer. Ritual narrative layer được điều khiển bởi `phase + mode + locale`
và có thể tiếp tục đến mốc reveal nếu engine hoàn tất sớm.

Quy tắc:

- Không hiện `Reading your birth hour` nếu birth time unknown.
- Nếu giờ sinh không rõ, dùng `Reading the stable parts of your BaZi chart` và
  `Comparing possible birth-hour patterns`; không tuyên bố đã lập lá số giờ sinh chính xác.
- Không hiện `Checking your space` vì MVP không có phong thủy không gian.
- Không hiện tên module kỹ thuật khi module đó `unavailable` hoặc không tham gia fusion; ritual narrative vẫn được phép chạy.
- Có thể tạo cảm giác “đang đọc nhiều lớp”, nhưng không hiện phần trăm độ chính xác giả, dữ kiện cá nhân giả,
  phát hiện cảm xúc giả hoặc câu tuyệt đối như `The universe has decided`.
- Kết quả đã tính xong vẫn hoàn thành animation đang chạy rồi mới reveal.
- Lỗi API: vòng dừng nhẹ và chuyển sang error state; không giả ra kết quả offline.

#### Reassurance response khi user chạm liên tục

Trong lúc loading, nếu user chạm màn hình từ hai lần trở lên liên tiếp, app phản hồi bằng một câu trấn an ngắn.
Đây là phản hồi theo hành vi tap, không được mô tả như app đã “đọc được sự lo lắng” của người dùng.

**Trigger chính xác:**

- Bắt đầu đếm sau khi màn loading đã xuất hiện.
- Kích hoạt ở lần tap thứ hai nếu hai tap cách nhau tối đa 900 ms.
- Chỉ kích hoạt một lần trong mỗi reading; các tap sau không đổi copy hoặc tạo thêm hiệu ứng.
- Không reset animation, không chạy lại engine, không thêm haptic, không kéo dài tổng thời lượng 4.2–5.2 giây.
- Nếu trigger xảy ra khi còn dưới 700 ms trước reveal, hiện câu đến lúc result xuất hiện; không chen thêm câu loading khác.
- Không dùng trigger này khi VoiceOver/TalkBack đang bật vì double-tap là gesture điều khiển của screen reader.
- Không đếm tap trên Back, Close hoặc accessibility controls nếu các control này xuất hiện.

Copy global chính:

```text
Give me a moment — I’m still bringing your cosmic signals into focus.
```

Phương án A/B mềm hơn:

```text
Stay with me for a moment — your signals are still coming into focus.
```

Cách hiển thị: center copy hiện tại cross-fade 120 ms sang reassurance, giữ 650–900 ms, sau đó tiếp tục ở câu
loading kế tiếp thay vì quay lại câu cũ. Avatar/quỹ đạo vẫn chuyển động bình thường. Không dùng `Calm down`,
`Be patient`, dấu chấm than hoặc rung cảnh báo vì dễ khiến người dùng cảm thấy bị trách móc.

## 7. Result screen

### 7.1 Reveal

Transition 650–900 ms:

1. Vòng loading thu nhỏ.
2. Nền chuyển gradient theo kết quả.
3. Winner fade/scale từ 0.92 → 1.
4. Phần trăm count-up trong 550 ms.
5. Haptic success mềm; NO dùng cùng cường độ, không rung cảnh báo.

### 7.2 Hierarchy

```text
YOUR DIRECTION

YES
64%

NO 36%
[ Clear lean ]

Based on your personal cycles and this moment.
```

Alignment labels:

| Chênh khỏi 50 | Nhãn English |
|---:|---|
| 0 | `Evenly balanced` |
| 1–7 | `Gentle lean` |
| 8–17 | `Clear lean` |
| 18–40 | `Strong lean` |

Không dùng `confidence`, `accuracy`, `chance of success` hoặc `certain`.

### 7.2.1 Result copy theo từng mode

```text
YES / NO              YOUR DIRECTION  YES      64%   • NO 36%
ACT / WAIT            YOUR DIRECTION  WAIT     61%   • ACT 39%
ADVANCE / RETREAT     YOUR DIRECTION  ADVANCE  58%   • RETREAT 42%
STAY / GO             YOUR DIRECTION  GO       58%   • STAY 42%
KEEP / LET GO         YOUR DIRECTION  LET GO   63%   • KEEP 37%
FORWARD / BACKWARD    YOUR DIRECTION  FORWARD  57%   • BACKWARD 43%
LEFT / RIGHT          YOUR DIRECTION  RIGHT    54%   • LEFT 46%
```

Đây chỉ là ví dụ layout; winner do engine trả về. Mỗi mode phải có đủ state cho cả hai winner và state `50/50`.
Không dùng câu mang tính mệnh lệnh như `You must leave`, `Do it now` hoặc `Never go back`.

### 7.3 NOW

NOW không có Top 2:

```text
This reading reflects your current moment.
```

### 7.4 Selected period

Copy phải gắn đúng period:

```text
Your Luckiest Times This Evening

[ 7:00 PM – 9:00 PM      72% ]
[ 9:00 PM – 11:00 PM     66% ]
```

- Không dùng `Best Times Today` khi user chọn Evening.
- Score của hai khung không cộng thành 100.
- Nếu còn một khung: `One favorable window remains this evening.`
- Nếu không còn ≥15 phút: `There isn’t enough time left in this period for a timing window.`

### 7.5 Actions

```text
[ Save to History ]      // auto-saved; button chuyển Saved
[ Try Another Direction ]
[ Share Result ]         // phase 2; ảnh không chứa ngày sinh/location
```

Tap `Try Another Direction` quay về Home. Cùng mode/period/profile/ruleset cho lại kết quả đã cache,
không reroll. Nếu đã unlock period trong ngày thì không yêu cầu xem lại ad.

## 8. Monetization UX

### 8.1 Free logic

- Daily Brief miễn phí.
- Một NOW reading miễn phí mỗi ngày.
- Lần đầu onboarding có thêm một bonus period để user thấy Top 2 trước khi gặp paywall.
- Additional period/readings: Rewarded Ad, giới hạn cấu hình ban đầu 2/ngày.
- Period đã mở khóa dùng lại trong ngày trên mọi mode.

### 8.2 Rewarded Ad prompt

Bottom sheet:

```text
Unlock this time period

Watch one short video to reveal your reading and lucky time windows.
Unlocked for the rest of today.

[ Watch Video ]
[ Maybe Later ]
```

- Không bắt quảng cáo giữa loading và result.
- Ad unavailable: `No video is available right now. Please try again shortly.` Giữ selection.
- Ad failed after completion callback: không buộc xem lại; cấp unlock và log lỗi reconciliation.

### 8.3 Premium paywall

Mở sau lần rewarded ad hoàn tất hoặc khi người dùng chủ động tap Premium; không mở ngay sau onboarding.

```text
Unlock Your Full Compass

✓ Every time period
✓ Ad-free access to all directions
✓ No ads
✓ Full history and weekly patterns

[ Start Free Trial ]      // chỉ nếu store offer thực sự tồn tại
[ Continue with Free ]

Restore Purchases
```

Giá lấy trực tiếp từ store và hiển thị đầy đủ chu kỳ thanh toán; không hardcode copy giá trong thiết kế.
Copy chi tiết dưới paywall phải nói rõ responsible-use limits vẫn áp dụng cho Premium.

## 9. History

Group theo ngày, newest first:

```text
TODAY
YES / NO       YES 64%       NOW       8:42 PM
STAY / GO      GO 58%        EVENING   7:10 PM
```

Detail dùng đúng result snapshot cũ, không tính lại khi ruleset/timezone thay đổi. Có badge nhỏ khi kết quả
dùng limited birth data: `Based on available birth details`. Không phơi bày diagnostics kỹ thuật.

Free giữ 7 ngày; Premium giữ toàn bộ lịch sử là cấu hình monetization có thể A/B test.

## 10. Notifications

Chỉ xin quyền notification sau khi user đã xem kết quả đầu tiên.

Các notification opt-in:

- `Your daily signals are ready.`
- `A favorable evening window begins in 30 minutes.`
- Weekly: `Your weekly decision pattern is ready.`

Không gửi: `Something bad will happen`, `You must open now`, hoặc kết quả YES/NO trực tiếp trên lock screen.

## 11. Profile & settings

Sections:

- Identity: name, zodiac avatar.
- Birth profile: date, time/unknown, country, traditional setting.
- Current timing: location permission, resolved timezone, refresh.
- Reading preferences: 12/24-hour time, haptics, reduced motion.
- Subscription: status, manage, restore.
- Privacy: export/delete profile and history.
- About: calculation version, entertainment/symbolic-use note, licenses.

Sửa dữ liệu sinh tạo `profileRevision` mới. Lịch sử cũ giữ nguyên snapshot; không tính lại âm thầm.

## 12. Responsible-use & harmful-use guardrails

### 12.1 Giới hạn có thể và không thể phát hiện

MVP không có ô nhập câu hỏi nên app **không biết** người dùng đang cân nhắc tình cảm, sức khỏe, đầu tư hay một
hành vi nguy hiểm. Vì vậy không được quảng cáo rằng app “tự phát hiện ý định xấu”. Guardrail của MVP dựa trên:

1. Thông báo phạm vi sử dụng rõ ràng.
2. Cấm các nhóm hành vi rủi ro trong Product Policy/Terms.
3. Giới hạn hành vi bấm lặp mang tính lệ thuộc.
4. Copy kết quả không tuyệt đối hóa, đe dọa hoặc thay thế chuyên gia.

### 12.2 Safety acknowledgement một lần

Hiện trước reading đầu tiên, không lặp ở mỗi lần dùng:

```text
For everyday choices only

Do not use Decision Compass for emergencies, health or medication,
legal or financial decisions, gambling, self-harm, violence,
or choices involving another person’s consent.

[ I Understand ]
```

Footer ngắn luôn có ở Result và link đến `Responsible Use`:

```text
For everyday reflection only. Important decisions need real information and qualified help.
```

### 12.3 Các hành vi bị cấm về mặt sản phẩm

- Dùng kết quả để quyết định cấp cứu, chẩn đoán, dùng/ngừng thuốc hoặc thay thế chuyên gia y tế.
- Dùng để quyết định tự hại, tự sát, bạo lực, phạm pháp hoặc gây nguy hiểm cho người khác.
- Dùng để cá cược, giao dịch/đầu tư tài chính hoặc vay nợ.
- Dùng để biện minh cho ép buộc, theo dõi, quấy rối hoặc quyết định thay cho sự đồng thuận của người khác.
- Marketing app như công cụ dự đoán chắc chắn, đo “độ chính xác” hoặc bảo đảm thành công.

Vì không có nội dung câu hỏi, MVP chỉ có thể cấm và cảnh báo, chưa thể semantic-block từng tình huống. Nếu sau
này thêm ô nhập câu hỏi, mọi nội dung thuộc các nhóm trên phải trả safety route, không sinh kết quả bói/định hướng.

### 12.4 Chống bấm lặp và lệ thuộc

- Cùng `profileRevision + mode + period + momentBucket + rulesetVersion` trả lại snapshot cũ; không reroll,
  không phát lại loading như một reading mới và không yêu cầu xem thêm quảng cáo.
- 4 reading hoàn tất trong 10 phút: khóa tạo reading mới trong 2 phút và hiện:

```text
Pause and return to the choice itself
Several readings in a short time can make a decision feel less clear.

[ Review Previous Results ]
Available again in 01:42
```

- Hard cap 12 reading hoàn tất trong một ngày local; Premium bỏ quảng cáo nhưng không bỏ safety cap:

```text
Your compass is resting for today
Use your saved readings and return tomorrow.
```

- Không bán lượt vượt safety cap, không gắn paywall với lời hứa “kết quả chính xác/an toàn hơn”.
- Notification không dùng sợ hãi, FOMO, kết quả xấu hoặc thúc người dùng mở app ngay.
- `Responsible Use` có CTA khẩn cấp trung tính: nếu người dùng hoặc người khác có thể đang gặp nguy hiểm,
  liên hệ dịch vụ khẩn cấp tại địa phương hoặc một người đáng tin cậy ngay. Chỉ thêm danh bạ trợ giúp theo quốc gia
  khi dữ liệu đã được duy trì và kiểm chứng.

## 13. Edge states bắt buộc

| Case | UX |
|---|---|
| Location denied | Dùng timezone thiết bị; banner không chặn `Using device time zone` |
| Location timeout/off | Fallback như trên; Settings có `Try location again` |
| Location nằm sát biên timezone | Dùng device timezone và cho user xem timezone đang active |
| Birth time unknown | Helper trung tính; kết quả vẫn chạy, không cảnh báo đỏ |
| Birth country nhiều timezone | Engine dùng tập ứng viên; Profile có `Add birth region for more detail` ở phase sau, không chặn MVP |
| Traditional setting skipped | Xét hai convention; badge nhẹ trong Profile, không nag mỗi ngày |
| Insufficient data | `We couldn’t form a stable direction from the available details.` Không tiêu lượt/ad |
| Result 50/50 | Nền violet; `Evenly balanced`; không ép chọn bên thắng |
| Period passed | Chip disabled; không tự nhảy sang ngày mai |
| Only one window remains | Hiện một window và copy rõ |
| Less than 15 minutes | Không tạo window giả |
| API/network error | Retry; selection và unlock giữ nguyên |
| Same reading repeated | Trả snapshot cũ; không animation như đang tạo vận mới |
| Rapid repeated readings | Cooldown 2 phút sau reading thứ tư trong 10 phút; dẫn về History |
| Daily safety cap reached | Khóa reading mới đến ngày local tiếp theo; Premium không bypass |
| Ruleset updated | Reading mới dùng version mới; history giữ version cũ |
| Ad unavailable | Giữ selection; không trừ lượt |
| Premium restore offline | Queue restore/retry; không báo thành công giả |

## 14. Motion and sound

- Idle particles: 10–16 điểm trên màn, chuyển động dưới 8 px/giây.
- Orbit: 12–24 giây/vòng; tối đa ba vòng.
- Button press: 120 ms; card select: 180 ms; page transition: 300–380 ms.
- Reveal idle: breathing pulse 1.5 giây, scale tối đa 1.022 và glow nhẹ; tắt hoàn toàn khi Reduced Motion.
- Result reveal: tối đa 900 ms.
- Reduced Motion: tắt parallax/particles/orbit; dùng fade 180 ms.
- Sound mặc định off. Nếu bật: âm pad ngắn dưới 1.2 giây, không voice whisper.
- Haptic chỉ dùng khi tap được nhận/snapshot locked và khi result reveal.

## 15. Accessibility và global UX

- Contrast text tối thiểu 4.5:1; chữ lớn tối thiểu 3:1.
- Dynamic text tới 200%; result percentage có layout thay thế khi text rất lớn.
- Screen reader đọc: `YES, 64 percent. NO, 36 percent. Clear lean.`
- Không dùng gestures độc quyền; ritual là một standard button, không yêu cầu hold hoặc thao tác vận động tinh.
- Ngôn ngữ dài như German phải làm button/card tự tăng chiều cao.
- RTL mirror layout nhưng không đảo nghĩa của các option.
- Thời gian theo locale và setting 12/24 giờ; lưu UTC + IANA timezone.
- Copy tránh idiom Mỹ, từ khó dịch và cách nói về chết chóc/bệnh/tai họa.

## 16. Component inventory

1. `ZodiacAvatar`: 12 variants, idle/loading/result states.
2. `GlassCard`: default/selected/locked/disabled.
3. `DecisionModeCard`: label A/B, icon, state.
4. `TimeChip`: default/selected/locked/elapsed.
5. `PrimaryButton`: default/pressed/loading/disabled/ad-unlock.
6. `RevealButton`: idle/pressed/locked/loading/reduced-motion.
7. `AnalysisOrbit`: 1–3 rings, completed nodes.
8. `ResultHero`: yes/no/balanced theme.
9. `PercentagePair`: winner, counterpart, screen-reader label.
10. `LuckyWindowCard`: primary/secondary/single.
11. `DailyBriefCard`: color, number, energy label.
12. `PermissionExplainer`: location/notification.
13. `UnlockSheet`: rewarded ad.
14. `Paywall`: monthly/annual/store offer/restoring.
15. `InlineStatus`: fallback, partial data, error, offline.

## 17. Prototype scope

Prototype đầu tiên cần tám màn:

1. Location permission explainer.
2. Onboarding birth profile.
3. Today/Home.
4. Mode selected + time selector.
5. One-tap ritual.
6. Loading.
7. YES result with Evening Top 2.
8. NO result with NOW.

Mock data cố định cho visual QA:

```json
{
  "mode": "yes_no",
  "period": "evening",
  "winner": "YES",
  "percentages": { "YES": 64, "NO": 36 },
  "alignmentLabel": "Clear lean",
  "luckyWindows": [
    { "start": "7:00 PM", "end": "9:00 PM", "score": 72 },
    { "start": "9:00 PM", "end": "11:00 PM", "score": 66 }
  ]
}
```

Prototype pass khi người mới có thể: hoàn thành onboarding, hiểu location dùng cho thời gian hiện tại,
chọn mode/period, hoàn tất one-tap ritual, đọc đúng winner + hai phần trăm và phân biệt được Top 2 score
không phải hai phần của 100%.

Ngoài hai màn result mock chính, component QA phải kiểm đủ bảy mode, hai winner/mode và state `50/50`;
đồng thời test double-tap, cooldown, daily safety cap và copy khi không rõ giờ sinh.

## 18. Không nên thêm vào MVP

- Chatbot hoặc ô nhập câu hỏi.
- Feed cộng đồng, tương hợp tình yêu, Tarot và Kinh Dịch.
- Bản đồ sao chi tiết hoặc bài luận dài.
- Gamification bằng coin, chest, spin wheel.
- Friend comparison/social graph.
- Background location.
- Camera, ảnh và video upload.
- Hướng nhà/la bàn phong thủy không gian.

Những phần này làm loãng lời hứa “một khoảnh khắc phân vân → một hướng rõ ràng” và tăng đáng kể phạm vi triển khai.
