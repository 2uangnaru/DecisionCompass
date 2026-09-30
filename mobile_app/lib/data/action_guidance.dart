import '../app_locale.dart';
import 'models/models.dart';

/// The short reflection shown beneath a reading result.
///
/// It is keyed on the **decision mode and which side the reading leaned to**,
/// and on nothing else.
///
/// Earlier it was keyed on the life-area category instead, which had two
/// problems. A KEEP / LET GO reading and a YES / NO reading about the same
/// area produced identical wording, so the one thing the reader actually
/// chose — the question — was the one thing the text ignored. And writing per
/// category meant writing about money and about relationships, which produced
/// lines like *"walk away from situations that drain you"* and *"the signs
/// warmly align for commitment"*. The app does not know what the reader is
/// deciding. It knows the pair they picked and which way the symbols leaned,
/// and this file says only that.
///
/// So: nothing here names money, work, a partner or any third person; nothing
/// tells the reader to start, end, buy, sell or leave anything; and every
/// line is about the reader's own attention rather than about the world.
class ActionGuidance {
  const ActionGuidance({
    required this.title,
    required this.headline,
    required this.shouldDo,
    required this.avoid,
    required this.shouldDoTag,
    required this.avoidTag,
  });

  /// Section title, e.g. "COSMIC GUIDANCE", "CHỈ DẪN HÀNH ĐỘNG".
  final String title;

  /// What the reading leaned toward, in the mode's own terms. One sentence.
  final String headline;

  /// Something to turn over. Never an instruction about the outside world.
  final String shouldDo;

  /// A way of misreading this that is worth naming.
  final String avoid;

  /// Localized label for [shouldDo], e.g. "Do:", "宜:", "Nên:".
  final String shouldDoTag;

  /// Localized label for [avoid], e.g. "Avoid:", "忌:", "Tránh:".
  final String avoidTag;
}

/// Which side of the pair a reading named.
enum _Lean { first, second, balanced }

_Lean _leanOf(ReadingResponse reading) {
  if (reading.status == ReadingStatus.balanced || reading.winner == null) {
    return _Lean.balanced;
  }
  final labels = _englishPair[reading.mode];
  if (labels == null) return _Lean.balanced;
  if (reading.winner == labels.$1) return _Lean.first;
  if (reading.winner == labels.$2) return _Lean.second;
  // A winner the app does not recognise is not guessed at.
  return _Lean.balanced;
}

/// The engine's own wire labels, used only to tell the two sides apart.
const Map<DecisionMode, (String, String)> _englishPair =
    <DecisionMode, (String, String)>{
      DecisionMode.yesNo: ('YES', 'NO'),
      DecisionMode.actWait: ('ACT', 'WAIT'),
      DecisionMode.advanceRetreat: ('ADVANCE', 'RETREAT'),
      DecisionMode.stayGo: ('STAY', 'GO'),
      DecisionMode.keepLetGo: ('KEEP', 'LET GO'),
      DecisionMode.commitWithdraw: ('COMMIT', 'WITHDRAW'),
      DecisionMode.leftRight: ('LEFT', 'RIGHT'),
      DecisionMode.forwardBackward: ('FORWARD', 'BACKWARD'),
    };

/// The guidance for one reading.
///
/// Deterministic: the same mode and the same leaning always produce the same
/// three sentences. There is no date seed and no rotation — the reading's
/// percentages already move from day to day, and rotating the interpretation
/// underneath them would suggest the interpretation had changed when only the
/// wording had.
ActionGuidance resolveActionGuidance({
  required AppLocale locale,
  required ReadingResponse reading,
}) {
  final tags = _tagsFor(locale);
  final table = _copyFor(locale);
  final lean = _leanOf(reading);
  // A retired mode has no guidance of its own; a saved reading in one still
  // gets the balanced reflection rather than borrowing another mode's words.
  final key = lean == _Lean.balanced || reading.mode.legacy
      ? _balancedKey
      : '${reading.mode.wireValue}:${lean == _Lean.first ? 'first' : 'second'}';
  final entry = table[key] ?? table[_balancedKey]!;
  return ActionGuidance(
    title: tags.$1,
    shouldDoTag: tags.$2,
    avoidTag: tags.$3,
    headline: entry.$1,
    shouldDo: entry.$2,
    avoid: entry.$3,
  );
}

