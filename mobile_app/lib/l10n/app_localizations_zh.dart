// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'AstraCue';

  @override
  String get continueAction => '继续';

  @override
  String get backAction => '返回';

  @override
  String get closeAction => '关闭';

  @override
  String get tryAgain => '重试';

  @override
  String get responsibleUse => '安全使用说明';

  @override
  String get history => '历史记录';

  @override
  String get onboardingTitle => '聆听宇宙的信号与你的直觉。';

  @override
  String get onboardingLanguageHint => '点击上方的地球图标以切换语言。';

  @override
  String get yourProfile => '你的资料';

  @override
  String get signAfterBirthDate => '输入出生日期后，将显示你的星座';

  @override
  String get buildPattern => '探索属于你的专属能量。';

  @override
  String get profileExplainer => '定格分析时所依据的能量周期。';

  @override
  String get nameField => '姓名';

  @override
  String get dateOfBirth => '出生日期';

  @override
  String get selectBirthDate => '选择出生日期';

  @override
  String get birthDateRequired => '请选择出生日期后继续。';

  @override
  String get birthTimeUnknown => '出生时间未知';

  @override
  String get birthTimeUnknownDetail => '若不知出生时间，算法将采用与你性格最契合的时段进行测算。';

  @override
  String get timeOfBirth => '出生时间';

  @override
  String get countryOfBirth => '出生国家';

  @override
  String get selectBirthCountry => '搜索并选择国家';

  @override
  String get birthCountryRequired => '请选择出生国家后继续。';

  @override
  String get createCompass => '创建我的指引罗盘';

  @override
  String get birthPrivacyPrototype => '在此原型版本中，你的出生信息将保持私密。';

  @override
  String get homeEyebrow => '指引方向的专属罗盘';

  @override
  String get homeTitle => '正在选择之间犹豫吗？';

  @override
  String get areaQuestion => '这与哪方面有关？';

  @override
  String get findDirection => '寻找你的专属方向';

  @override
  String get todaySignals => '今日信号';

  @override
  String get dailyEnergy => '今日能量';

  @override
  String get yourColorsToday => '今日属于你的颜色：';

  @override
  String get luckyNumberToday => '今日幸运数字：';

  @override
  String get categoryOverall => '综合';

  @override
  String get categoryLove => '爱情与人际关系';

  @override
  String get categoryCareer => '事业';

  @override
  String get categoryMoney => '财务';

  @override
  String get categoryStudy => '学习与成长';

  @override
  String get categoryFriends => '朋友';

  @override
  String get categoryOther => '其他事情';

  @override
  String get periodQuestion => '你考虑的是哪个时段？';

  @override
  String get periodNow => '现在';

  @override
  String get periodMorning => '上午';

  @override
  String get periodMidday => '中午';

  @override
  String get periodAfternoon => '下午';

  @override
  String get periodEvening => '晚间';

  @override
  String get periodPassed => '已过';

  @override
  String periodHasPassed(String period) {
    return '$period已经过去，请选择其他时段。';
  }

  @override
  String get reveal => '开始分析';

  @override
  String get aligning => '正在对齐信号';

  @override
  String get tapWhenReady => '准备好后轻点';

  @override
  String get keepChoiceInMind => '请在心中明确你正在考虑的选择。';

  @override
  String get ritualSafety => '仅供日常自我反思使用 • 不可用于医疗、投资、借贷、政治或可能造成伤害的决定。';

  @override
  String get loadingLocalMoment => '正在解读你此刻的信号';

  @override
  String get loadingReassurance => '请稍候片刻——当下的宇宙信号正在汇聚。';

  @override
  String readingForCategory(String category) {
    return '正在解读$category';
  }

  @override
  String get yourDirection => '给你的方向';

  @override
  String get resultBasis => '基于此刻属于你的能量与宇宙信号。';

  @override
  String get percentageCaveat => '百分比表示象征性的契合度，并非现实中的概率。';

  @override
  String get balancedHeading => '两边势均力敌';

  @override
  String get balancedResult => '平衡';

  @override
  String get balancedExplanation => '此刻没有哪一边更占优势。这表示平衡，并不暗示隐藏的答案。';

  @override
  String get currentMoment => '本次解读反映的是你当前的时刻。';

  @override
  String get luckyTimesCaveat =>
      '每个百分比都是该时段的象征性契合分数，不是成功概率。各时段分别评分，因此总和不一定是100%。';

  @override
  String get tryAnotherDirection => '探索其他方向';

  @override
  String get viewHistory => '查看历史记录';

  @override
  String get yourReadings => '你的解读记录';

  @override
  String get noReadings => '还没有解读记录。查看第一次指引后，记录就会出现在这里。';

  @override
  String get historySnapshot => '结果会按当时的状态保存，不会重新计算。';

  @override
  String get everydayReflection => '仅供日常自我反思。重要决定需要真实信息和专业人士的帮助。';

  @override
  String get luckyTimesMorning => '今天上午最幸运的时段';

  @override
  String get luckyTimesMidday => '今天中午最幸运的时段';

  @override
  String get luckyTimesAfternoon => '今天下午最幸运的时段';

  @override
  String get luckyTimesEvening => '今天晚间最幸运的时段';

  @override
  String get loadingLocalTime => '正在同步你所在地的日期和时辰';

  @override
  String get loadingBaZi => '正在分析你的八字五行平衡';

  @override
  String get loadingZiWei => '正在对照此刻的紫微周期';

  @override
  String get loadingVedic => '正在对照吠陀星宿与月宿';

  @override
  String get loadingNumerology => '正在梳理生命数字、月亮与行星的节律';

  @override
  String get loadingYinYang => '正在平衡阴阳信号，形成一个参考方向';

  @override
  String get loadingModeYesNo => '正在比较开放与阻力的信号';

  @override
  String get loadingModeActWait => '正在权衡行动的动力与耐心';

  @override
  String get loadingModeAdvanceRetreat => '正在权衡深度投入与适时抽离';

  @override
  String get loadingModeStayGo => '正在比较扎根与流动的信号';

  @override
  String get loadingModeKeepLetGo => '正在权衡延续与放下';

  @override
  String get loadingModeForwardBackward => '正在追踪向前与回返的节律';

  @override
  String get loadingModeLeftRight => '正在平衡接纳与表达的倾向';

  @override
  String get orbitMoment => '此刻';

  @override
  String get orbitRhythm => '节律';

  @override
  String get orbitBalance => '平衡';

  @override
  String get orbitAlmanac => '黄历';

  @override
  String get orbitBaZi => '八字';

  @override
  String get orbitZiWei => '紫微';

  @override
  String get orbitVedic => '吠陀占星';

  @override
  String get orbitNumerology => '生命数字';

  @override
  String get orbitLunarPhase => '月相';

  @override
  String get orbitPlanetary => '行星';

  @override
  String get orbitYinYang => '阴／阳';

  @override
  String get safetyHeading => '使用边界与安全说明';

  @override
  String get safetyTitle => '日常时刻的一面镜子';

  @override
  String get safetyIntro =>
      'AstraCue根据天文节律和个人周期提供象征性视角，仅供日常反思和娱乐，不是指令、预言或确定的事实。';

  @override
  String get prohibitedUses => '禁止用于以下事项';

  @override
  String get harmTitle => '自伤或伤害他人';

  @override
  String get harmDetail => '不得用于自伤、自杀、身体暴力，或让自己及他人陷入危险的决定。';

  @override
  String get navigationTitle => '驾驶与实际导航';

  @override
  String get navigationDetail => '左／右、向前／向后只是象征性选项，不得用于交通、驾驶、找路或人身安全。';

  @override
  String get politicsTitle => '政治与社会冲突';

  @override
  String get politicsDetail => '不得用于政治宣传、投票决定、社会动乱或极端主义活动。';

  @override
  String get medicalTitle => '健康、医疗与紧急情况';

  @override
  String get medicalDetail => '不能代替专业医疗服务、心理健康治疗、药物或紧急救援。';

  @override
  String get legalTitle => '法律、犯罪与重大合同';

  @override
  String get legalDetail => '不得用于犯罪行为、诉讼程序、证词或影响重大的法律合同。';

  @override
  String get financeTitle => '投资与赌博';

  @override
  String get financeDetail => '“财务”仅用于反思小额日常支出。不得把解读用于投资、借贷、加密资产投机、赌博或重大财务决定。';

  @override
  String get consentTitle => '同意、未成年人及关系';

  @override
  String get consentDetail => '不得用来无视他人的同意或自主权，也不得用于决定儿童抚养权或监护安排。';

  @override
  String get importantLimitsHeading => '重要使用边界';

  @override
  String get importantLimitsBody =>
      'AstraCue并非为儿童设计，也不提供医疗、法律或财务建议。作出重要决定时，请使用可靠信息并寻求适当的专业帮助。选择权仍在你手中。';

  @override
  String get crisisSupport => '如果你或他人正面临迫在眉睫的危险或心理危机，请立即联系当地紧急服务或可信赖的本地危机援助热线。';

  @override
  String get acknowledge => '我已了解并同意';

  @override
  String get acknowledgementOnce => '此确认仅会在第一次解读前出现一次。';

  @override
  String get knowBirthTime => '我知道自己的出生时间';

  @override
  String get knowBirthTimeDetail => '越准确的时间，时辰周期越清晰。';

  @override
  String get selectBirthTime => '选择出生时间';

  @override
  String get birthTimeRequired => '请选择出生时间后继续；如果不清楚，请关闭此选项。';

  @override
  String get languageSetting => '语言';

  @override
  String get chooseLanguage => '选择语言';

  @override
  String get changeLanguage => '切换语言';

  @override
  String get choiceYes => '是';

  @override
  String get choiceNo => '否';

  @override
  String get choiceAct => '行动';

  @override
  String get choiceWait => '等待';

  @override
  String get choiceAdvance => '投入';

  @override
  String get choiceRetreat => '抽离';

  @override
  String get choiceStay => '留下';

  @override
  String get choiceGo => '离开';

  @override
  String get choiceKeep => '保留';

  @override
  String get choiceLetGo => '放下';

  @override
  String get choiceForward => '向前';

  @override
  String get choiceBackward => '向后';

  @override
  String get choiceLeft => '左';

  @override
  String get choiceRight => '右';

  @override
  String get energyLevelQuiet => '宁静';

  @override
  String get energyLevelSoft => '柔和';

  @override
  String get energyLevelSteady => '平稳';

  @override
  String get energyLevelLively => '活跃';

  @override
  String get energyLevelBright => '明亮';

  @override
  String get energyLevelRadiant => '璀璨';

  @override
  String get energyLevelFocused => '专注';

  @override
  String get energyLevelFlowing => '流动';

  @override
  String get colorCedar => '雪松';

  @override
  String get colorJade => '翡翠';

  @override
  String get colorSage => '鼠尾草绿';

  @override
  String get colorMint => '薄荷绿';

  @override
  String get colorEmber => '余烬';

  @override
  String get colorSolarCoral => '阳光珊瑚';

  @override
  String get colorRose => '玫瑰粉';

  @override
  String get colorBlossom => '花瓣粉';

  @override
  String get colorOchre => '赭石';

  @override
  String get colorAmber => '琥珀';

  @override
  String get colorSand => '沙色';

  @override
  String get colorClay => '陶土色';

  @override
  String get colorSilver => '银色';

  @override
  String get colorSteel => '钢蓝';

  @override
  String get colorPearl => '珍珠白';

  @override
  String get colorChampagne => '香槟色';

  @override
  String get colorOceanBlue => '海洋蓝';

  @override
  String get colorAzure => '天青蓝';

  @override
  String get colorIndigo => '靛蓝';

  @override
  String get colorMistBlue => '雾蓝';

  @override
  String get homeDescription00 => '今天，宇宙也许在向你传递什么？想一想心中的犹豫，看看此刻周围有哪些信号。';

  @override
  String get homeDescription01 => '感觉被两个方向拉扯吗？让今天的宇宙信号为你的选择带来一个新视角。';

  @override
  String get homeDescription02 => '星辰不会替你作决定，但它们的运行规律或许能让你换个角度看下一步。';

  @override
  String get homeDescription03 => '前路不清晰时，先停一停，仔细看看。今天的信号提示了什么？';

  @override
  String get homeDescription04 => '每个时刻都有自己的能量。想一想你在意的事，看看此刻或许指向什么方向。';

  @override
  String get homeDescription05 => '也许宇宙正提醒你放慢脚步。选定方向前，先看看今天的信号。';

  @override
  String get homeDescription06 => '正站在岔路口吗？看看今天的天象如何与你心中的问题呼应。';

  @override
  String get homeDescription07 => '倾听此刻的节律。今天的象征或许会显出一个值得考虑的方向。';

  @override
  String get homeDescription08 => '这一刻想让你看到什么？先探索信号，再相信自己作出选择。';

  @override
  String get homeDescription09 => '一点宇宙视角或许能让思路更清晰。想想今天真正重要的事，看看信号指向哪里。';

  @override
  String get homeDescription10 => '还在反复琢磨同一个选择吗？看看今天的宇宙能量让什么变得更清楚。';

  @override
  String get homeDescription11 => '当理性指向一边、直觉指向另一边，不妨看看今天周围的信号。';

  @override
  String get homeDescription12 => '不确定该行动还是暂停？让今天的节律成为一个更平静的起点。';

  @override
  String get homeDescription13 => '如果清晰感从换个角度开始呢？看看今天的天象。';

  @override
  String get homeDescription14 => '有个问题总在心里浮现。看看今天的象征邀请你留意什么。';

  @override
  String get homeDescription15 => '有些选择在某些时刻格外沉重。决定之前，先感受此刻的能量。';

  @override
  String get homeDescription16 => '眼下道路也许还不明朗。星辰能照亮这份犹豫背后的什么？';

  @override
  String get homeDescription17 => '在一时冲动下行动之前，先深呼吸，看看今天的宇宙信号提示了什么。';

  @override
  String get homeDescription18 => '不是每个岔路口都需要立刻得到答案。让今天的解读给你一点思考空间。';

  @override
  String get homeDescription19 => '在想现在是不是合适的时机？探索今天的规律，寻找一个更稳的视角。';

  @override
  String get homeDescription20 => '当一切似乎皆有可能，却又没有定数时，让天空的节律带来新的视角。';

  @override
  String get homeDescription21 => '选择权始终在你手中。今天的信号或许能帮你看清什么最重要。';

  @override
  String get homeDescription22 => '当犹豫遮住下一步时，看看你的星座和今日能量能照亮什么。';

  @override
  String get homeDescription23 => '也许你不需要更响亮的答案，只需要和今天的象征安静相处片刻。';

  @override
  String get homeDescription24 => '直觉是在提醒你行动，还是等待？看看今天的宇宙节律映照了什么。';

  @override
  String get homeDescription25 => '在渴望与担忧之间，留一点暂停的空间。让今天的信号帮你再看一眼。';

  @override
  String get homeDescription26 => '你已经注意到了那个问题。现在，也留意这一刻吧。今天的天象信号提示什么？';

  @override
  String get homeDescription27 => '当决定变得纠结，古老的象征与今天的时机或许会显出另一个角度。';

  @override
  String get homeDescription28 => '也许此刻适合靠近一步，也许适合留些空间。看看选择周围的能量。';

  @override
  String get homeDescription29 => '你不必在这里找到确定的答案。找到一刻平静、一点宇宙提示，以及一个值得考虑的方向就好。';

  @override
  String get energyQuiet00 => '今天的象征性能量转向内心，为安静思考留出空间。';

  @override
  String get energyQuiet01 => '今天的宇宙节律转向内在；安静下来，或许能看见被喧嚣遮住的东西。';

  @override
  String get energyQuiet02 => '今天的天空带着安静的象征色彩，给思绪一些沉淀的时间。';

  @override
  String get energyQuiet03 => '一股宁静的节律贯穿今天，邀请你留意，而不是着急。';

  @override
  String get energyQuiet04 => '今天的信号提示你回望思考；暂停也可以是前进的一部分。';

  @override
  String get energyQuiet05 => '当一天显得平缓，内心的罗盘或许会更清晰。';

  @override
  String get energyQuiet06 => '今天的能量留出倾听的空间，不必急着给答案命名。';

  @override
  String get energyQuiet07 => '信号并不总是响亮地出现；慢下来，也许更容易发现今天的提示。';

  @override
  String get energySoft00 => '今天的象征性能量轻柔流动，适合关照自己、迈出小步。';

  @override
  String get energySoft01 => '今天的宇宙节律温柔流动；小步前行也许比大步跨越更自然。';

  @override
  String get energySoft02 => '今天的能量给关怀留了位置；面对选择时，不必逼自己马上确定。';

  @override
  String get energySoft03 => '今天更柔和的节律，也许能帮你从力所能及的事开始。';

  @override
  String get energySoft04 => '温柔也可以有力量；留意哪里需要放松，而不是压力。';

  @override
  String get energySoft05 => '今天的信号提示轻轻向前：足以开始，却不必催促自己。';

  @override
  String get energySoft06 => '今天的节律很细腻；简单而经过思考的行动或许更有意义。';

  @override
  String get energySoft07 => '再小的契机也可能重要；今天温柔的节律留出了探索空间。';

  @override
  String get energySteady00 => '今天的象征性能量保持平稳、踏实的节律。';

  @override
  String get energySteady01 => '今天的象征性能量节奏平稳；相信自己能持续的步调。';

  @override
  String get energySteady02 => '今天的宇宙节律让人感到踏实，适合从容思考、有意识地行动。';

  @override
  String get energySteady03 => '平稳的节律贯穿今天；专注也许比急迫更有帮助。';

  @override
  String get energySteady04 => '今天的信号指向平衡，但并不要求你停在原地。';

  @override
  String get energySteady05 => '持续本身也是力量；停下来想过之后，留意哪一步依然有意义。';

  @override
  String get energySteady06 => '今天的能量不急不缓，给你的选择一些成形的时间。';

  @override
  String get energySteady07 => '平静的节律也能指路；今天的进展不必轰轰烈烈。';

  @override
  String get energyLively00 => '一点轻快的火花点亮今天的象征性能量，带来好奇和变化。';

  @override
  String get energyLively01 => '好奇心点亮今天的象征性能量；一个新角度也许值得探索。';

  @override
  String get energyLively02 => '今天更有活力；留意吸引你的事，但不必急着投入。';

  @override
  String get energyLively03 => '今天的宇宙节律邀请你探索，同时保留判断的余地。';

  @override
  String get energyLively04 => '一股轻快的节律流过今天，可能在意想不到的地方发现新可能。';

  @override
  String get energyLively05 => '今天的好奇心或许是有用的信号；作出承诺前，先看看它指向哪里。';

  @override
  String get energyLively06 => '今天的信号带着动感；你可以探索，不必急着定下来。';

  @override
  String get energyLively07 => '今天的能量很活跃；先让它拓宽选择，再慢慢收拢。';

  @override
  String get energyBright00 => '今天的象征性能量明亮而有动力，也给表达留出空间。';

  @override
  String get energyBright01 => '今天的象征性能量让你想表达的事更清晰。';

  @override
  String get energyBright02 => '更明亮的宇宙节律或许能帮你看见哪种可能值得关注。';

  @override
  String get energyBright03 => '今天的信号显得开放；下一步或许更容易说清。';

  @override
  String get energyBright04 => '今天有表达的动力；当时机合适时，说出重要的事。';

  @override
  String get energyBright05 => '今天节律中的一处敞开，或许能带来清晰感，而不必催促你。';

  @override
  String get energyBright06 => '今天的能量更向外延展；留意你准备好展现什么。';

  @override
  String get energyBright07 => '一点亮光就能改变视角；今天的节律邀请你向前看。';

  @override
  String get energyRadiant00 => '今天的象征性能量达到最明亮的状态：开放而舒展。';

  @override
  String get energyRadiant01 => '今天的象征性能量充分展开，邀请你看见不止一条可能的路。';

  @override
  String get energyRadiant02 => '明亮的节律流过今天；保持自己的重心，也让可能性展开。';

  @override
  String get energyRadiant03 => '今天的宇宙节律格外开放，给启发你的事留一些空间。';

  @override
  String get energyRadiant04 => '更充盈的光彩映在今天的能量里，让你从更宽的视野看见可能性。';

  @override
  String get energyRadiant05 => '今天的信号带着舒展感；也许更容易想象接下来会怎样。';

  @override
  String get energyRadiant06 => '让今天的暖意拓宽眼界，同时把最终选择留在自己手中。';

  @override
  String get energyRadiant07 => '今天的天空带着丰沛的象征节律；带着清醒的判断欢迎新的可能。';

  @override
  String get energyFocused00 => '今天的象征性能量聚向清晰的方向；行动信号更为突出。';

  @override
  String get energyFocused01 => '今天的行动信号逐渐清晰；留意一个有意识的下一步。';

  @override
  String get energyFocused02 => '象征性的节律偏向行动，但步调仍由你决定。';

  @override
  String get energyFocused03 => '今天带着方向感；把注意力放在你真正能影响的事上。';

  @override
  String get energyFocused04 => '当选项彼此拉扯，今天的信号邀请你先专注于一个实际行动。';

  @override
  String get energyFocused05 => '今天的信号聚向一个意图；留意它，但不必匆忙。';

  @override
  String get energyFocused06 => '今天行动的象征性吸引更强；迈步之前先弄清自己的理由。';

  @override
  String get energyFocused07 => '今天重在意图，而非强度；让选定的方向慢慢成形。';

  @override
  String get energyFlowing00 => '今天的象征性能量如潮汐流动；变化信号更为突出。';

  @override
  String get energyFlowing01 => '今天的变化信号更加明显；给计划留一点弹性。';

  @override
  String get energyFlowing02 => '变化中的宇宙节律贯穿今天；保持灵活，也许会看见另一条路。';

  @override
  String get energyFlowing03 => '变化的能量更容易被察觉；开放地看看新视角带来了什么。';

  @override
  String get energyFlowing04 => '今天的信号谈的是可能性之间的流动，而不是固定的终点。';

  @override
  String get energyFlowing05 => '当情况变化时，灵活应对也许比僵硬的计划更有用。';

  @override
  String get energyFlowing06 => '流动的节律贯穿今天；不必强求答案，留意什么可以慢慢改变。';

  @override
  String get energyFlowing07 => '象征性的节律偏向转变；你仍可以按自己的步调前进。';

  @override
  String get defaultUserName => '探索者';

  @override
  String get searchCountries => '搜索国家';

  @override
  String get greetingMorning => '早上好，';

  @override
  String get greetingAfternoon => '下午好，';

  @override
  String get greetingEvening => '晚上好，';

  @override
  String get colorRoleLead => '主色';

  @override
  String get colorRoleSupporting => '辅助色';

  @override
  String colorRoleSemantics(String role, String name) {
    return '$role：$name';
  }

  @override
  String colorRoleUnavailableSemantics(String role) {
    return '$role暂不可用';
  }

  @override
  String readingAreaSemantics(String category) {
    return '解读领域：$category';
  }

  @override
  String get energyInsightNewTooltip => '今日有新的能量解读';

  @override
  String get energyInsightReadTooltip => '阅读今日能量解读';

  @override
  String get energyInsightHideTooltip => '收起今日能量解读';

  @override
  String get energyInsightCoachMark => '每天都可以在这里看到一则新的能量解读。';

  @override
  String get ritualLocked => '你的这一刻已确定。';

  @override
  String get periodPassedShort => '已过';

  @override
  String get errorNetworkHeadline => '网络连接已中断。';

  @override
  String get errorNetworkDetail => '请检查网络连接，然后重试。';

  @override
  String get errorServerHeadline => '目前无法完成解读。';

  @override
  String get errorServerDetail => '服务已响应，但未能完成处理。请稍后重试。';

  @override
  String get errorRejectedHeadline => '部分个人资料需要检查。';

  @override
  String get errorRejectedDetail => '请检查出生信息，然后重新开始解读。';

  @override
  String get errorInvalidHeadline => '此版本无法读取结果。';

  @override
  String get errorInvalidDetail => '更新应用后可能恢复解读功能。';

  @override
  String get errorConfigurationHeadline => '此版本尚未配置解读服务。';

  @override
  String get errorConfigurationDetail => '开发版本：尚未配置计算服务。';

  @override
  String get errorNothingRecorded => '本次尝试未保存任何解读。';

  @override
  String get insufficientHeading => '信息不足，暂无法解读';

  @override
  String get insufficientBody => '你的资料暂时不足以为这次解读给出方向。补充出生时间和出生国家，有助于更完整地分析周期。';

  @override
  String get periodElapsedHeading => '该时段已过去';

  @override
  String get periodElapsedBody =>
      '你所在地区的这个时段已经过去，无法再分析该时段。请选择之后的时段，或解读当前这一刻。今天的结果不会延续到明天。';

  @override
  String colorsToKeepNear(String first, String second) {
    return '适合放在身边的颜色：$first和$second';
  }

  @override
  String colorToKeepNear(String name) {
    return '适合放在身边的颜色：$name';
  }

  @override
  String get shareTooltip => '分享这次解读';

  @override
  String get shareUnavailable => '目前无法分享。';

  @override
  String get shareDisclaimer => '供日常反思的象征性视角，并非预测或概率。';

  @override
  String get backToHistory => '返回历史记录';

  @override
  String get saveFailedRetry => '保存失败 · 重试';

  @override
  String get savingToHistory => '正在保存到历史记录…';

  @override
  String get responsibleUseLink => '负责任使用与安全政策';

  @override
  String get historyToday => '今天';

  @override
  String get historyCouldNotOpen => '无法打开你的解读记录。';

  @override
  String get historyNotEnoughData => '信息不足';

  @override
  String get historyPeriodPassed => '时段已过';

  @override
  String get zodiacAries => '白羊座';

  @override
  String get zodiacTaurus => '金牛座';

  @override
  String get zodiacGemini => '双子座';

  @override
  String get zodiacCancer => '巨蟹座';

  @override
  String get zodiacLeo => '狮子座';

  @override
  String get zodiacVirgo => '处女座';

  @override
  String get zodiacLibra => '天秤座';

  @override
  String get zodiacScorpio => '天蝎座';

  @override
  String get zodiacSagittarius => '射手座';

  @override
  String get zodiacCapricorn => '摩羯座';

  @override
  String get zodiacAquarius => '水瓶座';

  @override
  String get zodiacPisces => '双鱼座';

  @override
  String zodiacAvatarSemantics(String sign) {
    return '$sign星座头像';
  }
}

