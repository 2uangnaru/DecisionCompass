# AstraCue — bàn giao để tiếp tục ở chat / máy mới

Cập nhật: 2026-11-13, Asia/Saigon. Đây là bản tóm tắt quyết định và trạng thái dự án,
không phải bản xuất đầy đủ lịch sử chat, ảnh đính kèm hoặc dữ liệu người dùng trên điện thoại.
Đối chiếu code và Git hiện tại trước khi làm tiếp; một số README cũ mô tả trạng thái trước đây.

## 1. Bắt đầu ở môi trường mới

Repository: https://github.com/2uangnaru/DecisionCompass

```sh
git clone --branch codex/ios https://github.com/2uangnaru/DecisionCompass.git
cd DecisionCompass
git status --short
git log -5 --oneline
```

Nếu đã có checkout, kiểm tra branch và working tree trước, không reset/clean/checkout đè
công việc chưa commit. Không tự merge `codex/ios` vào `main`: bản iOS đang miễn phí,
Android vẫn giữ kiếm tiền. Tên nhánh thực tế là **`codex/ios`**, không phải `IOS`.

Đọc theo thứ tự:

1. File này: mục tiêu hiện tại và quyết định mới nhất.
2. `mobile_app/MONETIZATION_SWITCH.md`: chính sách miễn phí riêng iOS.
3. `mobile_app/IOS_RELEASE.md` và `mobile_app/IOS_VERIFICATION.md`: build, ký, phát hành,
   phân biệt việc đã làm thực tế với việc chưa xác minh.
4. `CLAUDE.md`: hướng dẫn/cấu trúc và lịch sử kỹ thuật; một số phần cũ đã bị thay thế.
5. Khi đụng Android: `mobile_app/MONETIZATION.md`, `ADS_LIFECYCLE.md`, `PLUS_BILLING.md`,
   `TRACKING.md`. Không áp nguyên chính sách Android vào bản iOS miễn phí.

## 2. Công việc đang dừng ở đâu

Chủ app đang chuẩn bị **đăng ký Apple Developer dạng cá nhân**.
Theo thông tin đã xác nhận, hiện chưa có tài khoản Apple Developer hoạt động, chưa có
Apple Team ID/chứng chỉ/provisioning để phát hành, chưa có hồ sơ app App Store Connect.
Chủ app cũng chưa có Mac riêng; vấn đề môi trường build đã giải quyết bằng GitHub Actions macOS.
Không hỏi lại các thông tin đã có trong tài liệu; chỉ xác nhận khi chủ app báo tình trạng mới.

Đã hoàn tất:

- Chuẩn bị native iOS, responsive và chế độ iOS miễn phí, push vào `codex/ios`.
- Merge hướng dẫn lần đầu/TUT từ main sang iOS; không bỏ hoặc ghi đè TUT này.
- **Build release native iOS thành công trên cloud**, không chạy lại test theo yêu cầu.
- Đã tải archive chưa ký về máy Windows và kiểm tra checksum.

Chưa hoàn tất:

- Tài khoản Apple, Team/Bundle ID thực sự thuộc chủ app, signing/provisioning.
- Trang HTTPS privacy/terms/support với thông tin chủ app thật; cấu hình release thật.
- IPA có chữ ký, TestFlight, hồ sơ Store, ảnh Store, khai báo riêng tư/content rating,
  export compliance, upload và Apple xét duyệt.
- Native/device QA chưa được xác nhận. Build thành công không đồng nghĩa app được Apple duyệt.

Khi Apple Developer đã được kích hoạt: xác định Team ID/Bundle ID và quyền truy cập,
cấu hình signing trong secret storage của CI, hoàn tất release JSON/URL thật, build/export
IPA có chữ ký rồi upload vào App Store Connect. Không đăng ký tài khoản, chi tiền, phát hành
hoặc yêu cầu gửi mật khẩu/private key vào chat. Không dùng thông tin giả để vượt preflight.
Không cần mua Mac để dùng quy trình cloud; archive hiện tại không thể upload trực tiếp.

## 3. Bằng chứng build iOS gần nhất