const String _balancedKey = 'balanced';

/// (title, shouldDoTag, avoidTag)
(String, String, String) _tagsFor(AppLocale locale) => switch (locale) {
  AppLocale.english => ('COSMIC GUIDANCE', 'Consider:', 'Watch for:'),
  AppLocale.vietnamese => ('CHỈ DẪN HÀNH ĐỘNG', 'Suy ngẫm:', 'Lưu ý:'),
  AppLocale.spanish => ('GUÍA SIMBÓLICA', 'Para pensar:', 'Ojo con:'),
  AppLocale.japanese => ('今日の指針', '考えること:', '気をつけること:'),
  AppLocale.thai => ('แนวทางเชิงสัญลักษณ์', 'ลองพิจารณา:', 'ระวัง:'),
  AppLocale.hindi => ('प्रतीकात्मक मार्गदर्शन', 'सोचें:', 'ध्यान रखें:'),
  AppLocale.simplifiedChinese => ('象征指引', '可以想想:', '留意:'),
};

Map<String, (String, String, String)> _copyFor(AppLocale locale) =>
    switch (locale) {
      AppLocale.english => _en,
      AppLocale.vietnamese => _vi,
      AppLocale.spanish => _es,
      AppLocale.japanese => _ja,
      AppLocale.thai => _th,
      AppLocale.hindi => _hi,
      AppLocale.simplifiedChinese => _zh,
    };

// ---------------------------------------------------------------------------
// The copy. One entry per (mode, side), plus one shared balanced entry.
// Order within each map follows the order the modes appear on Home.
// ---------------------------------------------------------------------------

const Map<String, (String, String, String)>
_en = <String, (String, String, String)>{
  'balanced': (
    'The signals did not lean either way today.',
    'Write down what you already believe, before you look for more signs.',
    'Asking again in another mode until an answer looks like the one you wanted.',
  ),
  'yes_no:first': (
    'Today the signals lean toward openness rather than resistance.',
    'Notice where you were already leaning, and what that tells you.',
    'Treating a symbolic lean as permission to skip your own reasoning.',
  ),
  'yes_no:second': (
    'Today the signals lean toward resistance rather than openness.',
    'Name the hesitation you already feel, plainly, before arguing with it.',
    'Reading resistance as a verdict instead of a reason to look again.',
  ),
  'act_wait:first': (
    'Timing counted alongside everything else, the reading leans toward acting.',
    'Ask what you could begin now that would still be yours tomorrow.',
    'Confusing a well-timed moment with a finished decision.',
  ),
  'act_wait:second': (
    'Timing counted alongside everything else, the reading leans toward waiting.',
    'Let the question sit, and see whether it changes shape by evening.',
    'Mistaking patience for avoidance, or hurry for courage.',
  ),
  'advance_retreat:first': (
    'Recent momentum counted with the rest, the reading leans toward advancing.',
    'Notice what has actually shifted since the start of the week.',
    'Assuming momentum will keep itself going.',
  ),
  'advance_retreat:second': (
    'Recent momentum counted with the rest, the reading leans toward drawing back.',
    'Ask what would really be lost by holding your position a little longer.',
    'Reading a quiet day as a setback.',
  ),
  'stay_go:first': (
    'Staying power counted with the rest, the reading leans toward holding your place.',
    'Consider what the ground you are standing on is actually giving you.',
    'Confusing stillness with being stuck.',
  ),
  'stay_go:second': (
    'Staying power counted with the rest, the reading leans toward moving.',
    'Ask what you would take with you, and what you would set down.',
    'Treating restlessness as a plan.',
  ),
  'keep_let_go:first': (
    'The signals lean toward holding rather than releasing.',
    'Look at what you are holding, and whether you chose it or inherited it.',
    'Holding on from habit and calling it commitment.',
  ),
  'keep_let_go:second': (
    'The signals lean toward releasing rather than holding.',
    'Ask what would have room to grow if your attention were freed.',
    'Reading a symbolic lean as a reason to decide something for someone else.',
  ),
  'commit_withdraw:first': (
    'The week ahead counted with the rest, the reading leans toward committing.',
    'Think in weeks rather than hours, and see if the question survives that.',
    'Mistaking a steady week for a guarantee.',
  ),
  'commit_withdraw:second': (
    'The week ahead counted with the rest, the reading leans toward stepping back out.',
    'Ask what would have to be true for this to feel steadier.',
    'Reading an unsettled week as a permanent state.',
  ),
  'left_right:first': (
    'The polarity counted with the rest, the reading leans inward and receptive.',
    'Give the quieter, less obvious reading of your question some room.',
    'Using a symbolic polarity for anything physical — traffic, routes or safety.',
  ),
  'left_right:second': (
    'The polarity counted with the rest, the reading leans outward and expressive.',
    'Try saying the thing you have been circling, at least to yourself.',
    'Using a symbolic polarity for anything physical — traffic, routes or safety.',
  ),
};

