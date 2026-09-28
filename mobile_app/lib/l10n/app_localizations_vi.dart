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
  String get onboardingTitle => 'Lắng nghe tín hiệu của khoảnh khắc này.';

  @override
  String get onboardingLanguageHint =>
      'Muốn dùng ngôn ngữ khác? Nhấn biểu tượng địa cầu phía trên. Bạn có thể đổi bất cứ lúc nào.';

  @override
  String get yourProfile => 'HỒ SƠ CỦA BẠN';

  @override
  String get signAfterBirthDate =>
      'CUNG HOÀNG ĐẠO SẼ HIỆN SAU KHI BẠN CHỌN NGÀY SINH';

  @override
  String get buildPattern => 'Khám phá nhịp điệu riêng của bạn.';

  @override
  String get profileExplainer =>
      'Những thông tin này định hình các chu kỳ được dùng trong mỗi lần phân tích.';

  @override
  String get nameField => 'Tên';

  @override
  String get dateOfBirth => 'Ngày sinh';

  @override
  String get selectBirthDate => 'Chọn ngày sinh';

  @override
  String get birthDateRequired => 'Hãy chọn ngày sinh để tiếp tục.';

  @override
  String get birthTimeUnknown => 'Không rõ giờ sinh';

  @override
  String get birthTimeUnknownDetail =>
      'Chúng tôi sẽ so sánh các khả năng về khung giờ sinh.';

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
      'Trong bản thử nghiệm này, thông tin sinh của bạn được giữ riêng tư.';

  @override
  String get homeEyebrow => 'LA BÀN CHO NHỮNG LÚC PHÂN VÂN';

  @override
  String get homeTitle => 'Bạn đang phân vân giữa những lựa chọn?';

  @override
  String get areaQuestion => 'Điều bạn đang nghĩ đến thuộc lĩnh vực nào?';

  @override
  String get findDirection => 'Khám phá hướng đi';

  @override
  String get todaySignals => 'TÍN HIỆU HÔM NAY';

  @override
  String get dailyEnergy => 'Năng lượng hôm nay';

  @override
  String get yourColorsToday => 'Màu sắc của bạn hôm nay:';

  @override
  String get luckyNumberToday => 'Con số may mắn hôm nay:';

  @override
  String get categoryOverall => 'Tổng quan';

  @override
  String get categoryLove => 'Tình cảm & Mối quan hệ';

  @override
  String get categoryCareer => 'Công việc';

  @override
  String get categoryMoney => 'Chi tiêu hằng ngày';

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
  String periodHasPassed(String period) {
    return '$period đã qua. Hãy chọn thời điểm khác.';
  }

  @override
  String get reveal => 'XEM KẾT QUẢ';

  @override
  String get aligning => 'ĐANG KẾT NỐI TÍN HIỆU';

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
      'Đợi tôi một chút nhé — tôi đang làm rõ các tín hiệu vũ trụ của khoảnh khắc này.';

  @override
  String readingForCategory(String category) {
    return 'Đang phân tích về $category';
  }

  @override
  String get yourDirection => 'HƯỚNG ĐI DÀNH CHO BẠN';

  @override
  String get resultBasis =>
      'Dựa trên các chu kỳ cá nhân của bạn và khoảnh khắc này.';

  @override
  String get percentageCaveat =>
      'Tỷ lệ phần trăm thể hiện mức độ tương hợp mang tính biểu tượng, không phải xác suất ngoài đời thực.';

  @override
  String get balancedHeading => 'HAI PHÍA ĐANG CÂN BẰNG';

  @override
  String get balancedResult => 'CÂN BẰNG';

  @override
  String get balancedExplanation =>
      'Hiện chưa có phía nào nổi trội. Kết quả này thể hiện sự cân bằng, không phải một đáp án bị che giấu.';

  @override
  String get currentMoment =>
      'Kết quả này phản ánh khoảnh khắc hiện tại của bạn.';

  @override
  String get luckyTimesCaveat =>
      'Mỗi tỷ lệ phần trăm là điểm tương hợp mang tính biểu tượng của một khung giờ, không phải xác suất hay cơ hội thành công. Các khung giờ được tính riêng nên tổng không nhất thiết bằng 100%.';

  @override
  String get tryAnotherDirection => 'Khám phá hướng đi khác';

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
      'Đối chiếu xu hướng mở rộng và thu mình';

  @override
  String get loadingModeStayGo => 'Đối chiếu sự gắn bó và chuyển động';

  @override
  String get loadingModeKeepLetGo => 'Cân nhắc sự tiếp nối và buông bỏ';

  @override
  String get loadingModeForwardBackward =>
      'Đối chiếu xu hướng tiến lên và quay lại';

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
      'TRÁI / PHẢI và TIẾN / LÙI chỉ là lựa chọn mang tính biểu tượng. Không dùng chúng để tham gia giao thông, lái xe, tìm đường hoặc quyết định liên quan đến an toàn thân thể.';

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
      'Mục Chi tiêu hằng ngày chỉ để suy ngẫm về khoản chi nhỏ. Không dùng kết quả để đầu tư, vay nợ, đặt cược tiền mã hóa, cờ bạc hoặc quyết định tài chính lớn.';

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
  String get acknowledge => 'Tôi hiểu và đồng ý với các giới hạn';

  @override
  String get acknowledgementOnce =>
      'Xác nhận này chỉ xuất hiện một lần trước lần phân tích đầu tiên.';

  @override
  String get languageSetting => 'Ngôn ngữ';

  @override
  String get chooseLanguage => 'Chọn ngôn ngữ';

  @override
  String get changeLanguage => 'Đổi ngôn ngữ';

  @override
  String get choiceYes => 'CÓ';

  @override
  String get choiceNo => 'KHÔNG';

  @override
  String get choiceAct => 'HÀNH ĐỘNG';

  @override
  String get choiceWait => 'CHỜ ĐỢI';

  @override
  String get choiceAdvance => 'TIẾN TỚI';

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
  String get choiceForward => 'VỀ PHÍA TRƯỚC';

  @override
  String get choiceBackward => 'VỀ PHÍA SAU';

  @override
  String get choiceLeft => 'BÊN TRÁI';

  @override
  String get choiceRight => 'BÊN PHẢI';

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
  String get colorSage => 'Xanh xô thơm';

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
  String get colorSand => 'Cát';

  @override
  String get colorClay => 'Đất nung';

  @override
  String get colorSilver => 'Bạc';

  @override
  String get colorSteel => 'Thép';

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
      'Cảm thấy bị kéo về hai hướng? Hãy để những tín hiệu vũ trụ hôm nay gợi cho bạn một góc nhìn mới.';

  @override
  String get homeDescription02 =>
      'Các vì sao không quyết định thay bạn, nhưng những chuyển động của chúng có thể giúp bạn nhìn bước tiếp theo theo cách khác.';

  @override
  String get homeDescription03 =>
      'Khi con đường phía trước chưa rõ, hãy chậm lại và nhìn kỹ hơn. Những dấu hiệu hôm nay gợi điều gì?';

  @override
  String get homeDescription04 =>
      'Mỗi khoảnh khắc mang một nhịp năng lượng riêng. Hãy nghĩ về điều bạn băn khoăn và xem nó đang gợi bạn đi theo hướng nào.';

  @override
  String get homeDescription05 =>
      'Có lẽ vũ trụ đang nhắc bạn chậm lại. Khám phá tín hiệu hôm nay trước khi chọn hướng đi.';

  @override
  String get homeDescription06 =>
      'Đứng trước ngã rẽ? Hãy xem những chuyển động trên bầu trời hôm nay gợi mở điều gì cho câu hỏi của bạn.';

  @override
  String get homeDescription07 =>
      'Hãy lắng nghe nhịp điệu của khoảnh khắc này. Những biểu tượng hôm nay có thể gợi ra một hướng đáng cân nhắc.';

  @override
  String get homeDescription08 =>
      'Khoảnh khắc này đang cho bạn thấy điều gì? Khám phá các dấu hiệu, rồi tin vào chính mình khi lựa chọn.';

  @override
  String get homeDescription09 =>
      'Một góc nhìn từ vũ trụ có thể giúp mọi thứ sáng rõ hơn. Hãy chọn điều quan trọng hôm nay và xem tín hiệu đang hướng về đâu.';

  @override
  String get homeDescription10 =>
      'Bạn vẫn đang nghĩ đi nghĩ lại về cùng một lựa chọn? Xem năng lượng hôm nay giúp bạn chú ý đến điều gì.';

  @override
  String get homeDescription11 =>
      'Khi lý trí kéo bạn về một phía còn trực giác nghiêng về phía khác, hãy khám phá những tín hiệu của hôm nay.';

  @override
  String get homeDescription12 =>
      'Chưa biết nên tiến lên hay tạm dừng? Hãy để nhịp điệu của ngày hôm nay cho bạn một điểm bắt đầu bình tĩnh hơn.';

  @override
  String get homeDescription13 =>
      'Biết đâu sự rõ ràng bắt đầu từ một góc nhìn khác? Hãy nhìn vào những chuyển động trên bầu trời hôm nay.';

  @override
  String get homeDescription14 =>
      'Có một câu hỏi cứ trở lại trong đầu bạn. Khám phá xem những biểu tượng hôm nay mời bạn chú ý đến điều gì.';

  @override
  String get homeDescription15 =>
      'Có những lựa chọn bỗng nặng lòng hơn vào một thời điểm nhất định. Hãy cảm nhận năng lượng của khoảnh khắc này trước khi quyết định.';

  @override
  String get homeDescription16 =>
      'Lúc này con đường có thể chưa rõ. Những vì sao có thể soi sáng điều gì phía sau sự do dự ấy?';

  @override
  String get homeDescription17 =>
      'Trước khi làm theo một thôi thúc bất chợt, hãy hít thở và xem những dấu hiệu vũ trụ hôm nay gợi điều gì.';

  @override
  String get homeDescription18 =>
      'Không phải ngã rẽ nào cũng cần câu trả lời ngay. Hãy để lần phân tích hôm nay cho bạn khoảng lặng để suy ngẫm.';

  @override
  String get homeDescription19 =>
      'Bạn đang tự hỏi liệu đây có đúng thời điểm? Khám phá những tín hiệu hôm nay để tìm một góc nhìn vững vàng hơn.';

  @override
  String get homeDescription20 =>
      'Khi mọi thứ đều có thể mà chẳng điều gì chắc chắn, hãy để chuyển động của bầu trời gợi một góc nhìn mới.';

  @override
  String get homeDescription21 =>
      'Lựa chọn vẫn thuộc về bạn. Những dấu hiệu hôm nay có thể giúp bạn hiểu điều gì thực sự quan trọng.';

  @override
  String get homeDescription22 =>
      'Khi sự hoài nghi che mờ bước tiếp theo, hãy xem cung hoàng đạo và năng lượng hôm nay giúp bạn nhận ra điều gì.';

  @override
  String get homeDescription23 =>
      'Có lẽ bạn không cần một câu trả lời vang hơn, chỉ cần một khoảnh khắc yên tĩnh bên những biểu tượng của hôm nay.';

  @override
  String get homeDescription24 =>
      'Trực giác đang nhắc bạn hành động hay chờ đợi? Hãy xem nhịp điệu vũ trụ hôm nay phản chiếu điều gì.';

  @override
  String get homeDescription25 =>
      'Giữa điều bạn mong muốn và điều bạn lo sợ luôn có chỗ để dừng lại. Hãy để những dấu hiệu hôm nay giúp bạn nhìn lại.';

  @override
  String get homeDescription26 =>
      'Bạn đã nhận ra câu hỏi của mình. Giờ hãy để ý đến khoảnh khắc này. Những tín hiệu từ bầu trời gợi điều gì?';

  @override
  String get homeDescription27 =>
      'Khi một quyết định trở nên rối rắm, hãy để các biểu tượng cổ xưa và thời điểm hôm nay mở thêm một góc nhìn.';

  @override
  String get homeDescription28 =>
      'Có lẽ đây là lúc tiến gần hơn, hoặc cho mọi chuyện thêm không gian. Hãy khám phá năng lượng quanh lựa chọn của bạn.';

  @override
  String get homeDescription29 =>
      'Bạn không cần tìm sự chắc chắn ở đây. Chỉ cần một phút bình tâm, một tín hiệu vũ trụ và một hướng để cân nhắc.';

  @override
  String get energyQuiet00 =>
      'Năng lượng biểu tượng hôm nay hướng vào bên trong, mở ra khoảng lặng để suy ngẫm.';

  @override
  String get energyQuiet01 =>
      'Nhịp điệu vũ trụ hôm nay hướng vào bên trong; sự tĩnh lặng có thể làm rõ điều bị tiếng ồn che khuất.';

  @override
  String get energyQuiet02 =>
      'Bầu trời hôm nay mang sắc thái trầm lắng; hãy cho suy nghĩ của bạn thời gian lắng xuống.';

  @override
  String get energyQuiet03 =>
      'Một dòng năng lượng nhẹ và yên chạy qua ngày hôm nay, mời bạn quan sát thay vì vội vàng.';

  @override
  String get energyQuiet04 =>
      'Những dấu hiệu hôm nay gợi sự chiêm nghiệm; tạm dừng cũng có thể là một phần của việc tiến lên.';

  @override
  String get energyQuiet05 =>
      'Khi ngày trôi qua có vẻ trầm lắng, chiếc la bàn bên trong bạn có thể lên tiếng rõ hơn.';

  @override
  String get energyQuiet06 =>
      'Năng lượng hôm nay cho bạn khoảng trống để lắng nghe trước khi gọi tên câu trả lời.';

  @override
  String get energyQuiet07 =>
      'Không phải tín hiệu nào cũng đến thật rõ; hôm nay bạn có thể dễ nhận ra hơn khi chậm lại.';

  @override
  String get energySoft00 =>
      'Năng lượng biểu tượng hôm nay chuyển động dịu dàng, phù hợp với sự quan tâm và những bước nhỏ.';

  @override
  String get energySoft01 =>
      'Một dòng chảy vũ trụ nhẹ nhàng đi qua hôm nay; bước nhỏ có thể tự nhiên hơn một cú nhảy lớn.';

  @override
  String get energySoft02 =>
      'Năng lượng hôm nay dành chỗ cho sự chăm chút; hãy tiếp cận lựa chọn mà không ép mình phải chắc chắn.';

  @override
  String get energySoft03 =>
      'Nhịp điệu dịu hơn của ngày hôm nay có thể giúp bạn bắt đầu từ điều vừa sức.';

  @override
  String get energySoft04 =>
      'Sự nhẹ nhàng vẫn có sức mạnh; hãy nhận ra khi nào bạn cần thoải mái thay vì áp lực.';

  @override
  String get energySoft05 =>
      'Những dấu hiệu hôm nay gợi một bước đi nhẹ: đủ để bắt đầu, không cần thúc ép nhịp độ.';

  @override
  String get energySoft06 =>
      'Dòng chảy hôm nay khá tinh tế; những hành động đơn giản và có suy nghĩ có thể mang nhiều ý nghĩa.';

  @override
  String get energySoft07 =>
      'Ngay cả một cơ hội nhỏ cũng đáng chú ý; nhịp điệu dịu dàng hôm nay cho bạn chỗ để khám phá nó.';

  @override
  String get energySteady00 =>
      'Năng lượng biểu tượng hôm nay giữ nhịp đều và vững vàng.';

  @override
  String get energySteady01 =>
      'Năng lượng biểu tượng hôm nay đều đặn; hãy tin vào nhịp độ bạn có thể duy trì.';

  @override
  String get energySteady02 =>
      'Những chuyển động vũ trụ hôm nay tạo cảm giác vững vàng, cho bạn chỗ để suy nghĩ và hành động có chủ đích.';

  @override
  String get energySteady03 =>
      'Một dòng chảy ổn định đi qua hôm nay; chú tâm có thể hữu ích hơn vội vàng.';

  @override
  String get energySteady04 =>
      'Những dấu hiệu hôm nay hướng về sự cân bằng, nhưng không buộc bạn phải đứng yên.';

  @override
  String get energySteady05 =>
      'Sự đều đặn cũng là một sức mạnh; hãy xem bước tiếp theo nào vẫn hợp lý sau khi bạn dừng lại suy nghĩ.';

  @override
  String get energySteady06 =>
      'Ngày hôm nay mang nhịp năng lượng chừng mực, cho lựa chọn của bạn thời gian thành hình.';

  @override
  String get energySteady07 =>
      'Một nhịp điệu bình tĩnh cũng có thể dẫn đường; tiến bộ hôm nay không cần phải thật lớn.';

  @override
  String get energyLively00 =>
      'Một tia hứng khởi làm năng lượng biểu tượng hôm nay thêm sinh động, khơi dậy tò mò và chuyển động.';

  @override
  String get energyLively01 =>
      'Một tia tò mò khuấy động năng lượng biểu tượng hôm nay; một góc nhìn mới có thể đáng khám phá.';

  @override
  String get energyLively02 =>
      'Ngày hôm nay có vẻ sôi nổi hơn; hãy để ý điều thu hút bạn mà không vội lao theo.';

  @override
  String get energyLively03 =>
      'Nhịp điệu vũ trụ hôm nay mời bạn khám phá nhưng vẫn giữ sự sáng suốt.';

  @override
  String get energyLively04 =>
      'Một dòng năng lượng tươi vui đi qua hôm nay; khả năng mới có thể xuất hiện ở nơi bạn không ngờ.';

  @override
  String get energyLively05 =>
      'Sự tò mò có thể là tín hiệu hữu ích; hãy xem nó dẫn về đâu trước khi cam kết.';

  @override
  String get energyLively06 =>
      'Có sự chuyển động trong những dấu hiệu hôm nay; bạn có thể khám phá mà chưa cần quyết định vội.';

  @override
  String get energyLively07 =>
      'Năng lượng hôm nay đầy sức sống; hãy để nó mở rộng các lựa chọn trước khi thu hẹp lại.';

  @override
  String get energyBright00 =>
      'Năng lượng biểu tượng hôm nay sáng hơn, tạo đà và không gian để bạn thể hiện mình.';

  @override
  String get energyBright01 =>
      'Năng lượng biểu tượng hôm nay soi rõ hơn điều bạn muốn bày tỏ.';

  @override
  String get energyBright02 =>
      'Một dòng chảy vũ trụ tươi sáng hơn có thể giúp bạn thấy khả năng nào đáng chú ý.';

  @override
  String get energyBright03 =>
      'Những dấu hiệu hôm nay có vẻ cởi mở; bước tiếp theo có thể dễ gọi tên hơn.';

  @override
  String get energyBright04 =>
      'Hôm nay có đà để bạn bày tỏ; hãy chia sẻ điều quan trọng khi thấy đúng lúc.';

  @override
  String get energyBright05 =>
      'Một khoảng mở trong nhịp điệu hôm nay có thể giúp mọi thứ sáng rõ mà không cần vội.';

  @override
  String get energyBright06 =>
      'Năng lượng hôm nay hướng ra bên ngoài; hãy nhận ra điều bạn đã sẵn sàng đưa ra ánh sáng.';

  @override
  String get energyBright07 =>
      'Một chút tươi sáng có thể đổi góc nhìn; những chuyển động hôm nay mời bạn nhìn về phía trước.';

  @override
  String get energyRadiant00 =>
      'Năng lượng biểu tượng hôm nay rực rỡ nhất: cởi mở và rộng lớn.';

  @override
  String get energyRadiant01 =>
      'Năng lượng biểu tượng hôm nay mở rộng, mời bạn nhìn thấy nhiều hơn một con đường khả dĩ.';

  @override
  String get energyRadiant02 =>
      'Một dòng năng lượng rạng rỡ đi qua hôm nay; hãy mở lòng với khả năng mới mà vẫn giữ sự cân bằng.';

  @override
  String get energyRadiant03 =>
      'Những chuyển động vũ trụ hôm nay đặc biệt cởi mở; hãy dành chỗ cho điều truyền cảm hứng.';

  @override
  String get energyRadiant04 =>
      'Ánh sáng đầy đặn hơn nhuộm màu năng lượng hôm nay, giúp bạn nhìn các khả năng rộng hơn.';

  @override
  String get energyRadiant05 =>
      'Những dấu hiệu hôm nay mang sắc thái rộng mở; bạn có thể dễ hình dung điều tiếp theo hơn.';

  @override
  String get energyRadiant06 =>
      'Hãy để sự ấm áp của ngày hôm nay mở rộng tầm nhìn, còn quyết định cuối cùng vẫn ở trong tay bạn.';

  @override
  String get energyRadiant07 =>
      'Nhịp điệu biểu tượng của bầu trời hôm nay thật rộng lượng; hãy đón nhận khả năng mới bằng sự tỉnh táo.';

  @override
  String get energyFocused00 =>
      'Năng lượng biểu tượng hôm nay tập trung vào một hướng rõ ràng; tín hiệu hành động nổi bật hơn.';

  @override
  String get energyFocused01 =>
      'Tín hiệu hành động hôm nay rõ nét hơn; hãy chú ý đến một bước đi có chủ đích.';

  @override
  String get energyFocused02 =>
      'Dòng chảy biểu tượng hôm nay nghiêng về hành động, nhưng nhịp độ vẫn do bạn chọn.';

  @override
  String get energyFocused03 =>
      'Một cảm giác định hướng chạy xuyên suốt ngày hôm nay; hãy chú ý đến điều bạn thực sự có thể tác động.';

  @override
  String get energyFocused04 =>
      'Khi nhiều lựa chọn cùng xuất hiện, những dấu hiệu hôm nay mời bạn tập trung vào một bước thực tế.';

  @override
  String get energyFocused05 =>
      'Những dấu hiệu hôm nay hội tụ quanh một ý định; hãy dành sự chú ý cho nó mà không vội vàng.';

  @override
  String get energyFocused06 =>
      'Hành động có sức hút biểu tượng mạnh hơn hôm nay; hãy hiểu rõ lý do trước khi tiến bước.';

  @override
  String get energyFocused07 =>
      'Đây là ngày để có chủ đích, không phải để gắng sức quá mức; hãy để hướng bạn chọn dần thành hình.';

  @override
  String get energyFlowing00 =>
      'Năng lượng biểu tượng hôm nay chuyển động như thủy triều; tín hiệu thay đổi nổi bật hơn.';

  @override
  String get energyFlowing01 =>
      'Tín hiệu thay đổi hôm nay rõ hơn; hãy để kế hoạch của bạn có một chút linh hoạt.';

  @override
  String get energyFlowing02 =>
      'Một dòng chảy vũ trụ đang đổi hướng trong ngày; sự thích nghi có thể hé lộ con đường khác.';

  @override
  String get energyFlowing03 =>
      'Năng lượng của sự thay đổi dễ nhận ra hơn; hãy cởi mở với điều một góc nhìn mới cho thấy.';

  @override
  String get energyFlowing04 =>
      'Những dấu hiệu hôm nay nói về việc di chuyển giữa các khả năng, không phải một đích đến cố định.';

  @override
  String get energyFlowing05 =>
      'Khi hoàn cảnh thay đổi, phản ứng linh hoạt có thể hữu ích hơn một kế hoạch cứng nhắc.';

  @override
  String get energyFlowing06 =>
      'Một nhịp chảy êm đi qua hôm nay; hãy xem điều gì có thể chuyển biến mà không ép mình phải có câu trả lời.';

  @override
  String get energyFlowing07 =>
      'Dòng chảy biểu tượng hôm nay nghiêng về chuyển tiếp; bạn vẫn có thể đi theo nhịp của riêng mình.';

  @override
  String get defaultUserName => 'Người khám phá';

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
    return 'Lĩnh vực xem chỉ dẫn: $category';
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
  String get errorServerHeadline => 'Hiện chưa thể hoàn tất lần xem chỉ dẫn.';

  @override
  String get errorServerDetail =>
      'Dịch vụ chưa thể hoàn tất. Hãy thử lại sau ít phút.';

  @override
  String get errorRejectedHeadline =>
      'Một số thông tin hồ sơ cần được kiểm tra.';

  @override
  String get errorRejectedDetail =>
      'Hãy kiểm tra lại thông tin sinh rồi bắt đầu lần xem mới.';

  @override
  String get errorInvalidHeadline =>
      'Phiên bản ứng dụng này không đọc được kết quả.';

  @override
  String get errorInvalidDetail =>
      'Cập nhật ứng dụng có thể giúp xem chỉ dẫn trở lại.';

  @override
  String get errorConfigurationHeadline =>
      'Bản ứng dụng này chưa được cấu hình dịch vụ xem chỉ dẫn.';

  @override
  String get errorConfigurationDetail =>
      'Bản dành cho nhà phát triển: chưa cấu hình dịch vụ tính toán.';

  @override
  String get errorNothingRecorded =>
      'Lần thử này chưa được lưu thành một lần xem chỉ dẫn.';

  @override
  String get insufficientHeading => 'CHƯA ĐỦ THÔNG TIN';

  @override
  String get insufficientBody =>
      'Hồ sơ của bạn chưa đủ thông tin để đưa ra một hướng cho lần này. Thêm giờ sinh và quốc gia sinh sẽ giúp phân tích chu kỳ có thêm cơ sở.';

  @override
  String get periodElapsedHeading => 'THỜI ĐIỂM ĐÓ ĐÃ QUA';

  @override
  String get periodElapsedBody =>
      'Khoảng thời gian đó đã qua tại nơi bạn đang ở, nên không còn khung giờ nào để xem. Hãy chọn khoảng thời gian muộn hơn hoặc xem thời điểm hiện tại. Kết quả hôm nay không được chuyển sang ngày mai.';

  @override
  String colorsToKeepNear(String first, String second) {
    return 'Hai màu nên ở gần bạn: $first và $second';
  }

  @override
  String colorToKeepNear(String name) {
    return 'Màu nên ở gần bạn: $name';
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
  String get responsibleUseLink => 'Sử dụng có trách nhiệm & An toàn';

  @override
  String get historyToday => 'HÔM NAY';

  @override
  String get historyCouldNotOpen => 'Không thể mở các lần xem chỉ dẫn của bạn.';

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
}