/// The translations for Chinese, using the Han script (`zh_Hans`).
class AppLocalizationsZhHans extends AppLocalizationsZh {
  AppLocalizationsZhHans() : super('zh_Hans');

  @override
  String get appName => 'AstraCue';

  @override
  String get continueAction => '继续';

  @override
  String get backAction => '返回';

  @override
  String get closeAction => '关闭';

  @override
  String get tryAgain => '重试';

  @override
  String get responsibleUse => '安全使用说明';

  @override
  String get history => '历史记录';

  @override
  String get onboardingTitle => '聆听宇宙的信号与你的直觉。';

  @override
  String get onboardingLanguageHint => '点击上方的地球图标以切换语言。';

  @override
  String get yourProfile => '你的资料';

  @override
  String get signAfterBirthDate => '输入出生日期后，将显示你的星座';

  @override
  String get buildPattern => '探索属于你的专属能量。';

  @override
  String get profileExplainer => '定格分析时所依据的能量周期。';

  @override
  String get nameField => '姓名';

  @override
  String get dateOfBirth => '出生日期';

  @override
  String get selectBirthDate => '选择出生日期';

  @override
  String get birthDateRequired => '请选择出生日期后继续。';

  @override
  String get birthTimeUnknown => '出生时间未知';

  @override
  String get birthTimeUnknownDetail => '若不知出生时间，算法将采用与你性格最契合的时段进行测算。';

