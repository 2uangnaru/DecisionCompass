# AstraCue — Project Handover & Context Resume (Bàn giao tiếp tục công việc)

> **Mục đích:** File này tổng hợp 100% bối cảnh, trạng thái kỹ thuật, các quyết định sản phẩm và các bước tiếp theo của dự án **AstraCue** để khi mở một phiên chat mới (hoặc chuyển sang máy tính mới), AI agent mới có thể đọc và tiếp tục làm việc ngay lập tức mà không bị mất mạch thông tin.

---

## 1. Thông tin Chung & Cấu trúc Dự án

* **Tên ứng dụng:** AstraCue — Daily Cross-Cultural Decision Companion (`com.astracue.cosmicdecisions`).
* **Công nghệ:** Flutter / Dart (chạy 100% On-Device, chi phí API AI = 0).
* **Lõi Engine (7 trường phái):**
  1. Bát Tự / BaZi (Tứ Trụ, Thập Thần, Ngũ Hành).
  2. Tử Vi Đẩu Số (12 Cung, 14 Chính Tinh, Tứ Hóa).
  3. Hoàng Lịch Đông Á (Âm lịch, 24 Tiết khí, 12 Trực, Giờ Hoàng Đạo).
  4. Chiêm Tinh Vệ Đà / Jyotish (Lahiri Ayanamsa, 27 Nakshatras).
  5. Chiêm Tinh Phương Tây (Transit–Natal, 7 Hành tinh).
  6. Thần Số Học Pythagoras (Đường đời & Chu kỳ cá nhân).
  7. Thiên Văn Thực (Pha Mặt Trăng, Sao Thủy Nghịch hành).
* **Hỗ trợ 8 ngôn ngữ (11 locales):** `vi`, `en`, `es`, `ja`, `ko`, `th`, `hi` (`hi-IN`), `zh` (`zh-Hans-CN`).
* **Nguyên tắc Invariants bất di bất dịch (`GEMINI.md`):**
  - Cosmic Context Card: Format đúng **2 đoạn văn** (`\n\n`), 0 từ ngữ mê tín/tuyệt đối, 0 số % thô trong tiêu đề.
  - Action Guidance Card: `Nên` có prefix thời gian (`Đầu ngày: `, `Giữa ngày: `...), `Tránh` kết thúc bằng ngoặc đơn nhắc nhở nhịp độ `(tránh...)`. Tiếng Hindi dùng danda `।` thay vì dấu chấm `.`.
  - Date parsing: luôn sanitize `birthDateStr.split('T').first` thành 10 ký tự `YYYY-MM-DD`.
  - Build Test APK: Phải luôn có `--dart-define=PLUS_DEMO_BILLING=true` để chủ app test VIP/Plus.

---

## 2. Trạng thái Kỹ thuật Mới nhất (Phiên trước vừa hoàn thành)

### A. Giao diện & Trải nghiệm (UI/UX)
1. **TUT Bàn tay khai mở (Option T2 - Ghost Filigree Ethereal Hand):**
   - Đã thay thế bàn tay vector cũ bằng bàn tay nét mảnh ethereal ánh vàng kim, phong cách huyền ảo khớp visual app.
   - Đầu ngón trỏ được khóa FK chính xác tuyệt đối (`0.0 px` sai lệch) tại tâm điểm gợn sóng (`Offset(22, 22)`), nằm lọt trọn vẹn trong vòng lõi Reveal Orb ở góc dưới bên phải.
   - File: `mobile_app/lib/pages/ritual_page.dart` (`_RevealHandTut`, `_RevealHandTutPainter`).
2. **Icon Đợi hồi 3 tiếng (Option C2 - Astral Hourglass Icon):**
   - Xóa bỏ hoàn toàn emoji hệ điều hành (`⏱`) và icon Material không hợp tông (`Icons.hourglass_bottom_rounded`).
   - Tạo mới `AstralHourglassIcon` (CustomPainter vector) với hiệu ứng bầu cát thiên thể, 2 quầng sao 4 cánh `✦` tại eo đồng hồ và các hạt cát ánh sáng rơi.
   - Áp dụng đồng bộ tại: `RitualPage`, `ProfilePage`, `HomeEmbeddedEnergyTray`, `AnalysisEnergyPlusCard` trên cả 8 ngôn ngữ.
   - File: `mobile_app/lib/widgets/celestial_ui.dart`, `mobile_app/lib/widgets/astracue_plus_ui.dart`.