const Map<String, (String, String, String)>
_vi = <String, (String, String, String)>{
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
};

const Map<String, (String, String, String)>
_es = <String, (String, String, String)>{
  'balanced': (
    'Hoy las señales no se inclinaron hacia ningún lado.',
    'Anota lo que ya crees, antes de buscar más señales.',
    'Volver a preguntar en otro modo hasta que salga la respuesta que querías.',
  ),
  'yes_no:first': (
    'Hoy las señales se inclinan más hacia la apertura que hacia la resistencia.',
    'Fíjate hacia dónde ya te inclinabas, y qué te dice eso.',
    'Tomar una inclinación simbólica como permiso para saltarte tu propio razonamiento.',
  ),
  'yes_no:second': (
    'Hoy las señales se inclinan más hacia la resistencia que hacia la apertura.',
    'Nombra con claridad la duda que ya sientes, antes de discutir con ella.',
    'Leer la resistencia como un veredicto y no como un motivo para volver a mirar.',
  ),
  'act_wait:first': (
    'Contando el momento junto con todo lo demás, la lectura se inclina a actuar.',
    'Pregúntate qué podrías empezar ahora que mañana siga siendo tuyo.',
    'Confundir un momento bien elegido con una decisión ya tomada.',
  ),
  'act_wait:second': (
    'Contando el momento junto con todo lo demás, la lectura se inclina a esperar.',
    'Deja reposar la pregunta y mira si cambia de forma al caer la tarde.',
    'Confundir la paciencia con la evasión, o la prisa con el valor.',
  ),
  'advance_retreat:first': (
    'Contando el impulso reciente con el resto, la lectura se inclina a avanzar.',
    'Fíjate en qué ha cambiado de verdad desde el principio de la semana.',
    'Dar por hecho que el impulso se sostiene solo.',
  ),
  'advance_retreat:second': (
    'Contando el impulso reciente con el resto, la lectura se inclina a replegarse.',
    'Pregúntate qué se perdería realmente por mantener la posición un poco más.',
    'Leer un día tranquilo como un retroceso.',
  ),
  'stay_go:first': (
    'Contando la firmeza con el resto, la lectura se inclina a mantener tu sitio.',
    'Piensa qué te está dando realmente el suelo que pisas.',
    'Confundir la quietud con estar atascado.',
  ),
  'stay_go:second': (
    'Contando la firmeza con el resto, la lectura se inclina a moverte.',
    'Pregúntate qué te llevarías contigo y qué dejarías en el suelo.',
    'Tomar la inquietud por un plan.',
  ),
  'keep_let_go:first': (
    'Las señales se inclinan hacia conservar más que hacia soltar.',
    'Mira lo que sostienes y si lo elegiste o simplemente lo heredaste.',
    'Sostener por costumbre y llamarlo compromiso.',
  ),
  'keep_let_go:second': (
    'Las señales se inclinan hacia soltar más que hacia conservar.',
    'Pregúntate qué tendría sitio para crecer si liberaras tu atención.',
    'Leer una inclinación simbólica como motivo para decidir por otra persona.',
  ),
  'commit_withdraw:first': (
    'Contando la semana que viene con el resto, la lectura se inclina a comprometerse.',
    'Piensa en semanas y no en horas, y mira si la pregunta lo resiste.',
    'Confundir una semana estable con una garantía.',
  ),
  'commit_withdraw:second': (
    'Contando la semana que viene con el resto, la lectura se inclina a retirarse.',
    'Pregúntate qué tendría que ser cierto para que esto se sintiera más firme.',
    'Leer una semana inestable como un estado permanente.',
  ),
  'left_right:first': (
    'Contando la polaridad con el resto, la lectura se inclina hacia dentro y receptiva.',
    'Dale sitio a la lectura más callada y menos evidente de tu pregunta.',
    'Usar una polaridad simbólica para el tráfico, las rutas o la seguridad física.',
  ),
  'left_right:second': (
    'Contando la polaridad con el resto, la lectura se inclina hacia fuera y expresiva.',
    'Prueba a decir eso que llevas rondando, aunque sea solo para ti.',
    'Usar una polaridad simbólica para el tráfico, las rutas o la seguridad física.',
  ),
};

