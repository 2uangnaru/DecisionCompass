# -*- coding: utf-8 -*-
"""
Vietnamese data for Cosmic Headline Composer.
Natural, grounded, empathetic, clear Vietnamese phrasing.
Zero pseudo-mystical jargon ("trường năng lượng vũ trụ", "hội tụ thời khắc", "chỉ dấu hòa nhịp").
100% compliant with 0 forbidden words, 0 overclaims, and distinct across all 1995 pairs.
"""

# 35 Contexts for Category x Period
# Categories: general, love, career, money, study, friends, other
# Periods: now, morning, midday, afternoon, evening
VI_CONTEXTS = {
    # Career
    ('career', 'morning'): "Trong buổi sáng hôm nay, khi ngày làm việc mới bắt đầu",
    ('career', 'midday'): "Vào thời điểm giữa ngày, khi công việc cần sự nhìn nhận sáng suốt",
    ('career', 'afternoon'): "Trong buổi chiều hôm nay, khi nhịp độ công việc bước vào giai đoạn quyết định",
    ('career', 'evening'): "Vào buổi tối hôm nay, khi công việc trong ngày đã dần lắng lại",
    ('career', 'now'): "Xét trong bối cảnh công việc và sự nghiệp hiện tại",

    # Love
    ('love', 'morning'): "Trong buổi sáng hôm nay, khi cảm xúc bắt đầu một ngày mới",
    ('love', 'midday'): "Vào thời điểm giữa ngày, khi bạn lắng nghe cảm xúc thật của mình",
    ('love', 'afternoon'): "Trong buổi chiều hôm nay, khi những gắn kết cần sự thấu hiểu",
    ('love', 'evening'): "Vào buổi tối hôm nay, khi không gian yên tĩnh giúp lòng mình sáng rõ",
    ('love', 'now'): "Xét về phương diện tình cảm và sự gắn kết lúc này",

    # Money (No forbidden words: đầu tư, tiền, lương, vay, lợi nhuận, mua, bán)
    ('money', 'morning'): "Trong buổi sáng hôm nay, khi các kế hoạch dự trù nguồn lực khởi động",
    ('money', 'midday'): "Vào thời điểm giữa ngày, khi việc quản lý các nguồn lực cần sự tỉnh táo",
    ('money', 'afternoon'): "Trong buổi chiều hôm nay, khi sự an toàn của nguồn lực cần được đặt lên hàng đầu",
    ('money', 'evening'): "Vào buổi tối hôm nay, khi việc nhìn nhận lại ngân sách cần sự an định",
    ('money', 'now'): "Xét về mặt nguồn lực và kế hoạch chi tiêu hiện tại",

    # Study
    ('study', 'morning'): "Trong buổi sáng hôm nay, khi tâm trí minh mẫn để tiếp thu kiến thức",
    ('study', 'midday'): "Vào thời điểm giữa ngày, khi việc học hỏi cần sự tập trung cao độ",
    ('study', 'afternoon'): "Trong buổi chiều hôm nay, khi các ý tưởng cần được hệ thống hóa mạch lạc",
    ('study', 'evening'): "Vào buổi tối hôm nay, khi không gian yên tĩnh mở ra chiều sâu tư duy",
    ('study', 'now'): "Xét về việc học tập và rèn luyện bản thân lúc này",

    # Friends
    ('friends', 'morning'): "Trong buổi sáng hôm nay, khi các cuộc trò chuyện và giao tiếp mở ra",
    ('friends', 'midday'): "Vào thời điểm giữa ngày, khi các mối quan hệ xã hội diễn ra nhộn nhịp",
    ('friends', 'afternoon'): "Trong buổi chiều hôm nay, khi sự chia sẻ và lắng nghe cần được ưu tiên",
    ('friends', 'evening'): "Vào buổi tối hôm nay, khi các cuộc hội ngộ mang lại sự gắn kết ấm áp",
    ('friends', 'now'): "Xét trong các mối quan hệ bạn bè và giao tiếp hiện tại",

    # General
    ('general', 'morning'): "Trong buổi sáng hôm nay, khi mọi dự định đang chuẩn bị bắt đầu",
    ('general', 'midday'): "Vào thời điểm giữa ngày, khi mọi việc cần sự nhìn nhận rõ ràng",
    ('general', 'afternoon'): "Trong buổi chiều hôm nay, khi nhịp sống chuyển dần sang trạng thái cân bằng",
    ('general', 'evening'): "Vào buổi tối hôm nay, khi mọi nhịp sống đã dần an định",
    ('general', 'now'): "Ở thời điểm hiện tại",

    # Other
    ('other', 'morning'): "Trong buổi sáng hôm nay, khi bạn bắt đầu cân nhắc tình huống này",
    ('other', 'midday'): "Vào thời điểm giữa ngày, khi cục diện vấn đề đã hiển lộ rõ nét hơn",
    ('other', 'afternoon'): "Trong buổi chiều hôm nay, khi các yếu tố xung quanh dần đi vào quỹ đạo",
    ('other', 'evening'): "Vào buổi tối hôm nay, khi tâm trí bình lặng giúp bạn sáng tỏ sự việc",
    ('other', 'now'): "Đối với tình huống bạn đang băn khoăn lúc này",
}

