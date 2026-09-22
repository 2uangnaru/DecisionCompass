# Decision Compass — Calculation Engine

Engine MVP 3.1.0-mvp, ruleset `civil-midnight-chinese-calendar-symbolic-v4`, triển khai
19/09/2026, metadata đồng bộ 21/09/2026 (không đổi công thức tính). Nhận hồ sơ người dùng
và thời điểm hiện tại, tự lập dữ liệu lịch/lá số/thiên văn rồi trả kết quả số. Chạy offline
trên Node.js, không AI, không API trả phí, không sinh văn bản luận giải, không có random
trong đường tính kết quả.

## Chạy ngay

Dependency đã cài trong workspace này. Tại thư mục `calculation-engine`:

```sh
node examples/demo.js
node src/cli.js examples/request.json
node --test test/*.test.js
```

Máy mới: cài Node.js >=22 và pnpm, chạy `pnpm install --frozen-lockfile --ignore-scripts`.
Giữ `pnpm-lock.yaml` để pin cả thư viện gián tiếp. Python chỉ cần cho bài kiểm tra
đối chiếu code v1/v2, không cần cho runtime.

## Gọi từ code

```js
import { createCalculator } from './src/index.js';

const engine = createCalculator({
  birthDate: '1998-06-21',
  birthTime: '14:30', // null nếu Không rõ
  birthCountry: 'VN',
  traditionalProfile: 'male' // hoặc female, unspecified
});

const result = engine.calculate({
  context: {
    instantUtc: new Date().toISOString(),
    deviceTimezone: 'Asia/Ho_Chi_Minh' // app lấy từ hệ điều hành
  },
  mode: 'yes_no',
  period: 'evening',
  diagnostics: false
});
```

Tạo calculator một lần cho mỗi revision hồ sơ để tái sử dụng dữ liệu sinh đã tính.
`calculate(input)` cũng có sẵn cho lời gọi một lần. `inspectBirthCharts()` xuất
dữ liệu trung gian để kiểm tra. TypeScript contract nằm trong `src/index.d.ts`.

Với vị trí được cấp quyền, thêm `context.location` như `examples/request.json`.
Engine đọc tọa độ nhận từ app; chính app thực hiện màn xin quyền, lấy sensor, xử lý
timeout. Engine không tự bật GPS hoặc xin quyền từ điện thoại.

## Đã triển khai

| Module | Nội dung chạy được |
|---|---|
| Current context | Tọa độ → timezone, fallback timezone thiết bị, UTC/local, DST, tzdb snapshot |
| Lịch | Âm lịch Trung Quốc, tháng nhuận, 24 tiết khí UTC, Can Chi năm/tháng/ngày/giờ, hoàng/hắc đạo, 12 Trực |
| Bát Tự | Lập trụ, tàng can, Thập Thần, phân bố hành, chỉ số mùa, thông căn, quan hệ chi và cấu trúc, Đại vận khi đủ dữ liệu |
| Tử Vi | Tự lập 12 cung, an sao bằng iztro; chấm 14 chính tinh, 12 phụ/sát tinh, độ sáng, Tứ Hóa bản mệnh/đại hạn/năm/tháng/ngày/giờ |
| Western | Sun/Moon/Mercury/Venus/Mars/Jupiter/Saturn thực, natal–transit aspects |
| Thần số học | Life Path, Personal Year/Month/Day |
| Cosmic | Pha Mặt Trăng, vận tốc Mercury, direct/stationary/retrograde |
| Fusion | Hai trục nền A/C, 7 decision modes với projection riêng, phần trăm, độ phủ dữ liệu |
| Time windows | NOW, Morning/Midday/Afternoon/Evening, Top 2, hết buổi, còn một khung, DST fold/gap |
| Audit | Version, input snapshot, module đóng góp, reading key, kết quả có thể tái lập |

