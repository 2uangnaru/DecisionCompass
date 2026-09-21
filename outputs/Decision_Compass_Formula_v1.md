# Decision Compass — Bộ công thức nghiên cứu v1.0-alpha

Ngày nghiên cứu: 18/09/2026. Mục đích: đặc tả công thức cho prototype không dùng AI.

**Cập nhật:** xem `Decision_Compass_Formula_v2.md` và `decision_formula_v2.py` cho phần mở rộng không gian, Bát Tự/Tử Vi và chu kỳ thiên văn. Trọng số gộp v2 thay trọng số v1 khi dùng v2; bản v1 này giữ để đối chiếu lịch sử. Cả hai file Python vẫn là prototype chấm điểm. Engine input thô mới đã được triển khai ngày 19/09/2026 tại [calculation-engine](../calculation-engine/README.md), bỏ module không gian theo scope MVP mới.

## 1. Trạng thái và cách đọc

Đây là mô hình diễn giải biểu tượng do sản phẩm thiết kế, chưa được xác thực khả năng dự đoán. Không có công thức truyền thống thống nhất để cộng Tử Vi, Bát Tự, chiêm tinh và thần số học thành xác suất YES/NO. Những hệ số trong tài liệu là lựa chọn biên tập, không phải kết quả nghiên cứu thực nghiệm.

Phân biệt ba lớp:

- **Dữ liệu lịch/thiên văn:** tính được và có thể đối chiếu với nguồn độc lập.
- **Quy tắc trường phái:** chọn một cách tính rõ ràng; không trộn các phiên bản khi tiện cho kết quả.
- **Điểm sản phẩm:** các bảng số, trọng số, thang phần trăm và mapping mode dưới đây đều là quy ước v1.

Mã `decision_formula_reference.py` đi kèm thực hiện các phép chấm điểm trên dữ liệu đã chuẩn hóa. Mã chưa lập lá số, chưa tính lịch âm/thiên thể, chưa kết nối quảng cáo hay giao diện. Kiểm thử số học không phải kiểm chứng bói đoán.

## 2. Kết luận từ nguồn