const Map<String, (String, String, String)> _ja =
    <String, (String, String, String)>{
      'balanced': (
        '今日は、どちらにも傾きませんでした。',
        'さらに兆しを探す前に、すでに自分が信じていることを書き出してみてください。',
        '望んだ答えが出るまで、別のモードで問い直すこと。',
      ),
      'yes_no:first': (
        '今日は、抵抗よりも受け入れのほうに傾いています。',
        'もともと自分がどちらに傾いていたか、そしてそれが何を示すかを見てください。',
        '象徴的な傾きを、自分で考えることを省く口実にすること。',
      ),
      'yes_no:second': (
        '今日は、受け入れよりも抵抗のほうに傾いています。',
        'そのためらいと言い争う前に、まずはっきり言葉にしてみてください。',
        '抵抗を判決として読むこと。それは見直すきっかけにすぎません。',
      ),
      'act_wait:first': (
        'タイミングもほかの要素も合わせて見ると、今回は動くほうに傾いています。',
        '明日も自分のものであり続けるものを、いま何か始められるか考えてみてください。',
        'かみ合った時機を、決まった結論と取り違えること。',
      ),
      'act_wait:second': (
        'タイミングもほかの要素も合わせて見ると、今回は待つほうに傾いています。',
        '問いをいったん置いて、夕方までに形が変わるか見てください。',
        '待つことを避けること、急ぐことを勇気と取り違えること。',
      ),
      'advance_retreat:first': (
        '近ごろの勢いもほかの要素も合わせて見ると、今回は進むほうに傾いています。',
        '週の初めから実際に何が動いたか、確かめてみてください。',
        'その勢いがひとりでに続くと決めてかかること。',
      ),
      'advance_retreat:second': (
        '近ごろの勢いもほかの要素も合わせて見ると、今回は退くほうに傾いています。',
        'もう少しいまの位置に留まると、実際には何を失うのか考えてみてください。',
        '静かな一日を後退と読むこと。',
      ),
      'stay_go:first': (
        '留まる力もほかの要素も合わせて見ると、今回はその場を保つほうに傾いています。',
        'いま立っている場所が実際に何を与えているか考えてみてください。',
        '静けさを、行き詰まりと取り違えること。',
      ),
      'stay_go:second': (
        '留まる力もほかの要素も合わせて見ると、今回は動くほうに傾いています。',
        '何を携えていき、何を置いていくのかを考えてみてください。',
        '落ち着かなさを、計画と取り違えること。',
      ),
      'keep_let_go:first': (
        '手放すより、持ち続けるほうに傾いています。',
        'いま抱えているものを、自分で選んだのか受け継いだのか見てください。',
        '習慣で抱えていることを、思い入れと呼ぶこと。',
      ),
      'keep_let_go:second': (
        '持ち続けるより、手放すほうに傾いています。',
        '意識が軽くなれば何が育つ余地を得るか、考えてみてください。',
        '象徴的な傾きを、誰か他の人のことを決める理由にすること。',
      ),
      'commit_withdraw:first': (
        'これから一週間もほかの要素も合わせて見ると、今回は踏み込むほうに傾いています。',
        '時間ではなく週の単位で考え、問いがそれに耐えるか見てください。',
        '安定した一週間を、保証と取り違えること。',
      ),
      'commit_withdraw:second': (
        'これから一週間もほかの要素も合わせて見ると、今回は引くほうに傾いています。',
        'これがもっと安定して感じられるには何が必要か、考えてみてください。',
        '揺らいだ一週間を、変わらない状態と読むこと。',
      ),
      'left_right:first': (
        '極性もほかの要素も合わせて見ると、今回は内向きで受け取る側に傾いています。',
        '問いの、静かで目立たないほうの読み方にも場所を与えてください。',
        '象徴的な極性を、交通・道順・身体の安全に使うこと。',
      ),
      'left_right:second': (
        '極性もほかの要素も合わせて見ると、今回は外向きで表に出す側に傾いています。',
        'ずっと言いあぐねていたことを、せめて自分にだけでも言ってみてください。',
        '象徴的な極性を、交通・道順・身体の安全に使うこと。',
      ),
    };

