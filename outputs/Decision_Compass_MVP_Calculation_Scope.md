# Decision Compass — phạm vi tính toán MVP

Trạng thái cập nhật 19/09/2026: đã có engine MVP chạy input → kết quả tại
`../calculation-engine/src/index.js`. Hướng dẫn và giới hạn thực tế:
[Calculation Engine README](../calculation-engine/README.md).
Luồng kỹ thuật đã triển khai; không đồng nghĩa với luận Bát Tự/Tử Vi toàn diện.
Tài liệu này thay các yêu cầu input và phạm vi tương ứng trong Formula v1/v2.

## Input và thời gian

- Người dùng nhập ngày sinh, giờ sinh hoặc Không rõ; không bắt nhập thành phố sinh.
- Quốc gia sinh đã chọn được giữ như dữ liệu hồ sơ; không coi là vị trí hiện tại.
- Quy ước truyền thống là input riêng nếu phép tính cần; không suy từ tên/quốc gia.
- Current Context Resolver chỉ xử lý thời điểm/vùng/múi giờ hiện tại.
- App truyền UTC instant và IANA timezone đã resolve vào engine. Ưu tiên timezone từ vị trí hiện tại nếu xác định được rõ ràng; fallback timezone thiết bị. Lấy snapshot tại lúc bấm.
- Vùng/quốc gia hiện tại là metadata tùy chọn. Locale/ngôn ngữ không chứng minh vị trí.
- Lần mở đầu xin quyền vị trí hiện tại theo luồng bên dưới; không lấy GPS liên tục và không chặn app nếu từ chối.
- Không có Home/Travel mode. Vẫn phải xử lý DST và đổi ngày trong timezone đang dùng.
- Không dùng múi giờ hiện tại để suy múi giờ sinh lịch sử.
- Ngày/giờ sinh được giữ dưới dạng local civil date/time; birth UTC chưa xác định nếu thiếu birth timezone.
- Không chọn múi giờ phổ biến nhất của quốc gia như dữ liệu sinh đã xác nhận.

## Xin vị trí khi mở app

- Lần mở đầu hiển thị giải thích ngắn, rồi gọi hộp thoại quyền của hệ điều hành khi người dùng chọn Continue.
- Copy đề xuất: `Set your local timing` / `Use your current location to find your region and time zone for today's reading.`
- Hai nút trên màn giải thích của app: `Continue` và `Use device time zone`. Nhãn trong hộp thoại quyền gốc do hệ điều hành quyết định.
- Chỉ yêu cầu vị trí khi dùng app (foreground/When In Use), chấp nhận vị trí gần đúng; không yêu cầu quyền nền.
- Đã có quyền: lấy một vị trí hiện tại khi mở app nếu cần làm mới, không hiện lại màn xin quyền mỗi lần.
- Từ chối, quyền tạm thời hết hạn, tắt dịch vụ vị trí hoặc hết thời gian chờ: tiếp tục bằng timezone thiết bị. Cho bật lại qua Settings theo khả năng nền tảng, không lặp hộp thoại ép cấp quyền.
- Vị trí trả về gồm tọa độ, độ chính xác và thời điểm đo. Resolver ánh xạ tọa độ sang vùng/quốc gia và IANA timezone bằng dữ liệu địa lý; tọa độ không tự chứa timezone.
- Nếu vùng sai số cắt qua nhiều timezone, vị trí quá cũ hoặc tra cứu lỗi, dùng timezone thiết bị và ghi nguồn fallback. Không ép một timezone từ vị trí không chắc chắn.
- Không lưu đường đi hoặc gửi tọa độ vào analytics. Nếu chọn dịch vụ tra cứu bên ngoài, phải ghi rõ dịch vụ và dữ liệu gửi trước khi triển khai.
- Snapshot reading chứa `instant_utc`, `zone_id`, `offset_seconds`, `zone_source`, `tzdb_version`; vị trí cập nhật muộn chỉ áp dụng reading tiếp theo.
- Vị trí hiện tại không điền đè nơi sinh/quốc gia sinh hoặc birth timezone.

Tài liệu nền tảng đã đối chiếu:

- https://developer.apple.com/documentation/corelocation/requesting-authorization-to-use-location-services
- https://developer.android.com/develop/sensors-and-location/location/permissions/runtime

## Phạm vi module