  @override
  String get timeOfBirth => '出生时间';

  @override
  String get countryOfBirth => '出生国家';

  @override
  String get selectBirthCountry => '搜索并选择国家';

  @override
  String get birthCountryRequired => '请选择出生国家后继续。';

  @override
  String get createCompass => '创建我的指引罗盘';

  @override
  String get birthPrivacyPrototype => '在此原型版本中，你的出生信息将保持私密。';

  @override
  String get homeEyebrow => '指引方向的专属罗盘';

  @override
  String get homeTitle => '正在选择之间犹豫吗？';

  @override
  String get areaQuestion => '这与哪方面有关？';

  @override
  String get findDirection => '寻找你的专属方向';

  @override
  String get todaySignals => '今日信号';

  @override
  String get dailyEnergy => '今日能量';

  @override
  String get yourColorsToday => '今日属于你的颜色：';

  @override
  String get luckyNumberToday => '今日幸运数字：';

  @override
  String get categoryOverall => '综合';

  @override
  String get categoryLove => '爱情与人际关系';

  @override
  String get categoryCareer => '事业';

  @override
  String get categoryMoney => '财务';

  @override
  String get categoryStudy => '学习与成长';

  @override
  String get categoryFriends => '朋友';

  @override
  String get categoryOther => '其他事情';

  @override
  String get periodQuestion => '你考虑的是哪个时段？';

  @override
  String get periodNow => '现在';

  @override
  String get periodMorning => '上午';

  @override
  String get periodMidday => '中午';

  @override
  String get periodAfternoon => '下午';

  @override
  String get periodEvening => '晚间';

  @override
  String get periodPassed => '已过';

  @override
  String periodHasPassed(String period) {
    return '$period已经过去，请选择其他时段。';
  }

  @override
  String get reveal => '开始分析';

  @override
  String get aligning => '正在对齐信号';

  @override
  String get tapWhenReady => '准备好后轻点';

  @override
  String get keepChoiceInMind => '请在心中明确你正在考虑的选择。';

  @override
  String get ritualSafety => '仅供日常自我反思使用 • 不可用于医疗、投资、借贷、政治或可能造成伤害的决定。';

