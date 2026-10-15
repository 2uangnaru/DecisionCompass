import re
import sys

sys.stdout.reconfigure(encoding='utf-8')

# Read current action_guidance_vi.dart
with open('mobile_app/lib/data/action_guidance/action_guidance_vi.dart', 'r', encoding='utf-8') as f:
    content = f.read()

pattern = re.compile(
    r"'([a-z0-9_:]+)':\s*\(\s*'([^']*)',\s*'([^']*)',\s*'([^']*)',?\s*\)",
    re.MULTILINE
)

matches = pattern.findall(content)
entries = {k: [h, s, a] for k, h, s, a in matches}
print(f"Total entries parsed: {len(entries)}")

# 1. Fix 17 duplicate headlines
entries['career:act_wait:first:v2'][0] = 'Xét về khía cạnh thời điểm nghề nghiệp, bài đọc khuyên nên chủ động triển khai với sự chuẩn bị kỹ.'
entries['career:act_wait:second:v2'][0] = 'Xét về khía cạnh thời điểm nghề nghiệp, các tín hiệu gợi ý nên điềm tĩnh chờ điều kiện chín muồi.'
entries['career:advance_retreat:first:v2'][0] = 'Dựa trên nhịp vận hành của công việc, bài đọc khuyến nghị giữ đà tiến vững chắc từng chặng.'
entries['career:advance_retreat:second:v2'][0] = 'Dựa trên nhịp vận hành của công việc, bài đọc khuyên nên tạm lùi một bước để củng cố nền tảng.'
entries['friends:act_wait:first:v2'][0] = 'Xét về thời điểm kết nối, bài đọc gợi ý nên chủ động thăm hỏi bạn bè với thái độ cởi mở.'
entries['friends:advance_retreat:first:v2'][0] = 'Nhìn nhận nhịp giao tiếp gần đây, các tín hiệu ủng hộ việc chủ động nuôi dưỡng mối quan hệ bạn bè.'
entries['friends:yes_no:second:v2'][0] = 'Với mối quan hệ bạn hữu, tín hiệu nhắc nhở việc bảo vệ sự tôn trọng và khoảng không gian riêng.'
entries['love:act_wait:first:v2'][0] = 'Xét về nhịp điệu cảm xúc, bài đọc khuyên nên chân thành bộc lộ sự quan tâm đúng lúc.'
entries['love:act_wait:second:v2'][0] = 'Xét về nhịp điệu cảm xúc, các tín hiệu gợi ý nên chậm lại để đôi bên thấu hiểu nhau hơn.'
entries['love:advance_retreat:first:v2'][0] = 'Dựa trên sự đồng điệu gần đây, bài đọc khuyến khích từng bước bồi đắp sự gắn kết bền vững.'
entries['love:advance_retreat:second:v2'][0] = 'Dựa trên sự đồng điệu gần đây, bài đọc khuyên nên tạo khoảng lặng bình yên để nhìn nhận thấu đáo.'
entries['money:advance_retreat:first:v2'][0] = 'Xét theo nhịp biến động tài nguyên, bài đọc khuyến nghị chủ động tối ưu hóa và củng cố dự trữ.'
entries['money:advance_retreat:second:v2'][0] = 'Xét theo nhịp biến động tài nguyên, các tín hiệu khuyên nên thận trọng duy trì thế phòng thủ an toàn.'
entries['other:act_wait:first:v2'][0] = 'Xét trên bình diện tổng quát, bài đọc khuyên nên chủ động gỡ nút thắt với cái nhìn thực tế.'
entries['other:act_wait:second:v2'][0] = 'Xét trên bình diện tổng quát, các tín hiệu gợi ý nên dành thêm thời gian quan sát dòng chảy sự việc.'
entries['other:yes_no:second:v2'][0] = 'Đối với bối cảnh này, bài đọc khuyên nên tạm dừng và cân nhắc mọi yếu tố trước khi chuyển hướng.'
entries['study:yes_no:second:v2'][0] = 'Trên hành trình trau dồi tri thức, bài đọc khuyên nên dành thời gian củng cố nền móng căn bản.'

# 2. Fix duplicate should_dos
entries['other:act_wait:first:v2'][1] = 'Rà soát cẩn thận các yếu tố then chốt và chuẩn bị phương án giải quyết từng bước.'
entries['other:act_wait:second:v2'][1] = 'Giữ sự tĩnh tại để quan sát các chiều hướng phát triển trước khi đưa ra nhận định.'
entries['other:yes_no:first:v2'][1] = 'Đón nhận các gợi ý tích cực nhưng vẫn giữ thái độ tỉnh táo khi triển khai.'

