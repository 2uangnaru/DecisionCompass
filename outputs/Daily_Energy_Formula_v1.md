# Daily Energy v1 — công thức đang chạy

`Daily energy` là tông biểu tượng của **toàn ngày theo timezone hiện tại của người dùng**. Nó dùng hồ sơ sinh và sáu module sẵn có (Bát Tự, Tử Vi, lịch ngày/giờ, chiêm tinh phương Tây, thần số học, tín hiệu Mặt Trăng/Mercury). Đây không phải số đo sức khỏe, tâm trạng hay khả năng thành công.

## Cách tính

1. Chia ngày địa phương thành các khung có ranh giới giờ Can Chi, lịch và DST như engine đang dùng. Xét cả ngày, kể cả các giờ đã qua và chưa tới.
2. Với mỗi khung `i`, chạy sáu module và fusion `general` để có trục hành động `A_i`, trục thay đổi `C_i` và độ phủ `Q_i`. Category người dùng đang chọn không ảnh hưởng Daily Energy.
3. Lấy trung bình theo thời lượng thực `d_i = (end_i - start_i)`:

   `A_day = Σ(d_i × A_i) / Σd_i`

   `C_day = Σ(d_i × C_i) / Σd_i`

   `Q_day = Σ(d_i × Q_i) / Σd_i`

4. Nếu `Q_day < 0.2`, hiển thị `—`; không suy diễn khi thiếu dữ liệu. Trường hợp khác:

   `index = round(50 + 40 × clamp(0.65 × A_day + 0.35 × C_day, -1, 1))`

   | Index | Nhãn |
   |---:|---|
   | 10–49 | SOFT |
   | 50–52 | STEADY |
   | 53–90 | BRIGHT |

Các hệ số 0.65/0.35 và ngưỡng nhãn là quy tắc biên tập của sản phẩm. Ngưỡng được kiểm tra trên 90 ngày mẫu từ ba hồ sơ tổng hợp để tránh trường hợp hầu như ngày nào cũng hiện `STEADY`; đây không phải hiệu chuẩn dự báo đời thực. Chỉ hiển thị nhãn trên Home/Result; index và độ phủ nằm trong `dailyBrief.energy` để kiểm thử và giải thích công thức, không hiển thị như phần trăm xác suất.

Kết quả không thay đổi khi bấm lại trong cùng ngày địa phương, đổi YES/NO, category hoặc thời điểm. Khi qua nửa đêm hoặc mở lại app ngày mới, Home lấy bản Daily Brief mới. Ngày có đổi giờ mùa hè được cân theo 23/25 giờ thật. Snapshot lịch sử giữ phiên bản engine/ruleset để không diễn giải lại kết quả cũ.