  @override
  String get loadingLocalMoment => '正在解读你此刻的信号';

  @override
  String get loadingReassurance => '请稍候片刻——当下的宇宙信号正在汇聚。';

  @override
  String readingForCategory(String category) {
    return '正在解读$category';
  }

  @override
  String get yourDirection => '给你的方向';

  @override
  String get resultBasis => '基于此刻属于你的能量与宇宙信号。';

  @override
  String get percentageCaveat => '百分比表示象征性的契合度，并非现实中的概率。';

  @override
  String get balancedHeading => '两边势均力敌';

  @override
  String get balancedResult => '平衡';

  @override
  String get balancedExplanation => '此刻没有哪一边更占优势。这表示平衡，并不暗示隐藏的答案。';

  @override
  String get currentMoment => '本次解读反映的是你当前的时刻。';

  @override
  String get luckyTimesCaveat =>
      '每个百分比都是该时段的象征性契合分数，不是成功概率。各时段分别评分，因此总和不一定是100%。';

  @override
  String get tryAnotherDirection => '探索其他方向';

  @override
  String get viewHistory => '查看历史记录';

  @override
  String get yourReadings => '你的解读记录';

  @override
  String get noReadings => '还没有解读记录。查看第一次指引后，记录就会出现在这里。';

  @override
  String get historySnapshot => '结果会按当时的状态保存，不会重新计算。';

  @override
  String get everydayReflection => '仅供日常自我反思。重要决定需要真实信息和专业人士的帮助。';

  @override
  String get luckyTimesMorning => '今天上午最幸运的时段';

  @override
  String get luckyTimesMidday => '今天中午最幸运的时段';

  @override
  String get luckyTimesAfternoon => '今天下午最幸运的时段';

  @override
  String get luckyTimesEvening => '今天晚间最幸运的时段';

  @override
  String get loadingLocalTime => '正在同步你所在地的日期和时辰';

  @override
  String get loadingBaZi => '正在分析你的八字五行平衡';

  @override
  String get loadingZiWei => '正在对照此刻的紫微周期';

  @override
  String get loadingVedic => '正在对照吠陀星宿与月宿';

  @override
  String get loadingNumerology => '正在梳理生命数字、月亮与行星的节律';

  @override
  String get loadingYinYang => '正在平衡阴阳信号，形成一个参考方向';

  @override
  String get loadingModeYesNo => '正在比较开放与阻力的信号';

  @override
  String get loadingModeActWait => '正在权衡行动的动力与耐心';

  @override
  String get loadingModeAdvanceRetreat => '正在权衡深度投入与适时抽离';

  @override
  String get loadingModeStayGo => '正在比较扎根与流动的信号';

  @override
  String get loadingModeKeepLetGo => '正在权衡延续与放下';

  @override
  String get loadingModeForwardBackward => '正在追踪向前与回返的节律';

  @override
  String get loadingModeLeftRight => '正在平衡接纳与表达的倾向';

  @override
  String get orbitMoment => '此刻';

  @override
  String get orbitRhythm => '节律';

  @override
  String get orbitBalance => '平衡';

  @override
  String get orbitAlmanac => '黄历';

  @override
  String get orbitBaZi => '八字';

  @override
  String get orbitZiWei => '紫微';

  @override
  String get orbitVedic => '吠陀占星';

  @override
  String get orbitNumerology => '生命数字';

  @override
  String get orbitLunarPhase => '月相';

  @override
  String get orbitPlanetary => '行星';

  @override
  String get orbitYinYang => '阴／阳';

  @override
  String get safetyHeading => '使用边界与安全说明';

  @override
  String get safetyTitle => '日常时刻的一面镜子';

  @override
  String get safetyIntro =>
      'AstraCue根据天文节律和个人周期提供象征性视角，仅供日常反思和娱乐，不是指令、预言或确定的事实。';

  @override
  String get prohibitedUses => '禁止用于以下事项';

  @override
  String get harmTitle => '自伤或伤害他人';

  @override
  String get harmDetail => '不得用于自伤、自杀、身体暴力，或让自己及他人陷入危险的决定。';

  @override
  String get navigationTitle => '驾驶与实际导航';

  @override
  String get navigationDetail => '左／右、向前／向后只是象征性选项，不得用于交通、驾驶、找路或人身安全。';

  @override
  String get politicsTitle => '政治与社会冲突';

  @override
  String get politicsDetail => '不得用于政治宣传、投票决定、社会动乱或极端主义活动。';

  @override
  String get medicalTitle => '健康、医疗与紧急情况';

  @override
  String get medicalDetail => '不能代替专业医疗服务、心理健康治疗、药物或紧急救援。';

  @override
  String get legalTitle => '法律、犯罪与重大合同';

  @override
  String get legalDetail => '不得用于犯罪行为、诉讼程序、证词或影响重大的法律合同。';

  @override
  String get financeTitle => '投资与赌博';

  @override
  String get financeDetail => '“财务”仅用于反思小额日常支出。不得把解读用于投资、借贷、加密资产投机、赌博或重大财务决定。';

  @override
  String get consentTitle => '同意、未成年人及关系';

  @override
  String get consentDetail => '不得用来无视他人的同意或自主权，也不得用于决定儿童抚养权或监护安排。';

  @override
  String get importantLimitsHeading => '重要使用边界';

  @override
  String get importantLimitsBody =>
      'AstraCue并非为儿童设计，也不提供医疗、法律或财务建议。作出重要决定时，请使用可靠信息并寻求适当的专业帮助。选择权仍在你手中。';

  @override
  String get crisisSupport => '如果你或他人正面临迫在眉睫的危险或心理危机，请立即联系当地紧急服务或可信赖的本地危机援助热线。';

  @override
  String get acknowledge => '我已了解并同意';

  @override
  String get acknowledgementOnce => '此确认仅会在第一次解读前出现一次。';

  @override
  String get knowBirthTime => '我知道自己的出生时间';

  @override
  String get knowBirthTimeDetail => '越准确的时间，时辰周期越清晰。';

  @override
  String get selectBirthTime => '选择出生时间';

  @override
  String get birthTimeRequired => '请选择出生时间后继续；如果不清楚，请关闭此选项。';

  @override
  String get languageSetting => '语言';

  @override
  String get chooseLanguage => '选择语言';

  @override
  String get changeLanguage => '切换语言';

  @override
  String get choiceYes => '是';

  @override
  String get choiceNo => '否';

  @override
  String get choiceAct => '行动';

  @override
  String get choiceWait => '等待';

  @override
  String get choiceAdvance => '投入';

  @override
  String get choiceRetreat => '抽离';

  @override
  String get choiceStay => '留下';

  @override
  String get choiceGo => '离开';

  @override
  String get choiceKeep => '保留';

  @override
  String get choiceLetGo => '放下';

  @override
  String get choiceForward => '向前';

  @override
  String get choiceBackward => '向后';

  @override
  String get choiceLeft => '左';

  @override
  String get choiceRight => '右';

  @override
  String get energyLevelQuiet => '宁静';

  @override
  String get energyLevelSoft => '柔和';

  @override
  String get energyLevelSteady => '平稳';

  @override
  String get energyLevelLively => '活跃';

  @override
  String get energyLevelBright => '明亮';

  @override
  String get energyLevelRadiant => '璀璨';

  @override
  String get energyLevelFocused => '专注';

  @override
  String get energyLevelFlowing => '流动';

  @override
  String get colorCedar => '雪松';

  @override
  String get colorJade => '翡翠';

  @override
  String get colorSage => '鼠尾草绿';

  @override
  String get colorMint => '薄荷绿';

  @override
  String get colorEmber => '余烬';

  @override
  String get colorSolarCoral => '阳光珊瑚';

  @override
  String get colorRose => '玫瑰粉';

  @override
  String get colorBlossom => '花瓣粉';

  @override
  String get colorOchre => '赭石';

  @override
  String get colorAmber => '琥珀';

  @override
  String get colorSand => '沙色';

  @override
  String get colorClay => '陶土色';

  @override
  String get colorSilver => '银色';

  @override
  String get colorSteel => '钢蓝';

  @override
  String get colorPearl => '珍珠白';

  @override
  String get colorChampagne => '香槟色';

  @override
  String get colorOceanBlue => '海洋蓝';

  @override
  String get colorAzure => '天青蓝';

  @override
  String get colorIndigo => '靛蓝';

  @override
  String get colorMistBlue => '雾蓝';

  @override
  String get homeDescription00 => '今天，宇宙也许在向你传递什么？想一想心中的犹豫，看看此刻周围有哪些信号。';

  @override
  String get homeDescription01 => '感觉被两个方向拉扯吗？让今天的宇宙信号为你的选择带来一个新视角。';

  @override
  String get homeDescription02 => '星辰不会替你作决定，但它们的运行规律或许能让你换个角度看下一步。';

  @override
  String get homeDescription03 => '前路不清晰时，先停一停，仔细看看。今天的信号提示了什么？';

  @override
  String get homeDescription04 => '每个时刻都有自己的能量。想一想你在意的事，看看此刻或许指向什么方向。';

  @override
  String get homeDescription05 => '也许宇宙正提醒你放慢脚步。选定方向前，先看看今天的信号。';

  @override
  String get homeDescription06 => '正站在岔路口吗？看看今天的天象如何与你心中的问题呼应。';

  @override
  String get homeDescription07 => '倾听此刻的节律。今天的象征或许会显出一个值得考虑的方向。';

  @override
  String get homeDescription08 => '这一刻想让你看到什么？先探索信号，再相信自己作出选择。';

  @override
  String get homeDescription09 => '一点宇宙视角或许能让思路更清晰。想想今天真正重要的事，看看信号指向哪里。';

  @override
  String get homeDescription10 => '还在反复琢磨同一个选择吗？看看今天的宇宙能量让什么变得更清楚。';

  @override
  String get homeDescription11 => '当理性指向一边、直觉指向另一边，不妨看看今天周围的信号。';

  @override
  String get homeDescription12 => '不确定该行动还是暂停？让今天的节律成为一个更平静的起点。';