# 3. Fix duplicate avoids
entries['act_wait:second:v1'][2] = 'Vội vã thúc đẩy tiến độ khi điều kiện khách quan chưa thực sự thuận lợi.'
entries['career:act_wait:second:v2'][2] = 'Sốt ruột đẩy nhanh tiến độ chuyên môn khi nền tảng cốt lõi chưa vững vàng.'
entries['advance_retreat:first:v1'][2] = 'Lơ là kỷ luật vì cho rằng đà thuận lợi hiện tại sẽ tự nó duy trì mãi.'
entries['career:advance_retreat:first:v2'][2] = 'Ảo tưởng rằng sự hanh thông nhất thời sẽ giải quyết được mọi khúc mắc nghề nghiệp.'
entries['career:balanced'][2] = 'Đòi hỏi sự rõ ràng tuyệt đối ngay khi bối cảnh sự nghiệp đang trong giai đoạn chuyển dịch.'
entries['career:advance_retreat:second:v2'][2] = 'Coi việc dành thời gian tinh chỉnh chiến lược chuyên môn là biểu hiện của sự thất bại.'
entries['career:commit_withdraw:first:v2'][2] = 'Đánh đồng một vài kết quả khả quan trước mắt với sự thành công trọn vẹn của cả kế hoạch.'
entries['career:commit_withdraw:second:v2'][2] = 'Để vài trở ngại nhất thời nơi công sở làm lung lay ý chí và định hướng dài hạn.'
entries['career:keep_let_go:first:v2'][2] = 'Bám víu lấy những quy chuẩn đã lỗi thời chỉ vì tâm lý ngại đối mặt với đổi mới.'
entries['career:keep_let_go:second:v2'][2] = 'Đơn phương buông bỏ các cam kết nghề nghiệp mà thiếu đi sự trao đổi minh bạch.'

entries['career:left_right:first'][2] = 'Dùng trực giác biểu tượng cho các vấn đề kỹ thuật hay an toàn vận hành.'
entries['career:left_right:first:v1'][2] = 'Coi trực giác là sự thay thế cho các quy trình kiểm thử và dữ liệu vận hành.'
entries['career:left_right:first:v2'][2] = 'Bỏ qua các tiêu chuẩn an toàn nghề nghiệp chỉ vì cảm giác chủ quan.'
entries['career:left_right:second:v1'][2] = 'Thay đổi hướng kỹ thuật đột ngột khi chưa có phương án dự phòng rủi ro.'
entries['career:left_right:second:v2'][2] = 'Áp dụng biểu tượng trừu tượng vào các bài toán kỹ thuật đòi hỏi đo lường chính xác.'

entries['career:stay_go:first:v2'][2] = 'Đánh đồng sự tích lũy chuyên môn sâu sắc với cảm giác dậm chân tại chỗ.'
entries['career:stay_go:second:v2'][2] = 'Ngộ nhận sự bốc đồng muốn thay đổi là một định hướng phát triển bài bản.'

entries['friends:act_wait:first:v2'][2] = 'Áp đặt sự hồi đáp tức thì lên bạn bè khi họ đang có những mối bận tâm riêng.'
entries['friends:advance_retreat:second:v2'][2] = 'Quy chụp sự bận rộn tạm thời của đối phương thành sự xa cách trong tình bạn.'

entries['friends:left_right:first:v1'][2] = 'Dùng trực giác biểu tượng để phán xét nhân cách hay thiện chí của người khác.'
entries['friends:left_right:first:v2'][2] = 'Áp đặt suy đoán cảm tính lên động cơ hành động của bạn bè.'
entries['friends:left_right:second:v1'][2] = 'Để những biểu tượng mơ hồ tạo ra khoảng cách hoặc nghi ngờ vô cớ.'
entries['friends:left_right:second:v2'][2] = 'Vội vã kết luận về một mối quan hệ bạn hữu chỉ qua vài hiểu lầm nhỏ nhặt.'

entries['friends:yes_no:first:v2'][2] = 'Nhượng bộ quá mức chỉ để duy trì hòa khí bề ngoài mà đánh mất chính mình.'
entries['friends:yes_no:second:v2'][2] = 'Tự dằn vặt bản thân khi không thể gánh vác mọi mong cầu từ phía bạn bè.'

entries['left_right:first'][2] = 'Dùng biểu tượng trực giác cho việc đi đường, giao thông hay an toàn thân thể.'
entries['left_right:second'][2] = 'Dùng trực giác biểu tượng để điều hướng cơ học trong không gian vật lý.'
entries['left_right:first:v1'][2] = 'Dùng một cực tính biểu tượng cho việc đi đường, giao thông hay an toàn thân thể.'
entries['left_right:first:v2'][2] = 'Đem cảm giác định hướng trừu tượng áp dụng vào các quyết định an toàn di chuyển.'
entries['left_right:second:v1'][2] = 'Bỏ qua biển chỉ dẫn thực tế trên đường chỉ vì tin vào linh cảm nhất thời.'
entries['left_right:second:v2'][2] = 'Mạo hiểm an toàn cá nhân trong giao thông dựa trên các suy luận tượng trưng.'