### B. Build, Versioning & Google Play Release
1. **Mã phiên bản (Version Code):**
   - `versionCode = 1` và `versionCode = 2` đã bị Play Console báo đã sử dụng.
   - Đã nâng `mobile_app/pubspec.yaml` lên: **`version: 0.1.0+10`** (`versionCode = 10`).
   - Đã build và xác thực release AAB ký bằng release keystore:
     `mobile_app/build/app/outputs/bundle/release/app-release.aab` (đã verify `jar verified`, `versionCode="10"`).
2. **Khai báo Mã nhận dạng quảng cáo (AD_ID) trên Google Play Console:**
   - Hiện tại: Trong bản release mặc định (chưa bật cờ `ADS_ENABLED=true`), `noAdsNoPlus/AndroidManifest.xml` đã gỡ bỏ quyền `AD_ID` và tắt collection của Analytics.
   - **Đã chọn trên Play Console:** Chọn **"Không" (No)**.
   - Khi nào bật AdMob sau này: Sẽ chuyển sang chọn "Có" (Yes) -> tích chọn "Quảng cáo hoặc tiếp thị".
3. **Ảnh Store (Play Store Assets):**
   - Icon ứng dụng: `assets/app_icon/store_app_icon_512x512.png` & `.jpg` (512 × 512 px).
   - Đồ họa nổi bật (Feature Graphic): `assets/app_icon/store_feature_graphic_1024x500.png` & `.jpg` (1024 × 500 px, đã xóa ngôi sao thừa phía trên chữ WESTERN).
4. **Phạm vi Quốc gia / Vùng lãnh thổ:**
   - Trên Google Play Console: Chọn **"Tất cả quốc gia và khu vực"** (All countries/regions) để phục vụ tester toàn cầu và đón traffic organic.

---

## 3. CẢNH BÁO QUAN TRỌNG KHI CHUYỂN MÁY TÍNH

Khi chuyển sang máy mới, cần lưu ý 3 việc sống còn:

1. **Keystore ký ứng dụng (RẤT QUAN TRỌNG):**
   - Hai file này nằm trong `.gitignore` nên **KHÔNG CÓ TRÊN GITHUB**:
     + `mobile_app/android/upload-keystore.jks`
     + `mobile_app/android/key.properties`
   - **BẮT BUỘC** phải copy 2 file này sang máy mới vào đúng vị trí `mobile_app/android/`. Nếu mất keystore này, bạn sẽ **không bao giờ cập nhật được app này lên Google Play Store nữa**.
2. **Các file ảnh Store chưa commit:**
   - Thư mục `assets/app_icon/` chứa các ảnh store 512x512, 1024x500, banner dev... cần copy hoặc commit.
3. **Môi trường build trên máy mới:**
   - Flutter SDK: `3.35.x` (hoặc mới nhất tương thích).
   - JDK: Java 17 (`$env:JAVA_HOME='.../jdk-17'`).
   - Android SDK: API 34-36.

---

## 4. Các bước tiếp theo cần làm

1. **Commit & Push code:**
   - Commit các thay đổi T2, C2, `versionCode = 10` trên branch `android`:
     ```powershell
     git add mobile_app/lib/ mobile_app/test/ mobile_app/pubspec.yaml assets/app_icon/ HANDOVER_RESUME.md
     git commit -m "feat(ui): implement ethereal hand tut T2, astral hourglass C2, bump version to 0.1.0+10"
     git push origin android
     ```
   - Sync các cải tiến UI (T2 + C2) sang branch `main` và `codex/ios` nếu cần.
2. **Tiến hành Closed Testing trên Google Play Console:**
   - Upload file `app-release.aab` (`versionCode = 10`).
   - Mời danh sách 12 tester để chạy thử nghiệm 14 ngày theo chính sách Google Play cá nhân.
3. **Build APK Test cho chủ app (khi cần):**
   - Luôn chạy:
     ```powershell
     C:\Users\ADMIN\develop\flutter\bin\flutter.bat build apk --debug --dart-define=PLUS_DEMO_BILLING=true
     ```

---

## 5. Câu lệnh mẫu (Prompt) để dán vào phiên chat mới

Khi mở phiên chat mới ở máy mới hoặc công cụ mới, bạn chỉ cần dán đoạn prompt sau:

```text
Xin chào, tôi vừa chuyển sang phiên làm việc mới cho dự án AstraCue. 
Hãy đọc kỹ file HANDOVER_RESUME.md và GEMINI.md ở thư mục gốc của dự án để nắm toàn bộ bối cảnh kỹ thuật, các công việc vừa hoàn thành (TUT T2, icon C2, AAB v10, Play Console setup) và các việc tiếp theo.
Sau khi đọc xong, hãy xác nhận bạn đã sẵn sàng tiếp tục hỗ trợ tôi.
```