| Nội dung | Kết luận áp dụng | Nguồn |
|---|---|---|
| Can Chi và giờ địa chi | Có chu kỳ và bảng chuyển đổi xác định; dùng làm dữ liệu lịch | [HKO: Stems and Branches](https://www.hko.gov.hk/en/gts/time/stemsandbranches.htm) |
| Âm lịch, tiết khí | Có dữ liệu đối chiếu; chú ý múi giờ và những thời điểm sát ranh giới | [HKO: conversion](https://www.hko.gov.hk/en/gts/time/conversion.htm), [solar terms](https://www.hko.gov.hk/en/gts/time/24solarterms.htm) |
| Tứ Trụ | Nhật chủ là can ngày; không đồng nhất với nạp âm năm sinh | [Joey Yap: Day Master](https://home.joeyyap.com/article/bazi/what-is-bazi-astrology-a-beginners-complete-guide/) |
| Tử Vi | Có cách lập cung, sao, Tứ Hóa và vận; ý nghĩa không đơn giản là sao tốt/xấu cố định | [iztro: Tứ Hóa](https://iztro.com/learn/mutagen), [vận](https://iztro.com/learn/horoscope), [cung](https://www.iztro.com/en_US/posts/palace) |
| Lịch chọn ngày giờ | Có thư viện cung cấp trực ngày và hoàng/hắc đạo; dữ liệu này không chứng minh ngày thực tế tốt/xấu | [lunar-javascript](https://github.com/6tail/lunar-javascript), [API](https://6tail.cn/calendar/api.html) |
| Chiêm tinh | Tính góc giữa các kinh độ thiên thể được; ý nghĩa góc là diễn giải chiêm tinh | [Astrodienst: aspects](https://www.astro.com/astrowiki/en/Aspect), [Swiss Ephemeris](https://www.astro.com/swisseph/swephprg.htm) |
| Thần số học | Chốt một quy tắc ngày cá nhân và dùng nhất quán | [Numerology.com: personal day](https://www.numerology.com/articles/about-numerology/calculate-personal-day-number/) |
| Phong thủy | Phân tích không gian cần dữ liệu không gian; ngày sinh không đủ | [CityU: introduction](https://www.cityu.edu.hk/upress/pub/media/catalog/product/files/9789629372361_preview.pdf) |

Các nguồn hành nghề được dùng để xác định hệ quy tắc, không dùng như bằng chứng về hiệu quả dự đoán. Tài liệu này không sao chép phần luận giải thương mại của họ.

## 3. Đầu vào và hợp đồng với bộ tính lịch

Đầu vào UI: nickname, ngày sinh, giờ sinh tùy chọn, nơi sinh tùy chọn; lĩnh vực và thời điểm. Không hỏi hành động hay đọc câu hỏi trong đầu.

Đầu vào engine:

```text
profile_revision, birth_date, birth_time_precision,
birth_local_time?, birth_timezone?, birth_place?,
reading_instant_utc, reading_timezone_iana,
category, mode, selected_period, ruleset_version
```

- Ngày sinh UI là dương lịch. Định dạng theo locale nhưng lưu ISO.
- Nơi sinh dùng xác định múi giờ lịch sử; không lấy múi giờ hiện tại thay múi giờ sinh.
- Giờ sinh không biết: không tự điền 12:00. Bỏ các thành phần phụ thuộc.
- Múi giờ không biết: không tự suy ra từ ngôn ngữ; module nhạy với múi giờ chưa được sử dụng.
- Input trường phái Tử Vi có thể cần tham số giới tính truyền thống để an vận. Chỉ hỏi khi kích hoạt module và giải thích mục đích; từ chối thì không suy đoán. Không suy diễn tính cách từ trường này.
- `General` và `Other` dùng cùng thuật toán. Categories v1: general, love, career, money, relationships, other.

### Mô hình thời gian global

Không dùng `country`, tên viết tắt như EST/CST, hoặc một UTC offset cố định làm múi giờ. Một quốc gia có thể có nhiều vùng; cùng một vùng có thể đổi offset do DST hoặc thay đổi luật. Lưu **IANA time-zone ID**, ví dụ `America/New_York`, `Europe/Paris`, `Asia/Tokyo`.

Mỗi reading lưu đồng thời:

```text
instant_utc                 // thời điểm tuyệt đối, không mơ hồ
zone_id                     // IANA ID tại nơi user đang ở
utc_offset_at_instant       // offset thực tế tại lúc đọc, phục vụ audit
local_date, local_time      // dữ liệu đã quy đổi để tính ngày/giờ địa phương
tzdb_version                // phiên bản cơ sở dữ liệu múi giờ
location_source             // device_zone | manual_city | saved_home
```

Không chỉ lưu `2026-11-01 01:30`, vì giờ này có thể xuất hiện hai lần khi kết thúc DST. Không chỉ lưu UTC, vì app còn cần biết “ngày hôm nay”, buổi sáng/tối và quy tắc lịch nào đã được dùng khi tạo reading.

Hai dòng thời gian được tách rõ:

1. **Hồ sơ sinh:** local ngày/giờ sinh + IANA zone lịch sử + tọa độ nơi sinh → birth instant UTC. Không chuyển giờ sinh bằng múi giờ hiện tại của user.
2. **Reading:** instant UTC lúc bấm + IANA zone của nơi user đang ở → ngày và giờ địa phương của reading.

Mặc định `NOW` dùng múi giờ hiện tại của thiết bị. App không cần xin GPS để biết zone. Khi OS zone thay đổi trong chuyến đi, hiện một lần:

```text
Your time zone changed to Europe/Paris.
Use local time for your readings?  [Use local time] [Keep home time]
```

Chọn local time sẽ tạo context mới từ lần đọc kế tiếp; không tính lại hoặc ghi đè lịch sử. Chọn home time giữ zone đã lưu cho tới khi user đổi. UI luôn hiện tên thành phố/zone trong Settings và màn chi tiết để user sửa nếu hệ điều hành nhận sai.

Nếu nhập thành phố sinh, app cần resolver thành tọa độ + IANA zone **theo ngày sinh**, gồm quy tắc DST lịch sử. Một offset hiện tại như `UTC+7` không đủ để dựng birth instant ở nơi từng thay đổi luật. Có thể đóng gói city index và tzdb trong app để không phụ thuộc API online khi chạy; dữ liệu phải có version và cơ chế cập nhật.

Phân hệ dùng thời gian như sau:

| Module | Mốc thời gian |
|---|---|
| Thần số học và Daily Brief | local civil date trong reading zone |
| Can Chi ngày/giờ reading | local civil time theo ruleset v1 và quy ước đổi ngày 00:00 |
| Bát Tự hồ sơ sinh | birth local time/zone; tùy trường phái có thể thêm chế độ true-solar-time riêng |
| Tử Vi | birth local/lunar inputs và provider đã pin; reading vận theo reading context |
| Chiêm tinh | birth và reading instant UTC; vị trí/nhà nếu dùng cần tọa độ tương ứng |
| Ads/free reset | entitlement ledger riêng; không cho đổi zone để reset vô hạn |

V1 dùng **giờ dân sự địa phương** cho Can Chi reading để hành vi dễ hiểu toàn cầu. True solar time là một chế độ trường phái khác: cần kinh độ, central meridian và equation-of-time; không bật ngầm, không trộn kết quả của hai chế độ. Nếu sau này thêm, ruleset ID và UI chi tiết phải ghi rõ chế độ đang dùng.

Daily free reset theo `account_home_zone` đã lưu, hoặc theo zone đầu tiên của ngày nếu không có tài khoản. Đổi zone không cấp thêm lượt. Reading vẫn tính theo zone user chọn; quyền ads và công thức reading là hai hệ thống riêng.

Với Unity/C#, ưu tiên một gói mang sẵn IANA tzdb và pin phiên bản, ví dụ [Noda Time](https://www.nodatime.org/), thay vì dựa vào một UTC offset hoặc giả định `TimeZoneInfo` hoạt động giống nhau trên mọi nền tảng. Noda Time phân biệt `Instant`, `LocalDateTime`, `DateTimeZone` và có nguồn tzdb; cần kiểm tra tương thích Unity/IL2CPP và giấy phép của phiên bản trước khi chốt dependency. Microsoft cũng phân biệt rõ time zone với offset trong [tổng quan .NET](https://learn.microsoft.com/en-us/dotnet/standard/datetime/time-zone-overview).

Adapter phải trả về dữ liệu có nguồn/phiên bản:

1. Can Chi các trụ sinh và trụ ngày/giờ xem.
2. Nhật chủ và ngũ hành của thiên can.
3. Hoàng/hắc đạo ngày, giờ; một trong 12 trực.
4. Lá số và các vị trí Tứ Hóa theo từng tầng vận được dùng.
5. Kinh độ hoàng đạo địa tâm tropical của bảy thiên thể: Sun, Moon, Mercury, Venus, Mars, Jupiter, Saturn.

Không lấy các chuỗi “nên ký hợp đồng/cưới hỏi” để suy ra câu hỏi chưa biết của user.

### Quy ước lịch

- Ngày UI, quyền mở khóa và thần số học đổi lúc 00:00 địa phương.
- Với Can Chi v1, đề xuất ngày trụ đổi lúc 00:00; phải kiểm tra adapter không tự đổi can giờ theo ngày kế từ 23:00. Không chỉ gọi mặc định thư viện rồi mặc nhiên coi khớp.
- Trụ năm/tháng Bát Tự theo tiết khí của trường phái đã chọn; không thay tháng tiết khí bằng tháng âm lịch hoặc tháng dương lịch.
- Tử Vi dùng âm lịch và quy tắc tháng nhuận của provider đã cố định. Các module có thể dùng quy ước lịch khác nhau, nhưng phải lưu riêng thay vì ghi đè nhau.
- Không đưa lịch Việt Nam và lịch Trung Hoa vào cùng profile mà không ghi rõ quy ước. HKO là dữ liệu đối chiếu theo quy ước của HKO, không phải bảng âm lịch toàn cầu mặc định.
- Trước production phải pin phiên bản lịch, Tử Vi, dữ liệu múi giờ và bộ thiên văn; không dùng nhánh `main` thay đổi liên tục.
- Khi tzdb cập nhật luật quá khứ, không âm thầm tính lại reading cũ. Reading cũ dùng `instant_utc`, zone, offset và ruleset đã lưu; chỉ dữ liệu mới dùng phiên bản mới.

Với giờ địa phương h trong 0..23 và Chi Tý=0,...,Hợi=11:

```text
hour_branch = floor((h + 1) / 2) mod 12
hour_stem = (2 × (day_stem mod 5) + hour_branch) mod 10
```

Can Giáp=0,...,Quý=9. Công thức can giờ dùng đúng can ngày theo quy ước 00:00 đã chốt; phải đối chiếu đặc biệt tại 23:00 và 00:00.

## 4. Hai trục điểm thay vì một điểm thay mọi đáp án

Mỗi module trả vector `(A, C)` trong [-1,1]:

- A: mức nghiêng về hành động/khẳng định; âm thiên về chờ/cân nhắc.
- C: mức nghiêng về thay đổi; âm thiên về giữ nguyên.

Đây là nhãn diễn giải của sản phẩm, không phải đại lượng vật lý hoặc chỉ số tâm lý đã đo lường.

| Mode | Điểm phía thứ nhất | Phía đối lập |
|---|---:|---|
| YES / NO | A | -A |
| ACT / WAIT | A | -A |
| ADVANCE / RETREAT | A | -A |
| STAY / GO | -C | C |
| KEEP / LET GO | -C | C |

YES và ACT có thể trùng; STAY và KEEP có thể trùng. Đó là chủ ý nhất quán, không thêm random để tạo khác biệt.

**LEFT/RIGHT không có mapping thiên văn/tử vi đáng bảo vệ.** Giữ như chế độ lựa chọn biểu tượng riêng, không gọi là phân tích hướng phong thủy. Nếu giữ trong prototype: SHA-256 của JSON canonical `[profile_revision,date,slot,category,ruleset]`, lấy bit thấp của byte đầu để chọn bên; ghi rõ “Symbolic pick”, không xuất phần trăm chắc chắn. Nếu UI bắt buộc có hai phần trăm, chỉ hiển thị 50/50 và phân biệt phần chọn biểu tượng. Không quảng cáo trả tiền tăng độ chính xác cho mode này.

## 5. Module N — thần số học

Ký hiệu `r(n)=1+((n-1) mod 9)` với n nguyên dương; `digits(n)` là tổng chữ số.

```text
LP = r(digits(birth_year) + digits(birth_month) + digits(birth_day))
PY = r(birth_month + birth_day + digits(current_year))
PM = r(PY + current_month)
PD = r(PM + current_day)
```

Chọn chu kỳ năm dương lịch 01/01. Bản v1 quy về 1..9; không tuyên bố đang xử lý master numbers 11/22/33. Ngày sinh 29/2 được dùng trực tiếp, không cần gán sinh nhật năm thường.

Bảng ánh xạ sản phẩm, không phải bảng độ may mắn đã được chứng minh:

| Số | A | C |
|---|---:|---:|
| 1 | 0.6 | 0.6 |
| 2 | -0.2 | -0.3 |
| 3 | 0.4 | 0.2 |
| 4 | 0.1 | -0.6 |
| 5 | 0.3 | 0.7 |
| 6 | 0.1 | -0.5 |
| 7 | -0.6 | -0.2 |
| 8 | 0.5 | 0.1 |
| 9 | -0.2 | 0.6 |

```text
N = 0.10 × V(LP) + 0.15 × V(PY) + 0.25 × V(PM) + 0.50 × V(PD)
```

N không thay đổi theo phút hoặc giờ. Không chế thêm “số giây may mắn”. `Your Lucky Number` = PD là lựa chọn biên tập của app, không phải khẳng định đây là con số thắng thưởng.

## 6. Module B — Can Chi/ngũ hành từ Tứ Trụ, phạm vi rút gọn

**Không gọi module này là luận Bát Tự đầy đủ.** V1 chưa kết luận thân vượng/nhược, dụng thần/hỷ thần, cách cục hoặc đại vận. Không áp dụng quy tắc sai “mệnh thiếu gì cứ bổ sung thứ đó”.

Xét can ngày/giờ xem so với Nhật chủ (can ngày sinh). Ngũ hành: Mộc→Hỏa→Thổ→Kim→Thủy→Mộc là vòng sinh; kiểm soát theo Mộc→Thổ→Thủy→Hỏa→Kim→Mộc.

| Quan hệ yếu tố thời điểm với Nhật chủ | A | C |
|---|---:|---:|
| Thời điểm sinh Nhật chủ | 0.4 | -0.2 |
| Cùng hành | 0.2 | -0.3 |
| Nhật chủ sinh yếu tố thời điểm | 0.2 | 0.4 |
| Nhật chủ khắc yếu tố thời điểm | 0 | 0.2 |
| Yếu tố thời điểm khắc Nhật chủ | -0.4 | 0 |

Các điểm chỉ mã hóa motif hỗ trợ, biểu đạt, kiểm soát; không tuyên bố tương sinh luôn là tốt trong Bát Tự.

Chi đánh số Tý=0,...,Hợi=11. Quan hệ cặp:

- Lục hợp: {0,1}, {2,11}, {3,10}, {4,9}, {5,8}, {6,7}: vector (0.5,-0.4).
- Lục xung: chênh đúng 6 theo vòng 12: (-0.5,0.5).
- Cùng chi: (0.1,-0.2).
- Còn lại: (0,0).

V1 không gán mọi cặp trong nhóm dân gian “tứ hành xung” thành xung trực tiếp. Không tính tam hợp nếu chỉ có hai chi. Tam hợp, hình/hại/phá, hợp hóa và tàng can được hoãn cho đến khi có bộ kiểm chứng riêng.

Với mỗi trụ thời điểm k = ngày hoặc giờ:

```text
u_year=0.10, u_month=0.20, u_day=0.50, u_hour=0.20
qB = tổng u của chi sinh đã biết
Branch(k) = Σ[u_j × Pair(chi_k,chi_birth_j)] / qB
B(k) = 0.60 × Element(can_k,Nhật_chủ) + 0.40 × Branch(k)
B = 0.40 × B(day) + 0.60 × B(hour)
```

Không biết giờ sinh thì qB=0.8 nếu ba chi còn lại xác định. Không có Nhật chủ hoặc ngày lịch sinh chưa xác định thì qB=0, bỏ B. Không dùng nạp âm năm thế vào Nhật chủ.

## 7. Module T — lịch chọn thời điểm

Adapter cung cấp hoàng/hắc đạo theo đúng bộ lịch đã pin. Chuyển hoàng đạo=+0.5; hắc đạo=-0.5. Nếu không xác định thì T chưa khả dụng, không đoán.

Bảng trực ngày dưới đây là diễn giải sản phẩm; không phải mọi việc đều có cùng cát/hung:

| Trực / ID | A | C |
|---|---:|---:|
| Kiến / establish | 0.3 | 0.3 |
| Trừ / remove | 0.1 | 0.7 |
| Mãn / full | 0.1 | -0.3 |
| Bình / balance | 0 | 0 |
| Định / stable | 0.2 | -0.7 |
| Chấp / hold | 0.1 | -0.6 |
| Phá / break | -0.5 | 0.7 |
| Nguy / danger | -0.5 | 0 |
| Thành / success | 0.5 | 0.2 |
| Thu / receive | 0.3 | -0.3 |
| Khai / open | 0.4 | 0.6 |
| Bế / close | -0.3 | -0.5 |

```text
T_A = 0.25 × DayFlag + 0.40 × HourFlag + 0.35 × Officer_A
T_C = Officer_C
```

Không cộng danh sách hàng chục thần sát thêm vào T. V1 đã có trần ảnh hưởng để hạn chế lịch chung lấn át cá nhân.

## 8. Module Z — Tử Vi Tứ Hóa theo cung liên quan

Phạm vi: phép chiếu biểu tượng Tứ Hóa trên lá số, **không phải luận giải toàn bộ Tử Vi**. Lá số phải được lập từ dữ liệu sinh thật và đã đối chiếu. Không biết giờ sinh: qZ=0. Không hiện trong loading như thể đã chạy.

Lĩnh vực chọn cung mục tiêu: general/other→Mệnh; love→Phu Thê; career→Quan Lộc; money→Tài Bạch; relationships→Nô Bộc/Giao Hữu. Đây là mapping biên tập đơn giản; không tự suy ra đối tượng tình cảm cụ thể.

Adapter xuất đúng bốn Tứ Hóa của mỗi tầng: natal, yearly, monthly, daily, hourly; mỗi bản ghi có sao mang hóa và chỉ số cung chứa sao trong cùng hệ tọa độ với cung mục tiêu. Không gán can dương lịch trực tiếp cho tầng vận mà chưa theo cách lập vận của provider.

Với khoảng cách cung modulo 12: cùng cung hệ số 1; đối cung 0.5; hai cung tam hợp cách 4/8 hệ số 0.6; còn lại 0.

| Hóa / ID | A | C |
|---|---:|---:|
| Lộc / lu | 0.35 | -0.10 |
| Quyền / quan | 0.20 | 0.20 |
| Khoa / khoa | 0.25 | -0.20 |
| Kỵ / ky | -0.45 | 0.15 |

```text
Z_layer = clamp_vector(Σ[palace_coefficient × transformation_vector] / 2, -1, 1)
v = {natal:0.20, yearly:0.15, monthly:0.15, daily:0.25, hourly:0.25}
qZ = tổng v của tầng hợp lệ
Z = Σ[v_layer × Z_layer] / qZ
```

Nếu tầng thiếu một trong bốn biến hóa thì tầng đó không hợp lệ, không coi biến hóa thiếu là không ảnh hưởng. Các tổ hợp cùng sao/cung ở các tầng được phân bổ trong trọng số tầng, không tạo thêm một phiếu bên ngoài Z.

Hệ số Lộc/Quyền/Khoa/Kỵ trên là phép nén của app. Chính tài liệu trường phái lưu ý tác dụng còn phụ thuộc sao và bối cảnh. Vì vậy đây là phần cần chuyên gia Tử Vi rà soát trước khi marketing là phân tích chuyên sâu. Không nói “Hóa Kỵ nghĩa là bạn sẽ thất bại”.

Bản tham chiếu dữ liệu Tứ Hóa: [iztro heavenlyStems](https://github.com/SylarLong/iztro/blob/main/src/data/heavenlyStems.ts). Phải pin release/commit khi tích hợp; không sao chép bảng từ nhiều trường phái.

## 9. Module W — chiêm tinh theo vị trí thiên thể

Không chỉ tra Sun sign. Dùng kinh độ địa tâm tropical lúc sinh và tại đầu khung giờ chuẩn hóa. V1 chưa dùng cung nhà/Ascendant nên không giả có cung mọc khi thiếu giờ sinh.

Với thiên thể thời điểm p và thiên thể sinh n:

```text
d = abs(((longitude_p - longitude_n + 180) mod 360) - 180)
strength = max(0, 1 - abs(d - aspect_angle)/3)
```

Chọn góc gần nhất trong 0/60/90/120/180 độ; orb 3 độ là quy ước hẹp của prototype, không chuẩn chung cho mọi trường phái. Ngoài orb, vector (0,0).

| Góc | A | C |
|---|---:|---:|
| 0° | 0 | Theo thiên thể thời điểm, bảng dưới |
| 60° | 0.5 | 0.2 |
| 90° | -0.5 | 0.3 |
| 120° | 0.6 | -0.3 |
| 180° | -0.6 | 0.3 |

C của góc 0°: Moon=0, Sun=0.1, Mercury=0.2, Venus=-0.1, Mars=0.4, Jupiter=0.3, Saturn=-0.4. Không coi mọi conjunction là tốt hoặc xấu.

Trọng số thiên thể thời điểm: Moon .35; Sun .15; Mercury/Venus/Mars/Jupiter/Saturn mỗi .10.

Trọng số thiên thể sinh theo lĩnh vực (phần không liệt kê =0):

| Lĩnh vực | Trọng số |
|---|---|
| General/Other | Sun .30, Moon .30, Mercury .10, Venus .10, Mars .10, Jupiter .05, Saturn .05 |
| Love | Moon .35, Venus .40, Mercury .15, Mars .10 |
| Career | Sun .25, Mercury .25, Mars .20, Saturn .20, Jupiter .10 |
| Money | Jupiter .30, Saturn .30, Venus .20, Mercury .20 |
| Relationships | Moon .20, Venus .25, Mercury .40, Sun .15 |

```text
w_pair = transit_weight[p] × natal_weight[category,n]
qW = Σ w_pair của cặp có dữ liệu xác định
W = clamp_vector(3 × Σ[w_pair × strength × aspect_vector] / qW, -1, 1)
```

Hệ số 3 là độ nhạy thử nghiệm do sản phẩm đặt. Không tối ưu nó để tăng YES hoặc doanh thu. Nếu vị trí biết nhưng không có góc trong orb: đóng góp 0, vẫn tính vào qW. Không được chỉ chia cho số góc đang khớp vì sẽ phóng đại một góc yếu.

Không biết giờ sinh: chỉ giữ thiên thể sinh nếu bộ dữ liệu bảo đảm kinh độ không thay đổi quá ngưỡng sai số 0.5° trong toàn khoảng giờ sinh khả dĩ; dùng trung điểm cung tròn và gắn `approximate`. Đây là dung sai kỹ thuật, không độ tin cậy bói đoán. Adapter chưa kiểm tra được thì bỏ điểm đó, nhất là Moon. Trường hợp sát ranh cung không tự quyết cung từ bảng ngày cố định.

## 10. Gộp nhóm, dữ liệu thiếu và phần trăm

q_i trong [0,1] là **mức đầy đủ dữ liệu theo mô hình**, không phải độ chính xác. N có ngày sinh hợp lệ thì qN=1. T đủ đầu vào thì qT=1.

```text
E = 0.40 qB B + 0.35 qZ Z + 0.25 qT T
S = 0.50 E + 0.30 qW W + 0.20 qN N
```

Tương đương trọng số tuyệt đối: B=.20, Z=.175, T=.125, W=.30, N=.20.

Lý do thiết kế: khối Đông phương giới hạn tổng 50%; Can Chi/ngũ hành không có dòng điểm riêng để cộng hai lần; lịch chung chỉ tối đa 12.5%. Đây là giới hạn cấu trúc, không phải đã loại hết tương quan thống kê giữa các hệ.

Thiếu module thì đóng góp bằng 0 và **không chuyển hết trọng số thiếu sang module còn lại**. Như vậy một số ngày cá nhân đơn lẻ không thể tạo ra 90%.

```text
Coverage = .20 qB + .175 qZ + .125 qT + .30 qW + .20 qN
P_first = floor(50 + 40 × mode_score + 0.5)
P_second = 100 - P_first
```

Mức 10..90 là thang hiển thị do app chọn; không dùng sigmoid vì không có mô hình xác suất được huấn luyện. Rounding theo công thức trên, không phụ thuộc bankers rounding của ngôn ngữ.

- 50/50 sau làm tròn: `Evenly balanced`, không ép thắng bằng random.
- Bên lớn hơn 50 được highlight; 51–59 là `A gentle lean`, 60–74 `A clearer lean`, 75–90 `A strong symbolic lean`.
- Coverage<0.5: hiển thị `Limited birth details`; không làm giả độ đầy đủ.
- Coverage=0: không xuất reading, không tiêu lượt/ads.
- Câu tooltip: `Symbolic alignment, not a probability of success.`

Ví dụ kiểm tra số học với dữ liệu giả, q đều 1:

```text
B_A=.30, Z_A=.20, T_A=.40, W_A=.10, N_A=.50
S_A=.20×.30+.175×.20+.125×.40+.30×.10+.20×.50=.275
YES=61, NO=39
```

Không dùng ví dụ này như reading của ngày/người thật.

## 11. NOW, khung giờ và Top 2

Thời gian trên UI chỉ hiển thị chip NOW được chọn mặc định. Khi bấm, lấy thời gian hiện tại để xác định local_date và giờ địa chi.

Để bấm lại nhất quán, dữ liệu thiên thể và các module theo giờ dùng **đầu đoạn giờ địa chi đã chuẩn hóa**, không chạy theo từng giây. Giờ Tý tách tại 00:00 do đổi ngày; cũng tách đoạn tại chuyển DST, tiết khí đổi trụ, hoặc bất kỳ ranh dữ liệu adapter cần phân biệt. Các đoạn thực phải có UTC start/end và zone/offset. V1 không tuyên bố phân tích chi tiết từng phút.

Khóa reading: `[profile_revision, ruleset_version, timezone, local_date, segment_utc_start, category]`. Mode chỉ là phép chiếu cùng vector, không tính lại thành năng lượng khác. Một lần đọc có `evaluated_at` để biết thời điểm user bấm. Đổi hồ sơ/ruleset tạo reading mới, lịch sử cũ giữ nguyên.

`timezone` trong khóa là IANA ID; thêm `segment_utc_start` giúp phân biệt hai lần 01:00 giống chữ khi DST lùi đồng hồ. Offset chỉ dùng audit/hiển thị, không thay zone ID trong khóa.

Các buổi theo giờ địa phương, đầu bao gồm/cuối không bao gồm:

- Morning [05:00,11:00)
- Midday [11:00,13:00)
- Afternoon [13:00,17:00)
- Evening [17:00,23:00)

Buổi đã kết thúc: disable, không âm thầm chọn ngày mai. Buổi đang diễn ra: chỉ xét phần còn lại. Từ 23:00 đến 05:00 vẫn dùng NOW. Các đoạn qua DST không được suy ra bằng cộng một giờ vào datetime không có zone.

Tạo các ứng viên một giờ theo đồng hồ địa phương, cắt tại ranh dữ liệu và thời điểm hiện tại. Ô còn dưới 15 phút không dùng như một đề xuất mới (vẫn được phân tích NOW). Ô rỗng không tồn tại. Ô bị lặp do DST phải hiển thị offset nếu giờ chữ gây nhầm.

Cho mỗi ô i, lấy trung bình A theo **thời lượng thực** của các đoạn bao phủ ô:

```text
A_i = Σ(duration_j × S_A_j) / Σ duration_j
LuckyScore_i = floor(50 + 40 × A_i + 0.5)
```

**LuckyScore dùng trục A, độc lập với mode.** GO 75% không có nghĩa may mắn 75%. Không xếp “NO mạnh nhất” thành thời điểm may mắn nhất.

Xếp theo LuckyScore giảm dần, điểm hiển thị bằng nhau thì theo giờ sớm hơn. Không bịa sai biệt 82%/74% cho hai giờ cùng đầu vào. Hai ô liền nhau bằng điểm vẫn được hiển thị cả hai với `Equally aligned`. Chỉ còn một ô thì hiện một; không còn thì không bán lượt tìm Top 2.

Điểm cả buổi = trung bình vector S theo thời lượng còn lại, **không lấy max và không lấy trung bình của Top 2**. Vì vậy NO của cả buổi và một ô tốt hơn không mâu thuẫn.

Global headline theo đúng buổi: `Your luckiest times this morning`, `Your luckiest times around midday`, `Your luckiest times this afternoon`, `Your luckiest times tonight`. Nếu tất cả ô dưới 50, thêm `These are the highest-ranked windows, though the signs remain mixed.`

NOW chỉ đọc thời điểm hiện tại; phần Top 2 thuộc lựa chọn buổi. Nếu muốn quảng cáo mở buổi tiếp theo thì phải ghi rõ phạm vi trước khi xem.

## 12. Phong thủy và các hệ khác

- Màu hôm nay: chọn hành từ thiên can ngày theo cùng lịch; hiển thị `Today's color inspiration`. Bảng màu thiết kế: Mộc xanh sage, Hỏa coral, Thổ sand, Kim pearl, Thủy ocean blue. Đây là nội dung biểu tượng chung của ngày, chưa gọi là màu tối ưu cá nhân hay thuốc cải vận. Muốn cá nhân hóa thêm cần quy tắc được rà soát riêng.
- Không tính phong thủy nhà, hướng bàn, Bát Trạch/Phi Tinh từ ngày sinh đơn lẻ. Không biến LEFT/RIGHT thành la bàn.
- Kinh Dịch, Kỳ Môn, Tarot, Vedic, rune không tự thêm vào tổng điểm để tăng số lượng hệ. Chưa có adapter/rulebook đối chiếu thì không hiển thị là đã phân tích.
- Không dùng nguồn “năng lượng môi trường” từ cảm biến nếu app không thực sự thu thập và có mô hình phù hợp.

## 13. Loading, giải thích, ads

- Tính kết quả trước animation; animation là trình bày. Chỉ liệt kê module đã chạy với q>0.
- Copy phù hợp: `Reading today's patterns`, `Comparing your personal cycles`, `Finding your lucky windows`.
- Mỗi góp điểm lưu rule ID, nguồn dữ liệu, dấu điểm, giá trị trước/sau trọng số. Chọn lý do có đóng góp lớn và khác nhóm; nếu có tín hiệu ngược đáng kể thì nêu ngắn. Không viết kết quả trước rồi chọn lý do để hợp thức hóa.
- Nếu các nhóm trái chiều, dùng `Mixed signs` cho nội dung, không tạo phần trăm “đồng thuận khoa học”.
- Ads/Premium không là input của công thức. Xem lại không tiêu lượt. Một lần mở khóa buổi áp dụng các mode/categories trong buổi đó.
- Lượt NOW miễn phí đầu ngày mở đoạn hiện tại. Sang đoạn mới: một lượt rewarded hoặc Premium, tối đa hai lượt rewarded/ngày là cấu hình thử nghiệm.
- Khi người dùng đổi timezone/profile, lịch sử không bị ghi đè. Giới hạn quảng cáo và đọc kết quả phải tách khỏi cache tính toán để tránh thu lại phí vì đổi ngôn ngữ.
- Hoàn tất quảng cáo sau ranh giờ/buổi: giữ quyền đã thưởng, cho chuyển khoảng hợp lệ khác; không bắt xem lại.

## 14. Kiểm thử và điều kiện trước production

Kiểm thử toán học: ràng buộc [-1,1], P cộng 100, không đổi khi lặp input, q=0 không đóng góp, không cộng trọng số thiếu, cùng yếu tố bằng điểm, sorting Top 2 và trung bình thời lượng.

Kiểm thử adapter bắt buộc sau khi tích hợp:

- HKO lịch đối chiếu trong cùng quy ước; không coi bảng HKO là xác nhận toàn bộ thần sát.
- Ca 22:59/23:00/23:59/00:00/00:59/01:00; Lập Xuân và giao tiết; tháng nhuận.
- Ngày 29/2; người sinh sát ranh cung; giờ sinh không rõ; cả ngày sinh khả dĩ có/không đổi can ngày.
- DST thiếu/lặp giờ, múi giờ nửa giờ/45 phút, du lịch qua đường đổi ngày.
- Hai user cùng instant ở Tokyo và New York phải nhận đúng local date/hour khác nhau; cùng local clock nhưng khác zone phải có instant UTC khác nhau.
- Đổi zone giữa lúc mở màn hình và bấm: chốt snapshot zone tại lúc bắt đầu reading; loading không đổi kết quả giữa chừng.
- OS zone sai hoặc user chọn home time: mọi headline `today/tonight` phải dựa vào zone đang active và hiển thị được trong chi tiết.
- Entitlement reset không thay đổi khi user đổi zone nhiều lần trong ngày.
- Tử Vi so mẫu cùng trường phái, đặc biệt tháng nhuận, giờ Tý và an vận; từng layer phải đủ bốn hóa.
- Thiên thể đối chiếu dữ liệu thiên văn; xử lý vòng 359°/1°.
- Không thay hệ số để đạt tỷ lệ YES 50% hoặc tỷ lệ chuyển đổi trả phí mục tiêu.

Phân tích độ nhạy sau khi có dữ liệu thật: thay trọng số từng nhóm ±10%, giữ tổng trọng số cố định, đo tần suất đảo kết quả. Ca sát 50% phải được thể hiện nhẹ. Phân tích này đo độ ổn định thiết kế, không đo độ đúng ngoài đời.

Nhật ký tự báo cáo có thiên lệch chọn mẫu và ghi nhớ; không dùng làm “accuracy 85%”. Chỉ báo cáo thống kê trải nghiệm mô tả.

Thư viện: kiểm tra và giữ thông báo giấy phép. [Swiss Ephemeris](https://github.com/aloistr/swisseph/blob/master/LICENSE) có lựa chọn AGPL hoặc giấy phép thương mại; không mặc định miễn phí cho app đóng mã. [iztro](https://github.com/SylarLong/iztro) và thư viện lịch cần pin release, kiểm tra LICENSE của chính release đó trước khi phát hành. Tài liệu nghiên cứu này không cấp quyền dùng lại mọi nội dung trên web.

## 15. Việc đã có và còn thiếu

Đã có: công thức điểm và bảng hằng số cụ thể cho prototype; xử lý thiếu dữ liệu; hai trục; mapping mode; Top 2; quy tắc phần trăm; mã mẫu và kiểm thử toán học.

Chưa có: adapter lịch/thiên văn/Tử Vi, fixture lá số thật đã kiểm chứng, full Bát Tự/Tử Vi/phong thủy, UI/app hoàn chỉnh, nghiên cứu chứng minh dự đoán. Cần hoàn thành adapter và rà soát trường phái trước khi đưa vào production.
