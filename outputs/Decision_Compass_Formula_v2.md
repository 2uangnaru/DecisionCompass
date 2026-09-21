# Decision Compass — Phong thủy không gian, Bát Tự/Tử Vi mở rộng, chu kỳ thiên văn

Phiên bản: 2.0-alpha • 18/09/2026 • Bổ sung cho Formula v1, thay công thức gộp điểm của v1.

**Cập nhật 19/09/2026:** engine MVP v3 đã triển khai tại
[calculation-engine](../calculation-engine/README.md), nối input thô vào các bộ lập
lịch/lá số/thiên văn, bỏ phong thủy không gian theo scope mới. Tài liệu v2 bên dưới
được giữ làm bản tham chiếu lịch sử cho các công thức chấm điểm.

## Trạng thái thực tế

Đã triển khai **lớp chấm điểm mở rộng** trong `decision_formula_v2.py`, có kiểm thử đi kèm. Đây là prototype dùng dữ liệu đã chuẩn hóa. Chưa có bộ chạy từ ngày sinh/địa chỉ thô đến toàn bộ lá số và kết quả thật.

Các quan hệ lịch, ngũ hành, cung/sao và hình học thiên văn có nguồn để kiểm tra. Các vector A/C, hệ số trọng số và phần trăm ở đây là thiết kế riêng của sản phẩm, **không phải xác suất đúng hoặc khả năng thành công**. Nhiều module hơn không chứng minh dự đoán tốt hơn.

Tên phù hợp cho bản hiện tại: `Expanded symbolic reading`. Chưa dùng `Full BaZi`, `Complete Zi Wei`, `Full Feng Shui Audit`.

## 1. Kết quả nghiên cứu áp dụng