- Mã nguồn build: `4503df024e1e2a254e47fd4a86b8e4c7b4ab24f6`.
- Commit tài liệu sau build: `2be5a01` (không thay binary, có `[skip ci]`).
- Workflow: `.github/workflows/ios-unsigned.yml`, chỉ build nhánh `codex/ios`.
- Run thành công: https://github.com/2uangnaru/DecisionCompass/actions/runs/43350528827
- macOS 26, Xcode **26.6 (17F113)**, iPhoneOS SDK **26.5**.
- Flutter **3.47.5**, Dart **3.13.4**. Dart SDK của app là `^3.13.4`.
- Lệnh: `flutter pub get --enforce-lockfile`, `bash tool/build_ios.sh --unsigned`.
- Kết quả: `Runner.xcarchive`, 243.5 MB chưa nén; ZIP archive khoảng 91.3 MB.
- App: **AstraCue**, version `0.1.0+1`, deployment target iOS 15.0.
- Bundle ID đang dùng để compile: `com.decisioncompass.decisionCompass`;
  không coi đây là bằng chứng đã đăng ký/thuộc quyền Apple team của chủ app.
- Info.plist và PrivacyInfo.xcprivacy qua `plutil -lint`; binary qua kiểm tra selector
  Always Location của script. Không chạy Flutter analyze/test/native/UI tests trong run này.
- Artifact GitHub `AstraCue-iOS-UNSIGNED-1`, ID `14004052260`, giữ **1 ngày**,
  hết hạn dự kiến 2026-11-14 09:20 giờ Việt Nam. Không dựa vào URL tạm để lưu lâu dài.

Archive ZIP đã tải về đường dẫn cũ:

```text
C:\Users\ADMIN\Documents\Codex\2026-09-18\b-n-l-m-t-chuy\mobile_app\build\ios\cloud-artifacts\AstraCue-iOS-UNSIGNED.xcarchive.zip
```

SHA256 archive ZIP:
`b795df77fac681785a4bd910ef0dbcd880a1606e683ce0e1883239c3ddc6bb18`.
Thư mục trên cũng có `BUILD-INFO.txt`, `SHA256SUMS.txt` và ZIP bọc ngoài tải từ GitHub.
Thư mục `build/` bị Git ignore: **clone repo không mang các file này sang máy mới**.
Copy archive ZIP và build info sang nơi lưu riêng trước khi rời máy cũ.

Đây là **archive unsigned, không phải IPA cài được hay upload được**. Không đổi đuôi ZIP
thành IPA. Khi signing/config phát hành đã sẵn sàng, build/export lại theo release script.

Workflow chỉ build, không test; dùng runner macOS tiêu chuẩn, không tạo tài khoản Apple
hay thực hiện upload. Push thay đổi `mobile_app/**`, `assets/**` hoặc workflow trên nhánh iOS
có thể tự kích hoạt build. Commit chỉ sửa tài liệu có thể dùng `[skip ci]` để tránh build thừa.

## 4. Sản phẩm đã chốt

**AstraCue: Cosmic Decisions**: app di động global, gợi ý một hướng khi người dùng phân vân
trong khoảnh khắc/ngày đó. Không cần mô tả chi tiết câu hỏi, không dùng AI inference.
Tính toán theo các hệ biểu tượng: cung hoàng đạo/thiên văn, thần số học, lịch Can Chi,
Bát Tự, Tử Vi, lịch ngày giờ và các tín hiệu liên quan trong engine.
Các phần chuyên sâu phụ thuộc dữ liệu/trường phái không được ngụy tạo là đã đầy đủ.
Kết quả là độ nghiêng **biểu tượng**, không phải xác suất khoa học hay cam kết chính xác.

- 9 mode hiện chọn được: YES/NO, ACT/WAIT, ADVANCE/RETREAT, STAY/GO, KEEP/LET GO,
  COMMIT/WITHDRAW, LEFT/RIGHT, REASON/EMOTION, CONFRONT/AVOID.
- FORWARD/BACKWARD đã nghỉ; chỉ giữ mapping cho lịch sử cũ, không đưa lại vào selector.
- 7 category: `general`, `love`, `career`, `money`, `study`, `friends`, `other`.
  Mode và category phải tác động đúng ý nghĩa vào scoring; không chỉ đổi label của YES/NO.
- Thời điểm ở màn Reveal: NOW mặc định, Morning/Midday/Afternoon/Evening.
  NOW lấy thời điểm thực lúc bấm. Chọn buổi thì tìm Top 2 khung giờ may mắn trong buổi đó,
  không diễn đạt nhầm thành cả ngày; không đề xuất khung giờ đã qua.
- Khóa buổi khi thời gian còn lại không vượt cutoff: Morning 90 phút, Midday 60 phút,
  Afternoon 90 phút, Evening 90 phút. Xử lý timezone/DST trong engine.
- Header avatar theo cung hoàng đạo, tên, daily energy, hai màu cạnh nhau không có nhãn
  Lead/Support, lucky number; thông điệp ngày và mô tả năng lượng luân phiên có chống lặp.