  @override
  String get homeDescription13 => '如果清晰感从换个角度开始呢？看看今天的天象。';

  @override
  String get homeDescription14 => '有个问题总在心里浮现。看看今天的象征邀请你留意什么。';

  @override
  String get homeDescription15 => '有些选择在某些时刻格外沉重。决定之前，先感受此刻的能量。';

  @override
  String get homeDescription16 => '眼下道路也许还不明朗。星辰能照亮这份犹豫背后的什么？';

  @override
  String get homeDescription17 => '在一时冲动下行动之前，先深呼吸，看看今天的宇宙信号提示了什么。';

  @override
  String get homeDescription18 => '不是每个岔路口都需要立刻得到答案。让今天的解读给你一点思考空间。';

  @override
  String get homeDescription19 => '在想现在是不是合适的时机？探索今天的规律，寻找一个更稳的视角。';

  @override
  String get homeDescription20 => '当一切似乎皆有可能，却又没有定数时，让天空的节律带来新的视角。';

  @override
  String get homeDescription21 => '选择权始终在你手中。今天的信号或许能帮你看清什么最重要。';

  @override
  String get homeDescription22 => '当犹豫遮住下一步时，看看你的星座和今日能量能照亮什么。';

  @override
  String get homeDescription23 => '也许你不需要更响亮的答案，只需要和今天的象征安静相处片刻。';

  @override
  String get homeDescription24 => '直觉是在提醒你行动，还是等待？看看今天的宇宙节律映照了什么。';

  @override
  String get homeDescription25 => '在渴望与担忧之间，留一点暂停的空间。让今天的信号帮你再看一眼。';

  @override
  String get homeDescription26 => '你已经注意到了那个问题。现在，也留意这一刻吧。今天的天象信号提示什么？';

  @override
  String get homeDescription27 => '当决定变得纠结，古老的象征与今天的时机或许会显出另一个角度。';

  @override
  String get homeDescription28 => '也许此刻适合靠近一步，也许适合留些空间。看看选择周围的能量。';

  @override
  String get homeDescription29 => '你不必在这里找到确定的答案。找到一刻平静、一点宇宙提示，以及一个值得考虑的方向就好。';

  @override
  String get energyQuiet00 => '今天的象征性能量转向内心，为安静思考留出空间。';

  @override
  String get energyQuiet01 => '今天的宇宙节律转向内在；安静下来，或许能看见被喧嚣遮住的东西。';

  @override
  String get energyQuiet02 => '今天的天空带着安静的象征色彩，给思绪一些沉淀的时间。';

  @override
  String get energyQuiet03 => '一股宁静的节律贯穿今天，邀请你留意，而不是着急。';

  @override
  String get energyQuiet04 => '今天的信号提示你回望思考；暂停也可以是前进的一部分。';

  @override
  String get energyQuiet05 => '当一天显得平缓，内心的罗盘或许会更清晰。';

  @override
  String get energyQuiet06 => '今天的能量留出倾听的空间，不必急着给答案命名。';

  @override
  String get energyQuiet07 => '信号并不总是响亮地出现；慢下来，也许更容易发现今天的提示。';

  @override
  String get energySoft00 => '今天的象征性能量轻柔流动，适合关照自己、迈出小步。';

  @override
  String get energySoft01 => '今天的宇宙节律温柔流动；小步前行也许比大步跨越更自然。';

  @override
  String get energySoft02 => '今天的能量给关怀留了位置；面对选择时，不必逼自己马上确定。';

  @override
  String get energySoft03 => '今天更柔和的节律，也许能帮你从力所能及的事开始。';

  @override
  String get energySoft04 => '温柔也可以有力量；留意哪里需要放松，而不是压力。';

  @override
  String get energySoft05 => '今天的信号提示轻轻向前：足以开始，却不必催促自己。';

  @override
  String get energySoft06 => '今天的节律很细腻；简单而经过思考的行动或许更有意义。';

  @override
  String get energySoft07 => '再小的契机也可能重要；今天温柔的节律留出了探索空间。';

  @override
  String get energySteady00 => '今天的象征性能量保持平稳、踏实的节律。';

  @override
  String get energySteady01 => '今天的象征性能量节奏平稳；相信自己能持续的步调。';

  @override
  String get energySteady02 => '今天的宇宙节律让人感到踏实，适合从容思考、有意识地行动。';

  @override
  String get energySteady03 => '平稳的节律贯穿今天；专注也许比急迫更有帮助。';

  @override
  String get energySteady04 => '今天的信号指向平衡，但并不要求你停在原地。';

  @override
  String get energySteady05 => '持续本身也是力量；停下来想过之后，留意哪一步依然有意义。';

  @override
  String get energySteady06 => '今天的能量不急不缓，给你的选择一些成形的时间。';

  @override
  String get energySteady07 => '平静的节律也能指路；今天的进展不必轰轰烈烈。';

  @override
  String get energyLively00 => '一点轻快的火花点亮今天的象征性能量，带来好奇和变化。';

  @override
  String get energyLively01 => '好奇心点亮今天的象征性能量；一个新角度也许值得探索。';

  @override
  String get energyLively02 => '今天更有活力；留意吸引你的事，但不必急着投入。';

  @override
  String get energyLively03 => '今天的宇宙节律邀请你探索，同时保留判断的余地。';

  @override
  String get energyLively04 => '一股轻快的节律流过今天，可能在意想不到的地方发现新可能。';

  @override
  String get energyLively05 => '今天的好奇心或许是有用的信号；作出承诺前，先看看它指向哪里。';

  @override
  String get energyLively06 => '今天的信号带着动感；你可以探索，不必急着定下来。';

  @override
  String get energyLively07 => '今天的能量很活跃；先让它拓宽选择，再慢慢收拢。';

  @override
  String get energyBright00 => '今天的象征性能量明亮而有动力，也给表达留出空间。';

  @override
  String get energyBright01 => '今天的象征性能量让你想表达的事更清晰。';

  @override
  String get energyBright02 => '更明亮的宇宙节律或许能帮你看见哪种可能值得关注。';

  @override
  String get energyBright03 => '今天的信号显得开放；下一步或许更容易说清。';

  @override
  String get energyBright04 => '今天有表达的动力；当时机合适时，说出重要的事。';

  @override
  String get energyBright05 => '今天节律中的一处敞开，或许能带来清晰感，而不必催促你。';

  @override
  String get energyBright06 => '今天的能量更向外延展；留意你准备好展现什么。';

  @override
  String get energyBright07 => '一点亮光就能改变视角；今天的节律邀请你向前看。';

  @override
  String get energyRadiant00 => '今天的象征性能量达到最明亮的状态：开放而舒展。';

  @override
  String get energyRadiant01 => '今天的象征性能量充分展开，邀请你看见不止一条可能的路。';

  @override
  String get energyRadiant02 => '明亮的节律流过今天；保持自己的重心，也让可能性展开。';

  @override
  String get energyRadiant03 => '今天的宇宙节律格外开放，给启发你的事留一些空间。';

  @override
  String get energyRadiant04 => '更充盈的光彩映在今天的能量里，让你从更宽的视野看见可能性。';

  @override
  String get energyRadiant05 => '今天的信号带着舒展感；也许更容易想象接下来会怎样。';

  @override
  String get energyRadiant06 => '让今天的暖意拓宽眼界，同时把最终选择留在自己手中。';

  @override
  String get energyRadiant07 => '今天的天空带着丰沛的象征节律；带着清醒的判断欢迎新的可能。';

  @override
  String get energyFocused00 => '今天的象征性能量聚向清晰的方向；行动信号更为突出。';

  @override
  String get energyFocused01 => '今天的行动信号逐渐清晰；留意一个有意识的下一步。';

  @override
  String get energyFocused02 => '象征性的节律偏向行动，但步调仍由你决定。';

  @override
  String get energyFocused03 => '今天带着方向感；把注意力放在你真正能影响的事上。';

  @override
  String get energyFocused04 => '当选项彼此拉扯，今天的信号邀请你先专注于一个实际行动。';

  @override
  String get energyFocused05 => '今天的信号聚向一个意图；留意它，但不必匆忙。';

  @override
  String get energyFocused06 => '今天行动的象征性吸引更强；迈步之前先弄清自己的理由。';

  @override
  String get energyFocused07 => '今天重在意图，而非强度；让选定的方向慢慢成形。';

  @override
  String get energyFlowing00 => '今天的象征性能量如潮汐流动；变化信号更为突出。';

  @override
  String get energyFlowing01 => '今天的变化信号更加明显；给计划留一点弹性。';

  @override
  String get energyFlowing02 => '变化中的宇宙节律贯穿今天；保持灵活，也许会看见另一条路。';

  @override
  String get energyFlowing03 => '变化的能量更容易被察觉；开放地看看新视角带来了什么。';

  @override
  String get energyFlowing04 => '今天的信号谈的是可能性之间的流动，而不是固定的终点。';

  @override
  String get energyFlowing05 => '当情况变化时，灵活应对也许比僵硬的计划更有用。';

  @override
  String get energyFlowing06 => '流动的节律贯穿今天；不必强求答案，留意什么可以慢慢改变。';

  @override
  String get energyFlowing07 => '象征性的节律偏向转变；你仍可以按自己的步调前进。';

  @override
  String get defaultUserName => '探索者';

  @override
  String get searchCountries => '搜索国家';

  @override
  String get greetingMorning => '早上好，';

  @override
  String get greetingAfternoon => '下午好，';

  @override
  String get greetingEvening => '晚上好，';

  @override
  String get colorRoleLead => '主色';

  @override
  String get colorRoleSupporting => '辅助色';

  @override
  String colorRoleSemantics(String role, String name) {
    return '$role：$name';
  }

  @override
  String colorRoleUnavailableSemantics(String role) {
    return '$role暂不可用';
  }

  @override
  String readingAreaSemantics(String category) {
    return '解读领域：$category';
  }

  @override
  String get energyInsightNewTooltip => '今日有新的能量解读';

  @override
  String get energyInsightReadTooltip => '阅读今日能量解读';

  @override
  String get energyInsightHideTooltip => '收起今日能量解读';