| Chủ đề | Kết luận áp dụng | Nguồn |
|---|---|---|
| Hướng cá nhân và vị trí trong nhà | Life Gua xét hướng, House Gua xét vùng không gian; hai đầu vào khác nhau | [Joey Yap, House Gua](https://www.joeyyap.com/tutorial/tutorial-details.asp?tid=333) |
| Bát Trạch | Có công thức mệnh quái và quan hệ quái/hướng; năm phong thủy cần ranh năm mặt trời | [Joey Yap, Life Gua](https://www.joeyyap.com/tutorial/tutorial-details.asp?tid=328) |
| Tàng can/thập thần | Có thể tính từ can ngày, can khác và âm/dương, gồm can ẩn trong chi | [lunar-javascript source](https://github.com/6tail/lunar-javascript/blob/master/lunar.js), [API](https://6tail.cn/calendar/api.html) |
| Tử Vi | Cần xét sao và trạng thái của sao, không chỉ bốn hóa | [iztro, chính tinh](https://iztro.com/learn/major-star), [phụ tinh](https://iztro.com/learn/minor-star), [hệ sao](https://iztro.com/learn/star) |
| Phi Tinh | Có vận nhà, tọa/hướng, sơn/hướng tinh; không dựng đủ bàn chỉ bằng địa chỉ hoặc ngày sinh | [Ví dụ bàn vận 8 Đinh–Quý](https://fengshuisignal.com/flying-stars/charts/period-8-ding-gui/) |
| Pha Mặt Trăng | Là hình học Sun–Earth–Moon; có dữ liệu tính được | [NASA, Moon phases](https://science.nasa.gov/moon/moon-phases/) |
| Nghịch hành | Là chuyển động biểu kiến địa tâm, không phải hành tinh thực sự quay ngược quỹ đạo | [Astrodienst, Retrograde](https://www.astro.com/astrowiki/en/Retrograde) |

Nguồn hành nghề mô tả quy ước truyền thống, không được viện dẫn như kiểm chứng khoa học. NASA chỉ hỗ trợ dữ liệu thiên văn; NASA không xác nhận điểm may mắn.

## 2. Công thức gộp v2

Giữ hai trục A (hành động/chờ), C (thay đổi/giữ). Với V_i=(A_i,C_i) và q_i là mức đầy đủ dữ liệu theo mô hình:

```text
S = .20 qB B + .20 qZ Z + .10 qT T
  + .20 qW W + .15 qN N + .05 qU U + .10 qF F
```

| ID | Module | Trọng số tối đa |
|---|---|---:|
| B | Bát Tự mở rộng: can/chi, tàng can, thập thần, các tầng thời gian | 20% |
| Z | Tử Vi mở rộng: sao, độ sáng, cung liên hệ, Tứ Hóa theo tầng | 20% |
| T | Lịch chọn ngày giờ v1 | 10% |
| W | Góc chiêm tinh transit–natal v1 | 20% |
| N | Thần số học v1 | 15% |
| U | Chu kỳ thiên văn Sun/Moon và chuyển động biểu kiến Mercury | 5% |
| F | Phong thủy không gian theo hồ sơ đang áp dụng | 10% |

- B mới **thay B cũ**, Z mới **thay Z cũ**; không cộng cả hai phiên bản.
- W+U nằm trong ngân sách 25%; U không thêm lại chính các góc transit–natal đã chấm ở W.
- Phong thủy nhà chỉ dùng khi user chọn không gian có thật đang áp dụng. Đang ở ngoài đường không mặc định dùng nhà.
- Module thiếu dữ liệu đóng góp 0, không chia lại toàn bộ trọng số.
- Phần trăm: `P_first=floor(50+40×mode_score+0.5)`, `P_second=100-P_first`. Mode mapping, hòa 50/50 và tooltip giữ như v1.
- Các trọng số là cấu hình prototype cố định, chưa được tối ưu bằng kết quả thực nghiệm.

Trong module con, helper chuẩn hóa tạm vector theo dữ liệu đã có và trả q riêng. Khi gộp ngoài phải nhân q đúng một lần. Không coi q là độ chính xác dự đoán.

## 3. Bát Tự mở rộng — đã tính những gì

Đầu vào `natal` gồm bốn cặp can/chi năm, tháng, ngày, giờ **đã được adapter lịch xác định**. Giờ sinh không biết dùng `None`, không tự đoán. Can 0..9, chi 0..11; chỉ chấp nhận cặp cùng tính chẵn/lẻ trong chu kỳ 60.

### 3.1 Thập thần và tàng can

```text
element(stem) = floor(stem/2)       // Mộc,Hỏa,Thổ,Kim,Thủy
delta = (element(other)-element(day_master)) mod 5
same_polarity = (other mod 2) == (day_master mod 2)
```

| delta | Cùng âm/dương | Khác âm/dương |
|---:|---|---|
| 0 | Tỷ Kiên / peer | Kiếp Tài / competitor |
| 1 | Thực Thần / expression | Thương Quan / challenge |
| 2 | Thiên Tài / opportunity | Chính Tài / stewardship |
| 3 | Thất Sát / pressure | Chính Quan / responsibility |
| 4 | Thiên Ấn / reflection | Chính Ấn / support |

Tàng can của 12 chi đã có trong mã và được xét với Nhật chủ theo cùng công thức. V1 chỉ so ngũ hành chung; v2 giữ cả âm/dương và các can ẩn.

Điểm trụ thời gian: can lộ chiếm .4; phần tàng can chiếm .6 chia đều cho các can ẩn. **Chia đều là phép đơn giản hóa của app**, không phải bảng tỷ lệ khí lực theo từng tiết. Chưa tự suy diễn rằng can có mặt nhiều hơn chắc chắn mạnh hơn theo mọi trường phái.

Vector thập thần do sản phẩm đặt:

| ID | A | C |
|---|---:|---:|
| peer | .10 | -.25 |
| competitor | .05 | .25 |
| expression | .30 | .25 |
| challenge | .10 | .40 |
| opportunity | .20 | .35 |
| stewardship | .15 | -.20 |
| pressure | -.25 | .20 |
| responsibility | .10 | -.15 |
| reflection | -.20 | -.10 |
| support | .20 | -.20 |

### 3.2 Hồ sơ ngũ hành và chỉ số hỗ trợ

Tính phân bố năm hành bằng trụ năm/tháng/ngày/giờ có trọng số 1/1.5/1/1. Mỗi trụ dùng .4 can lộ + .6 tàng can. Tổng được chuẩn hóa về 1.

```text
support_index = tỷ trọng cùng hành Nhật chủ + tỷ trọng hành sinh Nhật chủ
```

Đây là **chỉ số nội bộ để mô tả dữ liệu**, chưa đủ kết luận thân vượng/nhược hay dụng thần. Hiện chỉ xuất trong diagnostics, không tự đẩy điểm YES lên vì thiếu một hành.

Có nhận diện bộ ba tam hợp đủ ba chi trong natal để giải thích cấu trúc. Chưa tự coi đủ bộ ba là đã hợp hóa thành hành mới. Các hiệu ứng hình/hại/phá và cách cục đặc biệt chưa được chấm khi chưa có bộ quy tắc đối chiếu.

### 3.3 Điểm từng tầng và điểm B

```text
Layer = .55 × TenGodVector + .30 × BranchRelationVector
      + .15 × ReviewedFavorableElementVector
```

BranchRelation dùng lục hợp/lục xung/cùng chi đã định nghĩa v1. Phần favorable chỉ tính nếu có bảng năm hành [-1,1] từ bộ luận đã rà soát, gắn nguồn và phiên bản. Hiện không có bộ tự luận dụng thần để sinh bảng này; nếu không có, phần .15 thiếu và không được bù sang chỗ khác.

```text
B = .10 × đại_vận + .15 × lưu_niên + .15 × lưu_nguyệt
  + .30 × lưu_nhật + .30 × lưu_thời
```

Các trụ của tầng vận phải do adapter cung cấp. Mã hiện xử lý can/chi của đại vận được cung cấp, **chưa tính tuổi khởi vận và chiều an vận từ ngày sinh**. Bản hoàn chỉnh cần thống nhất trường phái, lịch tiết khí, khởi vận và ca ngoại lệ.

## 4. Tử Vi mở rộng — chính tinh, phụ tinh, độ sáng và tầng vận

Đầu vào: danh sách sao với `name`, `palace_index`, `brightness`; bản đồ cung mục tiêu theo lĩnh vực; các vị trí Tứ Hóa theo tầng. Không biết giờ sinh: bỏ module Z.

Đã hỗ trợ đủ tên 14 chính tinh: Tử Vi, Thiên Cơ, Thái Dương, Vũ Khúc, Thiên Đồng, Liêm Trinh, Thiên Phủ, Thái Âm, Tham Lang, Cự Môn, Thiên Tướng, Thiên Lương, Thất Sát, Phá Quân.

Phụ tinh được chấm ở v2: Tả Phụ, Hữu Bật, Văn Xương, Văn Khúc, Thiên Khôi, Thiên Việt; Kình Dương, Đà La, Hỏa Tinh, Linh Tinh, Địa Không, Địa Kiếp. Sao ngoài danh sách phải được adapter giữ dưới dạng metadata chưa chấm, không tự gán điểm.

Mỗi sao có vector A/C riêng trong bảng hằng `MAJOR`/`AUX` của mã. Những vector này là diễn giải do app đặt; không phải điểm cát/hung chuẩn của cổ thư.

Độ sáng dùng hệ số: miếu 1; vượng .95; đắc .85; lợi .80; bình .70; bất .60; hãm .50. Đây là hệ số biên tập. Không làm sao hãm biến thành “sao xấu chắc chắn”, cũng không đổi dấu một sao chỉ vì miếu.

- Chính tinh thiếu trạng thái độ sáng: chưa chấm thành phần chính tinh.
- Phụ tinh thuộc trường phái không có trạng thái sáng: không áp hệ số sáng.
- Adapter phải cung cấp cả catalog được yêu cầu: thiếu sao khác với đã tính đủ và sao nằm ngoài vùng ảnh hưởng.

Quan hệ cung: chính cung 1; đối cung .5; hai cung tam hợp .6; còn lại 0. Tính riêng theo cung mục tiêu của lĩnh vực.

```text
Major = clamp(Σ[vector_sao × hệ_số_sáng × hệ_số_cung] / 4)
Aux   = clamp(Σ[vector_sao × hệ_số_sáng × hệ_số_cung] / 3)
Z     = .45 Major + .20 Aux + .35 Transformations
```

Transformations phân bổ:

```text
.15 bản_mệnh + .15 đại_hạn + .15 lưu_niên
+ .10 lưu_nguyệt + .20 lưu_nhật + .25 lưu_thời
```

Mỗi tầng có cung mục tiêu trong chính hệ tọa độ của tầng đó và đúng bốn biến hóa. Không dùng index cung bản mệnh thay index cung lưu vận khi chưa quy đổi.

**Giới hạn:** chưa có bộ an sao tự động trong Python, chưa luận mọi tổ hợp cách cục, vòng sao và sát tinh. Mã đã chấm được các sao/vận nêu trên nếu adapter đưa dữ liệu đúng. Cần đối chiếu lá số bằng cùng trường phái trước khi phát hành; không gọi là luận Tử Vi toàn diện.

## 5. Phong thủy không gian — module F

### 5.1 Hồ sơ không gian tối thiểu

```text
space_id, space_revision, active
room_sector                         // vị trí của ghế/phòng so với tâm nhà
seat_heading_deg, seat_error_deg    // hướng người ngồi, không phải hướng điện thoại bất kỳ
house_facing_deg, house_error_deg   // hướng mặt nhà, không tự lấy hướng cửa
personal_gua?                       // tùy chọn mệnh quái
north_reference                    // magnetic hoặc true; không trộn
chart_north_reference
```

Room sector là N/NE/E/SE/S/SW/W/NW/C. Thành phố hoặc GPS không đủ suy ra phòng đang ở vùng nào. User có thể chọn vùng trên sơ đồ đơn giản, không cần tải ảnh hay chụp nhà.

Đối với bàn Phi Tinh natal còn cần vận nhà, tọa/hướng chính xác, quy tắc xác định vận (hoàn công/nhập trạch/cải tạo theo trường phái), bàn sơn/hướng đã lập. Bản mã hiện chưa tự dựng bàn natal từ năm xây/hướng nhà; nhận bàn đã kiểm chứng để chấm.

User phải chủ động chọn `Use this space` cho reading. Địa điểm thay đổi không dùng tiếp nhà cũ một cách âm thầm. Không xin quyền vị trí chỉ để giả đo được cấu trúc nhà.

### 5.2 Mệnh quái và Bát Trạch

`solar_birth_year` là năm đã xử lý ranh Lập Xuân, không hardcode ngày 4/2. Với r là rút gọn 1..9:

```text
d = r(tổng chữ số solar_birth_year)
male_convention:   gua = r(11-d); nếu 5 đổi thành 2
female_convention: gua = r(4+d);  nếu 5 đổi thành 8
```

Đây là tham số theo quy tắc truyền thống; không suy đoán từ tên hay avatar. User bỏ qua thì không tính hướng cá nhân. Mã giới hạn năm đầu vào 1900–2099.

Mã hóa quái: Khảm 010, Khôn 000, Chấn 100, Tốn 011, Càn 111, Đoài 110, Cấn 001, Ly 101. XOR quái gốc với quái hướng cho bảng Du Niên:

| XOR | Du Niên | A | C |
|---:|---|---:|---:|
| 0 | Phục Vị | .20 | -.40 |
| 1 | Sinh Khí | .50 | .15 |
| 6 | Thiên Y | .30 | -.15 |
| 7 | Diên Niên | .35 | -.25 |
| 4 | Họa Hại | -.15 | 0 |
| 3 | Ngũ Quỷ | -.30 | .10 |
| 5 | Lục Sát | -.25 | .10 |
| 2 | Tuyệt Mệnh | -.40 | 0 |

Tên cổ được giữ trong dữ liệu, UI global dùng diễn đạt trung tính; không diễn giải tên sao thành nguy cơ sức khỏe, chết chóc hoặc tai nạn.

- PersonalDirection: quái cá nhân đối chiếu **hướng ghế/người ngồi**.
- HouseSector: quái **tọa nhà = facing+180°** đối chiếu **vị trí phòng/ghế**.
- Tám hướng chia ô 45°, Bắc có tâm 0°. Nếu sai số đo chạm ranh ô, module bỏ phần đó và yêu cầu đo lại; không chọn đại một hướng.
- `true` và `magnetic` phải thống nhất; có đổi thì adapter cần độ lệch từ theo địa điểm/thời điểm. Không mặc định true north = magnetic north.

### 5.3 Phi Tinh — tính được một phần, không giả dựng bàn natal

Mã đã có đường phi Lạc Thư `C→NW→W→NE→S→N→SW→E→SE`. Với tâm c, vị trí thứ i và chiều d=+1/-1:

```text
star_i = ((c - 1 + d × i) mod 9) + 1
annual_center = r(11 - r(tổng chữ số solar_year))
current_period = (floor((solar_year - 1864)/20) mod 9) + 1
```

`solar_year` phải được adapter xác định qua Lập Xuân. Không lấy năm Gregorian trước Lập Xuân. Bàn annual phi thuận; ví dụ năm mặt trời 2026 tâm 1. Hàm tạo bàn số không tự quyết chiều phi cho sơn/hướng tinh.

Nếu có hai bàn natal sơn/hướng hợp lệ, lấy sao ở `room_sector`. Mỗi bàn phải đủ chín ô và là hoán vị 1..9. Các bảng natal hợp lệ phải đi kèm metadata vận nhà, hướng, trường phái và nguồn/phiên bản; kiểm tra hoán vị trong kernel chỉ kiểm tra hình thức, chưa chứng minh an bàn đúng.

Điểm thời vận sao thử nghiệm theo khoảng cách modulo 9 với vận hiện tại: cùng vận .5; vận kế .25; sau nữa .1; còn lại -.2. Đây là phép đơn giản hóa biên tập, chưa luận đầy đủ tổ hợp sơn/hướng và hình thế.

```text
Flying_A = .40 MountainStar + .40 WaterStar + .20 AnnualStar
Flying_C = 0
F = .40 PersonalDirection + .30 HouseSector + .30 Flying
```

Thiếu bàn natal thì chỉ annual có dữ liệu, qFlying=.2. Thiếu năm/hướng để dựng natal không được tự gán nhà vào vận hiện tại. Chưa xử lý thế tinh, hướng sát ranh 24 sơn, nhà bất quy tắc, địa hình ngoài nhà, thủy pháp hoặc hình sát. Các trường hợp đó không được tuyên bố đã audit.

F thay đổi khi chọn không gian khác, đổi vị trí/hướng hoặc lớp vận năm thay đổi. Không tự tạo biến động mỗi giờ từ một hồ sơ nhà tĩnh.

## 6. “Tín hiệu vũ trụ” — module U

Tên global gợi ý: `Cosmic timing`; màn chi tiết dùng `Moon phase` và `Planetary motion` để user biết dữ liệu cụ thể.

V1 W đã xét góc transit–natal. U chỉ thêm hình học hiện tại Sun/Moon và vận tốc biểu kiến Mercury. Không có “tần số năng lượng” đo bằng điện thoại, angel numbers ngẫu nhiên, lời nhắn từ vũ trụ hoặc lượng tử giả định.

```text
phi = (longitude_moon - longitude_sun) mod 360
illumination_approx = (1 - cos(phi))/2
Phase_A = .35 sin(phi)
Phase_C = .25 cos(phi)
```

Phi dùng kinh độ địa tâm tropical tại thời điểm UTC chuẩn hóa của reading; sin/cos chuyển độ sang radian trong mã. `illumination_approx` là xấp xỉ hình học phẳng, không thay số chiếu sáng chính xác của ephemeris khi cần hiển thị khoa học.

Quy ước biên tập: trăng đang lớn nghiêng về tiến hành; trăng đang nhỏ nghiêng về suy xét. Đây là **ý nghĩa biểu tượng của app**, không kết luận từ NASA hay bằng chứng rằng pha trăng quyết định hành động con người.

Với speed là vận tốc kinh độ Mercury địa tâm, độ/ngày:

```text
m = clamp(speed / .10, -1, 1)
Motion_A = .15 m
Motion_C = .10 m
U = .80 Phase + .20 Motion
```

Những hệ số này chỉ tạo thay đổi nhỏ, liên tục. Nghịch hành không tự ép kết quả NO. `|speed|≤.01` được gắn nhãn stationary theo ngưỡng hiển thị thử nghiệm. Thiếu tốc độ thì bỏ phần .20, không đọc lịch “Mercury retrograde” từ ngày trong năm được ghi cứng.

Không tự suy nhật/nguyệt thực chỉ từ phi=0/180, vì cần thêm hình học nút quỹ đạo/vĩ độ và ephemeris. Nhật thực/nguyệt thực, void-of-course Moon, Kỳ Môn và Kinh Dịch chưa thêm vào U khi chưa có đặc tả riêng.

## 7. Luồng một nút và global time sau mở rộng

Trang chủ vẫn là avatar + tên + lựa chọn mode. Lĩnh vực General mặc định, thời điểm NOW mặc định, không thêm bước phân tích câu hỏi.

Hồ sơ mở rộng nằm trong Settings, cung cấp dần:

1. Hồ sơ sinh: ngày/giờ/nơi sinh và quy ước được chọn.
2. Không gian: Home/Office/Other, phòng/vị trí, hướng; nhập một lần và sửa khi đổi bố trí.
3. Khi đọc: không gian là tùy chọn; `No space selected` vẫn dùng được tất cả module đủ dữ liệu còn lại.

Loading chỉ hiện các bước đã có dữ liệu: `Reading your personal cycles`, `Comparing today's chart`, `Checking your space`, `Reading the Moon's phase`. Không được hiện `Checking your space` khi chưa chọn không gian hoặc qF=0.

UTC/IANA/local date tiếp tục theo v1. Với v2 thêm vào cache:

```text
ruleset_version, profile_revision, reading_zone, segment_utc_start,
category, active_space_id?, space_revision?, heading_snapshot?,
calendar_provider_version, chart_provider_version, ephemeris_version
```

Không tự lấy heading thay đổi từng giây để reroll. Heading được đo/xác nhận và giữ trong snapshot reading. Giờ chọn ở tương lai chỉ được dùng không gian hiện tại khi user dự định ở đó; không suy vị trí tương lai từ vị trí hiện tại.

Tính Top 2 theo A như v1, dùng cùng space snapshot cho toàn khoảng được chọn. Nếu đổi không gian, phải đánh dấu đây là kịch bản khác. Phần trăm của các ô không cộng thành 100; kết quả cùng đầu vào có thể bằng nhau.

Mở khóa qua Ads/Premium không ảnh hưởng trọng số, sao hay điểm. Đổi không gian không được dùng để âm thầm thu lại phí xem cùng khoảng đã mở.

## 8. Dữ liệu giải thích và kiểm chứng

Các hàm v2 trả Evidence và diagnostics (phân bố hành, thập thần, số sao được chấm, layer, quái/hướng, pha trăng…). Đây là dữ liệu để renderer viết câu mẫu; không dùng tên sao chưa tính làm lý do.

Trước production, adapter phải bổ sung `source_id`, `provider_version`, `ruleset_id`, `input_timestamp`, `computed_at`, `space_revision` và kiểm chứng nguồn của từng feature. Kernel hiện chưa phải kho audit đầy đủ.

Test số học và cấu trúc đã bổ sung:

- Mười Nhật chủ đều ánh xạ đủ mười thập thần; bộ ba tam hợp không kích hoạt khi thiếu một chi.
- Dữ liệu thiếu không bị biến thành dụng thần tự động.
- Sao trùng bị từ chối; thiếu giờ sinh, chính tinh hoặc độ sáng thì không giả bộ đầy đủ.
- Các ví dụ mệnh quái; tám quái có đủ tám quan hệ khác nhau; phân biệt tọa và hướng.
- Sai số la bàn sát ranh bị loại; north reference khác nhau bị từ chối.
- Lạc Thư là hoán vị đủ 1..9; annual center và vận năm mẫu.
- Trăng mới/tròn/bán nguyệt có hình học đúng theo công thức xấp xỉ; tốc độ Mercury âm được nhận là retrograde.
- Giới hạn tác động của F/U, xác định kết quả lặp, tổng hai phần trăm bằng 100.

Những test này xác nhận code thực hiện công thức đã định nghĩa, không xác nhận phong thủy/tử vi dự đoán đúng. Tính ngày/giờ global và lập lá số thực còn cần bộ adapter + fixture độc lập.

## 9. Bảng hoàn thành

| Hạng mục | Đã có trong v2 | Chưa có |
|---|---|---|
| Bát Tự | Tàng can, thập thần, phân bố hành, nhận diện tam hợp đủ, chấm trụ thời gian được cung cấp | Tự lập trụ từ DOB, luận thân/cách cục/dụng thần toàn diện, khởi vận tự động, hợp hóa/hình/hại/phá đầy đủ |
| Tử Vi | Chấm 14 chính tinh +12 phụ/sát tinh, độ sáng, tam phương tứ chính, Tứ Hóa các tầng kể cả đại hạn khi có input | Bộ an sao/an vận tự động, mọi tổ hợp cách cục/vòng sao và thẩm định đầy đủ |
| Không gian | Mệnh quái, Bát Trạch cá nhân/nhà, xử lý ranh hướng, Lạc Thư, annual stars, chấm bàn natal được cung cấp | Tự dựng bàn natal sơn/hướng từ nhà, toàn bộ 24 sơn/thế tinh, sơ đồ địa hình và hình thế |
| Cosmic timing | Pha trăng từ kinh độ, Mercury motion từ tốc độ, điểm biểu tượng giới hạn | Bộ thiên văn tích hợp và các sự kiện khác |

Đây là mở rộng thực sự của phần tính điểm. Muốn triển khai end-to-end, bước kế tiếp là adapter ngày sinh→trụ/lá số/kinh độ và adapter không gian→bàn sao có nguồn đối chiếu, không chỉ đổi nhãn thành “đầy đủ”.