const Map<String, (String, String, String)>
_th = <String, (String, String, String)>{
  'balanced': (
    'วันนี้สัญญาณไม่เอนไปทางใดทางหนึ่ง',
    'ลองเขียนสิ่งที่คุณเชื่ออยู่แล้วออกมา ก่อนจะไปหาสัญญาณเพิ่ม',
    'ถามซ้ำในโหมดอื่นไปเรื่อย ๆ จนกว่าจะได้คำตอบที่อยากได้',
  ),
  'yes_no:first': (
    'วันนี้สัญญาณเอนไปทางการเปิดรับมากกว่าการต้านทาน',
    'สังเกตว่าคุณเอนไปทางไหนอยู่แล้ว และนั่นบอกอะไร',
    'ใช้การเอนเชิงสัญลักษณ์เป็นข้ออ้างข้ามการคิดด้วยตัวเอง',
  ),
  'yes_no:second': (
    'วันนี้สัญญาณเอนไปทางการต้านทานมากกว่าการเปิดรับ',
    'เรียกชื่อความลังเลที่มีอยู่ให้ชัด ก่อนจะเถียงกับมัน',
    'อ่านการต้านทานเป็นคำตัดสิน แทนที่จะเป็นเหตุให้กลับมามองใหม่',
  ),
  'act_wait:first': (
    'เมื่อนับจังหวะเวลารวมกับปัจจัยอื่น ๆ การอ่านครั้งนี้เอนไปทางลงมือ',
    'ลองถามว่าตอนนี้เริ่มอะไรได้ ที่พรุ่งนี้ยังเป็นของคุณอยู่',
    'สับสนระหว่างจังหวะที่ดีกับการตัดสินใจที่จบแล้ว',
  ),
  'act_wait:second': (
    'เมื่อนับจังหวะเวลารวมกับปัจจัยอื่น ๆ การอ่านครั้งนี้เอนไปทางรอ',
    'ปล่อยให้คำถามนิ่งไว้ แล้วดูว่าพอตกเย็นมันเปลี่ยนรูปไหม',
    'สับสนระหว่างความอดทนกับการหลบเลี่ยง หรือความรีบกับความกล้า',
  ),
  'advance_retreat:first': (
    'เมื่อนับแรงส่งช่วงที่ผ่านมารวมกับส่วนที่เหลือ การอ่านครั้งนี้เอนไปทางเดินหน้า',
    'สังเกตว่าตั้งแต่ต้นสัปดาห์มีอะไรขยับจริง ๆ บ้าง',
    'คิดไปเองว่าแรงส่งนี้จะคงอยู่ได้ด้วยตัวมันเอง',
  ),
  'advance_retreat:second': (
    'เมื่อนับแรงส่งช่วงที่ผ่านมารวมกับส่วนที่เหลือ การอ่านครั้งนี้เอนไปทางถอยกลับ',
    'ลองถามว่าถ้าอยู่ที่เดิมอีกสักพัก จริง ๆ แล้วเสียอะไรไป',
    'อ่านวันที่เงียบลงว่าเป็นการถอยหลัง',
  ),
  'stay_go:first': (
    'เมื่อนับความมั่นคงรวมกับส่วนที่เหลือ การอ่านครั้งนี้เอนไปทางอยู่ที่เดิม',
    'ลองคิดว่าพื้นที่คุณยืนอยู่ให้อะไรกับคุณจริง ๆ บ้าง',
    'สับสนระหว่างความนิ่งกับการติดอยู่กับที่',
  ),
  'stay_go:second': (
    'เมื่อนับความมั่นคงรวมกับส่วนที่เหลือ การอ่านครั้งนี้เอนไปทางขยับ',
    'ลองถามว่าจะหยิบอะไรติดตัวไป และจะวางอะไรลง',
    'เอาความกระวนกระวายมาเป็นแผน',
  ),
  'keep_let_go:first': (
    'สัญญาณเอนไปทางการเก็บไว้มากกว่าการปล่อย',
    'มองสิ่งที่ถืออยู่ ว่าคุณเลือกมันเอง หรือรับช่วงมา',
    'ถือไว้เพราะความเคยชิน แล้วเรียกมันว่าความผูกพัน',
  ),
  'keep_let_go:second': (
    'สัญญาณเอนไปทางการปล่อยมากกว่าการเก็บไว้',
    'ลองถามว่าถ้าใจว่างขึ้น อะไรจะมีที่ให้เติบโต',
    'อ่านการเอนเชิงสัญลักษณ์เป็นเหตุผลในการตัดสินใจแทนคนอื่น',
  ),
  'commit_withdraw:first': (
    'เมื่อนับสัปดาห์ข้างหน้ารวมกับส่วนที่เหลือ การอ่านครั้งนี้เอนไปทางผูกพัน',
    'ลองคิดเป็นสัปดาห์แทนเป็นชั่วโมง แล้วดูว่าคำถามยังอยู่ไหม',
    'สับสนระหว่างสัปดาห์ที่นิ่งกับการรับประกัน',
  ),
  'commit_withdraw:second': (
    'เมื่อนับสัปดาห์ข้างหน้ารวมกับส่วนที่เหลือ การอ่านครั้งนี้เอนไปทางถอนตัว',
    'ลองถามว่าต้องมีอะไรเป็นจริง เรื่องนี้ถึงจะรู้สึกมั่นคงขึ้น',
    'อ่านสัปดาห์ที่คลอนแคลนว่าเป็นสภาพถาวร',
  ),
  'left_right:first': (
    'เมื่อนับขั้วรวมกับส่วนที่เหลือ การอ่านครั้งนี้เอนไปทางด้านในและรับเข้ามา',
    'เปิดที่ให้กับการตีความคำถามแบบเงียบ ๆ ที่ไม่ชัดเจนนัก',
    'ใช้ขั้วเชิงสัญลักษณ์กับการจราจร การหาเส้นทาง หรือความปลอดภัยทางกาย',
  ),
  'left_right:second': (
    'เมื่อนับขั้วรวมกับส่วนที่เหลือ การอ่านครั้งนี้เอนไปทางด้านนอกและแสดงออก',
    'ลองพูดสิ่งที่วนอยู่ในใจออกมา อย่างน้อยก็กับตัวเอง',
    'ใช้ขั้วเชิงสัญลักษณ์กับการจราจร การหาเส้นทาง หรือความปลอดภัยทางกาย',
  ),
};

