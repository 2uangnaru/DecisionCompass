// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appName => 'AstraCue';

  @override
  String get analyticsConsentTitle => 'Thống kê sử dụng (không bắt buộc)';

  @override
  String get analyticsConsentBody =>
      'Cho phép Firebase/Google Analytics thu thập thông tin sử dụng app và thiết bị để cải thiện AstraCue. Không gửi tên, thông tin sinh hoặc lá số của bạn. Bạn có thể tắt trong mục Sử dụng có trách nhiệm.';

  @override
  String get analyticsConsentSaveFailed =>
      'Không thể lưu lựa chọn này. Thống kê đã tắt trong phiên này.';

  @override
  String get continueAction => 'Tiếp tục';

  @override
  String get backAction => 'Quay lại';

  @override
  String get closeAction => 'Đóng';

  @override
  String get tryAgain => 'Thử lại';

  @override
  String get responsibleUse => 'Sử dụng có trách nhiệm';

  @override
  String get history => 'Lịch sử';

  @override
  String get onboardingTitle =>
      'Lắng nghe tín hiệu vũ trụ và trực giác của bạn.';

  @override
  String get onboardingLanguageHint =>
      'Nhấn biểu tượng địa cầu phía trên để đổi ngôn ngữ.';

  @override
  String get yourProfile => 'HỒ SƠ CỦA BẠN';

  @override
  String get signAfterBirthDate =>
      'CUNG HOÀNG ĐẠO SẼ HIỆN SAU KHI BẠN CHỌN NGÀY SINH';

  @override
  String get buildPattern => 'Khám phá năng lượng riêng của bạn.';

  @override
  String get profileExplainer =>
      'Định hình các chu kỳ được dùng khi phân tích.';

  @override
  String get nameField => 'Tên';

  @override
  String get dateOfBirth => 'Ngày sinh';

  @override
  String get selectBirthDate => 'Chọn ngày sinh';

  @override
  String get birthDateRequired => 'Hãy chọn ngày sinh để tiếp tục.';

  @override
  String get birthDay => 'Ngày';

  @override
  String get birthMonth => 'Tháng';

  @override
  String get birthYear => 'Năm';

  @override
  String get birthDateScroll => 'Cuộn';

  @override
  String get birthDateType => 'Nhập tay';

  @override
  String get birthDateInvalid => 'Nhập ngày hợp lệ từ năm 1900 đến hôm nay.';

  @override
  String get birthTimeUnknown => 'Không rõ giờ sinh';

  @override
  String get birthTimeUnknownDetail =>
      'Nếu bạn không nhớ giờ sinh, thuật toán sẽ dùng khung giờ gần với tính cách bạn nhất để tính toán.';

  @override
  String get timeOfBirth => 'Giờ sinh';

  @override
  String get countryOfBirth => 'Quốc gia nơi sinh';

  @override
  String get selectBirthCountry => 'Tìm và chọn quốc gia';

  @override
  String get birthCountryRequired => 'Hãy chọn quốc gia nơi sinh để tiếp tục.';

  @override
  String get createCompass => 'Tạo la bàn của tôi';

  @override
  String get birthPrivacyPrototype =>
      'Trong bản thử nghiệm này, thông tin ngày giờ sinh của bạn được giữ riêng tư.';

  @override
  String get homeEyebrow => 'LA BÀN CHỈ HƯỚNG GIÚP BẠN';

  @override
  String get homeTitle => 'Bạn đang phân vân?';

  @override
  String get areaQuestion => 'Điều bạn đang nghĩ đến thuộc lĩnh vực nào?';

  @override
  String get findDirection => 'Tìm hướng đi của bạn';

  @override
  String get todaySignals => 'TÍN HIỆU HÔM NAY';

  @override
  String get dailyEnergy => 'Năng lượng hôm nay';

  @override
  String get yourColorsToday => 'Màu sắc hôm nay:';

  @override
  String get luckyNumberToday => 'Con số hôm nay:';

  @override
  String get categoryOverall => 'Tổng quan';

  @override
  String get categoryLove => 'Tình cảm & Mối quan hệ';

  @override
  String get categoryCareer => 'Công việc';

  @override
  String get categoryMoney => 'Tài chính';

  @override
  String get categoryStudy => 'Học tập & Phát triển';

  @override
  String get categoryFriends => 'Bạn bè';

  @override
  String get categoryOther => 'Chuyện khác';

  @override
  String get periodQuestion => 'Bạn đang cân nhắc thời điểm nào?';

  @override
  String get periodNow => 'HIỆN TẠI';

  @override
  String get periodMorning => 'Sáng';

  @override
  String get periodMidday => 'Trưa';

  @override
  String get periodAfternoon => 'Chiều';

  @override
  String get periodEvening => 'Tối';

  @override
  String get periodPassed => 'Đã qua';

  @override
  String get periodTooLittleTime => 'Đã qua';

  @override
  String get periodCheckingTimezone => 'Đang xác định múi giờ';

  @override
  String get periodTimezoneUnknown => 'Chưa rõ múi giờ';

  @override
  String get timezoneUnavailableNotice =>
      'Không đọc được múi giờ của bạn, nên chỉ có thể chọn HIỆN TẠI. Hãy thử lại để chọn một buổi.';

  @override
  String periodHasPassed(String period) {
    return '$period đã qua. Hãy chọn thời điểm khác.';
  }

  @override
  String periodNotEnoughTimeLeft(String period) {
    return 'Hôm nay $period không còn đủ thời gian. Hãy chọn thời điểm khác.';
  }

  @override
  String get reveal => 'PHÂN TÍCH';

  @override
  String get aligning => 'KẾT NỐI';

  @override
  String get tapWhenReady => 'Chạm khi bạn đã sẵn sàng';

  @override
  String get keepChoiceInMind => 'Hãy nghĩ rõ về lựa chọn khiến bạn phân vân.';

  @override
  String get ritualSafety =>
      'Chỉ để suy ngẫm về chuyện thường ngày • Không dùng cho quyết định về y tế, đầu tư, vay nợ, chính trị hoặc việc có thể gây hại.';

  @override
  String get loadingLocalMoment => 'ĐANG PHÂN TÍCH KHOẢNH KHẮC CỦA BẠN';

  @override
  String get loadingReassurance =>
      'Vui lòng đợi một lát — các tín hiệu vũ trụ đang dần hội tụ.';

  @override
  String readingForCategory(String category) {
    return 'Đang phân tích về $category';
  }

  @override
  String get yourDirection => 'HƯỚNG ĐI DÀNH CHO BẠN';

  @override
  String get resultBasis =>
      'Dựa trên năng lượng và tín hiệu vũ trụ dành cho bạn tại thời điểm này.';

  @override
  String get percentageCaveat =>
      'Tỷ lệ phần trăm thể hiện mức độ tương hợp mang tính biểu tượng, không phải xác suất ngoài đời thực.';

  @override
  String get balancedHeading => 'HAI PHÍA ĐANG CÂN BẰNG';

  @override
  String get balancedResult => 'CÂN BẰNG';

  @override
  String get balancedExplanation =>
      'Hiện chưa có phía nào nổi trội. Kết quả này thể hiện sự cân bằng, không phải một câu trả lời bị che giấu.';

  @override
  String get currentMoment =>
      'Kết quả này phản ánh khoảnh khắc hiện tại của bạn.';

  @override
  String get luckyTimesCaveat =>
      'Mỗi tỷ lệ phần trăm là điểm tương hợp mang tính biểu tượng của một khung giờ, không phải xác suất hay cơ hội thành công. Các khung giờ được tính riêng nên tổng không nhất thiết bằng 100%.';

  @override
  String get tryAnotherDirection => 'Tìm hướng đi khác';

  @override
  String get viewHistory => 'Xem trong lịch sử';

  @override
  String get yourReadings => 'Các lần phân tích của bạn';

  @override
  String get noReadings =>
      'Chưa có lần phân tích nào. Hãy khám phá hướng đi đầu tiên để bắt đầu lưu lịch sử.';

  @override
  String get historySnapshot =>
      'Kết quả được lưu lại đúng như lúc hiển thị và không được tính lại.';

  @override
  String get everydayReflection =>
      'Chỉ để suy ngẫm về chuyện thường ngày. Quyết định quan trọng cần thông tin thực tế và sự hỗ trợ từ người có chuyên môn.';

  @override
  String get luckyTimesMorning => 'Những khung giờ may mắn nhất sáng nay';

  @override
  String get luckyTimesMidday => 'Những khung giờ may mắn nhất vào buổi trưa';

  @override
  String get luckyTimesAfternoon => 'Những khung giờ may mắn nhất chiều nay';

  @override
  String get luckyTimesEvening => 'Những khung giờ may mắn nhất tối nay';

  @override
  String get loadingLocalTime => 'Đồng bộ với ngày và giờ tại nơi bạn đang ở';

  @override
  String get loadingBaZi => 'Phân tích cân bằng ngũ hành Bát Tự';

  @override
  String get loadingZiWei => 'Đối chiếu chu kỳ Tử Vi quanh khoảnh khắc này';

  @override
  String get loadingVedic =>
      'Đối chiếu Nakshatra trong chiêm tinh Vệ Đà và các chòm sao Mặt Trăng';

  @override
  String get loadingNumerology =>
      'Kết nối thần số học với nhịp điệu Mặt Trăng và các hành tinh';

  @override
  String get loadingYinYang =>
      'Cân bằng tín hiệu Âm và Dương để gợi một hướng đi';

  @override
  String get loadingModeYesNo => 'Đối chiếu tín hiệu cởi mở và lực cản';

  @override
  String get loadingModeActWait =>
      'Cân bằng động lực hành động và sự kiên nhẫn';

  @override
  String get loadingModeAdvanceRetreat =>
      'Đối chiếu đà của hôm nay với vài ngày trước';

  @override
  String get loadingModeStayGo => 'Đối chiếu sự gắn bó và chuyển động';

  @override
  String get loadingModeKeepLetGo => 'Cân nhắc sự tiếp nối và buông bỏ';

  @override
  String get loadingModeForwardBackward =>
      'Đối chiếu xu hướng tiến lên và lùi lại';

  @override
  String get loadingModeCommitWithdraw =>
      'Đối chiếu xu hướng gắn bó và chấm dứt';

  @override
  String get loadingModeLeftRight => 'Cân bằng xu hướng tiếp nhận và thể hiện';

  @override
  String get orbitMoment => 'KHOẢNH KHẮC';

  @override
  String get orbitRhythm => 'NHỊP ĐIỆU';

  @override
  String get orbitBalance => 'CÂN BẰNG';

  @override
  String get orbitAlmanac => 'LỊCH CÁT HUNG';

  @override
  String get orbitBaZi => 'BÁT TỰ';

  @override
  String get orbitZiWei => 'TỬ VI';

  @override
  String get orbitVedic => 'CHIÊM TINH VỆ ĐÀ';

  @override
  String get orbitNumerology => 'THẦN SỐ HỌC';

  @override
  String get orbitLunarPhase => 'PHA MẶT TRĂNG';

  @override
  String get orbitPlanetary => 'HÀNH TINH';

  @override
  String get orbitYinYang => 'ÂM / DƯƠNG';

  @override
  String get safetyHeading => 'GIỚI HẠN & SỬ DỤNG CÓ TRÁCH NHIỆM';

  @override
  String get safetyTitle => 'Một góc soi chiếu cho chuyện thường ngày';

  @override
  String get safetyIntro =>
      'AstraCue đưa ra những góc nhìn mang tính biểu tượng dựa trên nhịp điệu thiên văn và các chu kỳ cá nhân. Ứng dụng chỉ dành cho việc suy ngẫm về chuyện thường ngày và giải trí, không phải mệnh lệnh, lời tiên đoán hay sự thật chắc chắn.';

  @override
  String get prohibitedUses => 'KHÔNG ĐƯỢC SỬ DỤNG CHO';

  @override
  String get harmTitle => 'Gây hại & Tự làm hại bản thân';

  @override
  String get harmDetail =>
      'Không dùng cho việc tự làm hại bản thân, tự sát, bạo lực thể chất hoặc gây nguy hiểm cho bất kỳ ai.';

  @override
  String get navigationTitle => 'Lái xe & Di chuyển ngoài đời thực';

  @override
  String get navigationDetail =>
      'TRÁI / PHẢI và TIẾN LÊN / LÙI LẠI chỉ là lựa chọn mang tính biểu tượng. Không dùng chúng để tham gia giao thông, lái xe, tìm đường hoặc quyết định liên quan đến an toàn thân thể.';

  @override
  String get politicsTitle => 'Chính trị & Xung đột xã hội';

  @override
  String get politicsDetail =>
      'Không dùng cho vận động chính trị, quyết định bầu cử, bất ổn dân sự hoặc hoạt động cực đoan.';

  @override
  String get medicalTitle => 'Sức khỏe, Y tế & Trường hợp khẩn cấp';

  @override
  String get medicalDetail =>
      'Không thay thế việc chăm sóc y tế có chuyên môn, điều trị sức khỏe tâm thần, thuốc men hoặc ứng phó khẩn cấp.';

  @override
  String get legalTitle => 'Pháp lý, Phạm pháp & Hợp đồng quan trọng';

  @override
  String get legalDetail =>
      'Không dùng cho hành vi phạm pháp, tố tụng, lời khai hoặc hợp đồng pháp lý có hậu quả lớn.';

  @override
  String get financeTitle => 'Đầu tư tài chính & Cờ bạc';

  @override
  String get financeDetail =>
      'Mục Tài chính chỉ để suy ngẫm về các khoản chi tiêu nhỏ thường ngày. Không dùng kết quả để đầu tư, vay nợ, đặt cược tiền mã hóa, cờ bạc hoặc quyết định tài chính lớn.';

  @override
  String get consentTitle => 'Sự đồng thuận, Trẻ vị thành niên & Mối quan hệ';

  @override
  String get consentDetail =>
      'Không dùng để phớt lờ sự đồng thuận hay quyền tự quyết của người khác, hoặc quyết định quyền nuôi dưỡng và giám hộ trẻ em.';

  @override
  String get importantLimitsHeading => 'GIỚI HẠN QUAN TRỌNG';

  @override
  String get importantLimitsBody =>
      'AstraCue không được thiết kế cho trẻ em. Ứng dụng không đưa ra lời khuyên y tế, pháp lý hoặc tài chính. Với quyết định quan trọng, hãy dùng thông tin đáng tin cậy và tìm sự hỗ trợ chuyên môn phù hợp. Quyền lựa chọn luôn thuộc về bạn.';

  @override
  String get crisisSupport =>
      'Nếu bạn hoặc người khác đang gặp nguy hiểm tức thời hay khủng hoảng tinh thần, hãy liên hệ ngay dịch vụ khẩn cấp hoặc đường dây hỗ trợ khủng hoảng đáng tin cậy tại nơi bạn sống.';

  @override
  String get acknowledge => 'Tôi hiểu và đồng ý';

  @override
  String get acknowledgementOnce =>
      'Xác nhận này chỉ xuất hiện một lần trước lần phân tích đầu tiên.';

  @override
  String get safetyScrollToContinue => 'Cuộn đến cuối, đọc hết để tiếp tục.';

  @override
  String get knowBirthTime => 'Tôi biết giờ sinh của mình';

  @override
  String get knowBirthTimeDetail =>
      'Giờ sinh chính xác giúp các chu kỳ theo giờ rõ nét hơn.';

  @override
  String get selectBirthTime => 'Chọn giờ sinh';

  @override
  String get birthTimeRequired =>
      'Hãy chọn giờ sinh để tiếp tục, hoặc tắt mục này nếu bạn không biết.';

  @override
  String get languageSetting => 'Ngôn ngữ';

  @override
  String get chooseLanguage => 'Chọn ngôn ngữ';

  @override
  String get changeLanguage => 'Đổi ngôn ngữ';

  @override
  String get languageNotSaved =>
      'Không lưu được lựa chọn ngôn ngữ, nên lần sau có thể không được ghi nhớ.';

  @override
  String get profileNotSaved =>
      'Không lưu được hồ sơ của bạn. Vui lòng thử lại.';

  @override
  String get choiceYes => 'CÓ';

  @override
  String get choiceNo => 'KHÔNG';

  @override
  String get choiceAct => 'HÀNH ĐỘNG';

  @override
  String get choiceWait => 'CHỜ ĐỢI';

  @override
  String get choiceAdvance => 'TIẾN LÊN';

  @override
  String get choiceRetreat => 'LÙI LẠI';

  @override
  String get choiceStay => 'Ở LẠI';

  @override
  String get choiceGo => 'RỜI ĐI';

  @override
  String get choiceKeep => 'GIỮ LẠI';

  @override
  String get choiceLetGo => 'BUÔNG BỎ';

  @override
  String get choiceForward => 'TIẾN LÊN';

  @override
  String get choiceBackward => 'LÙI LẠI';

  @override
  String get choiceCommit => 'GẮN BÓ';

  @override
  String get choiceWithdraw => 'CHẤM DỨT';

  @override
  String get choiceLeft => 'TRÁI';

  @override
  String get choiceRight => 'PHẢI';

  @override
  String get energyLevelQuiet => 'TĨNH LẶNG';

  @override
  String get energyLevelSoft => 'DỊU NHẸ';

  @override
  String get energyLevelSteady => 'ỔN ĐỊNH';

  @override
  String get energyLevelLively => 'SÔI NỔI';

  @override
  String get energyLevelBright => 'TƯƠI SÁNG';

  @override
  String get energyLevelRadiant => 'RỰC RỠ';

  @override
  String get energyLevelFocused => 'TẬP TRUNG';

  @override
  String get energyLevelFlowing => 'LINH HOẠT';

  @override
  String get colorCedar => 'Tuyết tùng';

  @override
  String get colorJade => 'Ngọc bích';

  @override
  String get colorSage => 'Xanh sage';

  @override
  String get colorMint => 'Xanh bạc hà';

  @override
  String get colorEmber => 'Than hồng';

  @override
  String get colorSolarCoral => 'San hô nắng';

  @override
  String get colorRose => 'Hồng phấn';

  @override
  String get colorBlossom => 'Hồng cánh hoa';

  @override
  String get colorOchre => 'Đất son';

  @override
  String get colorAmber => 'Hổ phách';

  @override
  String get colorSand => 'Màu cát';

  @override
  String get colorClay => 'Đất nung';

  @override
  String get colorSilver => 'Bạc';

  @override
  String get colorSteel => 'Xám thép';

  @override
  String get colorPearl => 'Ngọc trai';

  @override
  String get colorChampagne => 'Sâm panh';

  @override
  String get colorOceanBlue => 'Xanh đại dương';

  @override
  String get colorAzure => 'Xanh thiên thanh';

  @override
  String get colorIndigo => 'Chàm';

  @override
  String get colorMistBlue => 'Xanh sương mù';

  @override
  String get homeDescription00 =>
      'Hôm nay vũ trụ đang gửi đến bạn tín hiệu gì? Hãy nghĩ về điều khiến bạn băn khoăn và khám phá những dấu hiệu quanh khoảnh khắc này.';

  @override
  String get homeDescription01 =>
      'Đang phân vân giữa hai ngả đường? Hãy để những tín hiệu vũ trụ hôm nay gợi mở cho bạn một góc nhìn mới.';

  @override
  String get homeDescription02 =>
      'Các vì sao không quyết định thay bạn, nhưng nhịp điệu của chúng có thể giúp bạn nhìn nhận bước tiếp theo theo cách khác.';

  @override
  String get homeDescription03 =>
      'Khi con đường phía trước chưa rõ ràng, hãy chậm lại và nhìn sâu hơn. Tín hiệu hôm nay đang gợi nhắc điều gì?';

  @override
  String get homeDescription04 =>
      'Mỗi khoảnh khắc mang một nguồn năng lượng riêng. Hãy nghĩ về điều bạn băn khoăn và xem trực giác đang hướng bạn về đâu.';

  @override
  String get homeDescription05 =>
      'Có lẽ vũ trụ đang nhắc bạn chậm lại một nhịp. Hãy khám phá tín hiệu hôm nay trước khi chọn hướng đi.';

  @override
  String get homeDescription06 =>
      'Đứng trước ngã rẽ? Hãy xem những chuyển động trên bầu trời hôm nay gợi mở điều gì cho câu hỏi của bạn.';

  @override
  String get homeDescription07 =>
      'Hãy lắng nghe nhịp điệu của khoảnh khắc này. Tín hiệu hôm nay có thể mở ra một hướng đi đáng để bạn cân nhắc.';

  @override
  String get homeDescription08 =>
      'Khoảnh khắc này đang nhắn gửi điều gì? Hãy lắng nghe các dấu hiệu, rồi tin vào chính mình khi lựa chọn.';

  @override
  String get homeDescription09 =>
      'Một góc nhìn từ vũ trụ có thể giúp mọi thứ sáng rõ hơn. Hãy chọn điều quan trọng hôm nay và xem tín hiệu đang hướng về đâu.';

  @override
  String get homeDescription10 =>
      'Bạn vẫn đang trăn trở về cùng một lựa chọn? Hãy xem nguồn năng lượng hôm nay soi rọi điều gì.';

  @override
  String get homeDescription11 =>
      'Khi lý trí kéo bạn về một phía còn trực giác nghiêng về phía khác, hãy khám phá những tín hiệu của ngày hôm nay.';

  @override
  String get homeDescription12 =>
      'Chưa biết nên tiến bước hay tạm dừng? Hãy để nhịp điệu của ngày hôm nay mang lại cho bạn một điểm tựa bình tâm.';

  @override
  String get homeDescription13 =>
      'Biết đâu sự thông suốt lại bắt đầu từ một góc nhìn khác? Hãy dõi theo những chuyển động của vũ trụ hôm nay.';

  @override
  String get homeDescription14 =>
      'Một câu hỏi cứ lặp đi lặp lại trong tâm trí bạn. Hãy khám phá xem các tín hiệu hôm nay muốn bạn chú ý đến điều gì.';

  @override
  String get homeDescription15 =>
      'Có những quyết định trở nên nặng lòng hơn vào một thời điểm nào đó. Hãy cảm nhận nguồn năng lượng xung quanh trước khi lựa chọn.';

  @override
  String get homeDescription16 =>
      'Lúc này con đường có thể chưa tỏ tường. Những vì sao có thể soi sáng điều gì phía sau sự do dự của bạn?';

  @override
  String get homeDescription17 =>
      'Trước khi hành động theo một thôi thúc bất chợt, hãy hít một hơi thật sâu và xem tín hiệu vũ trụ hôm nay gợi mở điều gì.';

  @override
  String get homeDescription18 =>
      'Không phải ngã rẽ nào cũng cần câu trả lời ngay. Hãy để lần trải nghiệm hôm nay cho bạn một khoảng lặng để suy ngẫm.';

  @override
  String get homeDescription19 =>
      'Bạn đang tự hỏi liệu đây đã đúng thời điểm? Hãy khám phá những tín hiệu hôm nay để tìm một điểm tựa vững tâm hơn.';

  @override
  String get homeDescription20 =>
      'Khi mọi thứ đều có thể mà chẳng điều gì chắc chắn, hãy để chuyển động của bầu trời mở ra một góc nhìn mới.';

  @override
  String get homeDescription21 =>
      'Quyết định sau cùng vẫn luôn thuộc về bạn. Dấu hiệu hôm nay sẽ giúp bạn thấu tỏ điều gì mới thực sự quan trọng.';

  @override
  String get homeDescription22 =>
      'Khi sự hoài nghi che mờ bước tiếp theo, hãy xem cung hoàng đạo và năng lượng hôm nay soi tỏ điều gì.';

  @override
  String get homeDescription23 =>
      'Có lẽ bạn không cần một câu trả lời đao to búa lớn — chỉ cần một phút lắng lòng để cảm nhận những tín hiệu của hôm nay.';

  @override
  String get homeDescription24 =>
      'Trực giác đang nhắc bạn hành động hay kiên nhẫn chờ đợi? Hãy xem nhịp điệu vũ trụ hôm nay phản chiếu điều gì.';

  @override
  String get homeDescription25 =>
      'Giữa điều bạn mong muốn và điều bạn lo sợ luôn có chỗ để dừng lại. Hãy để những dấu hiệu hôm nay giúp bạn bình tâm nhìn nhận.';

  @override
  String get homeDescription26 =>
      'Bạn đã thấu tỏ câu hỏi trong lòng. Giờ hãy lắng nghe khoảnh khắc này: tín hiệu từ vũ trụ đang gợi mở điều gì?';

  @override
  String get homeDescription27 =>
      'Khi một quyết định trở nên rối rắm, hãy để các biểu tượng cổ xưa và thời khắc hôm nay mở ra cho bạn một góc nhìn mới.';

  @override
  String get homeDescription28 =>
      'Có lẽ đây là lúc để bước tới, hoặc cho mọi chuyện thêm không gian. Hãy cảm nhận nguồn năng lượng xung quanh lựa chọn của bạn.';

  @override
  String get homeDescription29 =>
      'Bạn không cần tìm kiếm sự chắc chắn tuyệt đối ở đây. Chỉ cần một phút bình tâm, một tín hiệu vũ trụ và một hướng đi để cân nhắc.';

  @override
  String get energyQuiet00 =>
      'Năng lượng hôm nay lắng đọng và hướng vào nội tâm, mở ra khoảng lặng để bạn suy ngẫm.';

  @override
  String get energyQuiet01 =>
      'Nhịp điệu vũ trụ hôm nay hướng về sự tĩnh lặng; chỉ khi lắng lại, bạn mới thấy rõ những điều từng bị xao nhãng che khuất.';

  @override
  String get energyQuiet02 =>
      'Bầu trời hôm nay mang sắc thái trầm mặc; hãy cho tâm trí thời gian để lắng dịu.';

  @override
  String get energyQuiet03 =>
      'Dòng chảy hôm nay nhẹ nhàng và sâu lắng, mời bạn tĩnh tâm quan sát thay vì vội vã đưa ra quyết định.';

  @override
  String get energyQuiet04 =>
      'Tín hiệu hôm nay gợi nhắc sự chiêm nghiệm; đôi khi tạm dừng một nhịp cũng chính là một phần của hành trình tiến bước.';

  @override
  String get energyQuiet05 =>
      'Khi mọi thứ xung quanh lắng xuống, chiếc la bàn trực giác bên trong bạn sẽ lên tiếng rõ ràng nhất.';

  @override
  String get energyQuiet06 =>
      'Năng lượng hôm nay dành không gian để bạn lắng nghe trực giác trước khi vội vã tìm kiếm câu trả lời.';

  @override
  String get energyQuiet07 =>
      'Không phải thông điệp nào cũng ồn ào; hôm nay bạn sẽ dễ dàng nhận ra tín hiệu hơn khi chậm lại.';

  @override
  String get energySoft00 =>
      'Năng lượng hôm nay chuyển động nhẹ nhàng, phù hợp cho sự cẩn trọng và từng bước đi vững chắc.';

  @override
  String get energySoft01 =>
      'Dòng chảy vũ trụ hôm nay rất dịu êm; từng bước đi nhỏ sẽ tự nhiên và an tâm hơn một bước nhảy vội.';

  @override
  String get energySoft02 =>
      'Năng lượng hôm nay nhắc bạn nhẹ nhàng với chính mình; hãy tiếp cận quyết định mà không tự tạo áp lực phải chắc chắn ngay.';

  @override
  String get energySoft03 =>
      'Nhịp điệu thư thái của ngày hôm nay sẽ giúp bạn bắt đầu từ những điều vừa sức và nhẹ nhàng nhất.';

  @override
  String get energySoft04 =>
      'Sự mềm mỏng cũng chứa đựng sức mạnh; hãy nhận biết lúc nào bạn cần thoải mái thay vì tự tạo áp lực.';

  @override
  String get energySoft05 =>
      'Tín hiệu hôm nay gợi ý một khởi đầu nhẹ nhàng: vừa đủ để chuyển động, không cần phải thúc ép tiến độ.';

  @override
  String get energySoft06 =>
      'Dòng năng lượng hôm nay rất tinh tế; một hành động giản dị nhưng thấu đáo sẽ mang lại nhiều ý nghĩa.';

  @override
  String get energySoft07 =>
      'Ngay cả một cơ hội nhỏ cũng đáng trân trọng; nhịp điệu dịu dàng hôm nay mở ra không gian để bạn khám phá nó.';

  @override
  String get energySteady00 =>
      'Năng lượng hôm nay giữ nhịp điệu cân bằng và vững chãi.';

  @override
  String get energySteady01 =>
      'Năng lượng hôm nay duy trì nhịp độ ổn định; hãy tin tưởng vào tốc độ bền bỉ mà bạn có thể bước tiếp.';

  @override
  String get energySteady02 =>
      'Chuyển động vũ trụ hôm nay mang lại cảm giác vững tâm, cho bạn không gian để suy xét và bước đi thấu đáo.';

  @override
  String get energySteady03 =>
      'Dòng năng lượng hôm nay êm đềm và vững chãi; sự chú tâm sâu lắng sẽ hữu ích hơn là vội vã.';

  @override
  String get energySteady04 =>
      'Tín hiệu hôm nay hướng về sự cân bằng, nhắc bạn giữ tâm thế vững vàng nhưng không ngừng tiến bước.';

  @override
  String get energySteady05 =>
      'Kiên định chính là một nguồn sức mạnh; hãy tạm dừng một nhịp để cảm nhận bước đi tiếp theo nào mới thực sự đúng đắn.';

  @override
  String get energySteady06 =>
      'Ngày hôm nay mang nguồn năng lượng chừng mực, tạo không gian để quyết định của bạn dần định hình rõ nét.';

  @override
  String get energySteady07 =>
      'Một nhịp điệu bình tâm sẽ là người dẫn đường tốt nhất; hôm nay không nhất thiết phải có những bước tiến quá vội vàng.';

  @override
  String get energyLively00 =>
      'Một làn gió tươi mới khơi dậy nguồn năng lượng hôm nay, mang đến sự tò mò và cảm hứng chuyển động.';

  @override
  String get energyLively01 =>
      'Trực giác tò mò đang đánh thức năng lượng hôm nay; một góc nhìn mới mẻ rất đáng để bạn khám phá.';

  @override
  String get energyLively02 =>
      'Ngày hôm nay tràn ngập sinh khí; hãy để ý điều thu hút bạn nhưng đừng vội lao theo trong bốc đồng.';

  @override
  String get energyLively03 =>
      'Nhịp điệu vũ trụ hôm nay thôi thúc bạn khám phá, đồng thời vẫn giữ được sự sáng suốt và tỉnh táo.';

  @override
  String get energyLively04 =>
      'Một nguồn năng lượng tươi vui đang lan tỏa; những cơ hội bất ngờ có thể xuất hiện ở nơi bạn ít ngờ tới nhất.';

  @override
  String get energyLively05 =>
      'Sự tò mò chính là chiếc la bàn hữu ích hôm nay; hãy quan sát xem nó dẫn bạn về đâu trước khi quyết định gắn bó.';

  @override
  String get energyLively06 =>
      'Các tín hiệu hôm nay đầy chuyển động; bạn hoàn toàn có thể thử nghiệm mà chưa cần vội vàng gắn bó.';

  @override
  String get energyLively07 =>
      'Nguồn năng lượng dồi dào hôm nay sẽ giúp bạn mở rộng các góc nhìn trước khi đưa ra lựa chọn sau cùng.';

  @override
  String get energyBright00 =>
      'Năng lượng hôm nay bừng sáng và tràn đầy động lực, mở ra không gian để bạn tự tin thể hiện bản thân.';

  @override
  String get energyBright01 =>
      'Năng lượng hôm nay soi rọi rõ nét hơn những điều bạn hằng ấp ủ muốn bày tỏ.';

  @override
  String get energyBright02 =>
      'Dòng chảy vũ trụ tươi sáng sẽ giúp bạn nhận ra cơ hội nào thực sự xứng đáng với tâm sức của mình.';

  @override
  String get energyBright03 =>
      'Tín hiệu hôm nay rất cởi mở và rõ ràng; bạn sẽ dễ dàng nhận ra bước đi tiếp theo của mình.';

  @override
  String get energyBright04 =>
      'Hôm nay mang đến đà thuận lợi để bày tỏ; hãy chia sẻ điều quan trọng khi cảm xúc thấy vừa vặn.';

  @override
  String get energyBright05 =>
      'Nhịp điệu thoáng đãng hôm nay sẽ mang lại sự sáng tỏ tự nhiên mà không cần phải hối hả.';

  @override
  String get energyBright06 =>
      'Năng lượng hôm nay hướng ngoại và lan tỏa; hãy đón nhận những điều bạn đã thực sự sẵn sàng bước ra ánh sáng.';

  @override
  String get energyBright07 =>
      'Một tia sáng mới có thể thay đổi toàn bộ góc nhìn; chuyển động hôm nay khích lệ bạn tự tin hướng về phía trước.';

  @override
  String get energyRadiant00 =>
      'Năng lượng hôm nay rực rỡ và thăng hoa nhất: rộng mở, bao dung và ngập tràn cảm hứng.';

  @override
  String get energyRadiant01 =>
      'Năng lượng hôm nay mở rộng tầm nhìn, giúp bạn thấy được nhiều hơn một con đường đầy hứa hẹn.';

  @override
  String get energyRadiant02 =>
      'Dòng năng lượng rạng ngời lan tỏa hôm nay; hãy đón nhận những tiềm năng mới mà không đánh mất sự vững tâm.';

  @override
  String get energyRadiant03 =>
      'Bầu trời hôm nay đặc biệt bao la và cởi mở; hãy mở rộng lòng mình cho những điều truyền cảm hứng.';

  @override
  String get energyRadiant04 =>
      'Nguồn năng lượng rực rỡ hôm nay thắp sáng mọi triển vọng, giúp bạn nhìn nhận tương lai ở một tầm vóc rộng lớn hơn.';

  @override
  String get energyRadiant05 =>
      'Tín hiệu hôm nay ngập tràn cảm hứng mở rộng; bạn sẽ dễ dàng mường tượng ra những bước tiến tốt đẹp tiếp theo.';

  @override
  String get energyRadiant06 =>
      'Hãy để nguồn năng lượng ấm áp mở rộng góc nhìn của bạn, trong khi quyền quyết định sau cùng luôn nằm trong tay bạn.';

  @override
  String get energyRadiant07 =>
      'Bầu trời hôm nay gửi gắm nguồn năng lượng hào phóng; hãy đón nhận mọi cơ hội mới bằng một tâm trí vững vàng.';

  @override
  String get energyFocused00 =>
      'Năng lượng hôm nay hội tụ về một hướng đi rõ rệt; tín hiệu hành động đang chiếm ưu thế.';

  @override
  String get energyFocused01 =>
      'Tín hiệu hành động hôm nay rất sắc nét; hãy chú tâm vào bước đi mà bạn cảm thấy có ý nghĩa nhất.';

  @override
  String get energyFocused02 =>
      'Dòng năng lượng hôm nay thôi thúc hành động, nhưng nhịp bước nhanh hay chậm hoàn toàn do bạn quyết định.';

  @override
  String get energyFocused03 =>
      'Một định hướng rõ ràng đang dẫn lối hôm nay; hãy dành trọn tâm trí cho điều bạn thực sự có thể tác động.';

  @override
  String get energyFocused04 =>
      'Khi có quá nhiều lựa chọn khiến bạn băn khoăn, tín hiệu hôm nay nhắc bạn hãy tập trung vào một bước đi thực tế nhất.';

  @override
  String get energyFocused05 =>
      'Các tín hiệu hôm nay cùng hội tụ về một mục tiêu duy nhất; hãy dành trọn sự chú ý cho nó mà không cần hấp tấp.';

  @override
  String get energyFocused06 =>
      'Động lực hành động hôm nay rất mạnh mẽ; hãy làm rõ lý do trong tim trước khi quyết định tiến bước.';

  @override
  String get energyFocused07 =>
      'Hôm nay cần sự thấu suốt và chuẩn xác hơn là sự gượng ép; hãy để con đường bạn chọn dần dần lộ diện.';

  @override
  String get energyFlowing00 =>
      'Năng lượng hôm nay uyển chuyển như dòng thủy triều; tín hiệu chuyển biến đang dần chiếm ưu thế.';

  @override
  String get energyFlowing01 =>
      'Tín hiệu chuyển biến đang đến gần; hãy giữ cho các kế hoạch của bạn sự linh hoạt cần thiết.';

  @override
  String get energyFlowing02 =>
      'Dòng năng lượng vũ trụ đang chuyển hướng; sự thích ứng linh hoạt sẽ mở ra cho bạn một con đường mới.';

  @override
  String get energyFlowing03 =>
      'Làn sóng đổi thay đang hiện diện rõ nét; hãy mở lòng đón nhận những điều mà góc nhìn mới mẻ mang lại.';

  @override
  String get energyFlowing04 =>
      'Tín hiệu hôm nay hướng về sự luân chuyển giữa các khả năng, chứ không trói buộc bạn vào một đích đến cố định.';

  @override
  String get energyFlowing05 =>
      'Khi hoàn cảnh xoay chuyển, sự linh hoạt nhạy bén sẽ giá trị hơn nhiều so với một kế hoạch cứng nhắc.';

  @override
  String get energyFlowing06 =>
      'Một dòng chảy nhẹ nhàng nâng đỡ ngày hôm nay; hãy để mọi thứ diễn tiến tự nhiên mà không cần cưỡng ép câu trả lời.';

  @override
  String get energyFlowing07 =>
      'Dòng năng lượng hôm nay đang trong giai đoạn chuyển giao; hãy thong thả thuận dòng theo nhịp độ của riêng bạn.';

  @override
  String get defaultUserName => 'Nhà thám hiểm';

  @override
  String get searchCountries => 'Tìm quốc gia';

  @override
  String get greetingMorning => 'Chào buổi sáng,';

  @override
  String get greetingAfternoon => 'Chào buổi chiều,';

  @override
  String get greetingEvening => 'Chào buổi tối,';

  @override
  String get colorRoleLead => 'Màu chính';

  @override
  String get colorRoleSupporting => 'Màu phụ';

  @override
  String colorRoleSemantics(String role, String name) {
    return '$role: $name';
  }

  @override
  String colorRoleUnavailableSemantics(String role) {
    return '$role hiện chưa có';
  }

  @override
  String readingAreaSemantics(String category) {
    return 'Lĩnh vực phân tích: $category';
  }

  @override
  String get energyInsightNewTooltip => 'Góc nhìn mới về năng lượng hôm nay';

  @override
  String get energyInsightReadTooltip => 'Xem ý nghĩa năng lượng hôm nay';

  @override
  String get energyInsightHideTooltip => 'Ẩn ý nghĩa năng lượng hôm nay';

  @override
  String get energyInsightCoachMark =>
      'Mỗi ngày, ở đây sẽ có một góc nhìn mới về năng lượng của bạn.';

  @override
  String get ritualLocked => 'Khoảnh khắc của bạn đã được ghi nhận.';

  @override
  String get periodPassedShort => 'ĐÃ QUA';

  @override
  String get errorNetworkHeadline => 'Kết nối vừa bị gián đoạn.';

  @override
  String get errorNetworkDetail => 'Hãy kiểm tra kết nối rồi thử lại.';

  @override
  String get errorServerHeadline => 'Hiện chưa thể hoàn tất phân tích kết quả.';

  @override
  String get errorServerDetail =>
      'Dịch vụ chưa thể hoàn tất. Hãy thử lại sau ít phút.';

  @override
  String get errorRejectedHeadline =>
      'Một số thông tin hồ sơ cần được kiểm tra.';

  @override
  String get errorRejectedDetail =>
      'Hãy kiểm tra lại ngày giờ sinh rồi bắt đầu lần phân tích mới.';

  @override
  String get errorInvalidHeadline =>
      'Phiên bản ứng dụng này không đọc được kết quả.';

  @override
  String get errorInvalidDetail =>
      'Cập nhật ứng dụng để khôi phục tính năng phân tích kết quả.';

  @override
  String get errorConfigurationHeadline =>
      'Bản ứng dụng này chưa được cấu hình dịch vụ phân tích.';

  @override
  String get errorConfigurationDetail =>
      'Bản dành cho nhà phát triển: chưa cấu hình dịch vụ tính toán.';

  @override
  String get errorNothingRecorded =>
      'Chưa có kết quả phân tích nào được ghi nhận cho lần này.';

  @override
  String get insufficientHeading => 'CHƯA ĐỦ THÔNG TIN';

  @override
  String get insufficientBody =>
      'Hồ sơ của bạn chưa đủ thông tin để đưa ra định hướng cho lần này. Thêm giờ sinh và quốc gia nơi sinh sẽ giúp các chu kỳ phân tích có thêm cơ sở.';

  @override
  String get periodElapsedHeading => 'THỜI ĐIỂM ĐÓ ĐÃ QUA';

  @override
  String get periodElapsedBody =>
      'Khoảng thời gian đó đã qua tại nơi bạn đang ở, nên không còn khung giờ nào để xem. Hãy chọn khoảng thời gian muộn hơn hoặc xem thời điểm hiện tại. Kết quả hôm nay không được chuyển sang ngày mai.';

  @override
  String colorsToKeepNear(String first, String second) {
    return 'Hai màu sắc may mắn bên bạn: $first và $second';
  }

  @override
  String colorToKeepNear(String name) {
    return 'Màu sắc may mắn bên bạn: $name';
  }

  @override
  String get shareTooltip => 'Chia sẻ kết quả này';

  @override
  String get shareUnavailable => 'Hiện không thể chia sẻ.';

  @override
  String get shareDisclaimer =>
      'Một góc nhìn biểu tượng để suy ngẫm hằng ngày, không phải lời tiên đoán hay xác suất.';

  @override
  String get backToHistory => 'Quay lại lịch sử';

  @override
  String get saveFailedRetry => 'Không lưu được · Thử lại';

  @override
  String get savingToHistory => 'Đang lưu vào lịch sử…';

  @override
  String get responsibleUseLink =>
      'Chính sách an toàn & sử dụng có trách nhiệm';

  @override
  String get historyToday => 'HÔM NAY';

  @override
  String get historyCouldNotOpen => 'Không thể mở lịch sử phân tích của bạn.';

  @override
  String get historyNotEnoughData => 'CHƯA ĐỦ DỮ LIỆU';

  @override
  String get historyPeriodPassed => 'ĐÃ QUA THỜI ĐIỂM';

  @override
  String get zodiacAries => 'Bạch Dương';

  @override
  String get zodiacTaurus => 'Kim Ngưu';

  @override
  String get zodiacGemini => 'Song Tử';

  @override
  String get zodiacCancer => 'Cự Giải';

  @override
  String get zodiacLeo => 'Sư Tử';

  @override
  String get zodiacVirgo => 'Xử Nữ';

  @override
  String get zodiacLibra => 'Thiên Bình';

  @override
  String get zodiacScorpio => 'Bọ Cạp';

  @override
  String get zodiacSagittarius => 'Nhân Mã';

  @override
  String get zodiacCapricorn => 'Ma Kết';

  @override
  String get zodiacAquarius => 'Bảo Bình';

  @override
  String get zodiacPisces => 'Song Ngư';

  @override
  String zodiacAvatarSemantics(String sign) {
    return 'Ảnh đại diện cung $sign';
  }

  @override
  String get profileTitle => 'Hồ sơ';

  @override
  String get openProfile => 'Mở hồ sơ của bạn';

  @override
  String get saveAction => 'Lưu';

  @override
  String get cancelAction => 'Huỷ';

  @override
  String get profileSaved => 'Đã cập nhật hồ sơ.';

  @override
  String profileBirthTimeLocked(String wait) {
    return 'Bạn có thể đổi giờ sinh sau $wait nữa.';
  }

  @override
  String profileBirthCountryLocked(String wait) {
    return 'Bạn có thể đổi quốc gia nơi sinh sau $wait nữa.';
  }

  @override
  String profileWaitHoursMinutes(String hours, String minutes) {
    return '$hours giờ $minutes phút';
  }

  @override
  String profileWaitMinutes(String minutes) {
    return '$minutes phút';
  }

  @override
  String get profileConfirmTitle => 'Lưu các thay đổi này?';

  @override
  String get profileConfirmBirthTime =>
      'Sau đó giờ sinh sẽ được giữ nguyên trong 2 giờ.';

  @override
  String get profileConfirmBirthCountry =>
      'Sau đó quốc gia nơi sinh sẽ được giữ nguyên trong 1 giờ.';

  @override
  String get profileBirthTimeUnknownValue => 'Không rõ';

  @override
  String get profileReadingsUnchanged => 'Các kết quả đã lưu vẫn giữ nguyên.';

  @override
  String profileBirthDateLocked(String wait) {
    return 'Bạn có thể đổi ngày sinh sau $wait nữa.';
  }

  @override
  String get profileConfirmBirthDate =>
      'Sau đó ngày sinh sẽ được giữ nguyên trong 4 giờ.';

  @override
  String energyCooldownTitle(String countdown) {
    return 'Năng lượng cần hồi phục ($countdown)';
  }

  @override
  String dailyQuotaExhaustedTitle(String countdown) {
    return 'Đã dùng hết 3 lượt hôm nay ($countdown)';
  }

  @override
  String get energyAccumulating => 'Năng lượng đang được tích tụ';

  @override
  String get quotaExhaustedNotice => 'Đã dùng hết lượt miễn phí hôm nay';

  @override
  String get watchAdPrompt => 'Bạn có thể xem video quảng cáo để tiếp tục';

  @override
  String get watchAdButton => 'Xem quảng cáo';

  @override
  String get adUnlockedReward =>
      'Đã xem quảng cáo & mở khóa 1 lượt phân tích ngay!';
}