Phong thủy không gian đã bỏ khỏi engine mới. Category nhận bảy giá trị:
`general`, `love`, `career`, `money`, `study`, `friends`, `other` — category
quyết định trọng số module, cung đích Tử Vi và bảng nhấn hành tinh Western
trước khi chiếu theo decision mode; giá trị lạ bị từ chối bằng
`INVALID_CATEGORY`. `other` dùng lại công thức của `general` như một fallback
trung thực nhưng vẫn là category riêng với reading snapshot riêng.
Các mode được hỗ trợ: YES/NO, ACT/WAIT, ADVANCE/RETREAT, STAY/GO, KEEP/LET GO,
FORWARD/BACKWARD và LEFT/RIGHT. FORWARD/BACKWARD dùng temporal momentum; LEFT/RIGHT
dùng symbolic polarity (LEFT = receptive/inward, RIGHT = expressive/outward), không đổi nhãn từ YES/NO.

### Projection riêng theo Decision Mode

Sau khi sáu module hợp nhất thành `A` (action) và `C` (change), điểm cho vế thứ nhất của từng mode là:

| Mode | Score vế thứ nhất |
|---|---:|
| YES / NO | `A` |
| ACT / WAIT | `.85A + .15C` |
| ADVANCE / RETREAT | `.55A + .45C` |
| STAY / GO | `-C` |
| KEEP / LET GO | `.30A - .70C` |
| FORWARD / BACKWARD | `.25A + .75C` |
| LEFT / RIGHT | `-.70A + .30C` |

Mọi score được clamp về `[-1, 1]`; phần trăm vế thứ nhất vẫn dùng
`floor(50 + 40 × score + .5)`. Top 2 time windows dùng projection của mode đang chọn,
không còn mặc định xếp theo YES/NO. LEFT/RIGHT là polarity biểu tượng, không dùng để
định hướng giao thông, điều hướng vật lý hoặc quyết định an toàn.

## Quy tắc thiếu dữ liệu

- Không lấy vị trí hiện tại làm nơi sinh.
- Quốc gia sinh nhiều timezone: xét tập timezone ứng viên; không chọn vùng đông dân nhất.
- Nhiều timezone cho cùng một UTC lúc sinh vẫn được xem là một thời điểm xác định.
- Không có thông tin xác định birth UTC: Western natal không khả dụng, không tự gán UTC/12 giờ trưa.
- Không biết giờ sinh: Bát Tự bỏ trụ giờ; các trụ năm/tháng chỉ giữ nếu không đổi trong khoảng sinh khả dĩ.
- Tử Vi không biết giờ sinh: 12 kịch bản giờ; nếu cũng thiếu quy ước nam/nữ thì 24 kịch bản. Chỉ giữ độ nghiêng cùng chiều trong mọi kịch bản, lấy mức nhỏ nhất; nếu trái chiều thì bằng 0 trên trục đó.
- Hệ số độ phủ của phân tích kịch bản là quy ước sản phẩm (.75 cho mỗi input giờ/quy ước thiếu); mức đồng thuận không được gọi là xác suất đúng.
- Thiếu giờ/múi giờ sinh có thể làm mất mốc khởi Đại vận. Metadata ghi rõ phần thiếu.
- Western giữ thiên thể có kinh độ ổn định trong khoảng sinh khả dĩ; lấy mẫu 3 giờ và dung sai .5 độ với guard .02 độ. Đây là phép xấp xỉ có giới hạn, không phải khôi phục giờ sinh.

## Quy tắc cần biết trước khi tích hợp