const Map<String, (String, String, String)>
_hi = <String, (String, String, String)>{
  'balanced': (
    'आज संकेत किसी एक ओर नहीं झुके।',
    'और संकेत ढूँढ़ने से पहले लिखिए कि आप पहले से क्या मानते हैं।',
    'मनचाहा उत्तर मिलने तक दूसरे मोड में बार-बार पूछते रहना।',
  ),
  'yes_no:first': (
    'आज संकेत प्रतिरोध से अधिक खुलेपन की ओर झुके हैं।',
    'देखिए आप पहले से किस ओर झुके थे, और वह क्या बताता है।',
    'प्रतीकात्मक झुकाव को अपनी सोच छोड़ देने की छूट मान लेना।',
  ),
  'yes_no:second': (
    'आज संकेत खुलेपन से अधिक प्रतिरोध की ओर झुके हैं।',
    'जो झिझक पहले से है, उससे बहस करने से पहले उसे साफ़ नाम दीजिए।',
    'प्रतिरोध को फ़ैसला मान लेना, जबकि वह दोबारा देखने का कारण है।',
  ),
  'act_wait:first': (
    'समय और बाकी सब को साथ गिनने पर, यह पाठ करने की ओर झुकता है।',
    'सोचिए अभी क्या शुरू कर सकते हैं जो कल भी आपका ही रहे।',
    'सही समय को पूरा हो चुका निर्णय समझ लेना।',
  ),
  'act_wait:second': (
    'समय और बाकी सब को साथ गिनने पर, यह पाठ रुकने की ओर झुकता है।',
    'प्रश्न को ठहरने दीजिए, और देखिए शाम तक उसका रूप बदलता है या नहीं।',
    'धैर्य को टालना समझ लेना, या जल्दबाज़ी को साहस।',
  ),
  'advance_retreat:first': (
    'हाल की गति और बाकी सब को साथ गिनने पर, यह पाठ आगे बढ़ने की ओर झुकता है।',
    'देखिए सप्ताह की शुरुआत से असल में क्या बदला है।',
    'यह मान लेना कि यह गति अपने आप बनी रहेगी।',
  ),
  'advance_retreat:second': (
    'हाल की गति और बाकी सब को साथ गिनने पर, यह पाठ पीछे लौटने की ओर झुकता है।',
    'पूछिए कि थोड़ी देर और वहीं टिके रहने से सचमुच क्या जाता है।',
    'एक शांत दिन को पीछे हटना मान लेना।',
  ),
  'stay_go:first': (
    'टिके रहने की ताक़त और बाकी सब को साथ गिनने पर, यह पाठ अपनी जगह बनाए रखने की ओर झुकता है।',
    'सोचिए जिस ज़मीन पर आप खड़े हैं वह असल में आपको क्या दे रही है।',
    'ठहराव को अटक जाना समझ लेना।',
  ),
  'stay_go:second': (
    'टिके रहने की ताक़त और बाकी सब को साथ गिनने पर, यह पाठ हिलने की ओर झुकता है।',
    'पूछिए आप साथ क्या ले जाएँगे, और क्या नीचे रख देंगे।',
    'बेचैनी को योजना मान लेना।',
  ),
  'keep_let_go:first': (
    'संकेत छोड़ने से अधिक थामे रखने की ओर झुके हैं।',
    'जो थामे हैं उसे देखिए — वह आपका चुना हुआ है या विरासत में मिला।',
    'आदत से थामे रहना और उसे लगाव कह देना।',
  ),
  'keep_let_go:second': (
    'संकेत थामे रखने से अधिक छोड़ने की ओर झुके हैं।',
    'पूछिए ध्यान हल्का हो जाए तो किसे बढ़ने की जगह मिलेगी।',
    'प्रतीकात्मक झुकाव को किसी और के लिए निर्णय लेने का कारण बनाना।',
  ),
  'commit_withdraw:first': (
    'आने वाले सप्ताह और बाकी सब को साथ गिनने पर, यह पाठ प्रतिबद्ध होने की ओर झुकता है।',
    'घंटों के बजाय सप्ताहों में सोचिए, और देखिए प्रश्न टिकता है या नहीं।',
    'एक स्थिर सप्ताह को गारंटी समझ लेना।',
  ),
  'commit_withdraw:second': (
    'आने वाले सप्ताह और बाकी सब को साथ गिनने पर, यह पाठ अलग होने की ओर झुकता है।',
    'पूछिए क्या सच होना चाहिए कि यह अधिक स्थिर लगे।',
    'एक डगमगाते सप्ताह को स्थायी स्थिति मान लेना।',
  ),
  'left_right:first': (
    'ध्रुवता और बाकी सब को साथ गिनने पर, यह पाठ भीतर की ओर, ग्रहणशील झुकता है।',
    'अपने प्रश्न के शांत, कम स्पष्ट पाठ को भी जगह दीजिए।',
    'प्रतीकात्मक ध्रुवता को यातायात, रास्ते या शारीरिक सुरक्षा में इस्तेमाल करना।',
  ),
  'left_right:second': (
    'ध्रुवता और बाकी सब को साथ गिनने पर, यह पाठ बाहर की ओर, अभिव्यक्तिपूर्ण झुकता है।',
    'जिस बात के इर्द-गिर्द घूम रहे हैं उसे कहिए, कम से कम अपने आप से।',
    'प्रतीकात्मक ध्रुवता को यातायात, रास्ते या शारीरिक सुरक्षा में इस्तेमाल करना।',
  ),
};

