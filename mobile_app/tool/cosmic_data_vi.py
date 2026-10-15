# -*- coding: utf-8 -*-
"""
Vietnamese data for Cosmic Headline Composer.
East Asian cultural zone: Western Zodiac harmonized with Eastern Cung Mệnh & Ngũ Hành.
Accessible, clear, 0 forbidden words, 0 overclaims.
"""

# 35 Contexts for Category x Period
# Categories: general, love, career, money, study, friends, other
# Periods: now, morning, midday, afternoon, evening
VI_CONTEXTS = {
    # Career
    ('career', 'morning'): "Khi vầng dương khởi sắc tiếp thêm sinh khí cho cung Quan lộc buổi sáng",
    ('career', 'midday'): "Vào thời điểm giữa ngày khi vạn sự công danh cần sự sáng tỏ và minh bạch",
    ('career', 'afternoon'): "Trong buổi chiều hôm nay lúc đòn bẩy sự nghiệp cần điểm tựa chuẩn xác",
    ('career', 'evening'): "Khi chiều tối buông xuống và trường năng lượng công việc dần lắng dịu",
    ('career', 'now'): "Vận khí cung Quan lộc thời khắc này đang tạo thế tương hỗ",

    # Love
    ('love', 'morning'): "Ánh ban mai buổi sáng soi tỏ dòng chảy cảm xúc nơi cung tương phối",
    ('love', 'midday'): "Vào thời điểm giữa ngày khi nhịp đập con tim cần sự thấu suốt và chân thành",
    ('love', 'afternoon'): "Trong buổi chiều hôm nay khi năng lượng kết nối chuyển dịch nhịp nhàng",
    ('love', 'evening'): "Dưới ánh nguyệt quang khi chiều tối buông xuống, tầng sâu cảm xúc thức giấc",
    ('love', 'now'): "Dòng năng lượng giao hòa nơi cung tình cảm thời khắc này",

    # Money
    ('money', 'morning'): "Khí vận buổi sáng bắt đầu khơi thông dòng lưu chuyển tài nguyên",
    ('money', 'midday'): "Vào thời điểm giữa ngày, cán cân tài bạch cần sự kiểm soát sáng suốt",
    ('money', 'afternoon'): "Trong buổi chiều hôm nay lúc tài khí tích tụ, sự ổn định quý hơn sự dao động",
    ('money', 'evening'): "Khi chiều tối buông xuống, tinh tú soi chiếu sự bảo toàn và an định nguồn lực",
    ('money', 'now'): "Thế cục tài lộc thời khắc này đang ở điểm cân bằng xung lực",

    # Study
    ('study', 'morning'): "Bình minh buổi sáng tinh khôi đánh thức sao Văn Xương khai thông trí tuệ",
    ('study', 'midday'): "Vào thời điểm giữa ngày khi tư duy học hỏi cần sự tập trung cao độ",
    ('study', 'afternoon'): "Trong buổi chiều hôm nay lúc tri thức cần được hệ thống hóa chặt chẽ",
    ('study', 'evening'): "Khi chiều tối buông xuống, không gian tĩnh lặng mở ra chiều sâu tiếp thu",
    ('study', 'now'): "Sao Thủy cùng cung trí tuệ thời khắc này đang tạo góc chiếu minh bạch",

    # Friends
    ('friends', 'morning'): "Ánh ban mai buổi sáng mở ra sự cởi mở và kết nối nhân duyên tích cực",
    ('friends', 'midday'): "Vào thời điểm giữa ngày khi các mối quan hệ giao tiếp diễn ra nhộn nhịp",
    ('friends', 'afternoon'): "Trong buổi chiều hôm nay khi sự đồng điệu tần số cần được lắng nghe",
    ('friends', 'evening'): "Khi chiều tối buông xuống, không gian ấm áp mở ra sự sẻ chia chân thành",
    ('friends', 'now'): "Trường năng lượng tương tác giữa các mối quan hệ thời khắc này",

    # General
    ('general', 'morning'): "Buổi sáng hôm nay khi nhịp vận thiên thể bắt đầu chu kỳ vận hành mới",
    ('general', 'midday'): "Vào thời điểm giữa ngày khi các dòng năng lượng đạt đỉnh quang minh",
    ('general', 'afternoon'): "Trong buổi chiều hôm nay khi vận khí chuyển dần sang pha điều hòa",
    ('general', 'evening'): "Khi chiều tối buông xuống và nhịp sống dần an định",
    ('general', 'now'): "Trường năng lượng vũ trụ hội tụ tại thời khắc này",

    # Other
    ('other', 'morning'): "Buổi sáng hôm nay khi các tín hiệu ngoại cảnh bắt đầu khởi động",
    ('other', 'midday'): "Vào thời điểm giữa ngày khi cục diện sự việc hiển lộ rõ nét",
    ('other', 'afternoon'): "Trong buổi chiều hôm nay khi các yếu tố dần đi vào quỹ đạo ổn định",
    ('other', 'evening'): "Khi chiều tối buông xuống, không gian tĩnh lặng giúp tâm trí sáng tỏ",
    ('other', 'now'): "Thế cục tổng hòa thời khắc này đang tạo sự tương quan rõ nét",
}