- N: thần số học theo ngày sinh và ngày địa phương hiện tại.
- T: lịch/ngày giờ theo ruleset lịch được chốt và timezone hiện tại.
- B: Bát Tự; không biết giờ sinh thì không tạo trụ giờ. Quy tắc cần thời điểm sinh tuyệt đối (ranh tiết khí, khởi vận) phải đánh dấu chưa xác định khi thiếu dữ liệu.
- Z: Tử Vi; phân tích giờ sinh không rõ là tính năng cần đặc tả và kiểm chứng riêng.
- W: chiêm tinh theo thiên thể. Chưa dùng Ascendant/houses trong MVP. Natal positions cần xử lý khoảng thời điểm sinh chưa xác định; không âm thầm lấy giờ hiện tại hoặc giờ trưa làm giờ sinh.
- U: pha Mặt Trăng và chuyển động hành tinh ở thời điểm phân tích.
- F: phong thủy không gian loại khỏi MVP; không cần hồ sơ nhà/hướng/phòng.
- Category mặc định General. Decision mode lấy từ thẻ đã chọn, không hỏi lại trong hồ sơ.
- Không sinh văn bản luận giải. Giữ diagnostics nội bộ để kiểm chứng.

## Giờ sinh không rõ

Đã triển khai 12 kịch bản Tử Vi khi thiếu giờ sinh; 24 khi thiếu cả quy ước nam/nữ.
Chỉ giữ tín hiệu cùng chiều ở mọi kịch bản và dùng mức nhỏ nhất; nếu khác chiều thì
trục tương ứng đóng góp 0. Không dùng trung bình 12 lá số như một giờ sinh thật.
Đây là quy tắc tổng hợp của app, chưa phải phương pháp dự đoán được xác thực.
Không gọi 10/12 lá số đồng thuận là độ chính xác hay coverage cao.
Coverage thiếu input và khoảng phân tán kịch bản được lưu riêng.

Không được gán trung bình một giờ đại diện cho ngày sinh có giao tiết khí,
giao lịch hoặc thay đổi múi giờ. Giữ phần bất biến; phần chưa xác định phải
có trạng thái riêng hoặc bỏ đóng góp.

## Tổng hợp

Ruleset mới bỏ F và chuẩn hóa trọng số cấu hình một lần:

    B=2/9, Z=2/9, T=1/9, W=2/9, N=1/6, U=1/18

Dùng các phân số trên khi tính; phần trăm làm tròn chỉ để hiển thị.
Đây là quyết định cấu hình MVP, không phải thay đổi theo dữ liệu từng người.
Module thiếu dữ liệu không được phân phối trọng số lại cho module khác.
Không tự tạo kết quả ngẫu nhiên. Cùng snapshot và ruleset trả cùng kết quả.
Các điểm phần trăm là mức phù hợp biểu tượng theo mô hình, không phải xác suất thành công.

## Các hạng mục đã được nối vào pipeline MVP

1. Current Context Resolver và cắt đoạn UTC/local quanh DST, giao ngày.
2. Calendar provider: lịch âm, tháng nhuận, tiết khí, Can Chi, hoàng/hắc đạo, Trực.
3. BaZi generator và quy tắc thiếu giờ/múi giờ sinh, có nguồn đối chiếu.
4. Zi Wei generator; chỉ mở các tầng vận và chế độ thiếu giờ đã kiểm chứng.
5. Ephemeris provider và adapter W/U; xử lý sai số natal time.
6. Fusion mới, quét khoảng thời gian, Top 2, snapshot/cache/version.
7. Đối chiếu dữ liệu lịch/lá số/thiên văn độc lập và kiểm thử toàn pipeline.

Giấy phép và phiên bản thư viện phải kiểm tra khi chọn provider.
Không gọi đầy đủ chỉ vì các module có tên hoặc có bảng chấm điểm.
Kernel v1/v2 hiện có vẫn nhận dữ liệu chuyên môn chuẩn hóa;
engine mới tại `calculation-engine` đã bổ sung generator và dùng lại các hệ số v2.

## Giới hạn hiện còn

- Dụng/Hỷ thần tự động và mọi cách cục đặc biệt chưa có bộ quy tắc được kiểm chứng;
  engine xuất null, bỏ thành phần favorable-element và phản ánh trong coverage.
- Một số quan hệ Bát Tự/vòng sao Tử Vi được tạo làm diagnostics nhưng chưa được chấm điểm.
- Chưa có kiểm thử thiết bị mobile hoặc plugin Unity; bản hiện tại là Node.js SDK offline.
- Không thể phục hồi dữ liệu sinh không có. Country/timezone candidates được xử lý như
  dữ liệu chưa xác định, không lấy vị trí hiện tại thay cho nơi sinh.
- Bảng kiểm thử thực tế: [Verification](../calculation-engine/VERIFICATION.md).