- Calendar ruleset là **Chinese calendar applied to the declared civil date**. Chưa phải bộ lịch âm Việt Nam/Japan theo từng địa phương.
- Năm/tháng Bát Tự theo thời điểm tiết khí quy về UTC; trụ ngày đổi lúc 00:00 địa phương. Giờ Tý 23:00 dùng can ngày hiện hành theo lựa chọn này.
- Tử Vi dùng iztro `normal` (năm âm lịch), `dayDivide: current`, `fixLeap: true`, algorithm `default`. Đây là một trường phái cố định; không trộn với năm Lập Xuân của Bát Tự.
- Ngày sinh/thời điểm phân tích hỗ trợ 1900–2099. Dữ liệu múi giờ lịch sử và dự báo thiên văn xa hiện tại vẫn chịu giới hạn nguồn.
- NOW chốt tại đầu đoạn giờ có ranh DST/ngày/tiết khí/buổi/Đại vận. Bấm lại trong cùng đoạn giữ kết quả. `context.instantUtc` là lúc bấm, `evaluatedAtUtc` là mốc dùng tính.
- Morning 06:00–12:00, Midday 12:00–14:00, Afternoon 14:00–18:00, Evening 18:00–24:00. Đây là quy ước UX toàn cầu, không tính theo bình minh/hoàng hôn.
- Top 2 chỉ xét phần còn lại của buổi hôm nay, mỗi khung ít nhất 15 phút. Hai điểm có thể bằng nhau và không cần cộng thành 100. NOW không có Top 2.
- Hai phần trăm quyết định cộng 100; công thức `floor(50 + 40 × score + .5)`. Điểm là **symbolic alignment**, không phải xác suất thành công thực tế.
- Không phân phối lại trọng số khi thiếu module. Trọng số MVP: B=2/9, Z=2/9, T=1/9, W=2/9, N=1/6, U=1/18.
- Engine không xử lý Ads, Premium hoặc số lượt. `consumeUnlock:false` chỉ có ở trạng thái hết buổi; quyền mở khóa thuộc app.
- `readingKey` là ID tính toán, không phải token bảo mật. Không đưa hồ sơ sinh hoặc tọa độ vào analytics.

## Giới hạn còn lại, nói rõ

Luồng input → kết quả đã chạy được. Tuy nhiên **đây chưa phải bộ luận Bát Tự/Tử Vi toàn diện**:

1. `traditionalYongShen` và `traditionalXiShen` vẫn `null`. Chỉ số hỗ trợ/mùa đã tính không đủ để tự nhận là Dụng/Hỷ thần theo mọi cách cục. Thành phần .15 favorable-element trong Bát Tự không được chấm, và coverage phản ánh điều đó.
2. Các quan hệ hình/hại/phá và hợp có trong diagnostics; chỉ nhóm quan hệ đã có điểm ở công thức v2 tham gia tổng điểm. Không tự kết luận hợp hóa.
3. Tử Vi tạo được các sao/vòng sao trong chart provider, nhưng chỉ chấm danh mục đã quy định; không chấm mọi tổ hợp cách cục.
4. Không có Ascendant/houses/true solar time vì input MVP không yêu cầu tọa độ sinh. Không có Kỳ Môn, Kinh Dịch hay điểm nhật/nguyệt thực.
5. Kiểm thử xác nhận phần mềm, lịch và một số mốc thiên văn; không xác nhận khả năng dự đoán ngoài đời.

## API cục bộ (chỉ dùng cho phát triển)

`src/server.js` bọc engine thành HTTP API tối giản, chỉ dùng `node:http`, không
thêm framework hay dependency mới. Chạy tại thư mục `calculation-engine`:

```sh
npm run api            # hoặc: node src/server.js
PORT=9000 npm run api  # cổng mặc định 8787; PORT phải là số nguyên 1–65535
```

Server **chỉ bind 127.0.0.1**, không bao giờ 0.0.0.0. Không có cách nào cấu hình
địa chỉ khác: `startApiServer({ host })` **từ chối mọi host khác** `127.0.0.1` —
kể cả `0.0.0.0`, `::`, `::1`, `localhost`, IP LAN hay chuỗi rỗng — và từ chối
*trước khi* tạo socket, nên không bao giờ tồn tại một server nghe ngoài loopback.
CLI thì hard-code loopback, không đọc host từ đâu cả. `PORT` sai định dạng thì
thoát ngay với mã 1.