  @override
  String get energyInsightCoachMark => '每天都可以在这里看到一则新的能量解读。';

  @override
  String get ritualLocked => '你的这一刻已确定。';

  @override
  String get periodPassedShort => '已过';

  @override
  String get errorNetworkHeadline => '网络连接已中断。';

  @override
  String get errorNetworkDetail => '请检查网络连接，然后重试。';

  @override
  String get errorServerHeadline => '目前无法完成解读。';

  @override
  String get errorServerDetail => '服务已响应，但未能完成处理。请稍后重试。';

  @override
  String get errorRejectedHeadline => '部分个人资料需要检查。';

  @override
  String get errorRejectedDetail => '请检查出生信息，然后重新开始解读。';

  @override
  String get errorInvalidHeadline => '此版本无法读取结果。';

  @override
  String get errorInvalidDetail => '更新应用后可能恢复解读功能。';

  @override
  String get errorConfigurationHeadline => '此版本尚未配置解读服务。';

  @override
  String get errorConfigurationDetail => '开发版本：尚未配置计算服务。';

  @override
  String get errorNothingRecorded => '本次尝试未保存任何解读。';

  @override
  String get insufficientHeading => '信息不足，暂无法解读';

  @override
  String get insufficientBody => '你的资料暂时不足以为这次解读给出方向。补充出生时间和出生国家，有助于更完整地分析周期。';

  @override
  String get periodElapsedHeading => '该时段已过去';

  @override
  String get periodElapsedBody =>
      '你所在地区的这个时段已经过去，无法再分析该时段。请选择之后的时段，或解读当前这一刻。今天的结果不会延续到明天。';

  @override
  String colorsToKeepNear(String first, String second) {
    return '适合放在身边的颜色：$first和$second';
  }

  @override
  String colorToKeepNear(String name) {
    return '适合放在身边的颜色：$name';
  }

  @override
  String get shareTooltip => '分享这次解读';

  @override
  String get shareUnavailable => '目前无法分享。';

  @override
  String get shareDisclaimer => '供日常反思的象征性视角，并非预测或概率。';

  @override
  String get backToHistory => '返回历史记录';

  @override
  String get saveFailedRetry => '保存失败 · 重试';

  @override
  String get savingToHistory => '正在保存到历史记录…';

  @override
  String get responsibleUseLink => '负责任使用与安全政策';

  @override
  String get historyToday => '今天';

  @override
  String get historyCouldNotOpen => '无法打开你的解读记录。';

  @override
  String get historyNotEnoughData => '信息不足';

  @override
  String get historyPeriodPassed => '时段已过';

  @override
  String get zodiacAries => '白羊座';

  @override
  String get zodiacTaurus => '金牛座';

  @override
  String get zodiacGemini => '双子座';

  @override
  String get zodiacCancer => '巨蟹座';

  @override
  String get zodiacLeo => '狮子座';

  @override
  String get zodiacVirgo => '处女座';

  @override
  String get zodiacLibra => '天秤座';

  @override
  String get zodiacScorpio => '天蝎座';

  @override
  String get zodiacSagittarius => '射手座';

  @override
  String get zodiacCapricorn => '摩羯座';

  @override
  String get zodiacAquarius => '水瓶座';

  @override
  String get zodiacPisces => '双鱼座';

  @override
  String zodiacAvatarSemantics(String sign) {
    return '$sign星座头像';
  }
}

/// The translations for Chinese, as used in China, using the Han script (`zh_Hans_CN`).
class AppLocalizationsZhHansCn extends AppLocalizationsZh {
  AppLocalizationsZhHansCn() : super('zh_Hans_CN');

  @override
  String get appName => 'AstraCue';

  @override
  String get continueAction => '继续';

  @override
  String get backAction => '返回';

  @override
  String get closeAction => '关闭';

  @override
  String get tryAgain => '重试';

  @override
  String get responsibleUse => '安全使用说明';

  @override
  String get history => '历史记录';

  @override
  String get onboardingTitle => '聆听宇宙的信号与你的直觉。';

  @override
  String get onboardingLanguageHint => '点击上方的地球图标以切换语言。';

  @override
  String get yourProfile => '你的资料';

  @override
  String get signAfterBirthDate => '输入出生日期后，将显示你的星座';

  @override
  String get buildPattern => '探索属于你的专属能量。';

  @override
  String get profileExplainer => '定格分析时所依据的能量周期。';

  @override
  String get nameField => '姓名';

  @override
  String get dateOfBirth => '出生日期';

  @override
  String get selectBirthDate => '选择出生日期';

  @override
  String get birthDateRequired => '请选择出生日期后继续。';

  @override
  String get birthTimeUnknown => '出生时间未知';

  @override
  String get birthTimeUnknownDetail => '若不知出生时间，算法将采用与你性格最契合的时段进行测算。';

  @override
  String get timeOfBirth => '出生时间';

  @override
  String get countryOfBirth => '出生国家';

  @override
  String get selectBirthCountry => '搜索并选择国家';

  @override
  String get birthCountryRequired => '请选择出生国家后继续。';

  @override
  String get createCompass => '创建我的指引罗盘';

  @override
  String get birthPrivacyPrototype => '在此原型版本中，你的出生信息将保持私密。';

  @override
  String get homeEyebrow => '指引方向的专属罗盘';

  @override
  String get homeTitle => '正在选择之间犹豫吗？';

  @override
  String get areaQuestion => '这与哪方面有关？';

  @override
  String get findDirection => '寻找你的专属方向';

  @override
  String get todaySignals => '今日信号';

  @override
  String get dailyEnergy => '今日能量';

  @override
  String get yourColorsToday => '今日属于你的颜色：';

  @override
  String get luckyNumberToday => '今日幸运数字：';

  @override
  String get categoryOverall => '综合';

  @override
  String get categoryLove => '爱情与人际关系';

  @override
  String get categoryCareer => '事业';

  @override
  String get categoryMoney => '财务';

  @override
  String get categoryStudy => '学习与成长';

  @override
  String get categoryFriends => '朋友';

  @override
  String get categoryOther => '其他事情';

  @override
  String get periodQuestion => '你考虑的是哪个时段？';

  @override
  String get periodNow => '现在';

  @override
  String get periodMorning => '上午';

  @override
  String get periodMidday => '中午';

  @override
  String get periodAfternoon => '下午';

  @override
  String get periodEvening => '晚间';

  @override
  String get periodPassed => '已过';

  @override
  String periodHasPassed(String period) {
    return '$period已经过去，请选择其他时段。';
  }

  @override
  String get reveal => '开始分析';

  @override
  String get aligning => '正在对齐信号';

  @override
  String get tapWhenReady => '准备好后轻点';

  @override
  String get keepChoiceInMind => '请在心中明确你正在考虑的选择。';

  @override
  String get ritualSafety => '仅供日常自我反思使用 • 不可用于医疗、投资、借贷、政治或可能造成伤害的决定。';

  @override
  String get loadingLocalMoment => '正在解读你此刻的信号';

  @override
  String get loadingReassurance => '请稍候片刻——当下的宇宙信号正在汇聚。';

  @override
  String readingForCategory(String category) {
    return '正在解读$category';
  }

  @override
  String get yourDirection => '给你的方向';

  @override
  String get resultBasis => '基于此刻属于你的能量与宇宙信号。';

  @override
  String get percentageCaveat => '百分比表示象征性的契合度，并非现实中的概率。';

  @override
  String get balancedHeading => '两边势均力敌';

  @override
  String get balancedResult => '平衡';

  @override
  String get balancedExplanation => '此刻没有哪一边更占优势。这表示平衡，并不暗示隐藏的答案。';

  @override
  String get currentMoment => '本次解读反映的是你当前的时刻。';

  @override
  String get luckyTimesCaveat =>
      '每个百分比都是该时段的象征性契合分数，不是成功概率。各时段分别评分，因此总和不一定是100%。';

  @override
  String get tryAnotherDirection => '探索其他方向';

  @override
  String get viewHistory => '查看历史记录';

  @override
  String get yourReadings => '你的解读记录';

  @override
  String get noReadings => '还没有解读记录。查看第一次指引后，记录就会出现在这里。';

  @override
  String get historySnapshot => '结果会按当时的状态保存，不会重新计算。';

  @override
  String get everydayReflection => '仅供日常自我反思。重要决定需要真实信息和专业人士的帮助。';

  @override
  String get luckyTimesMorning => '今天上午最幸运的时段';

  @override
  String get luckyTimesMidday => '今天中午最幸运的时段';

  @override
  String get luckyTimesAfternoon => '今天下午最幸运的时段';

  @override
  String get luckyTimesEvening => '今天晚间最幸运的时段';

  @override
  String get loadingLocalTime => '正在同步你所在地的日期和时辰';

  @override
  String get loadingBaZi => '正在分析你的八字五行平衡';

  @override
  String get loadingZiWei => '正在对照此刻的紫微周期';

  @override
  String get loadingVedic => '正在对照吠陀星宿与月宿';

  @override
  String get loadingNumerology => '正在梳理生命数字、月亮与行星的节律';

  @override
  String get loadingYinYang => '正在平衡阴阳信号，形成一个参考方向';

  @override
  String get loadingModeYesNo => '正在比较开放与阻力的信号';

  @override
  String get loadingModeActWait => '正在权衡行动的动力与耐心';

  @override
  String get loadingModeAdvanceRetreat => '正在权衡深度投入与适时抽离';

  @override
  String get loadingModeStayGo => '正在比较扎根与流动的信号';

  @override
  String get loadingModeKeepLetGo => '正在权衡延续与放下';

  @override
  String get loadingModeForwardBackward => '正在追踪向前与回返的节律';

  @override
  String get loadingModeLeftRight => '正在平衡接纳与表达的倾向';

  @override
  String get orbitMoment => '此刻';

  @override
  String get orbitRhythm => '节律';

  @override
  String get orbitBalance => '平衡';

  @override
  String get orbitAlmanac => '黄历';

  @override
  String get orbitBaZi => '八字';

  @override
  String get orbitZiWei => '紫微';

  @override
  String get orbitVedic => '吠陀占星';

  @override
  String get orbitNumerology => '生命数字';

