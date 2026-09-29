# Core UI copy — translation matrix v0.1

Stable editorial keys for Claude to map into Flutter localization. Do not concatenate the translated parts of a sentence. `{category}`, `{period}`, `{color1}`, `{color2}`, `{percent}`, and `{time}` are placeholders; their values must be localized separately. `en` is the current approved English sense. `es` aims for neutral international Spanish.

This is the **core-screen batch**, not the whole-app translation: the 30 Home descriptions, 64 rotating energy insights, 20 shade names, full safety sheet, all error variants and all accessibility labels still need a dedicated parity pass before enabling any non-English locale in a release. Vietnamese (`vi`) is in `CORE_COPY_VI.md`; Hindi (`hi-IN`) and Simplified Chinese (`zh-Hans-CN`) are in `CORE_COPY_HI_ZH.md`.

| Key | English (`en`) | Japanese (`ja`) | Spanish (`es`) | Thai (`th`) |
|---|---|---|---|---|
| appName | AstraCue | AstraCue | AstraCue | AstraCue |
| continueAction | Continue | 続ける | Continuar | ดำเนินต่อ |
| backAction | Back | 戻る | Volver | กลับ |
| closeAction | Close | 閉じる | Cerrar | ปิด |
| tryAgain | Try Again | もう一度試す | Volver a intentar | ลองอีกครั้ง |
| responsibleUse | Responsible Use | 安全な使い方 | Uso responsable | การใช้งานอย่างรับผิดชอบ |
| history | History | 履歴 | Historial | ประวัติ |
| onboardingTitle | Listen to the signals of the universe and your intuition. | 宇宙のサインと、あなたの直感に耳を澄ます。 | Escucha las señales del universo y tu intuición. | ฟังสัญญาณจากจักรวาลและสัญชาตญาณของคุณ |
| onboardingLanguageHint | Prefer another language? Tap the globe above. You can change it anytime. | 別の言語で使いたい方は、上の地球アイコンをタップしてください。言語はいつでも変更できます。 | ¿Prefieres otro idioma? Toca el icono del globo de arriba. Puedes cambiarlo cuando quieras. | อยากใช้ภาษาอื่นไหม? แตะไอคอนรูปโลกด้านบน คุณเปลี่ยนภาษาได้ทุกเมื่อ |
| yourProfile | YOUR PROFILE | あなたのプロフィール | TU PERFIL | โปรไฟล์ของคุณ |
| signAfterBirthDate | YOUR SIGN APPEARS AFTER YOUR BIRTH DATE | 生年月日を入力すると星座が表示されます | TU SIGNO APARECERÁ AL INDICAR TU FECHA DE NACIMIENTO | ใส่วันเกิดเพื่อดูราศีของคุณ |
| buildPattern | Discover your unique energy. | あなただけのエネルギーを見つけましょう。 | Descubre tu propia energía. | ค้นพบพลังงานเฉพาะตัวของคุณ |
| profileExplainer | Shapes the cycles used during analysis. | 分析時に用いる周期を導き出します。 | Define los ciclos utilizados en el análisis. | กำหนดรอบเวลาที่ใช้ในการวิเคราะห์ |
| nameField | Name | 名前 | Nombre | ชื่อ |
| dateOfBirth | Date of birth | 生年月日 | Fecha de nacimiento | วันเกิด |
| selectBirthDate | Select your date of birth | 生年月日を選択 | Selecciona tu fecha de nacimiento | เลือกวันเกิดของคุณ |
| birthDateRequired | Select your birth date to continue. | 続けるには生年月日を選択してください。 | Selecciona tu fecha de nacimiento para continuar. | โปรดเลือกวันเกิดก่อนดำเนินต่อ |
| birthTimeUnknown | Birth time unknown | 出生時刻が不明 | No sé mi hora de nacimiento | ไม่ทราบเวลาเกิด |
| birthTimeUnknownDetail | If you don't know your birth time, the algorithm will use the time window closest to your personality. | 出生時刻が分からない場合、あなたの性格に最も近い時間帯を用いて算出します。 | Si no sabes tu hora de nacimiento, el algoritmo usará el horario más cercano a tu personalidad. | หากคุณไม่ทราบเวลาเกิด ระบบจะใช้ช่วงเวลาที่ใกล้เคียงกับบุคลิกของคุณมากที่สุดในการคำนวณ |
| timeOfBirth | Time of birth | 出生時刻 | Hora de nacimiento | เวลาเกิด |
| countryOfBirth | Country of birth | 出生国 | País de nacimiento | ประเทศที่เกิด |
| selectBirthCountry | Search and select a country | 国を検索して選択 | Busca y selecciona un país | ค้นหาและเลือกประเทศ |
| birthCountryRequired | Select your country of birth to continue. | 続けるには出生国を選択してください。 | Selecciona tu país de nacimiento para continuar. | โปรดเลือกประเทศที่เกิดก่อนดำเนินต่อ |
| createCompass | Create My Compass | 私のコンパスを作る | Crear mi brújula | สร้างเข็มทิศของฉัน |
| birthPrivacyPrototype | Your birth details remain private in this prototype. | この試作版では、出生情報は非公開のまま保たれます。 | En este prototipo, tus datos de nacimiento se mantienen privados. | ในต้นแบบนี้ ข้อมูลการเกิดของคุณจะยังเป็นส่วนตัว |
| homeEyebrow | A COMPASS TO GUIDE YOUR PATH | あなたを導く、心の羅針盤 | UNA BRÚJULA QUE GUÍA TU CAMINO | เข็มทิศนำทางเพื่อช่วยคุณ |
| homeTitle | Caught between choices? | 選択肢の間で迷っていますか？ | ¿No sabes qué camino elegir? | กำลังลังเลระหว่างตัวเลือกใช่ไหม |
| areaQuestion | What area is this about? | どんなことについてですか？ | ¿Sobre qué tema? | เรื่องที่คุณกำลังคิดอยู่เกี่ยวกับอะไร |
| findDirection | Find Your Path | 進むべき道を見つける | Encuentra tu camino | ค้นหาเส้นทางของคุณ |
| todaySignals | TODAY’S SIGNALS | 今日のサイン | SEÑALES DE HOY | สัญญาณวันนี้ |
| dailyEnergy | Daily energy | 今日のエネルギー | Energía de hoy | พลังงานวันนี้ |
| yourColorsToday | Your colors today: | 今日の色： | Tus colores de hoy: | สีของคุณวันนี้: |
| luckyNumberToday | Lucky number today: | 今日のラッキーナンバー： | Número de la suerte de hoy: | เลขนำโชควันนี้: |
| categoryOverall | Overall | 全体 | General | ภาพรวม |
| categoryLove | Love & Relationships | 恋愛・人間関係 | Amor y relaciones | ความรักและความสัมพันธ์ |
| categoryCareer | Career | 仕事 | Trabajo | การงาน |
| categoryMoney | Finances | 財務 | Finanzas | การเงิน |
| categoryStudy | Study & Growth | 学び・成長 | Estudios y crecimiento | การเรียนรู้และเติบโต |
| categoryFriends | Friends | 友人 | Amistades | เพื่อน |
| categoryOther | Something Else | その他 | Otro tema | เรื่องอื่น ๆ |
| periodQuestion | When are you considering it? | いつのことを考えていますか？ | ¿Para qué momento lo estás considerando? | คุณกำลังคิดถึงช่วงเวลาไหน |
| periodNow | NOW | 今 | AHORA | ตอนนี้ |
| periodMorning | Morning | 朝 | Mañana | ช่วงเช้า |
| periodMidday | Midday | 昼 | Mediodía | ช่วงเที่ยง |
| periodAfternoon | Afternoon | 午後 | Tarde | ช่วงบ่าย |
| periodEvening | Evening | 夜 | Noche | ช่วงเย็น |
| periodPassed | Passed | 終了 | Pasado | ผ่านไปแล้ว |
| periodHasPassed | {period} has passed. Choose another time. | {period}は過ぎました。別の時間帯を選んでください。 | {period} ya pasó. Elige otro momento. | ช่วง{period}ผ่านไปแล้ว โปรดเลือกช่วงเวลาอื่น |
| reveal | ANALYZE | 分析する | ANALIZAR | วิเคราะห์ |
| aligning | ALIGNING | 調整中 | ALINEANDO | กำลังปรับสัญญาณ |
| tapWhenReady | Tap when you’re ready | 準備ができたらタップ | Toca cuando estés listo | แตะเมื่อคุณพร้อม |
| keepChoiceInMind | Keep the choice clearly in your mind. | 迷っていることを心に思い浮かべてください。 | Ten presente la decisión que estás considerando. | นึกถึงสิ่งที่คุณกำลังลังเลให้ชัดเจน |
| ritualSafety | For everyday reflection only • Never for medical, investing, borrowing, political, or harmful choices. | 日常の振り返り専用です。医療・投資・借入・政治・危険な判断には使わないでください。 | Solo para reflexionar sobre asuntos cotidianos. Nunca para decisiones médicas, de inversión, de préstamos, políticas o que puedan causar daño. | ใช้เพื่อทบทวนเรื่องทั่วไปในชีวิตประจำวันเท่านั้น ห้ามใช้ตัดสินใจเรื่องการแพทย์ การลงทุน การกู้ยืม การเมือง หรือสิ่งที่อาจก่ออันตราย |
| loadingLocalMoment | READING YOUR LOCAL MOMENT | 今この場所の瞬間を読み解いています | LEYENDO TU MOMENTO LOCAL | กำลังอ่านสัญญาณ ณ เวลาของคุณ |
| loadingReassurance | Please wait a moment — cosmic signals are coming into focus. | 少々お待ちください。宇宙のサインを整えています。 | Un momento, por favor: las señales cósmicas se están alineando. | โปรดรอสักครู่ สัญญาณจากจักรวาลกำลังรวมตัวกัน |
| readingForCategory | Reading for {category} | {category}について読み解いています | Lectura sobre {category} | กำลังอ่านเรื่อง{category} |
| yourDirection | YOUR DIRECTION | あなたへの方向性 | TU DIRECCIÓN | แนวทางของคุณ |
| resultBasis | Based on the cosmic energy and signals aligned with you at this moment. | この瞬間のあなたに寄り添うエネルギーと宇宙のサインに基づいて。 | Basado en la energía y las señales cósmicas para ti en este momento. | อิงตามพลังงานและสัญญาณจักรวาลที่สอดคล้องกับคุณในขณะนี้ |
| percentageCaveat | Percentages show symbolic alignment, not a real-world probability. | パーセンテージは象徴的な一致度であり、現実の確率ではありません。 | Los porcentajes muestran una afinidad simbólica, no una probabilidad real. | เปอร์เซ็นต์แสดงความสอดคล้องเชิงสัญลักษณ์ ไม่ใช่ความน่าจะเป็นจริง |
| balancedHeading | EVENLY BALANCED | どちらも均衡 | EQUILIBRIO | สมดุลทั้งสองด้าน |
| balancedResult | BALANCED | 均衡 | EQUILIBRADO | สมดุล |
| balancedExplanation | Neither side leads right now. This is a reading of balance, not a hidden answer. | 今はどちらも優勢ではありません。これは均衡を示すもので、隠れた答えではありません。 | Por ahora, ninguna opción predomina. La lectura indica equilibrio, no una respuesta oculta. | ตอนนี้ยังไม่มีด้านใดเด่นกว่า ผลนี้บอกถึงความสมดุล ไม่ใช่คำตอบที่ซ่อนอยู่ |
| currentMoment | This reading reflects your current moment. | このリーディングは今この瞬間を映しています。 | Esta lectura refleja tu momento actual. | ผลนี้สะท้อนช่วงเวลาปัจจุบันของคุณ |
| luckyTimesCaveat | Each percentage is a symbolic timing alignment score, not a probability or chance of success. The windows are scored independently, so they do not add up to 100%. | 各パーセンテージは時間帯との象徴的な一致度で、成功確率ではありません。時間帯ごとに独立して算出するため、合計は100%になりません。 | Cada porcentaje indica una afinidad simbólica con ese horario; no es una probabilidad ni una posibilidad de éxito. Los intervalos se valoran por separado, por lo que no suman 100%. | แต่ละเปอร์เซ็นต์คือคะแนนความสอดคล้องเชิงสัญลักษณ์ของช่วงเวลา ไม่ใช่โอกาสสำเร็จหรือความน่าจะเป็น แต่ละช่วงคำนวณแยกกัน จึงไม่จำเป็นต้องรวมเป็น 100% |
| tryAnotherDirection | Try Another Direction | 別の方向性を見る | Explorar otra dirección | ดูแนวทางอื่น |
| viewHistory | View in History | 履歴を見る | Ver en el historial | ดูในประวัติ |
| yourReadings | Your readings | あなたの履歴 | Tus lecturas | ผลการอ่านของคุณ |
| noReadings | No readings yet. Reveal your first direction to start your history. | まだ履歴はありません。最初の方向性を見て、履歴を始めましょう。 | Aún no hay lecturas. Explora tu primera dirección para iniciar tu historial. | ยังไม่มีผลการอ่าน ลองดูแนวทางครั้งแรกเพื่อเริ่มบันทึกประวัติ |
| historySnapshot | Results are saved as snapshots and never rerolled. | 結果はその時点の記録として保存され、再計算されません。 | Los resultados se guardan tal como aparecieron; no se vuelven a calcular. | ผลจะถูกบันทึกตามที่แสดงในขณะนั้น และไม่คำนวณใหม่ |
| everydayReflection | For everyday reflection only. Important decisions need real information and qualified help. | 日常の振り返り専用です。重要な判断には事実に基づく情報と専門家の助けが必要です。 | Solo para reflexionar sobre asuntos cotidianos. Las decisiones importantes requieren información real y ayuda profesional. | ใช้เพื่อทบทวนเรื่องทั่วไปในชีวิตประจำวันเท่านั้น การตัดสินใจสำคัญต้องอาศัยข้อมูลจริงและคำแนะนำจากผู้เชี่ยวชาญ |

## Important wording decisions

- Full-sentence headings in `LUCKY_TIMES_HEADINGS.md` preserve the user's requested “luckiest” framing without ungrammatical period interpolation; the score caveat remains visible immediately below the windows.
- `periodEvening` is a daypart label, not an exact clock range. Claude should use the app's actual local daypart boundaries and locale-aware time format rather than translating `PM`/`AM` by string replacement.
- Japanese/Thai result labels need visual QA at 360dp. Do not shrink the result until unreadable simply to preserve the English 114px treatment. Keep the winner visually dominant over the percentage.
- The English source currently uses “Your Luckiest Times This {period}”; that template is ungrammatical for some periods. The new key intentionally says “in {period}”; it is a copy correction, not a formula change.
- Current onboarding says location permission is unnecessary. If the code later begins requesting location, update all four versions of that sentence together.