const Map<String, (String, String, String)> _zh =
    <String, (String, String, String)>{
      'balanced': (
        '今天的信号没有偏向任何一边。',
        '在继续找线索之前，先写下你本来就相信的事。',
        '换个模式一再追问，直到出现你想要的答案。',
      ),
      'yes_no:first': (
        '今天的信号偏向开放，而非阻力。',
        '留意你原本就偏向哪一边，以及这说明了什么。',
        '把象征性的偏向当成可以略过自己思考的许可。',
      ),
      'yes_no:second': (
        '今天的信号偏向阻力，而非开放。',
        '在与那份犹豫争辩之前，先把它清楚地说出来。',
        '把阻力读成判决，而不是重新审视的理由。',
      ),
      'act_wait:first': (
        '把时机和其余因素一并计入，这次的结果偏向行动。',
        '想想现在可以开始什么，明天仍然属于你。',
        '把合适的时机误当成已经做完的决定。',
      ),
      'act_wait:second': (
        '把时机和其余因素一并计入，这次的结果偏向等待。',
        '让问题先放一放，看它到傍晚会不会换个样子。',
        '把忍耐当成回避，或把匆忙当成勇气。',
      ),
      'advance_retreat:first': (
        '把近日的势头和其余因素一并计入，这次的结果偏向进取。',
        '看看从本周开始到现在，究竟有什么真的动了。',
        '以为这股势头会自己延续下去。',
      ),
      'advance_retreat:second': (
        '把近日的势头和其余因素一并计入，这次的结果偏向退守。',
        '问问再守一阵子，实际上会失去什么。',
        '把安静的一天读成退步。',
      ),
      'stay_go:first': (
        '把稳住的力量和其余因素一并计入，这次的结果偏向守住原位。',
        '想想脚下这片地方，实际上给了你什么。',
        '把安静误当成被困住。',
      ),
      'stay_go:second': (
        '把稳住的力量和其余因素一并计入，这次的结果偏向移动。',
        '问问你会带走什么，又会放下什么。',
        '把心神不宁当成一个计划。',
      ),
      'keep_let_go:first': (
        '信号偏向留住，而非放开。',
        '看看你正握着的东西，是自己选的，还是接手来的。',
        '出于习惯握着，却称之为投入。',
      ),
      'keep_let_go:second': (
        '信号偏向放开，而非留住。',
        '问问如果心思空出来，什么会有生长的余地。',
        '把象征性的偏向当成替别人做决定的理由。',
      ),
      'commit_withdraw:first': (
        '把未来一周和其余因素一并计入，这次的结果偏向投入。',
        '以周为单位而不是以小时来想，看这个问题经不经得住。',
        '把平稳的一周误当成保证。',
      ),
      'commit_withdraw:second': (
        '把未来一周和其余因素一并计入，这次的结果偏向抽离。',
        '问问要有什么成立，这件事才会显得更稳。',
        '把动荡的一周读成永久的状态。',
      ),
      'left_right:first': (
        '把极性和其余因素一并计入，这次的结果偏向向内、偏接纳。',
        '给你那个更安静、更不明显的解读留点位置。',
        '把象征性的极性用在交通、找路或人身安全上。',
      ),
      'left_right:second': (
        '把极性和其余因素一并计入，这次的结果偏向向外、偏表达。',
        '试着把一直绕着不说的话说出来，至少说给自己听。',
        '把象征性的极性用在交通、找路或人身安全上。',
      ),
    };