  @override
  String get orbitLunarPhase => '月相';

  @override
  String get orbitPlanetary => '行星';

  @override
  String get orbitYinYang => '阴／阳';

  @override
  String get safetyHeading => '使用边界与安全说明';

  @override
  String get safetyTitle => '日常时刻的一面镜子';

  @override
  String get safetyIntro =>
      'AstraCue根据天文节律和个人周期提供象征性视角，仅供日常反思和娱乐，不是指令、预言或确定的事实。';

  @override
  String get prohibitedUses => '禁止用于以下事项';

  @override
  String get harmTitle => '自伤或伤害他人';

  @override
  String get harmDetail => '不得用于自伤、自杀、身体暴力，或让自己及他人陷入危险的决定。';

  @override
  String get navigationTitle => '驾驶与实际导航';

  @override
  String get navigationDetail => '左／右、向前／向后只是象征性选项，不得用于交通、驾驶、找路或人身安全。';

  @override
  String get politicsTitle => '政治与社会冲突';

  @override
  String get politicsDetail => '不得用于政治宣传、投票决定、社会动乱或极端主义活动。';

  @override
  String get medicalTitle => '健康、医疗与紧急情况';

  @override
  String get medicalDetail => '不能代替专业医疗服务、心理健康治疗、药物或紧急救援。';

  @override
  String get legalTitle => '法律、犯罪与重大合同';

  @override
  String get legalDetail => '不得用于犯罪行为、诉讼程序、证词或影响重大的法律合同。';

  @override
  String get financeTitle => '投资与赌博';

  @override
  String get financeDetail => '“财务”仅用于反思小额日常支出。不得把解读用于投资、借贷、加密资产投机、赌博或重大财务决定。';

  @override
  String get consentTitle => '同意、未成年人及关系';

  @override
  String get consentDetail => '不得用来无视他人的同意或自主权，也不得用于决定儿童抚养权或监护安排。';

  @override
  String get importantLimitsHeading => '重要使用边界';

  @override
  String get importantLimitsBody =>
      'AstraCue并非为儿童设计，也不提供医疗、法律或财务建议。作出重要决定时，请使用可靠信息并寻求适当的专业帮助。选择权仍在你手中。';

  @override
  String get crisisSupport => '如果你或他人正面临迫在眉睫的危险或心理危机，请立即联系当地紧急服务或可信赖的本地危机援助热线。';

  @override
  String get acknowledge => '我已了解并同意';

  @override
  String get acknowledgementOnce => '此确认仅会在第一次解读前出现一次。';

  @override
  String get knowBirthTime => '我知道自己的出生时间';

  @override
  String get knowBirthTimeDetail => '越准确的时间，时辰周期越清晰。';

  @override
  String get selectBirthTime => '选择出生时间';

  @override
  String get birthTimeRequired => '请选择出生时间后继续；如果不清楚，请关闭此选项。';

  @override
  String get languageSetting => '语言';

  @override
  String get chooseLanguage => '选择语言';

  @override
  String get changeLanguage => '切换语言';

  @override
  String get choiceYes => '是';

  @override
  String get choiceNo => '否';

  @override
  String get choiceAct => '行动';

  @override
  String get choiceWait => '等待';

  @override
  String get choiceAdvance => '投入';

  @override
  String get choiceRetreat => '抽离';

  @override
  String get choiceStay => '留下';

  @override
  String get choiceGo => '离开';

  @override
  String get choiceKeep => '保留';

  @override
  String get choiceLetGo => '放下';

  @override
  String get choiceForward => '向前';

  @override
  String get choiceBackward => '向后';

  @override
  String get choiceLeft => '左';

  @override
  String get choiceRight => '右';

  @override
  String get energyLevelQuiet => '宁静';

  @override
  String get energyLevelSoft => '柔和';

  @override
  String get energyLevelSteady => '平稳';

  @override
  String get energyLevelLively => '活跃';

  @override
  String get energyLevelBright => '明亮';

  @override
  String get energyLevelRadiant => '璀璨';

  @override
  String get energyLevelFocused => '专注';

  @override
  String get energyLevelFlowing => '流动';

  @override
  String get colorCedar => '雪松';

  @override
  String get colorJade => '翡翠';

  @override
  String get colorSage => '鼠尾草绿';

  @override
  String get colorMint => '薄荷绿';

  @override
  String get colorEmber => '余烬';

  @override
  String get colorSolarCoral => '阳光珊瑚';

  @override
  String get colorRose => '玫瑰粉';

  @override
  String get colorBlossom => '花瓣粉';

  @override
  String get colorOchre => '赭石';

  @override
  String get colorAmber => '琥珀';

  @override
  String get colorSand => '沙色';

  @override
  String get colorClay => '陶土色';

  @override
  String get colorSilver => '银色';

  @override
  String get colorSteel => '钢蓝';

  @override
  String get colorPearl => '珍珠白';

  @override
  String get colorChampagne => '香槟色';

  @override
  String get colorOceanBlue => '海洋蓝';

  @override
  String get colorAzure => '天青蓝';

  @override
  String get colorIndigo => '靛蓝';

  @override
  String get colorMistBlue => '雾蓝';

  @override
  String get homeDescription00 => '今天，宇宙也许在向你传递什么？想一想心中的犹豫，看看此刻周围有哪些信号。';

  @override
  String get homeDescription01 => '感觉被两个方向拉扯吗？让今天的宇宙信号为你的选择带来一个新视角。';

  @override
  String get homeDescription02 => '星辰不会替你作决定，但它们的运行规律或许能让你换个角度看下一步。';

  @override
  String get homeDescription03 => '前路不清晰时，先停一停，仔细看看。今天的信号提示了什么？';

  @override
  String get homeDescription04 => '每个时刻都有自己的能量。想一想你在意的事，看看此刻或许指向什么方向。';

  @override
  String get homeDescription05 => '也许宇宙正提醒你放慢脚步。选定方向前，先看看今天的信号。';

  @override
  String get homeDescription06 => '正站在岔路口吗？看看今天的天象如何与你心中的问题呼应。';

  @override
  String get homeDescription07 => '倾听此刻的节律。今天的象征或许会显出一个值得考虑的方向。';

  @override
  String get homeDescription08 => '这一刻想让你看到什么？先探索信号，再相信自己作出选择。';

  @override
  String get homeDescription09 => '一点宇宙视角或许能让思路更清晰。想想今天真正重要的事，看看信号指向哪里。';

  @override
  String get homeDescription10 => '还在反复琢磨同一个选择吗？看看今天的宇宙能量让什么变得更清楚。';

  @override
  String get homeDescription11 => '当理性指向一边、直觉指向另一边，不妨看看今天周围的信号。';

  @override
  String get homeDescription12 => '不确定该行动还是暂停？让今天的节律成为一个更平静的起点。';

  @override
  String get homeDescription13 => '如果清晰感从换个角度开始呢？看看今天的天象。';

  @override
  String get homeDescription14 => '有个问题总在心里浮现。看看今天的象征邀请你留意什么。';

  @override
  String get homeDescription15 => '有些选择在某些时刻格外沉重。决定之前，先感受此刻的能量。';

  @override
  String get homeDescription16 => '眼下道路也许还不明朗。星辰能照亮这份犹豫背后的什么？';

  @override
  String get homeDescription17 => '在一时冲动下行动之前，先深呼吸，看看今天的宇宙信号提示了什么。';

  @override
  String get homeDescription18 => '不是每个岔路口都需要立刻得到答案。让今天的解读给你一点思考空间。';

  @override
  String get homeDescription19 => '在想现在是不是合适的时机？探索今天的规律，寻找一个更稳的视角。';

  @override
  String get homeDescription20 => '当一切似乎皆有可能，却又没有定数时，让天空的节律带来新的视角。';

  @override
  String get homeDescription21 => '选择权始终在你手中。今天的信号或许能帮你看清什么最重要。';

  @override
  String get homeDescription22 => '当犹豫遮住下一步时，看看你的星座和今日能量能照亮什么。';

  @override
  String get homeDescription23 => '也许你不需要更响亮的答案，只需要和今天的象征安静相处片刻。';

  @override
  String get homeDescription24 => '直觉是在提醒你行动，还是等待？看看今天的宇宙节律映照了什么。';

  @override
  String get homeDescription25 => '在渴望与担忧之间，留一点暂停的空间。让今天的信号帮你再看一眼。';

  @override
  String get homeDescription26 => '你已经注意到了那个问题。现在，也留意这一刻吧。今天的天象信号提示什么？';

  @override
  String get homeDescription27 => '当决定变得纠结，古老的象征与今天的时机或许会显出另一个角度。';

  @override
  String get homeDescription28 => '也许此刻适合靠近一步，也许适合留些空间。看看选择周围的能量。';

  @override
  String get homeDescription29 => '你不必在这里找到确定的答案。找到一刻平静、一点宇宙提示，以及一个值得考虑的方向就好。';

  @override
  String get energyQuiet00 => '今天的象征性能量转向内心，为安静思考留出空间。';

  @override
  String get energyQuiet01 => '今天的宇宙节律转向内在；安静下来，或许能看见被喧嚣遮住的东西。';

  @override
  String get energyQuiet02 => '今天的天空带着安静的象征色彩，给思绪一些沉淀的时间。';

  @override
  String get energyQuiet03 => '一股宁静的节律贯穿今天，邀请你留意，而不是着急。';

  @override
  String get energyQuiet04 => '今天的信号提示你回望思考；暂停也可以是前进的一部分。';

  @override
  String get energyQuiet05 => '当一天显得平缓，内心的罗盘或许会更清晰。';

  @override
  String get energyQuiet06 => '今天的能量留出倾听的空间，不必急着给答案命名。';

  @override
  String get energyQuiet07 => '信号并不总是响亮地出现；慢下来，也许更容易发现今天的提示。';

  @override
  String get energySoft00 => '今天的象征性能量轻柔流动，适合关照自己、迈出小步。';

  @override
  String get energySoft01 => '今天的宇宙节律温柔流动；小步前行也许比大步跨越更自然。';