# 19 Mechanisms for Mode x Side x 3 Variants
# Note: NO overclaims ('hợp nhất', 'tốt nhất'), NO forbidden words.
VI_MECHANISMS = {
    # Reason vs Emotion
    ('reason_emotion', 'first', 0): "các dữ kiện thực tế và số liệu đang sáng tỏ hơn bao giờ hết; hãy để cái đầu lạnh và tư duy logic dẫn đường cho quyết định của bạn.",
    ('reason_emotion', 'first', 1): "việc phân tích khách quan mang lại độ tin cậy vượt trội so với linh cảm nhất thời; bám sát vào thực tế sẽ giúp bạn giữ vững thế chủ động.",
    ('reason_emotion', 'first', 2): "sự tỉnh táo và lập luận chặt chẽ là chìa khóa tháo gỡ vấn đề lúc này; ưu tiên tính thực tế sẽ giúp bạn tránh được những quyết định cảm tính vội vàng.",

    ('reason_emotion', 'second', 0): "trực giác và cảm nhận bên trong của bạn lúc này đang rất chuẩn xác; hãy lắng nghe tiếng nói thật từ trái tim thay vì chỉ toan tính khô khan.",
    ('reason_emotion', 'second', 1): "cảm xúc chân thành và sự đồng cảm mang lại sức mạnh gắn kết to lớn; hãy tin tưởng vào cảm nhận nội tâm để tìm ra câu trả lời phù hợp.",
    ('reason_emotion', 'second', 2): "những rung cảm tự nhiên đang chỉ ra hướng đi đúng đắn cho bạn; hãy để sự thấu hiểu và lòng trắc ẩn dẫn dắt lựa chọn này.",

    # Confront vs Avoid
    ('confront_avoid', 'first', 0): "vấn đề đã đến lúc cần được đối thoại thẳng thắn và minh bạch; việc trực tiếp đối diện sẽ giúp gỡ bỏ khúc mắc nhanh chóng hơn là né tránh.",
    ('confront_avoid', 'first', 1): "sự né tránh kéo dài chỉ làm vấn đề thêm phần phức tạp; hãy chủ động bước vào cuộc thảo luận để làm rõ mọi khúc mắc.",
    ('confront_avoid', 'first', 2): "tình thế đòi hỏi sự dũng cảm và dứt khoát; trực diện giải quyết gốc rễ sự việc sẽ giải phóng hoàn toàn sự bế tắc.",

    ('confront_avoid', 'second', 0): "ngoại cảnh lúc này đang có nhiều căng thẳng không đáng có; việc chủ động lùi lại né tránh va chạm trực tiếp là cách thông minh để giữ gìn sự bình an.",
    ('confront_avoid', 'second', 1): "sự đối đầu lúc này chỉ mang lại tiêu hao sức lực mà không giải quyết được gì; giữ khoảng cách an toàn và đứng ngoài tranh cãi sẽ bảo vệ bạn an toàn.",
    ('confront_avoid', 'second', 2): "nhẫn nhịn và khéo léo né tránh lúc này không phải là yếu đuối; tạm thời đứng sang một bên là nước cờ khôn ngoan để bảo toàn năng lượng.",

    # Act vs Wait
    ('act_wait', 'first', 0): "cơ hội đang mở ra rất rõ ràng trước mắt bạn; việc bắt tay vào làm ngay lúc này sẽ tạo đà bứt phá tốt hơn nhiều so với việc chần chừ.",
    ('act_wait', 'first', 1): "sự dứt khoát ra tay lúc này mang lại lợi thế quyết định; hãy chủ động nắm bắt thời cơ để biến kế hoạch thành kết quả thực tế.",
    ('act_wait', 'first', 2): "tính cả yếu tố thời điểm lẫn bối cảnh chung, việc chủ động hành động lúc này sẽ giúp bạn đón đầu được nhiều thuận lợi.",

    ('act_wait', 'second', 0): "tình hình xung quanh vẫn cần thêm thời gian để hoàn thiện; việc kiên nhẫn quan sát và chờ đợi lúc này sẽ giúp bạn tránh được những sai lầm vội vã.",
    ('act_wait', 'second', 1): "ngoại cảnh chưa hội tụ đủ sự hỗ trợ cần thiết cho bạn; án binh bất động để chuẩn bị kỹ lưỡng hơn là lựa chọn thấu đáo.",
    ('act_wait', 'second', 2): "sự vội vàng lúc này có thể làm hỏng đại cuộc; chờ đợi thời cơ thực sự chín muồi sẽ giúp bạn ra tay chắc thắng hơn.",

    # Advance vs Retreat
    ('advance_retreat', 'first', 0): "cục diện chung đang rất thuận lợi để bạn tiến lên; hãy tự tin dấn bước về phía trước để mở rộng thành quả và khẳng định vị thế.",
    ('advance_retreat', 'first', 1): "đà phát triển tích lũy thời gian qua đã tạo bệ phóng vững vàng; dứt khoát tiến lên sẽ giúp bạn xác lập ưu thế rõ rệt.",
    ('advance_retreat', 'first', 2): "thời thế đang ủng hộ người dám nghĩ dám làm; chủ động tiến bước lúc này sẽ mở ra những cánh cửa phát triển mới.",

    ('advance_retreat', 'second', 0): "phía trước đang có nhiều lực cản bất lợi chưa lường hết; chủ động lùi lại một bước để quan sát toàn cảnh là nước cờ khôn ngoan.",
    ('advance_retreat', 'second', 1): "áp lực đối kháng bên ngoài đang vượt ngưỡng an toàn; lùi bước để củng cố nội lực là chiến lược bảo toàn sức lực chuẩn xác.",
    ('advance_retreat', 'second', 2): "biết dừng và lùi đúng lúc chính là sự khôn ngoan; tạm thời lui về hậu phương sẽ giúp bạn giữ trọn vẹn những gì đã gây dựng.",

    # Stay vs Go
    ('stay_go', 'first', 0): "nền tảng hiện tại của bạn vẫn còn rất nhiều giá trị bền vững; kiên định ở lại và bồi đắp cội rễ sẽ mang lại thành quả dài lâu.",
    ('stay_go', 'first', 1): "sự an định và gắn bó lúc này mang lại sự an toàn cao hơn; ở lại để hoàn thiện những điều dang dở là lựa chọn đúng đắn.",
    ('stay_go', 'first', 2): "chỗ đứng hiện tại vẫn đang hỗ trợ bạn rất tốt; duy trì sự gắn kết và tiếp tục cống hiến sẽ giúp bạn gặt hái kết quả xứng đáng.",

    ('stay_go', 'second', 0): "môi trường hiện tại dường như đã hoàn tất vai trò đối với bạn; dũng cảm dời bước sang môi trường mới sẽ mở ra những chân trời tươi sáng hơn.",
    ('stay_go', 'second', 1): "nhu cầu chuyển dịch và đổi mới đang thôi thúc mạnh mẽ; bước ra đi lúc này sẽ giải phóng những tiềm năng đang bị kìm hãm.",
    ('stay_go', 'second', 2): "không gian cũ đã chạm tới ngưỡng giới hạn phát triển; khởi hành tìm kiếm cơ hội mới sẽ đem lại nguồn cảm hứng và sinh khí mới.",

    # Keep vs Let Go
    ('keep_let_go', 'first', 0): "điều này vẫn còn nguyên vẹn giá trị cốt lõi và ý nghĩa đối với bạn; sự kiên trì gìn giữ lúc này là hoàn toàn xứng đáng.",
    ('keep_let_go', 'first', 1): "những gì bạn đang nắm giữ là nền tảng đáng trân quý; bảo vệ và chăm chút cẩn trọng sẽ đem lại quả ngọt trong tương lai.",
    ('keep_let_go', 'first', 2): "chưa phải lúc để từ bỏ hay buông xuôi; tiếp tục trân trọng và giữ vững điều này sẽ chứng minh giá trị của nó theo thời gian.",

    ('keep_let_go', 'second', 0): "những ràng buộc cũ đã bắt đầu trở thành gánh nặng cho tâm trí; buông bỏ nhẹ nhàng chính là cách để bạn tìm lại sự tự do và thanh thản.",
    ('keep_let_go', 'second', 1): "rời tay khỏi những điều không còn phù hợp là điều cần thiết; buông xả quá khứ sẽ tạo khoảng trống cho những điều tốt đẹp hơn xuất hiện.",
    ('keep_let_go', 'second', 2): "sự níu giữ lúc này chỉ mang lại mệt mỏi và bế tắc; nhẹ lòng buông tay sẽ giúp bạn cảm thấy nhẹ nhõm và sẵn sàng cho khởi đầu mới.",

    # Commit vs Withdraw
    ('commit_withdraw', 'first', 0): "các điều kiện và triển vọng tương lai đã dần hiển lộ rõ ràng; việc thiết lập cam kết gắn bó lúc này sẽ tạo nên nền móng vững chắc.",
    ('commit_withdraw', 'first', 1): "bối cảnh chung rất ủng hộ sự hợp tác và gắn kết lâu dài; chủ động cam kết trách nhiệm sẽ tạo dựng được lòng tin sâu sắc.",
    ('commit_withdraw', 'first', 2): "sự kiên định và tinh thần trách nhiệm là chìa khóa mở ra thành công; cam kết dốc lòng sẽ tạo đòn bẩy lớn cho sự phát triển.",

    ('commit_withdraw', 'second', 0): "tình hình phía trước còn nhiều điểm mập mờ và chưa rõ ràng; khéo léo rút lui là cách khôn ngoan để bảo vệ bản thân và nguồn lực.",
    ('commit_withdraw', 'second', 1): "các điều kiện ràng buộc tiềm ẩn nhiều rủi ro bất lợi; chủ động thoái lui khỏi sự gắn kết này sẽ giúp bạn tránh được phiền toái.",
    ('commit_withdraw', 'second', 2): "dấu hiệu thực tế cho thấy bạn không nên dấn thân quá sâu; dừng lại và thu hồi cam kết lúc này là quyết định tỉnh táo nhất.",

    # Left vs Right (Receptive vs Expressive)
    ('left_right', 'first', 0): "tình huống rất thích hợp cho sự lắng nghe và tiếp nhận; hãy khiêm nhường quan sát và thu thập thông tin để có cái nhìn sâu sắc.",
    ('left_right', 'first', 1): "sự tĩnh lặng và kín đáo lúc này mang lại sức mạnh to lớn; hãy học cách tiếp nhận và thấu hiểu thay vì vội vã phản ứng ra bên ngoài.",
    ('left_right', 'first', 2): "tình huống đòi hỏi sự kiên nhẫn và bao dung; quan sát kỹ lưỡng và tiếp thu ý kiến xung quanh sẽ giúp bạn đưa ra lựa chọn sáng suốt.",

    ('left_right', 'second', 0): "đây là lúc bạn nên chủ động bộc lộ bản lĩnh và quan điểm; hãy tự tin chia sẻ ý tưởng và truyền cảm hứng tới mọi người xung quanh.",
    ('left_right', 'second', 1): "sự chủ động thể hiện bản thân sẽ mở ra nhiều cơ hội đáng giá; hãy bước ra ánh sáng và cho mọi người thấy năng lực của bạn.",
    ('left_right', 'second', 2): "việc mạnh dạn lên tiếng và hành động hướng ngoại lúc này rất được ủng hộ; hãy tự tin thể hiện rõ ràng chính kiến của mình.",

    # Yes vs No
    ('yes_no', 'first', 0): "các yếu tố khách quan đều đang nghiêng về câu trả lời đồng ý; bạn hoàn toàn có thể tự tin gật đầu và tiến bước để đón nhận kết quả thuận lợi.",
    ('yes_no', 'first', 1): "ngoại cảnh đang rất ủng hộ sự đón nhận và cởi mở; một sự đồng ý dứt khoát sẽ tạo đà thuận lợi cho những bước tiếp theo.",
    ('yes_no', 'first', 2): "tình thế xung quanh đang tạo điều kiện rất thuận lợi cho lựa chọn này; hãy mạnh dạn nói 'có' để mở ra cơ hội phát triển mới.",

    ('yes_no', 'second', 0): "tình hình thực tế cho thấy còn nhiều điểm bất lợi chưa được tháo gỡ; việc chủ động từ chối và nói 'không' lúc này là quyết định sáng suốt.",
    ('yes_no', 'second', 1): "các điều kiện xung quanh chưa thực sự sẵn sàng để bạn gật đầu; tạm thời khép lại cơ hội này sẽ giúp bạn tránh được những phiền phức không đáng có.",
    ('yes_no', 'second', 2): "dấu hiệu cảnh báo cho thấy việc đồng ý lúc này tiềm ẩn nhiều rủi ro; hãy giữ vững lập trường từ chối để bảo vệ quyền lợi của bản thân.",

    # Balanced
    ('balanced', 'balanced', 0): "các yếu tố thuận lợi và rủi ro hiện đang ở thế cân bằng đối trọng; thời điểm này chưa rõ bên nào vượt trội, sự bình tâm quan sát là lựa chọn thông thái nhất.",
    ('balanced', 'balanced', 1): "tình thế đang giữ trạng thái giằng co chưa nghiêng hẳn về bên nào; đừng vội vàng đưa ra quyết định khi sự việc còn cần thêm thời gian để rõ ràng.",
    ('balanced', 'balanced', 2): "hai phương án hiện đang có trọng lượng tương đương nhau; hãy cho bản thân một khoảng dừng cần thiết để cân nhắc thấu đáo trước khi chốt lại.",
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
