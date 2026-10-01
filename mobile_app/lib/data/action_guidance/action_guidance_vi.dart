/// Vietnamese copy for Action Guidance.
///
/// Contains base reflections per decision mode plus context lenses for
/// career, love, finances (money), study, friends, and other.
///
/// Adheres strictly to responsible use:
/// - Never tells the reader to buy, sell, quit, marry, or divorce.
/// - Free from forbidden words: 'đầu tư', 'tiền', 'lương', 'vay', 'lợi nhuận',
///   'mua', 'bán', 'chia tay', 'ly hôn', 'nghỉ việc', 'người yêu', 'kết hôn'.
/// - Avoids overclaims like 'hợp nhịp nhất', 'tốt nhất'.
const Map<String, (String, String, String)> actionGuidanceVi =
    <String, (String, String, String)>{
  // ---------------------------------------------------------------------------
  // Base entries (General / Universal)
  // ---------------------------------------------------------------------------
  'balanced': (
    'Hôm nay các tín hiệu không nghiêng về bên nào.',
    'Viết ra điều bạn vốn đã tin, trước khi đi tìm thêm dấu hiệu.',
    'Hỏi lại ở một chế độ khác cho tới khi ra được câu trả lời mình muốn.',
  ),
  'yes_no:first': (
    'Hôm nay các tín hiệu nghiêng về sự cởi mở hơn là sự cản trở.',
    'Để ý xem bạn vốn đã nghiêng về đâu, và điều đó nói lên điều gì.',
    'Xem một tín hiệu biểu tượng là cái cớ để bỏ qua lý lẽ của chính mình.',
  ),
  'yes_no:second': (
    'Hôm nay các tín hiệu nghiêng về sự cản trở hơn là sự cởi mở.',
    'Gọi tên thẳng sự do dự bạn đang có, trước khi tranh luận với nó.',
    'Coi sự cản trở là phán quyết thay vì là lý do để nhìn lại.',
  ),
  'act_wait:first': (
    'Tính cả yếu tố thời điểm lẫn mọi thứ khác, bài đọc nghiêng về việc hành động.',
    'Thử hỏi bạn có thể bắt đầu điều gì bây giờ mà ngày mai vẫn còn là của mình.',
    'Nhầm một thời điểm hợp nhịp với một quyết định đã xong.',
  ),
  'act_wait:second': (
    'Tính cả yếu tố thời điểm lẫn mọi thứ khác, bài đọc nghiêng về việc chờ.',
    'Để câu hỏi lắng lại, xem tới chiều tối nó có đổi dáng hình không.',
    'Nhầm sự kiên nhẫn với né tránh, hoặc vội vàng với dũng cảm.',
  ),
  'advance_retreat:first': (
    'Tính cả đà mấy ngày gần đây lẫn phần còn lại, bài đọc nghiêng về việc tiến.',
    'Để ý xem thực sự điều gì đã đổi khác từ đầu tuần đến giờ.',
    'Cho rằng đà này sẽ tự nó giữ được mãi.',
  ),
  'advance_retreat:second': (
    'Tính cả đà mấy ngày gần đây lẫn phần còn lại, bài đọc nghiêng về việc lùi.',
    'Thử hỏi giữ nguyên vị trí thêm một chút thì thật ra mất gì.',
    'Coi một ngày lắng xuống là một bước lùi.',
  ),
  'stay_go:first': (
    'Tính cả sức trụ lẫn phần còn lại, bài đọc nghiêng về việc giữ chỗ đứng.',
    'Nghĩ xem chỗ đứng hiện tại thật ra đang cho bạn những gì.',
    'Nhầm sự tĩnh tại với việc bị mắc kẹt.',
  ),
  'stay_go:second': (
    'Tính cả sức trụ lẫn phần còn lại, bài đọc nghiêng về việc dịch chuyển.',
    'Thử hỏi bạn sẽ mang theo điều gì, và đặt xuống điều gì.',
    'Coi sự bồn chồn là một kế hoạch.',
  ),
  'keep_let_go:first': (
    'Các tín hiệu nghiêng về việc giữ lại hơn là buông ra.',
    'Nhìn lại điều bạn đang giữ, và xem bạn chọn nó hay thừa hưởng nó.',
    'Giữ vì thói quen rồi gọi đó là sự gắn bó.',
  ),
  'keep_let_go:second': (
    'Các tín hiệu nghiêng về việc buông ra hơn là giữ lại.',
    'Thử hỏi điều gì sẽ có chỗ lớn lên nếu tâm trí bạn nhẹ bớt.',
    'Coi một tín hiệu biểu tượng là lý do để quyết thay cho người khác.',
  ),
  'commit_withdraw:first': (
    'Tính cả tuần sắp tới lẫn phần còn lại, bài đọc nghiêng về việc gắn bó.',
    'Nghĩ theo đơn vị tuần thay vì giờ, xem câu hỏi có trụ được không.',
    'Nhầm một tuần ổn định với một sự bảo đảm.',
  ),
  'commit_withdraw:second': (
    'Tính cả tuần sắp tới lẫn phần còn lại, bài đọc nghiêng về việc rút ra.',
    'Thử hỏi cần điều gì là thật thì việc này mới thấy vững hơn.',
    'Coi một tuần chao đảo là trạng thái vĩnh viễn.',
  ),
  'left_right:first': (
    'Tính cả cực tính lẫn phần còn lại, bài đọc nghiêng vào trong, mang tính tiếp nhận.',
    'Cho cách hiểu lặng lẽ, ít hiển nhiên hơn của câu hỏi một chỗ đứng.',
    'Dùng một cực tính biểu tượng cho việc đi đường, giao thông hay an toàn thân thể.',
  ),
  'left_right:second': (
    'Tính cả cực tính lẫn phần còn lại, bài đọc nghiêng ra ngoài, mang tính biểu đạt.',
    'Thử nói ra điều bạn vẫn vòng quanh, ít nhất là nói với chính mình.',
    'Dùng một cực tính biểu tượng cho việc đi đường, giao thông hay an toàn thân thể.',
  ),

  // ---------------------------------------------------------------------------
  // Career (Công việc / Dự án)
  // ---------------------------------------------------------------------------
  'career:balanced': (
    'Trong công việc hôm nay, các tín hiệu chưa nghiêng hẳn về hướng nào.',
    'Tập hợp đầy đủ số liệu và lập trường của bạn trước khi tìm thêm dấu hiệu.',
    'Hỏi đi hỏi lại để tìm một câu trả lời xoa dịu nỗi băn khoăn tức thời.',
  ),
  'career:yes_no:first': (
    'Trong công việc, các tín hiệu nghiêng về sự cởi mở và chủ động nắm bắt cơ hội.',
    'Tự hỏi xem bước đi này có thực sự phục vụ cho mục tiêu dài hạn của bạn không.',
    'Nhầm lẫn sự hứng khởi nhất thời với một kế hoạch hành động đã chuẩn bị kỹ.',
  ),
  'career:yes_no:second': (
    'Trong công việc, các tín hiệu nghiêng về việc cẩn trọng và xem xét rào cản hiện hữu.',
    'Nhìn thẳng vào những điểm chưa chắc chắn trong dự án trước khi tiếp tục xúc tiến.',
    'Coi trở ngại tạm thời là bế tắc thay vì là tín hiệu cần hoàn thiện phương án.',
  ),
  'career:act_wait:first': (
    'Tính cả yếu tố thời điểm trong công việc, bài đọc nghiêng về việc hành động.',
    'Bắt đầu những phần việc cụ thể mà ngày mai bạn có thể tiếp tục nối dài.',
    'Nhầm một thời điểm thuận lợi với một công việc đã hoàn thành trọn vẹn.',
  ),
  'career:act_wait:second': (
    'Tính cả yếu tố thời điểm trong công việc, bài đọc nghiêng về việc chờ và quan sát.',
    'Dành thêm thời gian thu thập dữ liệu và chuẩn bị kỹ lưỡng trước khi chốt.',
    'Vội vã thúc đẩy tiến độ khi nền tảng chuyên môn chưa thực sự vững vàng.',
  ),
  'career:advance_retreat:first': (
    'Tính cả đà công việc gần đây, bài đọc nghiêng về việc chủ động tiến bước.',
    'Tận dụng đà tiến triển hiện có để mở rộng quy mô hoặc đề xuất ý tưởng mới.',
    'Chủ quan cho rằng đà thuận lợi này sẽ tự nó duy trì mà không cần nỗ lực.',
  ),
  'career:advance_retreat:second': (
    'Tính cả đà công việc gần đây, bài đọc nghiêng về việc củng cố và lùi lại quan sát.',
    'Giữ vững vị trí hiện tại để rà soát quy trình, tránh dàn trải nguồn lực.',
    'Coi việc tạm dừng để điều chỉnh chiến lược là một bước lùi trong sự nghiệp.',
  ),
  'career:stay_go:first': (
    'Tính cả sức trụ trong công việc, bài đọc nghiêng về việc giữ vững chỗ đứng.',
    'Khai thác tối đa những giá trị và kinh nghiệm mà vị trí hiện tại đang mang lại.',
    'Nhầm sự ổn định chuyên môn với việc bị dậm chân tại chỗ.',
  ),
  'career:stay_go:second': (
    'Tính cả sức trụ trong công việc, bài đọc nghiêng về việc dịch chuyển hướng đi.',
    'Xác định rõ bạn muốn mang theo kỹ năng gì và sẵn sàng buông bỏ điều gì.',
    'Coi cảm giác muốn thay đổi là một kế hoạch nghề nghiệp hoàn chỉnh.',
  ),
  'career:keep_let_go:first': (
    'Trong công việc, các tín hiệu nghiêng về việc bảo vệ những gì đã gây dựng.',
    'Đánh giá lại những giá trị cốt lõi bạn đang theo đuổi và kiên định với chúng.',
    'Giữ lại những quy trình cũ kỹ chỉ vì thói quen ngại đổi mới.',
  ),
  'career:keep_let_go:second': (
    'Trong công việc, các tín hiệu nghiêng về việc buông bỏ bớt gánh nặng.',
    'Giải phóng bớt những đầu việc kém hiệu quả để tập trung cho mục tiêu trọng tâm.',
    'Tự ý cắt giảm các trách nhiệm chung mà không có sự thống nhất rõ ràng.',
  ),
  'career:commit_withdraw:first': (
    'Tính cả tuần sắp tới trong công việc, bài đọc nghiêng về sự gắn kết lâu dài.',
    'Đặt kế hoạch trong tầm nhìn trung hạn để xem dự án có đủ sức bền không.',
    'Xem một giai đoạn trôi chảy là sự đảm bảo chắc chắn cho toàn bộ dự án.',
  ),
  'career:commit_withdraw:second': (
    'Tính cả tuần sắp tới trong công việc, bài đọc nghiêng về việc tạm rút lui tái cấu trúc.',
    'Xác định những điều kiện cần thiết để công việc lấy lại sự cân bằng.',
    'Xem một tuần nhiều biến động là dấu hiệu của sự đổ vỡ hoàn toàn.',
  ),
  'career:left_right:first': (
    'Trong công việc, bài đọc nghiêng về việc lắng nghe và tiếp nhận thông tin.',
    'Tạo không gian cho những ý kiến phản biện và quan sát sâu hơn trước khi quyết định.',
    'Dùng trực giác biểu tượng cho các vấn đề kỹ thuật hay an toàn vận hành.',
  ),
  'career:left_right:second': (
    'Trong công việc, bài đọc nghiêng về việc chủ động bày tỏ và thể hiện ý tưởng.',
    'Trình bày thẳng thắn giải pháp của bạn với đồng nghiệp hoặc người liên quan.',
    'Dùng trực giác biểu tượng cho các vấn đề kỹ thuật hay an toàn vận hành.',
  ),

  // ---------------------------------------------------------------------------
  // Love (Tình cảm & Mối quan hệ)
  // ---------------------------------------------------------------------------
  'love:balanced': (
    'Trong chuyện tình cảm hôm nay, các tín hiệu ở trạng thái cân bằng và tĩnh lặng.',
    'Cảm nhận sự chân thật trong lòng mình trước khi tìm kiếm thêm dấu hiệu từ bên ngoài.',
    'Hỏi đi hỏi lại để tìm một câu trả lời xoa dịu nỗi bất an nhất thời.',
  ),
  'love:yes_no:first': (
    'Trong chuyện tình cảm, các tín hiệu nghiêng về sự cởi mở và đón nhận.',
    'Mở lòng chia sẻ cảm xúc chân thành thay vì dựng lên rào chắn để tự vệ.',
    'Kỳ vọng đối phương tự hiểu cảm xúc của mình mà không cần đối thoại thẳng thắn.',
  ),
  'love:yes_no:second': (
    'Trong chuyện tình cảm, các tín hiệu nghiêng về việc cẩn trọng và giữ khoảng cách.',
    'Lắng nghe sự ngập ngừng trong lòng bạn và cho bản thân thời gian nhìn nhận lại.',
    'Xem sự dè dặt là dấu chấm hết thay vì là cơ hội để hai bên hiểu nhau hơn.',
  ),
  'love:act_wait:first': (
    'Tính cả yếu tố thời điểm trong tình cảm, bài đọc nghiêng về việc chủ động thể hiện.',
    'Chủ động gửi gắm sự quan tâm chân thành và tạo cơ hội gắn kết.',
    'Nóng vội mong đợi phản hồi tức thì khi đối phương cần thêm thời gian.',
  ),
  'love:act_wait:second': (
    'Tính cả yếu tố thời điểm trong tình cảm, bài đọc nghiêng về việc kiên nhẫn chờ.',
    'Cho nhau thêm thời gian và không gian để cảm xúc tự nhiên lắng dịu.',
    'Nhầm lẫn sự im lặng xa cách với sự kiên nhẫn chân thành.',
  ),
  'love:advance_retreat:first': (
    'Tính cả đà gắn kết gần đây, bài đọc nghiêng về việc tiến gần nhau hơn.',
    'Trân trọng những khoảnh khắc sẻ chia gần đây để vun đắp niềm tin.',
    'Vội vàng cho rằng mọi khúc mắc đã tự động được giải quyết triệt để.',
  ),
  'love:advance_retreat:second': (
    'Tính cả đà gắn kết gần đây, bài đọc nghiêng về việc giữ nhịp độ chậm lại.',
    'Tạo khoảng lặng cần thiết để cả hai cùng nhìn nhận rõ ràng cảm xúc của mình.',
    'Coi một ngày ít trò chuyện là sự lạnh nhạt hay bước lùi trong tình cảm.',
  ),
  'love:stay_go:first': (
    'Tính cả sức bền trong tình cảm, bài đọc nghiêng về việc trân trọng mối gắn kết hiện tại.',
    'Nhìn lại những giá trị và sự đồng hành quý báu mà hai người đã cùng đi qua.',
    'Nhầm lẫn sự bình yên quen thuộc với cảm giác buồn tẻ hay bế tắc.',
  ),
  'love:stay_go:second': (
    'Tính cả sức bền trong tình cảm, bài đọc nghiêng về việc làm mới không gian giữa hai người.',
    'Thử thay đổi cách tương tác và thói quen cũ để mang lại năng lượng mới.',
    'Để cảm giác bồn chồn nhất thời dẫn dắt những phản ứng thiếu cân nhắc.',
  ),
  'love:keep_let_go:first': (
    'Trong chuyện tình cảm, các tín hiệu nghiêng về việc gìn giữ và nâng niu gắn kết.',
    'Nhìn nhận xem tình cảm này xuất phát từ sự thấu hiểu hay chỉ là thói quen.',
    'Gắng gượng duy trì sự gần gũi bằng cách né tránh những điều cần trao đổi.',
  ),
  'love:keep_let_go:second': (
    'Trong chuyện tình cảm, các tín hiệu nghiêng về việc buông bớt những kỳ vọng nặng nề.',
    'Thử giải phóng bản thân khỏi việc kiểm soát hoặc áp đặt suy nghĩ lên đối phương.',
    'Lấy lý do biểu tượng để đơn phương quyết định thay cho cảm xúc của người khác.',
  ),
  'love:commit_withdraw:first': (
    'Tính cả tuần sắp tới trong tình cảm, bài đọc nghiêng về sự gắn bó vững vàng.',
    'Nghĩ về sự đồng hành qua từng tuần, từng tháng thay vì những cảm xúc thất thường.',
    'Nhầm lẫn một khoảng thời gian êm đẹp với sự hòa hợp không cần vun đắp.',
  ),
  'love:commit_withdraw:second': (
    'Tính cả tuần sắp tới trong tình cảm, bài đọc nghiêng về việc cho nhau khoảng lặng riêng.',
    'Tự chăm sóc bản thân và để mỗi người có không gian riêng để thở.',
    'Xem một tuần có sự chênh vênh là trạng thái vĩnh viễn của mối quan hệ.',
  ),
  'love:left_right:first': (
    'Trong chuyện tình cảm, bài đọc nghiêng về sự thấu cảm và lắng nghe sâu sắc.',
    'Dành sự chú tâm để lắng nghe những điều đối phương chưa nói thành lời.',
    'Dùng các biểu tượng cảm tính để áp đặt kết luận lên mối quan hệ.',
  ),
  'love:left_right:second': (
    'Trong chuyện tình cảm, bài đọc nghiêng về sự bày tỏ và bộc lộ cảm xúc.',
    'Dũng cảm nói ra tình cảm và mong muốn thực sự trong lòng bạn.',
    'Dùng các biểu tượng cảm tính để áp đặt kết luận lên mối quan hệ.',
  ),

  // ---------------------------------------------------------------------------
  // Money / Finances (Tài chính & Nguồn lực)
  // ---------------------------------------------------------------------------
  'money:balanced': (
    'Về phương diện tài chính hôm nay, các tín hiệu ở trạng thái cân bằng ổn định.',
    'Ghi chép lại các con số hiện có và giữ nguyên kế hoạch đã định trước đó.',
    'Tìm kiếm các dấu hiệu bên ngoài để biện minh cho một quyết định chi tiêu bốc đồng.',
  ),
  'money:yes_no:first': (
    'Về phương diện tài chính, các tín hiệu nghiêng về sự rõ ràng và triển vọng tích cực.',
    'Cân nhắc xem quyết định này dựa trên nhu cầu thực tế và kế hoạch dài hạn.',
    'Vội vàng đưa ra cam kết khi các điều khoản chi phí chưa thực sự minh bạch.',
  ),
  'money:yes_no:second': (
    'Về phương diện tài chính, các tín hiệu nghiêng về việc cẩn trọng và thắt chặt kiểm soát.',
    'Rà soát lại các khoản dự phòng và ưu tiên bảo toàn nguồn lực hiện có.',
    'Xem sự thận trọng là sự thiếu hụt thay vì là bước phòng thủ cần thiết.',
  ),
  'money:act_wait:first': (
    'Tính cả yếu tố thời điểm về tài chính, bài đọc nghiêng về việc thực hiện kế hoạch đã định.',
    'Thực hiện các bước phân bổ nguồn lực đã được tính toán kỹ từ trước.',
    'Mở rộng ngân sách vượt quá kế hoạch ban đầu chỉ vì cảm thấy thuận lợi.',
  ),
  'money:act_wait:second': (
    'Tính cả yếu tố thời điểm về tài chính, bài đọc nghiêng về việc giữ nhịp quan sát.',
    'Giữ ngân sách ổn định và cân nhắc thêm vài ngày trước các quyết định lớn.',
    'Cảm giác sợ bỏ lỡ mà vội vàng cam kết nguồn lực khi chưa kiểm tra rủi ro.',
  ),
  'money:advance_retreat:first': (
    'Tính cả đà tài chính gần đây, bài đọc nghiêng về việc mở rộng có kiểm soát.',
    'Tận dụng sự ổn định hiện có để nâng cao hiệu quả quản lý ngân sách.',
    'Nghĩ rằng đà tăng trưởng này sẽ tự nó kéo dài mà thiếu kỷ luật kiểm soát.',
  ),
  'money:advance_retreat:second': (
    'Tính cả đà tài chính gần đây, bài đọc nghiêng về việc co hẹp và củng cố dự phòng.',
    'Cắt giảm các khoản chi phí phát sinh không thực sự cần thiết.',
    'Coi việc siết chặt kỷ luật ngân sách là dấu hiệu của sự tụt hậu.',
  ),
  'money:stay_go:first': (
    'Tính cả sức bền tài chính, bài đọc nghiêng về việc duy trì cấu trúc hiện có.',
    'Đánh giá sự an toàn mà phương án quản lý nguồn lực hiện tại mang lại.',
    'Nhầm sự an toàn tài chính với việc thiếu cơ hội phát triển.',
  ),
  'money:stay_go:second': (
    'Tính cả sức bền tài chính, bài đọc nghiêng về việc điều chỉnh cơ cấu phân bổ.',
    'Xem xét bạn cần cắt giảm khoản nào để tập trung vào mục tiêu trọng tâm hơn.',
    'Thực hiện thay đổi đột ngột vì tâm lý nóng vội muốn có kết quả tức thì.',
  ),
  'money:keep_let_go:first': (
    'Về tài chính, các tín hiệu nghiêng về việc gìn giữ và duy trì nguồn tích lũy.',
    'Xem xét kỹ những gì bạn đang bảo vệ và giá trị thực sự mà nó mang lại.',
    'Duy trì các chi phí định kỳ chỉ vì thói quen không rà soát lại sổ sách.',
  ),
  'money:keep_let_go:second': (
    'Về tài chính, các tín hiệu nghiêng về việc cắt giảm những hao tổn không cần thiết.',
    'Hỏi xem ngân sách của bạn sẽ nhẹ nhõm thế nào nếu loại bỏ các khoản lãng phí.',
    'Cắt giảm bừa bãi những hạng mục cốt lõi phục vụ cuộc sống và sự phát triển.',
  ),
  'money:commit_withdraw:first': (
    'Tính cả tuần sắp tới về tài chính, bài đọc nghiêng về kế hoạch ổn định lâu dài.',
    'Đánh giá các kế hoạch tài chính trong khung thời gian tháng hoặc quý.',
    'Xem một tuần chi tiêu hợp lý là lý do để nới lỏng kiểm soát ngân sách.',
  ),
  'money:commit_withdraw:second': (
    'Tính cả tuần sắp tới về tài chính, bài đọc nghiêng về việc tạm ngưng các cam kết mới.',
    'Xem xét những điều kiện cần có để tình hình ngân sách đạt mức ổn định hơn.',
    'Xem một đợt phát sinh chi phí ngoài dự kiến là một khủng hoảng nghiêm trọng.',
  ),
  'money:left_right:first': (
    'Về phương diện tài chính, bài đọc nghiêng về việc phân tích kỹ lưỡng các số liệu.',
    'Kiểm tra kỹ các con số và đối chiếu thực tế trước khi đưa ra quyết định.',
    'Dùng trực giác biểu tượng để mạo hiểm với ngân sách hay cam kết vật chất.',
  ),
  'money:left_right:second': (
    'Về phương diện tài chính, bài đọc nghiêng về sự quyết đoán trong phạm vi cho phép.',
    'Rõ ràng và dứt khoát trong việc giải quyết các nghĩa vụ tài chính còn tồn đọng.',
    'Dùng trực giác biểu tượng để mạo hiểm với ngân sách hay cam kết vật chất.',
  ),

  // ---------------------------------------------------------------------------
  // Study (Học tập & Phát triển cá nhân)
  // ---------------------------------------------------------------------------
  'study:balanced': (
    'Trong học tập và rèn luyện, các tín hiệu hôm nay nghiêng về sự tích lũy tĩnh tại.',
    'Xem lại những kiến thức nền tảng đã học trước khi bắt đầu bài học mới.',
    'Cố gắng học dồn ép nhiều kiến thức khi tâm trí chưa thực sự sẵn sàng.',
  ),
  'study:yes_no:first': (
    'Trong việc học hỏi, các tín hiệu nghiêng về việc tiếp thu kiến thức mới.',
    'Nhìn lại kỹ năng bạn muốn trau dồi và dành sự tập trung trọn vẹn cho nó.',
    'Bắt đầu quá nhiều kỹ năng cùng lúc mà thiếu kiên trì đi đến cùng.',
  ),
  'study:yes_no:second': (
    'Trong việc học hỏi, các tín hiệu khuyên nên củng cố kiến thức nền tảng.',
    'Dành thời gian ôn tập và lấp đầy các khoảng trống trước khi đi tiếp.',
    'Tự ti khi thấy bản thân tiếp thu chậm hơn mong đợi ban đầu.',
  ),
  'study:act_wait:first': (
    'Tính cả thời điểm học tập, bài đọc nghiêng về việc bắt tay vào rèn luyện ngay.',
    'Bắt đầu từ những bài thực hành nhỏ mỗi ngày để hình thành thói quen.',
    'Lên kế hoạch học tập quá đồ sộ nhưng không thực sự bắt tay vào làm.',
  ),
  'study:act_wait:second': (
    'Tính cả thời điểm học tập, bài đọc nghiêng về việc đọc kỹ và nghiền ngẫm.',
    'Cho bộ não thời gian thẩm thấu kiến thức thay vì cố nhồi nhét cấp tốc.',
    'Nhầm sự vội vã chạy theo số lượng chứng chỉ với việc hiểu sâu bản chất.',
  ),
  'study:advance_retreat:first': (
    'Tính cả đà học tập gần đây, bài đọc nghiêng về việc nâng cao độ khó.',
    'Thử thách bản thân với những đề tài mới đòi hỏi tư duy sâu sắc hơn.',
    'Vội vàng bỏ qua các bài tập cơ bản khi chưa thực sự thành thạo.',
  ),
  'study:advance_retreat:second': (
    'Tính cả đà học tập gần đây, bài đọc nghiêng về việc giảm tải và hệ thống lại.',
    'Hệ thống hóa lại các ghi chép và sơ đồ tư duy để nhớ lâu hơn.',
    'Coi việc giảm tốc độ học là sự thụt lùi so với người khác.',
  ),
  'study:stay_go:first': (
    'Trong học tập, các tín hiệu nghiêng về việc đào sâu chuyên môn hiện tại.',
    'Tập trung khai thác hết tiềm năng của lĩnh vực bạn đang theo đuổi.',
    'Nhảy việc học từ chủ đề này sang chủ đề khác vì nhanh chán.',
  ),
  'study:stay_go:second': (
    'Trong học tập, các tín hiệu nghiêng về việc mở rộng sang góc nhìn liên ngành.',
    'Tìm hiểu thêm những kỹ năng bổ trợ giúp làm phong phú góc nhìn của bạn.',
    'Xem sự tò mò nhất thời là một định hướng học tập lâu dài.',
  ),
  'study:keep_let_go:first': (
    'Trong rèn luyện, bài đọc nghiêng về việc giữ vững phương pháp học hiệu quả.',
    'Duy trì kỷ luật và khung giờ tự học đã phát huy tác dụng tốt.',
    'Cố chấp giữ những cách học cũ kỹ không còn mang lại tiến bộ.',
  ),
  'study:keep_let_go:second': (
    'Trong rèn luyện, bài đọc nghiêng về việc buông bỏ bớt những tài liệu dư thừa.',
    'Thanh lọc danh sách tài liệu cần đọc, chỉ giữ lại những nguồn thực sự giá trị.',
    'Tích trữ tài liệu học tập mà không bao giờ thực sự mở ra đọc.',
  ),
  'study:commit_withdraw:first': (
    'Tính theo tuần sắp tới, bài đọc nghiêng về việc cam kết theo đuổi khóa học.',
    'Lên lịch học đều đặn mỗi tuần và coi đó là ưu tiên không thể trì hoãn.',
    'Đăng ký khóa học dài hạn chỉ vì cảm hứng bộc phát mà không tính thời gian.',
  ),
  'study:commit_withdraw:second': (
    'Tính theo tuần sắp tới, bài đọc nghiêng về việc cho phép bản thân nghỉ ngơi.',
    'Nghỉ ngơi hợp lý để tái tạo năng lượng tinh thần sau giai đoạn học căng thẳng.',
    'Coi việc nghỉ xả hơi ngắn hạn là sự từ bỏ việc học.',
  ),
  'study:left_right:first': (
    'Trong học tập, bài đọc nghiêng về việc đọc hiểu, tổng hợp và phân tích.',
    'Lắng nghe bài giảng và nghiên cứu tài liệu với sự tập trung sâu sắc.',
    'Dùng biểu tượng trực giác thay cho việc học tập và nghiên cứu thực tế.',
  ),
  'study:left_right:second': (
    'Trong học tập, bài đọc nghiêng về việc thuyết trình, thảo luận và chia sẻ.',
    'Thử giảng giải lại kiến thức cho người khác để kiểm tra mức độ hiểu bài.',
    'Dùng biểu tượng trực giác thay cho việc học tập và nghiên cứu thực tế.',
  ),

  // ---------------------------------------------------------------------------
  // Friends (Bạn bè & Vòng kết nối)
  // ---------------------------------------------------------------------------
  'friends:balanced': (
    'Trong quan hệ bạn bè hôm nay, các tín hiệu ở trạng thái hòa nhã và bình lặng.',
    'Tận hưởng sự tĩnh lặng của riêng bạn trước khi tham gia các cuộc vui.',
    'Cố tìm kiếm sự chú ý trong nhóm bạn khi tâm trạng không thoải mái.',
  ),
  'friends:yes_no:first': (
    'Trong quan hệ bạn bè, các tín hiệu nghiêng về sự gắn kết chân thành.',
    'Dành thời gian và tâm sức cho những người bạn mang lại năng lượng tích cực.',
    'Cố gắng làm hài lòng tất cả mọi người mà đánh mất ranh giới cá nhân.',
  ),
  'friends:yes_no:second': (
    'Trong quan hệ bạn bè, các tín hiệu khuyên nên giữ ranh giới cá nhân rõ ràng.',
    'Nhận biết những tương tác khiến bạn kiệt sức và biết nói lời từ chối.',
    'Tự trách mình khi không thể đáp ứng mọi kỳ vọng của bạn bè.',
  ),
  'friends:act_wait:first': (
    'Tính cả yếu tố thời điểm, bài đọc nghiêng về việc chủ động liên lạc bạn bè.',
    'Nhắn tin hoặc gọi điện hỏi thăm một người bạn cũ mà bạn vẫn quý mến.',
    'Mong đợi người khác phải phản hồi ngay lập tức khi họ đang bận rộn.',
  ),
  'friends:act_wait:second': (
    'Tính cả yếu tố thời điểm, bài đọc nghiêng về việc để các mối quan hệ tự nhiên.',
    'Để mọi việc diễn ra tự nhiên, không cần gượng ép gặp gỡ khi chưa tiện.',
    'Suy diễn tiêu cực khi một người bạn phản hồi tin nhắn chậm hơn thường lệ.',
  ),
  'friends:advance_retreat:first': (
    'Tính cả đà gắn kết gần đây, bài đọc nghiêng về việc mở rộng vòng bạn bè.',
    'Tham gia các hoạt động cộng đồng phù hợp với sở thích của bạn.',
    'Vội vã tin tưởng tuyệt đối vào những người bạn mới quen.',
  ),
  'friends:advance_retreat:second': (
    'Tính cả đà gắn kết gần đây, bài đọc nghiêng về việc chọn lọc vòng bạn thân.',
    'Ưu tiên thời gian cho một vài người bạn thực sự tri kỷ và thấu hiểu.',
    'Tự cô lập bản thân hoàn toàn vì một hiểu lầm nhỏ với bạn bè.',
  ),
  'friends:stay_go:first': (
    'Trong quan hệ bạn bè, bài đọc nghiêng về việc gìn giữ nhóm bạn lâu năm.',
    'Trân trọng những người đã đồng hành cùng bạn qua nhiều thăng trầm.',
    'Duy trì tình bạn độc hại chỉ vì quen biết đã lâu năm.',
  ),
  'friends:stay_go:second': (
    'Trong quan hệ bạn bè, bài đọc nghiêng về việc tìm kiếm những người bạn mới.',
    'Mở rộng thế giới quan bằng cách kết nối với những người cùng đam mê.',
    'Coi việc rời xa một nhóm bạn không còn chung chí hướng là sự phản bội.',
  ),
  'friends:keep_let_go:first': (
    'Trong tình bạn, bài đọc nghiêng về việc gìn giữ niềm tin và lời hứa.',
    'Ủng hộ và ở bên cạnh bạn bè khi họ cần sự sẻ chia chân thành.',
    'Bao che cho những hành vi sai trái của bạn bè nhân danh tình nghĩa.',
  ),
  'friends:keep_let_go:second': (
    'Trong tình bạn, bài đọc nghiêng về việc buông bỏ những ấm ức vụn vặt.',
    'Bao dung với những sai sót nhỏ và giải tỏa những hiểu lầm không đáng có.',
    'Giữ sự giận dỗi trong lòng rồi đối xử im lặng với bạn bè.',
  ),
  'friends:commit_withdraw:first': (
    'Tính theo tuần sắp tới, bài đọc nghiêng về việc cam kết đồng hành cùng bạn bè.',
    'Tham gia vào kế hoạch chung hoặc dự án thiện nguyện cùng nhóm bạn.',
    'Nhận lời giúp đỡ quá nhiều việc vượt quá khả năng thực tế của mình.',
  ),
  'friends:commit_withdraw:second': (
    'Tính theo tuần sắp tới, bài đọc nghiêng về việc tạm lùi lại dành thời gian cho mình.',
    'Nạp lại năng lượng tinh thần trong không gian yên tĩnh của bản thân.',
    'Cắt đứt liên lạc đột ngột khiến bạn bè lo lắng mà không báo trước.',
  ),
  'friends:left_right:first': (
    'Trong giao tiếp bạn bè, bài đọc nghiêng về việc lắng nghe và đồng cảm.',
    'Lắng nghe câu chuyện của bạn với sự tôn trọng, không vội phán xét.',
    'Dùng biểu tượng trực giác để đánh giá lòng dạ người khác.',
  ),
  'friends:left_right:second': (
    'Trong giao tiếp bạn bè, bài đọc nghiêng về việc chia sẻ cởi mở góc nhìn của mình.',
    'Góp ý chân thành trên tinh thần xây dựng và vì sự tiến bộ của bạn.',
    'Dùng biểu tượng trực giác để đánh giá lòng dạ người khác.',
  ),

  // ---------------------------------------------------------------------------
  // Other / Situational (Chuyện khác / Tình huống đặc thù)
  // ---------------------------------------------------------------------------
  'other:balanced': (
    'Với tình huống này hôm nay, các tín hiệu ở trạng thái trung dung.',
    'Nhìn nhận sự việc khách quan mà không gán ghép định kiến trước đó.',
    'Nôn nóng muốn có kết quả ngay khi tình hình chưa ngã ngũ.',
  ),
  'other:yes_no:first': (
    'Với tình huống này, các tín hiệu nghiêng về sự cởi mở và linh hoạt thích ứng.',
    'Thử tiếp cận vấn đề theo một hướng mới mà trước đây bạn chưa từng nghĩ tới.',
    'Áp dụng máy móc cách giải quyết cũ cho một bối cảnh hoàn toàn mới.',
  ),
  'other:yes_no:second': (
    'Với tình huống này, các tín hiệu khuyên nên thận trọng và giữ nguyên hiện trạng.',
    'Xem xét kỹ mọi khía cạnh và lường trước các hệ quả tiềm ẩn.',
    'Quyết định vội vã chỉ để giải tỏa cảm giác bấp bênh tạm thời.',
  ),
  'other:act_wait:first': (
    'Tính cả thời điểm hiện tại, bài đọc nghiêng về việc chủ động giải quyết.',
    'Xử lý dứt điểm các vướng mắc nhỏ trước khi chúng tích tụ thành chuyện lớn.',
    'Hành động bốc đồng khi chưa có phương án dự phòng thích hợp.',
  ),
  'other:act_wait:second': (
    'Tính cả thời điểm hiện tại, bài đọc nghiêng về việc kiên nhẫn quan sát.',
    'Để sự việc diễn tiến thêm một thời gian để bộc lộ rõ bản chất.',
    'Nóng ruột can thiệp làm đảo lộn tiến trình tự nhiên của sự việc.',
  ),
};