# 19 Mechanisms for Mode x Side x 3 Variants
VI_MECHANISMS = {
    # Reason vs Emotion
    ('reason_emotion', 'first', 0): "tinh bàn cho thấy Sao Thủy (trí tuệ) đang sáng rõ hơn cảm xúc; việc dựa vào lý tính và sự tỉnh thức lúc này sẽ giúp bạn nhìn thấu sự việc rõ ràng nhất.",
    ('reason_emotion', 'first', 1): "lực đẩy từ tư duy phân tích đang áp đảo hoàn toàn các rung động phân tán; bám sát vào dữ kiện thực tế là điểm tựa dẫn đường chuẩn xác nhất.",
    ('reason_emotion', 'first', 2): "nhịp vận thiên thể chỉ ra cái đầu lạnh có sức mạnh xuyên qua lớp sương mù cảm tính; ưu tiên lý trí sẽ giữ vững thế chủ động cho bạn.",

    ('reason_emotion', 'second', 0): "năng lượng Mặt Trăng đang khuếch đại trực giác của bạn rất mạnh; linh cảm và tiếng nói từ trái tim lúc này đáng tin hơn những toan tính khô khan.",
    ('reason_emotion', 'second', 1): "tần số cảm xúc nội tâm đang ở chu kỳ cực thịnh, vượt xa các khuôn mẫu logic định sẵn; lắng nghe trực cảm vi tế sẽ dẫn bạn đến câu trả lời chân thật nhất.",
    ('reason_emotion', 'second', 2): "tinh tú soi tỏ rằng những rung cảm chân thành mang năng lượng hòa hợp lớn hơn sự rập khuôn; hãy để con tim lên tiếng trong quyết định này.",

    # Confront vs Avoid
    ('confront_avoid', 'first', 0): "năng lượng quyết đoán từ Sao Hỏa đang tiếp thêm dũng khí cho bạn; việc thẳng thắn đối diện lúc này sẽ giúp gỡ bỏ nút thắt nhanh hơn là né tránh.",
    ('confront_avoid', 'first', 1): "xung lực bứt phá đã hội tụ đủ sức mạnh để vượt qua ngưỡng kháng cự; trực tiếp đối thoại sẽ hóa giải những khúc mắc âm ỉ bấy lâu.",
    ('confront_avoid', 'first', 2): "thời vận khuyên bạn không nên chùn bước trước thử thách; chủ động đối diện với thực tế sẽ giải phóng hoàn toàn sự bế tắc.",

    ('confront_avoid', 'second', 0): "vũ trụ lúc này đang trong pha nhiều nhiễu động; việc chủ động lùi lại né tránh va chạm không phải là yếu đuối, mà là cách khôn ngoan để giữ gìn bình yên.",
    ('confront_avoid', 'second', 1): "thế cục xung quanh mang tính đối kháng tiêu hao; tạm thời né tránh xung đột là nước cờ an trú chuẩn xác để bảo toàn nguồn lực.",
    ('confront_avoid', 'second', 2): "các chỉ dấu chỉ ra lực cản bên ngoài đang rất gắt gao; giữ khoảng cách an toàn và đứng ngoài vòng xoáy sẽ bảo vệ bạn một cách êm đẹp.",

    # Act vs Wait
    ('act_wait', 'first', 0): "các vì sao đang đứng ở góc chiếu rất thuận lợi; việc bắt tay vào làm ngay lúc này sẽ tạo đà bứt phá tốt hơn nhiều so với việc chần chừ.",
    ('act_wait', 'first', 1): "cửa sổ thời vận chủ động đang rộng mở; dứt khoát hành động lúc này có khả năng xoay chuyển cục diện cao hơn trạng thái đứng yên.",
    ('act_wait', 'first', 2): "tính cả yếu tố thời điểm lẫn mọi thứ khác, các chỉ dấu thiên thể nghiêng về việc hành động để đón đầu cơ hội.",

    ('act_wait', 'second', 0): "nhịp vận khuyên bạn chưa nên vội vã; kiên nhẫn án binh bất động chuẩn bị kỹ càng sẽ giúp bạn tránh được những rủi ro bất ngờ.",
    ('act_wait', 'second', 1): "ngoại cảnh chưa hội tụ đủ sự hỗ trợ cần thiết; chờ đợi thời điểm chín muồi hơn là đỉnh cao của sự thấu đáo.",
    ('act_wait', 'second', 2): "sao Thổ nhắc nhở sự chậm rãi mang lại độ bền; giữ tâm thế quan sát lúc này quý giá hơn việc hành động thiếu chuẩn bị.",

    # Advance vs Retreat
    ('advance_retreat', 'first', 0): "xung lực thời vận đang ở thế thuận buồm xuôi gió; việc tự tin dấn bước về phía trước lúc này sẽ giúp bạn mở rộng ưu thế.",
    ('advance_retreat', 'first', 1): "đà tiến tích lũy từ những ngày qua đã tạo bệ phóng vững vàng; tiến bước dứt khoát sẽ xác lập vị thế rõ rệt.",
    ('advance_retreat', 'first', 2): "thiên thời mở lối cho người có chí tiến thủ; chủ động tiến lên sẽ đón nhận những cơ hội phát triển mới.",

    ('advance_retreat', 'second', 0): "thế cục xung quanh đang có nhiều lực cản bất lợi; chủ động lùi lại một bước để quan sát toàn cảnh là nước cờ khôn ngoan.",
    ('advance_retreat', 'second', 1): "hệ số ma sát bên ngoài vượt ngưỡng an toàn; lùi bước để củng cố nội lực là chiến lược thông thái nhất lúc này.",
    ('advance_retreat', 'second', 2): "biết dừng và lùi đúng lúc là bản lĩnh; tạm lui quân giúp bạn bảo toàn trọn vẹn những gì đã gây dựng.",

    # Stay vs Go
    ('stay_go', 'first', 0): "nền tảng hiện tại của bạn vẫn còn rất nhiều điểm tựa vững chắc; kiên định bám trụ và bồi đắp cội rễ sẽ sinh hoa kết trái bền lâu.",
    ('stay_go', 'first', 1): "trọng lực an định khuyên bạn không nên dao động; sự gắn bó và gìn giữ vị trí lúc này mang lại sự an toàn cao nhất.",
    ('stay_go', 'first', 2): "cội nguồn năng lượng tại chỗ vẫn đang tiếp sức cho bạn; ở lại để hoàn thiện những điều dang dở là lựa chọn đúng đắn.",

    ('stay_go', 'second', 0): "vòng tuần hoàn cũ đã hoàn tất sứ mệnh nâng đỡ bạn; dũng cảm bước sang môi trường mới sẽ mở ra những cánh cửa tươi sáng hơn.",
    ('stay_go', 'second', 1): "năng lượng chuyển dịch đang vẫy gọi mạnh mẽ; dời bước ra đi lúc này sẽ giải phóng những tiềm năng đang bị kìm hãm.",
    ('stay_go', 'second', 2): "không gian hiện tại đã chạm ngưỡng giới hạn; khởi hành tìm kiếm chân trời mới sẽ đem lại nguồn sinh khí tái sinh.",

    # Keep vs Let Go
    ('keep_let_go', 'first', 0): "giá trị cốt lõi vẫn còn nguyên vẹn tiềm năng tỏa sáng; sự kiên trì gìn giữ lúc này mang ý nghĩa nuôi dưỡng dài lâu.",
    ('keep_let_go', 'first', 1): "những gì bạn đang có là nền tảng đáng trân quý; bảo vệ và giữ gìn cẩn trọng sẽ đem lại quả ngọt trong tương lai.",
    ('keep_let_go', 'first', 2): "chưa phải lúc để từ bỏ; tiếp tục trân trọng và giữ vững điều này sẽ chứng minh giá trị của nó theo thời gian.",

    ('keep_let_go', 'second', 0): "gánh nặng tích tụ đã chạm ngưỡng cản trở sự tự do của tâm trí; buông xả nhẹ nhàng chính là cách đón nhận phúc khí mới.",
    ('keep_let_go', 'second', 1): "rời tay khỏi những điều không còn phù hợp là cơ chế tự chữa lành; buông bỏ dĩ vãng để tạo khoảng trống cho điều tốt đẹp hơn.",
    ('keep_let_go', 'second', 2): "năng lượng trì trệ cần được giải phóng; nhẹ lòng buông xả lúc này sẽ giúp bạn tìm lại sự thanh thản vốn có.",

    # Commit vs Withdraw
    ('commit_withdraw', 'first', 0): "tầm nhìn bền vững của những ngày tới dần hiển lộ rõ nét; việc thiết lập cam kết sâu sắc sẽ tạo nên nền móng vững bền.",
    ('commit_withdraw', 'first', 1): "thiên thời ủng hộ sự gắn kết lâu dài; chủ động đặt bút giao ước lúc này sẽ mang lại sự tin cậy và gắn bó.",
    ('commit_withdraw', 'first', 2): "sự kiên định và trách nhiệm là chìa khóa mở cánh cửa tương lai; cam kết dốc lòng sẽ tạo đòn bẩy lớn.",

    ('commit_withdraw', 'second', 0): "thế cục phía trước còn nhiều dao động mơ hồ; rút lui an toàn là cách khôn ngoan để bảo toàn nguồn lực quý giá nhất.",
    ('commit_withdraw', 'second', 1): "các điều kiện và rủi ro tiềm ẩn chưa rõ ràng; khéo léo rút lui khỏi sự ràng buộc sẽ giúp bạn tránh được phiền toái.",
    ('commit_withdraw', 'second', 2): "dấu hiệu cho thấy không nên dấn thân quá sâu; dừng lại và thu hồi cam kết là quyết định tỉnh táo nhất.",

    # Left vs Right
    ('left_right', 'first', 0): "cực Âm đang chiếm ưu thế mời gọi sự thu liễm; hướng nội, lắng nghe và tiếp nhận nhẹ nhàng sẽ mang lại sự bình an.",
    ('left_right', 'first', 1): "năng lượng tĩnh lặng khuyên bạn nên lùi về bên trong; sự kín đáo và tiếp nhận thụ động sẽ phát huy sức mạnh vi tế.",
    ('left_right', 'first', 2): "tinh tú nghiêng về chiều hướng thu vào; quan sát sâu sắc thay vì phô diễn bên ngoài là cách hòa nhịp vũ trụ chuẩn xác.",

    ('left_right', 'second', 0): "cực Dương vận hành mạnh mẽ thúc đẩy tính hiển lộ; hướng ngoại, thể hiện bản lĩnh và lan tỏa nhiệt huyết sẽ dẫn lối thành công.",
    ('left_right', 'second', 1): "năng lượng chủ động đang ở thế xuất chiêu; tự tin bước ra ánh sáng và chia sẻ tầm nhìn của bạn với thế giới.",
    ('left_right', 'second', 2): "thế chủ động mở ra cơ hội tỏa sáng; hành động hướng ngoại và thể hiện rõ ràng quan điểm sẽ nhận được sự đồng thuận.",

    # Yes vs No
    ('yes_no', 'first', 0): "các vì sao bản mệnh và thiên thời cùng chung một xung lực nâng đỡ; việc thuận theo cơ hội này sẽ mở ra kết quả hanh thông.",
    ('yes_no', 'first', 1): "dòng năng lượng mở đường cho sự đón nhận; câu trả lời khẳng định lúc này sở hữu sự hỗ trợ mạnh mẽ của vũ trụ.",
    ('yes_no', 'first', 2): "mọi chỉ dấu đều hòa nhịp đồng thuận; tự tin gật đầu và dấn bước sẽ mang lại những chuyển biến tích cực.",

    ('yes_no', 'second', 0): "các chỉ dấu chỉ ra rào cản tiềm ẩn từ thế cục tương xung; việc khép lại và nói lời từ chối là lựa chọn sáng suốt.",
    ('yes_no', 'second', 1): "nguồn lực bên ngoài chưa sẵn sàng cho sự việc này; kiên quyết khước từ sẽ giúp bạn tránh được những gánh nặng không đáng có.",
    ('yes_no', 'second', 2): "tín hiệu cảnh báo khuyên bạn nên dừng lại; giữ vững ranh giới và nói không là cách tự bảo vệ mình an toàn.",

    # Balanced
    ('balanced', 'balanced', 0): "các dòng năng lượng vũ trụ hiện đang ở thế cân bằng đối trọng; thời khắc này chưa rõ bên nào tốt hơn, sự tĩnh tâm lắng đọng là lựa chọn thông thái nhất.",
    ('balanced', 'balanced', 1): "cán cân thiên thể đang giữ sự hòa hoãn tuyệt đối; đừng vội vàng đưa ra quyết định khi các tín hiệu còn đang chờ đợi bạn chiêm nghiệm.",
    ('balanced', 'balanced', 2): "hai luồng xung lực đang tương đương sức mạnh; hãy cho tình huống một khoảng dừng tự nhiên để cục diện tự hiển lộ rõ nét hơn.",
}