- Nút Reveal bấm một lần, hiệu ứng huyền bí/tech và vòng quay mượt. Giữ bố cục đã chốt,
  không tự kéo dài loading hay thiết kế lại. Loading có câu trấn an khi tap liên tiếp.
- Kết quả hướng chính lớn/nổi bật hơn số %, YES tông xanh nước biển thân thiện;
  lịch sử lưu snapshot, không tính lại kết quả cũ theo hồ sơ mới.
- Ngôn ngữ mặc định English; hỗ trợ 8 ngôn ngữ: English, Vietnamese, Japanese,
  Spanish, Thai, Hindi, Simplified Chinese, Korean. Font được bundle cho chữ đa ngôn ngữ.

Hồ sơ: tên có thể trống (render Explorer theo locale hiện tại, không lưu cứng bản dịch),
ngày sinh, giờ sinh hoặc Không rõ, quốc gia sinh; không bắt nhập thành phố sinh.
Bộ chọn giờ dạng AM/PM, không tự lưu giờ mặc định chưa có lựa chọn thực sự.
Quốc gia sinh dùng cho tính toán, không bị thay bằng chọn ngôn ngữ.
Timezone hiện tại lấy IANA từ thiết bị; không ép GPS cho luồng thông thường.

Sửa hồ sơ: đổi tên; giờ sinh có thể thêm/sửa, cooldown sau đổi 2 giờ; quốc gia sinh 1 giờ;
ngày sinh lần đầu sửa sau tạo hồ sơ 2 giờ, sau mỗi lần đổi chờ 4 giờ.
Hồ sơ cũ thiếu thời điểm tạo được sửa ngày sinh lần đầu ngay. Đổi dữ liệu tính toán phải
invalidate/tính lại tín hiệu mới, không viết lại lịch sử. Thông báo cooldown chống spam,
overlay dưới nút Back, không đẩy cả layout xuống; Cancel/Save ngang hàng, bằng kích thước.

Responsible Use: đọc/cuộn đến cuối mới Agree; khi chưa đủ, nút xám không cho đi vào
phân tích, chạm nút có hướng dẫn được dịch. Back vẫn dùng được, không nhốt người dùng.
Không dùng app để định hướng hành vi bạo lực, phạm pháp hay quyết định rủi ro cao.

## 5. Tính toán hiện tại và giới hạn

- App chạy engine **trong máy** qua background isolate; không cần gọi server để đọc.
  Tuy vậy có app-level network guard: không quảng cáo toàn app hoạt động offline.
- JS tham chiếu: `calculation-engine/src/`; Dart dùng thực tế: `mobile_app/lib/local_engine/`.
- Engine `4.4.0-mvp`, ruleset `civil-midnight-chinese-calendar-symbolic-v9.7-experimental`.
  Scoring quyết định vẫn ghi `v9.6-experimental`; v9.7 có hiệu chỉnh daily energy.
- Chủ app đã chốt giảm chuỗi cả tuần cùng kết quả và quá nhiều kết quả 51/49, 52/48.
  Đã có các lần mô phỏng/chỉnh phân bố; không tự quay về công thức cũ hay thêm random
  để ép mới. Điểm phải xác định từ input/ngày giờ, có thể giải thích và giữ parity JS/Dart.
- Nếu đổi công thức: đọc `calculation-engine/VERIFICATION.md`, scoring ở hai engine,
  fixtures và Python đối chiếu; bump version và xác minh phù hợp. Không thay thuật toán
  dưới danh nghĩa chỉ sửa UI. Không diễn giải độ nghiêng 80% thành cơ hội thành công 80%.
- Daily energy: 8 nhãn; v9.7 hiệu chỉnh trên cohort giả lập với mục tiêu QUIET 7%, SOFT 10%,
  STEADY 15%, LIVELY 17%, BRIGHT 15%, RADIANT 8%, FOCUSED 14%, FLOWING 14%.
  Đây là mục tiêu phân bố hiệu chỉnh, không phải đo đạc sức khỏe/năng lượng thực của user.

## 6. iOS và Android khác nhau thế nào

**iOS hiện tại**: `MonetizationPolicy` mặc định false, không tạo dịch vụ ads/Plus;
mọi mode/category/buổi còn hợp lệ/guidance miễn phí, không quota/chờ do kiếm tiền.
Ẩn VIP/upsell/reward/banner và chỗ trống tương ứng; vẫn giữ safety, cutoff buổi và cooldown
sửa hồ sơ. Không xóa trạng thái Plus/quota cũ. Analytics là chính sách độc lập;
cloud build này đặt Firebase analytics=false rõ ràng.