Kiểm tra sức khỏe:

```sh
curl http://127.0.0.1:8787/health
```

```json
{
  "service": "decision-compass-calculation-api",
  "status": "ok",
  "engineVersion": "3.1.0-mvp",
  "rulesetVersion": "civil-midnight-chinese-calendar-symbolic-v4"
}
```

Xin một lượt đọc — body theo đúng `ReadingInput` trong `src/index.d.ts`:

```sh
curl -X POST http://127.0.0.1:8787/v1/readings \
  -H 'Content-Type: application/json' \
  -d '{
    "profile": {
      "birthDate": "1998-06-21",
      "birthTime": "14:30",
      "birthCountry": "VN",
      "traditionalProfile": "male"
    },
    "context": {
      "instantUtc": "2026-09-18T08:30:00Z",
      "deviceTimezone": "Asia/Ho_Chi_Minh"
    },
    "mode": "yes_no",
    "period": "evening"
  }'
```

Trả về nguyên văn `ReadingResult` của engine (giữ `readingKey`, `context`,
`warnings`, `percentages`, `modeScore`, `dailyBrief`, `luckyWindows`). API không
thêm giá trị mặc định, không random, không sinh văn bản luận giải.

Mã lỗi: 400 JSON hỏng hoặc body rỗng · 404 sai đường dẫn · 405 sai method ·
413 body quá 64 KiB · 415 sai `Content-Type` · 422 input engine không hợp lệ
hoặc có `diagnostics: true` · 500 lỗi nội bộ. Mọi lỗi trả về dạng
`{"error":{"code","message"}}` cố định, **không** kèm thông điệp ngoại lệ của
engine, stack trace hay nội dung request.

Body quá cỡ: **mọi** request vượt 64 KiB đều nhận JSON 413 kèm đủ
`Cache-Control: no-store` và `X-Content-Type-Options: nosniff`, bất kể lớn tới
đâu (65 KiB, 1 MiB hay 10 MiB đều như nhau). Server không bao giờ đóng socket
chỉ vì body lớn: nó ngừng giữ dữ liệu ngay khi vượt ngưỡng, xả nốt phần còn lại
rồi mới trả lời, nên client luôn đọc được 413 thay vì gặp connection reset.
Bộ nhớ giữ tối đa 64 KiB mỗi request.

Quyền riêng tư: API không ghi log body, hồ sơ sinh, tọa độ, `readingKey` hay
timezone. `diagnostics: true` bị từ chối thẳng để nội tại từng module không rời
khỏi tiến trình engine.

> **Chỉ dành cho máy phát triển.** Hiện chưa có HTTPS, xác thực, rate limiting,
> quota, CORS hay audit log. Trước khi đưa ra ngoài internet bắt buộc phải bổ
> sung TLS, xác thực, rate limiting và các bước làm cứng khi triển khai.

Test riêng cho API: `npm run api:test`. Lệnh `npm test` đã bao gồm sẵn.

## Tích hợp mobile

Gói hiện tại là **Node.js SDK chạy trên máy phát triển hoặc backend**, chưa phải plugin C#/Unity,
APK hoặc IPA. `geo-tz` đọc dữ liệu biên giới từ disk (dataset all khoảng 30 MB; package có cả
các dataset khác), nên không đưa nguyên thư mục này vào mobile bundle.

App có thể gọi SDK qua backend do mình vận hành, hoặc port phần thuần tính toán và thay
resolver bằng adapter mobile. Chưa triển khai server công khai hoặc gửi hồ sơ đi đâu.
Xem JSON contract và ví dụ hiện có để tích hợp; không cần AI service.

## Kiểm chứng

```sh
node --test test/*.test.js
node scripts/stress.js
node scripts/check-reference.js
```

Kết quả và phạm vi kiểm thử: [VERIFICATION.md](VERIFICATION.md).
Thư viện, nguồn và giấy phép: [THIRD_PARTY.md](THIRD_PARTY.md).