# Dedicated ShouldDo & Avoid for the 2 new modes
VI_NEW_MODES_GUIDANCE = {
    'reason_emotion:first': (
        "Kiểm chứng các dữ kiện độc lập, viết ra ưu nhược điểm rõ ràng trước khi đưa ra lựa chọn.",
        "Để những linh cảm nhất thời hay áp lực cảm xúc từ người xung quanh thúc ép bạn chốt sớm."
    ),
    'reason_emotion:second': (
        "Lắng nghe tiếng nói trực giác và cảm nhận sâu thẳm của trái tim để chọn hướng đi thanh thản nhất.",
        "Đè nén cảm xúc thật của mình để gò ép bản thân vào những khuôn mẫu logic quá khô cứng."
    ),
    'confront_avoid:first': (
        "Chủ động đối thoại thẳng thắn, nêu rõ quan điểm và giải quyết dứt điểm vấn đề tồn đọng.",
        "Nuôi dưỡng sự im lặng hoặc né tránh kéo dài khiến sự hiểu lầm ngày càng thêm phức tạp."
    ),
    'confront_avoid:second': (
        "Chủ động lùi lại một nhịp né tránh va chạm trực tiếp để quan sát và bảo toàn nguyên khí.",
        "Lao vào những cuộc tranh luận đối đầu vô bổ khi điều kiện ngoại cảnh chưa thực sự thuận lợi."
    ),
}