entries['love:act_wait:first:v2'][2] = 'Hấp tấp đòi hỏi sự phản hồi cảm xúc khi đối phương đang cần không gian suy ngẫm.'
entries['love:act_wait:second:v2'][2] = 'Ngộ nhận việc né tránh đối thoại thẳng thắn là sự nhẫn nại tinh tế.'
entries['love:advance_retreat:first:v2'][2] = 'Chủ quan cho rằng sự êm ấm trước mắt là lời giải trọn vẹn cho các bất đồng sâu kín.'
entries['love:advance_retreat:second:v2'][2] = 'Thổi phồng vài khoảnh khắc im lặng thành tín hiệu đổ vỡ của tình cảm.'
entries['love:commit_withdraw:first:v2'][2] = 'Coi sự thuận hòa nhất thời là lý do để ngừng nỗ lực lắng nghe và thấu hiểu.'
entries['love:commit_withdraw:second:v2'][2] = 'Bi kịch hóa một tuần trầm lắng thành hồi kết của một mối duyên.'
entries['love:keep_let_go:first:v2'][2] = 'Cố níu giữ sự thân mật giả tạo bằng cách làm ngơ trước những vấn đề cốt lõi.'
entries['love:keep_let_go:second:v2'][2] = 'Dùng lý lẽ biểu tượng để phán xét cảm xúc chân thực của người kia.'

entries['love:left_right:first:v1'][2] = 'Dùng các biểu tượng cảm tính để áp đặt kết luận lên mối quan hệ.'
entries['love:left_right:first:v2'][2] = 'Đem những suy diễn mơ hồ thay thế cho những cuộc trò chuyện chân thành.'
entries['love:left_right:second:v1'][2] = 'Để linh cảm trừu tượng làm xói mòn niềm tin đã dày công xây đắp.'
entries['love:left_right:second:v2'][2] = 'Tự tạo ra kịch bản bi quan trong tâm trí khi chưa có sự đối thoại rõ ràng.'

entries['love:stay_go:first:v2'][2] = 'Nhầm lẫn sự bình yên lâu ngày với cảm giác nguội lạnh trong tình cảm.'
entries['love:stay_go:second:v2'][2] = 'Để nỗi bất an vô cớ thôi thúc những phản ứng làm tổn thương đối phương.'
entries['love:yes_no:first:v2'][2] = 'Mặc định rằng người kia phải thấu hiểu trọn vẹn tâm ý của mình mà không cần sẻ chia.'

entries['money:left_right:first'][2] = 'Dùng trực giác biểu tượng để mạo hiểm với ngân sách hay cam kết vật chất.'
entries['money:left_right:first:v1'][2] = 'Xem biểu tượng tinh thần như một bảo chứng cho an toàn ngân sách.'
entries['money:left_right:first:v2'][2] = 'Để sự hào hứng cảm xúc làm lơ là việc quản lý thu chi thực tế.'
entries['money:left_right:second:v2'][2] = 'Dùng trực giác thay cho việc cân đối dòng dự trữ phòng ngừa rủi ro.'
entries['money:stay_go:second:v2'][2] = 'Xáo trộn thói quen chi tiêu một cách bột phát khi chưa thiết lập quỹ an toàn.'

entries['other:act_wait:first:v2'][2] = 'Hành động hấp tấp khi chưa chuẩn bị kịch bản ứng phó cho các tình huống bất ngờ.'
entries['other:act_wait:second:v2'][2] = 'Can thiệp nóng vội làm gián đoạn tiến trình đang dần định hình tự nhiên.'

entries['other:left_right:first'][2] = 'Dùng trực giác biểu tượng cho các tình huống đòi hỏi tính chuẩn xác vật lý hay an toàn.'
entries['other:left_right:first:v1'][2] = 'Coi cảm giác biểu tượng là căn cứ tuyệt đối thay cho dữ liệu xác thực.'
entries['other:left_right:first:v2'][2] = 'Bỏ qua các nguyên tắc thận trọng cơ bản chỉ vì chạy theo linh cảm.'
entries['other:left_right:second'][2] = 'Áp dụng định hướng tượng trưng vào các bài toán thực tiễn phức tạp.'
entries['other:left_right:second:v1'][2] = 'Đổi hướng giải quyết một cách cảm tính mà thiếu đi kế hoạch rõ ràng.'
entries['other:left_right:second:v2'][2] = 'Cố chấp duy trì lựa chọn ban đầu khi hoàn cảnh thực tế đã đổi khác.'