**Android**: giữ logic đã có, không vô hiệu hóa theo iOS.

- 3 lượt free/ngày, cách nhau 3 giờ sau hoàn tất; local 00:00 reset ngay quota và chờ.
  UI hiển thị lượt còn lại 3/3 → 2/3. Rewarded earned cấp bonus; đóng chưa earned không cấp.
- Interstitial: bảo vệ lần đọc đầu/ngày và History trong flow đó. Lần free sau có thể
  show trước Result; lượt bonus/reward không show inter sau phân tích. History tap đủ
  điều kiện có thể show. Không show khi về Home/back/resume. Gap chung 30 giây tính từ
  native dismiss; không trần inter/ngày và không gap riêng cho rewarded.
- Preload, retry/backoff, cache expiry, fullscreen lock, UMP recovery đã có;
  banner adaptive ở Home/Reveal, refresh do SDK/AdMob, không timer tự refresh.
- Plus một lần, mức demo USD **$4.99** đã chốt: 6 lượt/ngày, không energy cooldown,
  mở gates và bỏ banner/inter; optional rewarded khi hết lượt theo bản đã chốt.
  Có app-side entitlement/billing, nhưng chưa có cấu hình store/verifier Android thật.
- Chưa có xác nhận tài khoản Play Console/AdMob và production IDs. Chỉ test IDs.
  Firebase instrumentation đã có, cấu hình dự án thật/receipt dashboard chưa xác minh.
  Không coi UI demo, test ads hoặc test purchase là tiền/doanh thu thật.

## 7. Cấu trúc và file cần biết

```text
.github/workflows/ios-unsigned.yml    Build macOS, archive unsigned
mobile_app/
  lib/main.dart, app.dart            Startup/router/dependencies
  lib/pages/                        Onboarding, Home, Ritual, Loading, Result,
                                    History, Profile, Legal, Compass awakening
  lib/widgets/                      UI/dialog/animation/TUT dùng chung
  lib/data/                         Profile/history/quota/time-period stores
  lib/local_engine/                 Engine offline Dart và daily energy/colors
  lib/data/models/                  DTO/contracts của engine
  lib/billing/                      Store adapter, verifier, entitlement
  lib/services/                     Ads/UMP/banner/network guard/iOS bridge
  lib/analytics/                    Event contract, consent, sinks
  lib/l10n/                         ARB và localization generated
  lib/monetization_policy.dart       Switch miễn phí iOS
  lib/reading_dependencies.dart      Boundary quota/ads/Plus/engine
  ios/Runner/AppDelegate.swift       Native StoreKit/iOS bridge
  ios/Runner/PrivacyInfo.xcprivacy   Privacy manifest
  ios/Flutter/AppSettings.xcconfig   Public defaults
  ios/scripts/validate_release.sh    Guard release; unsigned opt-in riêng
  tool/build_ios.sh                 --unsigned, --demo hoặc signed JSON
  tool/ios_release_config.dart       Validate/generate native owner settings
  test/                            Tests/fixtures; không phải production engine
calculation-engine/                 Node tham chiếu, fixtures, parity/cohort tools
handoff/localization/               Bàn giao localization trước đây
outputs/                           Đặc tả, audit, các report
assets/ và mobile_app/assets/       Art/font và asset app; giữ đúng paths pubspec
CLAUDE.md                           Handoff cũ/hướng dẫn repo, đọc có đối chiếu ngày
```

Không cần thiết kế lại backend/auth/DB để tiếp tục tác vụ iOS này. Những đề xuất game,
app ảnh/nhóm/tiền chung từ đầu lịch sử đã bị bỏ, không phải scope dự án hiện tại.

## 8. Máy cũ và các dữ liệu KHÔNG có trong clone

Workspace cũ: `C:\Users\ADMIN\Documents\Codex\2026-09-18\b-n-l-m-t-chuy`.
Flutter: `C:\Users\ADMIN\develop\flutter`; JDK: `C:\Users\ADMIN\develop\jdk-17`.
Android toolchain đã cài ở máy cũ: SDK 36, Build-Tools 36.0.0, JDK 17;
môi trường máy mới phải setup riêng, clone repo không cài SDK giúp bạn.
GitHub CLI trên máy cũ chưa login; Git push qua credential manager dùng được.
Không sao chép/phơi lộ token, certificate hoặc credential store vào repo public.

Tại thời điểm bàn giao có các thay đổi local từ trước tác vụ cloud build, chưa commit:

```text
 M CLAUDE.md
?? RELEASE_CHECKLIST.md
?? assets/app_icon/store_developer_header_4096x2304.jpg
?? assets/app_icon/store_developer_icon_512x512.jpg
?? assets/app_icon/store_developer_icon_512x512.png
?? mobile_app/review/
?? outputs/APP_WALKTHROUGH_2026-11-02.md
?? outputs/ASTRACUE_GLOBAL_REVENUE_MARKETING_PLAN_2026-11-12.md
?? outputs/ENERGY_AUDIT_2026-11-05.md
?? outputs/energy_audit_2026_11_05.dart
?? outputs/energy_audit_2026_11_05.json
```

Những file này được giữ nguyên, **không tự push kèm**. Nếu cần mang chúng sang máy mới,
copy thư mục dự án hoặc sao lưu chúng riêng; đối chiếu với `git status` mới nhất.
Ảnh đính kèm chat ở Temp, APK cũ, `build/`, SDK/caches và dữ liệu app trên điện thoại
không được bảo đảm có trên GitHub. File bàn giao này không khôi phục toàn bộ chat cũ.

Gói bàn giao tạo ở máy cũ: `mobile_app/build/handoff/AstraCue-handoff-2026-11-13.zip`.
Gói này nằm ngoài Git, cần copy/download riêng trước khi rời máy. Bên trong gồm
file bàn giao, ZIP source nhánh iOS hiện tại (không có thư mục `.git`/lịch sử đầy đủ),
các file local liệt kê trên, archive iOS chưa ký và hướng dẫn khôi phục. Không gồm
toàn bộ ảnh/chat Temp, mọi APK lịch sử, SDK/caches, dữ liệu app hay credential store.
Nếu có GitHub, ưu tiên clone branch rồi xem phần local-worktree trước khi ghép lại.

## 9. Cách làm việc với chủ app

- Trao đổi tiếng Việt rõ, ngắn; chủ app làm solo và dựa vào trợ lý cho phần code.
- Tôn trọng UI/UX đã chốt; tác vụ logic không tự đổi giao diện/branding/copy.
- Không tự thêm quảng cáo, bật VIP iOS, đổi công thức hoặc merge khác nền tảng.
- Khi chủ app chỉ xin prompt cho Claude, chỉ viết prompt; khi yêu cầu sửa/build/push,
  làm trong scope đó. Tránh hỏi xác nhận lặp lại cho bước đã được phép.
- Ở tác vụ build iOS vừa rồi chủ app nói **không cần chạy lại test**: đã tuân thủ;
  không chạy lại toàn bộ suite chỉ để đọc handoff/đổi máy. Nếu tác vụ sau thực sự đổi
  logic, chọn kiểm chứng phù hợp theo yêu cầu mới, không tuyên bố chưa chạy là đã pass.
- Giữ nguyên thay đổi của người/agent khác, đọc file mới nhất trước sửa, không git clean,
  reset hard hoặc force-push. Không tự commit/publish file unrelated hay thông tin riêng tư.
- Mỗi báo cáo phân biệt implemented / tested / native-built / signed / uploaded / approved.
- Sau việc đáng kể, cập nhật bàn giao để lần chuyển chat tiếp theo không phụ thuộc bộ nhớ.

## 10. Prompt dán vào chat mới

```text
Tiếp tục dự án AstraCue (DecisionCompass) từ repo:
https://github.com/2uangnaru/DecisionCompass
Nhánh làm việc hiện tại: codex/ios. Đọc HANDOFF_CURRENT.md ở gốc repo trước,
sau đó đọc các tài liệu iOS/monetization được chỉ dẫn trong đó và kiểm tra Git hiện tại.

App Flutter đã build release iOS unsigned thành công bằng GitHub Actions macOS.
iOS hiện miễn phí, tắt Ads/VIP; Android giữ kiếm tiền. Tôi đang chuẩn bị Apple Developer
cá nhân, chưa xác nhận có Team ID/chứng chỉ. Mục tiêu tiếp là chuẩn bị ký/export IPA
và phát hành iOS khi tài khoản sẵn sàng; không mặc định rằng archive unsigned upload được.

Không chạy lại test chỉ để tiếp nhận dự án, không tự sửa UI/UX, công thức hoặc bật kiếm
tiền iOS; không merge iOS sang main. Bảo toàn mọi thay đổi local. Nếu chưa có repo access,
hãy đọc file bàn giao tôi đính kèm và nói rõ giới hạn, không tự nhận đã kiểm tra code.
Trước hết tóm tắt ngắn tình trạng hiện tại và bước tiếp theo dựa trên tài liệu/code.
```