  @override
  String get energySoft02 => '今天的能量给关怀留了位置；面对选择时，不必逼自己马上确定。';

  @override
  String get energySoft03 => '今天更柔和的节律，也许能帮你从力所能及的事开始。';

  @override
  String get energySoft04 => '温柔也可以有力量；留意哪里需要放松，而不是压力。';

  @override
  String get energySoft05 => '今天的信号提示轻轻向前：足以开始，却不必催促自己。';

  @override
  String get energySoft06 => '今天的节律很细腻；简单而经过思考的行动或许更有意义。';

  @override
  String get energySoft07 => '再小的契机也可能重要；今天温柔的节律留出了探索空间。';

  @override
  String get energySteady00 => '今天的象征性能量保持平稳、踏实的节律。';

  @override
  String get energySteady01 => '今天的象征性能量节奏平稳；相信自己能持续的步调。';

  @override
  String get energySteady02 => '今天的宇宙节律让人感到踏实，适合从容思考、有意识地行动。';

  @override
  String get energySteady03 => '平稳的节律贯穿今天；专注也许比急迫更有帮助。';

  @override
  String get energySteady04 => '今天的信号指向平衡，但并不要求你停在原地。';

  @override
  String get energySteady05 => '持续本身也是力量；停下来想过之后，留意哪一步依然有意义。';

  @override
  String get energySteady06 => '今天的能量不急不缓，给你的选择一些成形的时间。';

  @override
  String get energySteady07 => '平静的节律也能指路；今天的进展不必轰轰烈烈。';

  @override
  String get energyLively00 => '一点轻快的火花点亮今天的象征性能量，带来好奇和变化。';

  @override
  String get energyLively01 => '好奇心点亮今天的象征性能量；一个新角度也许值得探索。';

  @override
  String get energyLively02 => '今天更有活力；留意吸引你的事，但不必急着投入。';

  @override
  String get energyLively03 => '今天的宇宙节律邀请你探索，同时保留判断的余地。';

  @override
  String get energyLively04 => '一股轻快的节律流过今天，可能在意想不到的地方发现新可能。';

  @override
  String get energyLively05 => '今天的好奇心或许是有用的信号；作出承诺前，先看看它指向哪里。';

  @override
  String get energyLively06 => '今天的信号带着动感；你可以探索，不必急着定下来。';

  @override
  String get energyLively07 => '今天的能量很活跃；先让它拓宽选择，再慢慢收拢。';

  @override
  String get energyBright00 => '今天的象征性能量明亮而有动力，也给表达留出空间。';

  @override
  String get energyBright01 => '今天的象征性能量让你想表达的事更清晰。';

  @override
  String get energyBright02 => '更明亮的宇宙节律或许能帮你看见哪种可能值得关注。';

  @override
  String get energyBright03 => '今天的信号显得开放；下一步或许更容易说清。';

  @override
  String get energyBright04 => '今天有表达的动力；当时机合适时，说出重要的事。';

  @override
  String get energyBright05 => '今天节律中的一处敞开，或许能带来清晰感，而不必催促你。';

  @override
  String get energyBright06 => '今天的能量更向外延展；留意你准备好展现什么。';

  @override
  String get energyBright07 => '一点亮光就能改变视角；今天的节律邀请你向前看。';

  @override
  String get energyRadiant00 => '今天的象征性能量达到最明亮的状态：开放而舒展。';

  @override
  String get energyRadiant01 => '今天的象征性能量充分展开，邀请你看见不止一条可能的路。';

  @override
  String get energyRadiant02 => '明亮的节律流过今天；保持自己的重心，也让可能性展开。';

  @override
  String get energyRadiant03 => '今天的宇宙节律格外开放，给启发你的事留一些空间。';

  @override
  String get energyRadiant04 => '更充盈的光彩映在今天的能量里，让你从更宽的视野看见可能性。';

  @override
  String get energyRadiant05 => '今天的信号带着舒展感；也许更容易想象接下来会怎样。';

  @override
  String get energyRadiant06 => '让今天的暖意拓宽眼界，同时把最终选择留在自己手中。';

  @override
  String get energyRadiant07 => '今天的天空带着丰沛的象征节律；带着清醒的判断欢迎新的可能。';

  @override
  String get energyFocused00 => '今天的象征性能量聚向清晰的方向；行动信号更为突出。';

  @override
  String get energyFocused01 => '今天的行动信号逐渐清晰；留意一个有意识的下一步。';

  @override
  String get energyFocused02 => '象征性的节律偏向行动，但步调仍由你决定。';

  @override
  String get energyFocused03 => '今天带着方向感；把注意力放在你真正能影响的事上。';

  @override
  String get energyFocused04 => '当选项彼此拉扯，今天的信号邀请你先专注于一个实际行动。';

  @override
  String get energyFocused05 => '今天的信号聚向一个意图；留意它，但不必匆忙。';

  @override
  String get energyFocused06 => '今天行动的象征性吸引更强；迈步之前先弄清自己的理由。';

  @override
  String get energyFocused07 => '今天重在意图，而非强度；让选定的方向慢慢成形。';

  @override
  String get energyFlowing00 => '今天的象征性能量如潮汐流动；变化信号更为突出。';

  @override
  String get energyFlowing01 => '今天的变化信号更加明显；给计划留一点弹性。';

  @override
  String get energyFlowing02 => '变化中的宇宙节律贯穿今天；保持灵活，也许会看见另一条路。';

  @override
  String get energyFlowing03 => '变化的能量更容易被察觉；开放地看看新视角带来了什么。';

  @override
  String get energyFlowing04 => '今天的信号谈的是可能性之间的流动，而不是固定的终点。';

  @override
  String get energyFlowing05 => '当情况变化时，灵活应对也许比僵硬的计划更有用。';

  @override
  String get energyFlowing06 => '流动的节律贯穿今天；不必强求答案，留意什么可以慢慢改变。';

  @override
  String get energyFlowing07 => '象征性的节律偏向转变；你仍可以按自己的步调前进。';

  @override
  String get defaultUserName => '探索者';

  @override
  String get searchCountries => '搜索国家';

  @override
  String get greetingMorning => '早上好，';

  @override
  String get greetingAfternoon => '下午好，';

  @override
  String get greetingEvening => '晚上好，';

  @override
  String get colorRoleLead => '主色';

  @override
  String get colorRoleSupporting => '辅助色';

  @override
  String colorRoleSemantics(String role, String name) {
    return '$role：$name';
  }

  @override
  String colorRoleUnavailableSemantics(String role) {
    return '$role暂不可用';
  }

  @override
  String readingAreaSemantics(String category) {
    return '解读领域：$category';
  }

  @override
  String get energyInsightNewTooltip => '今日有新的能量解读';

  @override
  String get energyInsightReadTooltip => '阅读今日能量解读';

  @override
  String get energyInsightHideTooltip => '收起今日能量解读';

  @override
  String get energyInsightCoachMark => '每天都可以在这里看到一则新的能量解读。';

  @override
  String get ritualLocked => '你的这一刻已确定。';

  @override
  String get periodPassedShort => '已过';

  @override
  String get errorNetworkHeadline => '网络连接已中断。';

  @override
  String get errorNetworkDetail => '请检查网络连接，然后重试。';

  @override
  String get errorServerHeadline => '目前无法完成解读。';

  @override
  String get errorServerDetail => '服务已响应，但未能完成处理。请稍后重试。';

  @override
  String get errorRejectedHeadline => '部分个人资料需要检查。';

  @override
  String get errorRejectedDetail => '请检查出生信息，然后重新开始解读。';

  @override
  String get errorInvalidHeadline => '此版本无法读取结果。';

  @override
  String get errorInvalidDetail => '更新应用后可能恢复解读功能。';

  @override
  String get errorConfigurationHeadline => '此版本尚未配置解读服务。';

  @override
  String get errorConfigurationDetail => '开发版本：尚未配置计算服务。';

  @override
  String get errorNothingRecorded => '本次尝试未保存任何解读。';

  @override
  String get insufficientHeading => '信息不足，暂无法解读';

  @override
  String get insufficientBody => '你的资料暂时不足以为这次解读给出方向。补充出生时间和出生国家，有助于更完整地分析周期。';

  @override
  String get periodElapsedHeading => '该时段已过去';

  @override
  String get periodElapsedBody =>
      '你所在地区的这个时段已经过去，无法再分析该时段。请选择之后的时段，或解读当前这一刻。今天的结果不会延续到明天。';

  @override
  String colorsToKeepNear(String first, String second) {
    return '适合放在身边的颜色：$first和$second';
  }

  @override
  String colorToKeepNear(String name) {
    return '适合放在身边的颜色：$name';
  }

  @override
  String get shareTooltip => '分享这次解读';

  @override
  String get shareUnavailable => '目前无法分享。';

  @override
  String get shareDisclaimer => '供日常反思的象征性视角，并非预测或概率。';

  @override
  String get backToHistory => '返回历史记录';

  @override
  String get saveFailedRetry => '保存失败 · 重试';

  @override
  String get savingToHistory => '正在保存到历史记录…';

  @override
  String get responsibleUseLink => '负责任使用与安全政策';

  @override
  String get historyToday => '今天';

  @override
  String get historyCouldNotOpen => '无法打开你的解读记录。';

  @override
  String get historyNotEnoughData => '信息不足';

  @override
  String get historyPeriodPassed => '时段已过';

  @override
  String get zodiacAries => '白羊座';

  @override
  String get zodiacTaurus => '金牛座';

  @override
  String get zodiacGemini => '双子座';

  @override
  String get zodiacCancer => '巨蟹座';

  @override
  String get zodiacLeo => '狮子座';

  @override
  String get zodiacVirgo => '处女座';

  @override
  String get zodiacLibra => '天秤座';

  @override
  String get zodiacScorpio => '天蝎座';

  @override
  String get zodiacSagittarius => '射手座';

  @override
  String get zodiacCapricorn => '摩羯座';

  @override
  String get zodiacAquarius => '水瓶座';

  @override
  String get zodiacPisces => '双鱼座';

  @override
  String zodiacAvatarSemantics(String sign) {
    return '$sign星座头像';
  }
}