entries['other:yes_no:first:v2'][2] = 'Rập khuôn giải pháp của quá khứ vào một tình huống mới phát sinh.'
entries['other:yes_no:second:v2'][2] = 'Phản ứng thiếu cân nhắc chỉ để xua tan cảm giác hoang mang tạm thời.'

entries['study:left_right:first'][2] = 'Dùng trực giác biểu tượng thay cho việc học tập và nghiên cứu thực tế.'
entries['study:left_right:first:v1'][2] = 'Trông chờ vào linh cảm thay vì nỗ lực rèn luyện bài vở bài bản.'
entries['study:left_right:first:v2'][2] = 'Bỏ qua các phương pháp học tập khoa học để đi theo trực giác tùy tiện.'
entries['study:left_right:second:v1'][2] = 'Thay đổi môn học hoặc chuyên ngành liên tục mà không tích lũy đủ sâu.'
entries['study:left_right:second:v2'][2] = 'Xem thường việc kiểm tra kiến thức thực tế chỉ vì cảm thấy đã hiểu bài.'

entries['study:yes_no:first:v2'][2] = 'Mở rộng quá nhiều lĩnh vực mới cùng lúc khiến năng lượng bị phân tán.'

# Replace forbidden word 'tiền' in money:keep_let_go:first
entries['money:keep_let_go:first'][1] = 'Thiết lập hạn mức chi tiêu nghiêm ngặt; duy trì sự kiểm soát chặt chẽ đối với các dòng ngân sách.'

# Verify no duplicate headlines, should_dos, avoids
from collections import Counter

h_counts = Counter(v[0] for v in entries.values())
s_counts = Counter(v[1] for v in entries.values())
a_counts = Counter(v[2] for v in entries.values())

dup_h = [h for h, c in h_counts.items() if c > 1]
dup_s = [s for s, c in s_counts.items() if c > 1]
dup_a = [a for a, c in a_counts.items() if c > 1]

print(f"Remaining duplicate headlines: {len(dup_h)}")
for h in dup_h:
    print(f"  H: {h}")
print(f"Remaining duplicate should_dos: {len(dup_s)}")
for s in dup_s:
    print(f"  S: {s}")
print(f"Remaining duplicate avoids: {len(dup_a)}")
for a in dup_a:
    print(f"  A: {a}")

# Check forbidden words
forbidden_vi = ['đầu tư', 'tiền', 'lương', 'vay', 'lợi nhuận', 'mua', 'bán', 'chia tay', 'ly hôn', 'nghỉ việc', 'người yêu', 'kết hôn']
overclaims_vi = ['hợp nhịp nhất', 'tốt nhất']

forbidden_hits = []
for k, v in entries.items():
    text = f"{v[0]} {v[1]} {v[2]}".lower()
    for w in forbidden_vi:
        if w in text:
            forbidden_hits.append((k, 'forbidden', w))
    for o in overclaims_vi:
        if o in text:
            forbidden_hits.append((k, 'overclaim', o))

print(f"Forbidden / overclaim hits: {len(forbidden_hits)}")
for f in forbidden_hits:
    print(f"  {f}")

if len(dup_h) == 0 and len(dup_s) == 0 and len(dup_a) == 0 and len(forbidden_hits) == 0:
    print("SUCCESS: 100% unique entries, 0 forbidden words, 0 overclaims!")
    # Write back to mobile_app/lib/data/action_guidance/action_guidance_vi.dart
    out_lines = [
        "// Generated action guidance dictionary for Vietnamese (vi).",
        "// 315 keys = 105 base keys * 3 variants.",
        "// 100% unique headlines, shouldDos, avoids.",
        "",
        "const Map<String, (String, String, String)> actionGuidanceVi = {",
    ]
    for k in sorted(entries.keys()):
        h, s, a = entries[k]
        # escape single quotes if any
        h_esc = h.replace("'", "\\'")
        s_esc = s.replace("'", "\\'")
        a_esc = a.replace("'", "\\'")
        out_lines.append(f"  '{k}': (")
        out_lines.append(f"    '{h_esc}',")
        out_lines.append(f"    '{s_esc}',")
        out_lines.append(f"    '{a_esc}',")
        out_lines.append("  ),")
    out_lines.append("};")
    out_lines.append("")
    with open('mobile_app/lib/data/action_guidance/action_guidance_vi.dart', 'w', encoding='utf-8') as f:
        f.write('\n'.join(out_lines))
    print("Wrote action_guidance_vi.dart successfully!")
else:
    print("FAILED: Duplicates or forbidden hits remain!")
