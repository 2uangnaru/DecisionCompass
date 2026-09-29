// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appName => 'AstraCue';

  @override
  String get continueAction => '続ける';

  @override
  String get backAction => '戻る';

  @override
  String get closeAction => '閉じる';

  @override
  String get tryAgain => 'もう一度試す';

  @override
  String get responsibleUse => '安全な使い方';

  @override
  String get history => '履歴';

  @override
  String get onboardingTitle => '今この場所、この瞬間を読み解く。';

  @override
  String get onboardingLanguageHint =>
      '別の言語で使いたい方は、上の地球アイコンをタップしてください。言語はいつでも変更できます。';

  @override
  String get yourProfile => 'あなたのプロフィール';

  @override
  String get signAfterBirthDate => '生年月日を入力すると星座が表示されます';

  @override
  String get buildPattern => 'あなただけのエネルギーを見つけましょう。';

  @override
  String get profileExplainer => '分析時に用いる周期を導き出します。';

  @override
  String get nameField => '名前';

  @override
  String get dateOfBirth => '生年月日';

  @override
  String get selectBirthDate => '生年月日を選択';

  @override
  String get birthDateRequired => '続けるには生年月日を選択してください。';

  @override
  String get birthTimeUnknown => '出生時刻が不明';

  @override
  String get birthTimeUnknownDetail => '出生時刻が分からない場合、あなたの性格に最も近い時間帯を用いて算出します。';

  @override
  String get timeOfBirth => '出生時刻';

  @override
  String get countryOfBirth => '出生国';

  @override
  String get selectBirthCountry => '国を検索して選択';

  @override
  String get birthCountryRequired => '続けるには出生国を選択してください。';

  @override
  String get createCompass => '私のコンパスを作る';

  @override
  String get birthPrivacyPrototype => 'この試作版では、出生情報は非公開のまま保たれます。';

  @override
  String get homeEyebrow => 'あなたを導く、心の羅針盤';

  @override
  String get homeTitle => '選択肢の間で迷っていますか？';

  @override
  String get areaQuestion => 'どんなことについてですか？';

  @override
  String get findDirection => '進むべき道を見つける';

  @override
  String get todaySignals => '今日のサイン';

  @override
  String get dailyEnergy => '今日のエネルギー';

  @override
  String get yourColorsToday => '今日の色：';

  @override
  String get luckyNumberToday => '今日のラッキーナンバー：';

  @override
  String get categoryOverall => '全体';

  @override
  String get categoryLove => '恋愛・人間関係';

  @override
  String get categoryCareer => '仕事';

  @override
  String get categoryMoney => '財務';

  @override
  String get categoryStudy => '学び・成長';

  @override
  String get categoryFriends => '友人';

  @override
  String get categoryOther => 'その他';

  @override
  String get periodQuestion => 'いつのことを考えていますか？';

  @override
  String get periodNow => '今';

  @override
  String get periodMorning => '朝';

  @override
  String get periodMidday => '昼';

  @override
  String get periodAfternoon => '午後';

  @override
  String get periodEvening => '夜';

  @override
  String get periodPassed => '終了';

  @override
  String periodHasPassed(String period) {
    return '$periodは過ぎました。別の時間帯を選んでください。';
  }

  @override
  String get reveal => '分析する';

  @override
  String get aligning => '調整中';

  @override
  String get tapWhenReady => '準備ができたらタップ';

  @override
  String get keepChoiceInMind => '迷っていることを心に思い浮かべてください。';

  @override
  String get ritualSafety => '日常の振り返り専用です。医療・投資・借入・政治・危険な判断には使わないでください。';

  @override
  String get loadingLocalMoment => '今この場所の瞬間を読み解いています';

  @override
  String get loadingReassurance => '少々お待ちください。宇宙のサインを整えています。';

  @override
  String readingForCategory(String category) {
    return '$categoryについて読み解いています';
  }

  @override
  String get yourDirection => 'あなたへの方向性';

  @override
  String get resultBasis => 'この瞬間のあなたに寄り添うエネルギーと宇宙のサインに基づいて。';

  @override
  String get percentageCaveat => 'パーセンテージは象徴的な一致度であり、現実の確率ではありません。';

  @override
  String get balancedHeading => 'どちらも均衡';

  @override
  String get balancedResult => '均衡';

  @override
  String get balancedExplanation => '今はどちらも優勢ではありません。これは均衡を示すもので、隠れた答えではありません。';

  @override
  String get currentMoment => 'このリーディングは今この瞬間を映しています。';

  @override
  String get luckyTimesCaveat =>
      '各パーセンテージは時間帯との象徴的な一致度で、成功確率ではありません。時間帯ごとに独立して算出するため、合計は100%になりません。';

  @override
  String get tryAnotherDirection => '別の方向性を見る';

  @override
  String get viewHistory => '履歴を見る';

  @override
  String get yourReadings => 'あなたの履歴';

  @override
  String get noReadings => 'まだ履歴はありません。最初の方向性を見て、履歴を始めましょう。';

  @override
  String get historySnapshot => '結果はその時点の記録として保存され、再計算されません。';

  @override
  String get everydayReflection => '日常の振り返り専用です。重要な判断には事実に基づく情報と専門家の助けが必要です。';

  @override
  String get luckyTimesMorning => '今朝、特に運が向く時間帯';

  @override
  String get luckyTimesMidday => '今日の昼、特に運が向く時間帯';

  @override
  String get luckyTimesAfternoon => '今日の午後、特に運が向く時間帯';

  @override
  String get luckyTimesEvening => '今夜、特に運が向く時間帯';

  @override
  String get loadingLocalTime => '現在地の時刻と時間帯を確認しています';

  @override
  String get loadingBaZi => 'BaZiの五行バランスを読み解いています';

  @override
  String get loadingZiWei => 'この瞬間に重なるZi Weiの周期を見ています';

  @override
  String get loadingVedic => 'ヴェーダ占星術のナクシャトラと月宿を照らし合わせています';

  @override
  String get loadingNumerology => '数秘術、月、惑星のリズムをたどっています';

  @override
  String get loadingYinYang => '陰と陽のサインを一つの方向にまとめています';

  @override
  String get loadingModeYesNo => '開放と抵抗のサインを比べています';

  @override
  String get loadingModeActWait => '行動の勢いと待つ余地を比べています';

  @override
  String get loadingModeAdvanceRetreat => 'コミットする動きと身を引く動きを読み解いています';

  @override
  String get loadingModeStayGo => '根づくことと動くことを比べています';

  @override
  String get loadingModeKeepLetGo => '続けることと手放すことを見比べています';

  @override
  String get loadingModeForwardBackward => '前へ進む流れと戻る流れをたどっています';

  @override
  String get loadingModeLeftRight => '受け取ることと表すことの両極を比べています';

  @override
  String get orbitMoment => 'この瞬間';

  @override
  String get orbitRhythm => 'リズム';

  @override
  String get orbitBalance => 'バランス';

  @override
  String get orbitAlmanac => '暦';

  @override
  String get orbitBaZi => 'BaZi';

  @override
  String get orbitZiWei => 'Zi Wei';

  @override
  String get orbitVedic => 'ヴェーダ占星術';

  @override
  String get orbitNumerology => '数秘術';

  @override
  String get orbitLunarPhase => '月の満ち欠け';

  @override
  String get orbitPlanetary => '惑星';

  @override
  String get orbitYinYang => '陰／陽';

  @override
  String get safetyHeading => '利用上の注意と安全について';

  @override
  String get safetyTitle => '日常を映す、一つの視点';

  @override
  String get safetyIntro =>
      'AstraCueは、天体のリズムと個人の周期に着想を得た象徴的な視点を提供します。日常の振り返りと娯楽のためのものであり、命令・予言・確実な事実ではありません。';

  @override
  String get prohibitedUses => '禁止される用途';

  @override
  String get harmTitle => '自傷・他者への危害';

  @override
  String get harmDetail => '自傷、自殺、身体的な暴力、または自分や他人を危険にさらす判断には使わないでください。';

  @override
  String get navigationTitle => '運転・実際の道案内';

  @override
  String get navigationDetail =>
      '左／右、前へ／後ろへは象徴的な選択肢です。交通、運転、経路案内、身体の安全に関わる判断には使わないでください。';

  @override
  String get politicsTitle => '政治・社会的な対立';

  @override
  String get politicsDetail => '政治運動、投票の判断、社会的な混乱、過激な活動には使わないでください。';

  @override
  String get medicalTitle => '健康・医療・緊急時';

  @override
  String get medicalDetail => '医療専門家による診療、精神的なケア、薬、緊急時の対応の代わりにはなりません。';

  @override
  String get legalTitle => '法律・犯罪・重大な契約';

  @override
  String get legalDetail => '犯罪行為、裁判手続き、証言、重大な法的契約の判断には使わないでください。';

  @override
  String get financeTitle => '投資・ギャンブル';

  @override
  String get financeDetail =>
      '「財務」は少額の支出を振り返るためだけの項目です。投資、借入、暗号資産への投機、ギャンブル、重大な金銭判断には使わないでください。';

  @override
  String get consentTitle => '同意・未成年者・人間関係';

  @override
  String get consentDetail => '他人の同意や自己決定を無視するため、また子どもの親権や後見の判断には使わないでください。';

  @override
  String get importantLimitsHeading => '大切な注意事項';

  @override
  String get importantLimitsBody =>
      'AstraCueは子ども向けに設計されていません。医療・法律・金融に関する助言は提供しません。重要な判断には、信頼できる情報と適切な専門家の助けを利用してください。選ぶのはあなた自身です。';

  @override
  String get crisisSupport =>
      'あなたや周囲の人が差し迫った危険や心の危機にある場合は、地域の緊急サービスまたは信頼できる相談窓口にすぐ連絡してください。';

  @override
  String get acknowledge => '理解して同意する';

  @override
  String get acknowledgementOnce => 'この確認は、最初のリーディング前に一度だけ表示されます。';

  @override
  String get knowBirthTime => '出生時刻がわかる';

  @override
  String get knowBirthTimeDetail => '正確な時刻ほど、時辰の周期がはっきりします。';

  @override
  String get selectBirthTime => '出生時刻を選択';

  @override
  String get birthTimeRequired => '続けるには出生時刻を選択してください。わからない場合はこの設定をオフにしてください。';

  @override
  String get languageSetting => '言語';

  @override
  String get chooseLanguage => '言語を選択';

  @override
  String get changeLanguage => '言語を変更';

  @override
  String get choiceYes => 'はい';

  @override
  String get choiceNo => 'いいえ';

  @override
  String get choiceAct => '行動する';

  @override
  String get choiceWait => '待つ';

  @override
  String get choiceAdvance => '踏み込む';

  @override
  String get choiceRetreat => '引く';

  @override
  String get choiceStay => 'とどまる';

  @override
  String get choiceGo => '離れる';

  @override
  String get choiceKeep => '持ち続ける';

  @override
  String get choiceLetGo => '手放す';

  @override
  String get choiceForward => '前へ';

  @override
  String get choiceBackward => '後ろへ';

  @override
  String get choiceLeft => '左';

  @override
  String get choiceRight => '右';

  @override
  String get energyLevelQuiet => '静穏';

  @override
  String get energyLevelSoft => 'やわらか';

  @override
  String get energyLevelSteady => '安定';

  @override
  String get energyLevelLively => '活発';

  @override
  String get energyLevelBright => '明るい';

  @override
  String get energyLevelRadiant => '輝き';

  @override
  String get energyLevelFocused => '集中';

  @override
  String get energyLevelFlowing => '流動';

  @override
  String get colorCedar => 'シダー';

  @override
  String get colorJade => '翡翠';

  @override
  String get colorSage => 'セージ';

  @override
  String get colorMint => 'ミント';

  @override
  String get colorEmber => '残り火';

  @override
  String get colorSolarCoral => 'サンコーラル';

  @override
  String get colorRose => 'ローズ';

  @override
  String get colorBlossom => 'ブロッサムピンク';

  @override
  String get colorOchre => 'オーカー';

  @override
  String get colorAmber => '琥珀';

  @override
  String get colorSand => 'サンド';

  @override
  String get colorClay => 'クレイ';

  @override
  String get colorSilver => 'シルバー';

  @override
  String get colorSteel => 'スチール';

  @override
  String get colorPearl => 'パール';

  @override
  String get colorChampagne => 'シャンパン';

  @override
  String get colorOceanBlue => 'オーシャンブルー';

  @override
  String get colorAzure => 'アジュール';

  @override
  String get colorIndigo => 'インディゴ';

  @override
  String get colorMistBlue => 'ミストブルー';

  @override
  String get homeDescription00 =>
      '今日、宇宙はあなたに何を伝えているのでしょう。心にある迷いを選び、この瞬間のサインを見つめてみましょう。';

  @override
  String get homeDescription01 =>
      '二つの方向に引かれるような気持ちですか？ 今日の宇宙のサインが、選択を別の角度から見るきっかけになるかもしれません。';

  @override
  String get homeDescription02 =>
      '星が代わりに決めることはありません。でも、その巡りは次の一歩を違った角度から見せてくれるかもしれません。';

  @override
  String get homeDescription03 => '進む道が見えにくいときは、少し立ち止まって。今日のサインは何を示しているでしょうか。';

  @override
  String get homeDescription04 =>
      'どの瞬間にも、それぞれのエネルギーがあります。気になることを選び、この瞬間が示すかもしれない方向を探りましょう。';

  @override
  String get homeDescription05 =>
      '宇宙は少しペースを落とすよう促しているのかもしれません。道を選ぶ前に、今日のサインを眺めてみましょう。';

  @override
  String get homeDescription06 => '岐路に立っていますか？ 今日の天体の巡りが、心の問いとどう響き合うか見てみましょう。';

  @override
  String get homeDescription07 =>
      'この瞬間のリズムに耳を澄ませて。今日の象徴が、考えてみる価値のある方向を示すかもしれません。';

  @override
  String get homeDescription08 => 'この瞬間は何を見せてくれるでしょう。サインを探ったあとは、自分を信じて選んでください。';

  @override
  String get homeDescription09 =>
      '宇宙からの小さな視点が、気持ちを整理する助けになるかもしれません。今日大切なことを選び、サインの向きを見てみましょう。';

  @override
  String get homeDescription10 =>
      '同じ選択を何度も考えていますか？ 今日の宇宙のエネルギーが、何を浮かび上がらせるか見てみましょう。';

  @override
  String get homeDescription11 => '考えは一方へ、直感はもう一方へ向かうとき。今日を取り巻くサインを探ってみましょう。';

  @override
  String get homeDescription12 =>
      '進むか、待つか迷っていますか？ 今日のリズムを、落ち着いて考えるための出発点にしてみましょう。';

  @override
  String get homeDescription13 =>
      '見方を変えることから、明確さが生まれるかもしれません。今日の天体の巡りに目を向けてみましょう。';

  @override
  String get homeDescription14 =>
      '何度も心に戻ってくる問いがありますか？ 今日の象徴が何に気づかせてくれるか探ってみましょう。';

  @override
  String get homeDescription15 =>
      '同じ選択でも、時によって重く感じるもの。決める前に、この瞬間のエネルギーを眺めてみましょう。';

  @override
  String get homeDescription16 => '今は道がはっきり見えないかもしれません。その迷いの奥に、星は何を照らすでしょうか。';

  @override
  String get homeDescription17 => '衝動のまま動く前に、ひと呼吸。今日の宇宙のサインが何を示すか見てみましょう。';

  @override
  String get homeDescription18 =>
      'すべての岐路に、すぐ答えが必要なわけではありません。今日のリーディングを、考えるための余白にしてください。';

  @override
  String get homeDescription19 =>
      '今がその時か迷っていますか？ 今日の巡りを探り、もう少し落ち着いた視点を見つけましょう。';

  @override
  String get homeDescription20 =>
      '何でもできそうなのに、確かなことがないとき。空の巡りが新しい見方をくれるかもしれません。';

  @override
  String get homeDescription21 => '選ぶのはあなた自身。今日のサインは、本当に大切なことに気づく助けになるかもしれません。';

  @override
  String get homeDescription22 =>
      '迷いで次の一歩が見えないとき、あなたの星座と今日のエネルギーが何を照らすか見てみましょう。';

  @override
  String get homeDescription23 => 'もっと強い答えより、今日の象徴と静かに向き合う時間が必要なのかもしれません。';

  @override
  String get homeDescription24 =>
      '直感は行動を促していますか、それとも待つよう告げていますか？ 今日の宇宙のリズムを見てみましょう。';

  @override
  String get homeDescription25 =>
      '望みと不安の間には、立ち止まる余地があります。今日のサインを手がかりに、もう一度見つめてみましょう。';

  @override
  String get homeDescription26 =>
      '問いには気づきました。今度は、この瞬間にも目を向けて。今日の天体のサインは何を示すでしょうか。';

  @override
  String get homeDescription27 =>
      '決断が複雑に感じるとき、古くからの象徴と今日という時間が別の角度を見せるかもしれません。';

  @override
  String get homeDescription28 =>
      '今は一歩近づくときか、それとも少し距離を置くときか。選択を取り巻くエネルギーを探ってみましょう。';

  @override
  String get homeDescription29 =>
      'ここで確信を得る必要はありません。心を落ち着け、宇宙の小さなヒントと、考えるための方向を見つけましょう。';

  @override
  String get energyQuiet00 => '今日の象徴的なエネルギーは内側へ向かい、静かに振り返る余白をつくります。';

  @override
  String get energyQuiet01 => '今日の宇宙のリズムは内側へ。静けさの中で、騒がしさに隠れていたものに気づくかもしれません。';

  @override
  String get energyQuiet02 => '今日の空には静かな気配があります。考えが落ち着く時間をつくりましょう。';

  @override
  String get energyQuiet03 => '今日は穏やかな流れがあります。急ぐより、気づくことに目を向けてみましょう。';

  @override
  String get energyQuiet04 => '今日のサインは振り返ることを促します。立ち止まるのも、前に進む過程の一つです。';

  @override
  String get energyQuiet05 => '穏やかな日には、心のコンパスの声が聞こえやすくなるかもしれません。';

  @override
  String get energyQuiet06 => '今日のエネルギーは、答えを言葉にする前に耳を澄ませる余地をくれます。';

  @override
  String get energyQuiet07 =>
      'サインはいつも大きな音で届くわけではありません。今日はゆっくりすると気づきやすいかもしれません。';

  @override
  String get energySoft00 => '今日の象徴的なエネルギーはやさしく流れ、思いやりと小さな一歩を支えます。';

  @override
  String get energySoft01 => '今日は穏やかな宇宙の流れがあります。大きく跳ぶより、小さな一歩が自然に感じられるかもしれません。';

  @override
  String get energySoft02 => '今日のエネルギーには、いたわる余地があります。確信を急がず、選択に向き合いましょう。';

  @override
  String get energySoft03 => '今日のやわらかなリズムは、無理なくできることから始める助けになるかもしれません。';

  @override
  String get energySoft04 => 'やさしさも強さの一つ。今日はプレッシャーより、心地よさが必要な場所に気づいてください。';

  @override
  String get energySoft05 => '今日のサインは、軽やかな一歩を示します。始めるには十分でも、急ぐ必要はありません。';

  @override
  String get energySoft06 => '今日は繊細な流れです。シンプルで思慮深い行動に、意味が宿るかもしれません。';

  @override
  String get energySoft07 => '小さなきっかけにも価値があります。今日の穏やかな巡りの中で探ってみましょう。';

  @override
  String get energySteady00 => '今日の象徴的なエネルギーには、落ち着いた安定したリズムがあります。';

  @override
  String get energySteady01 => '今日の象徴的なエネルギーは一定のリズムを保っています。続けられるペースを大切に。';

  @override
  String get energySteady02 => '宇宙の巡りには落ち着きがあり、考えてから動く余裕をくれます。';

  @override
  String get energySteady03 => '今日は安定した流れがあります。急ぐことより、丁寧に注意を向けることが役立つかもしれません。';

  @override
  String get energySteady04 => '今日のサインはバランスを示します。立ち止まり続ける必要はありません。';

  @override
  String get energySteady05 => '続けることにも強さがあります。ひと息ついた後も納得できる一歩に目を向けましょう。';

  @override
  String get energySteady06 => '今日はほどよく整ったエネルギーがあり、選択が形になる時間をくれます。';

  @override
  String get energySteady07 => '穏やかなリズムも道しるべ。今日の前進は劇的でなくてもかまいません。';

  @override
  String get energyLively00 => '今日の象徴的なエネルギーに遊び心が灯り、好奇心と動きが生まれます。';

  @override
  String get energyLively01 => '今日の象徴的なエネルギーに好奇心が灯ります。新しい角度を探る価値があるかもしれません。';

  @override
  String get energyLively02 => '今日は少し活気があります。惹かれるものに気づきつつ、飛びつく前に一呼吸。';

  @override
  String get energyLively03 => '今日の宇宙のリズムは発見を促します。見極める余裕も忘れずに。';

  @override
  String get energyLively04 => '今日は弾むような流れがあります。思いがけないところに可能性が見えるかもしれません。';

  @override
  String get energyLively05 => '好奇心が今日のヒントになるかもしれません。決める前に、その向かう先を見てみましょう。';

  @override
  String get energyLively06 => '今日のサインには動きがあります。すぐに決めなくても、探ることはできます。';

  @override
  String get energyLively07 => '今日は活気あるエネルギーです。選択肢を絞る前に、視野を広げてみましょう。';

  @override
  String get energyBright00 => '今日の象徴的なエネルギーには勢いと、自分を表現する余白があります。';

  @override
  String get energyBright01 => '今日の象徴的なエネルギーは、あなたが伝えたいことを少し明るく照らします。';

  @override
  String get energyBright02 => '明るい宇宙の流れが、注目したい可能性を見つける助けになるかもしれません。';

  @override
  String get energyBright03 => '今日のサインには開放感があります。次の一歩を言葉にしやすくなるかもしれません。';

  @override
  String get energyBright04 => '今日は表現する勢いがあります。時が来たと感じたら、大切なことを伝えてみましょう。';

  @override
  String get energyBright05 => '今日のリズムの中にある開きが、急がずに気持ちを整理する助けになるかもしれません。';

  @override
  String get energyBright06 => '今日のエネルギーは外へ向かっています。表に出す準備ができたことに気づいてください。';

  @override
  String get energyBright07 => '少しの明るさで見方は変わります。今日の巡りは前を見るよう誘っています。';

  @override
  String get energyRadiant00 => '今日の象徴的なエネルギーは最も明るく、開放的で広がりがあります。';

  @override
  String get energyRadiant01 => '今日の象徴的なエネルギーは大きく開き、複数の道を見るよう促します。';

  @override
  String get energyRadiant02 => '今日は輝くような流れがあります。自分の軸を保ちながら可能性を広げましょう。';

  @override
  String get energyRadiant03 => '宇宙の巡りはとりわけ開放的です。心が動くもののために余白をつくりましょう。';

  @override
  String get energyRadiant04 => '今日のエネルギーはより明るく、可能性を広い視野から見せてくれます。';

  @override
  String get energyRadiant05 => '今日のサインには広がりがあり、次を思い描きやすいかもしれません。';

  @override
  String get energyRadiant06 => '今日の温かさで視野を広げながら、最後に選ぶのは自分自身だと忘れずに。';

  @override
  String get energyRadiant07 => '今日の空の象徴的なリズムは豊かです。地に足をつけて可能性を迎えましょう。';

  @override
  String get energyFocused00 => '今日の象徴的なエネルギーは一つの方向に集まり、行動のサインが前に出ています。';

  @override
  String get energyFocused01 => '今日の行動のサインがはっきりしています。意図を持てる一歩に注目しましょう。';

  @override
  String get energyFocused02 => '象徴的な流れは行動に傾いていますが、ペースはあなたが選べます。';

  @override
  String get energyFocused03 => '今日は方向感があります。実際に働きかけられることに目を向けましょう。';

  @override
  String get energyFocused04 => '選択肢が競い合うとき、今日のサインは現実的な一歩に集中するよう促します。';

  @override
  String get energyFocused05 => '今日のサインは一つの意図に集まります。急がず、そこに注意を向けてみましょう。';

  @override
  String get energyFocused06 => '今日は行動の象徴的な引力が強めです。動く前に理由をはっきりさせましょう。';

  @override
  String get energyFocused07 => '今日は勢いより意図を大切に。選んだ方向を少しずつ形にしましょう。';

  @override
  String get energyFlowing00 => '今日の象徴的なエネルギーは潮のように動き、変化のサインが前に出ています。';

  @override
  String get energyFlowing01 => '今日は変化のサインが強まっています。計画に少し柔軟さを持たせましょう。';

  @override
  String get energyFlowing02 => '変わりゆく宇宙の流れの中で、柔軟さが別の道を見せるかもしれません。';

  @override
  String get energyFlowing03 => '変化のエネルギーが目立つ日です。新しい見方が示すものに心を開いて。';

  @override
  String get energyFlowing04 => '今日のサインが示すのは、決まった行き先ではなく可能性の間の動きです。';

  @override
  String get energyFlowing05 => '状況が変わるときは、固い計画より柔軟な対応が役立つかもしれません。';

  @override
  String get energyFlowing06 => '今日は流れるようなリズムがあります。答えを急がず、変わっていけるものに気づきましょう。';

  @override
  String get energyFlowing07 => '象徴的な流れは転換に傾いています。自分のペースで進んでかまいません。';

  @override
  String get defaultUserName => '探求者';

  @override
  String get searchCountries => '国を検索';

  @override
  String get greetingMorning => 'おはようございます、';

  @override
  String get greetingAfternoon => 'こんにちは、';

  @override
  String get greetingEvening => 'こんばんは、';

  @override
  String get colorRoleLead => 'メイン';

  @override
  String get colorRoleSupporting => 'サポート';

  @override
  String colorRoleSemantics(String role, String name) {
    return '$roleカラー：$name';
  }

  @override
  String colorRoleUnavailableSemantics(String role) {
    return '$roleカラーはまだありません';
  }

  @override
  String readingAreaSemantics(String category) {
    return 'リーディングの分野：$category';
  }

  @override
  String get energyInsightNewTooltip => '今日の新しいエネルギーのヒント';

  @override
  String get energyInsightReadTooltip => '今日のエネルギーの意味を読む';

  @override
  String get energyInsightHideTooltip => '今日のエネルギーの意味を閉じる';

  @override
  String get energyInsightCoachMark => 'ここで毎日、新しいエネルギーのヒントを読めます。';

  @override
  String get ritualLocked => 'この瞬間が確定しました。';

  @override
  String get periodPassedShort => '終了';

  @override
  String get errorNetworkHeadline => '接続が途切れました。';

  @override
  String get errorNetworkDetail => '接続を確認して、もう一度お試しください。';

  @override
  String get errorServerHeadline => '現在、リーディングを完了できません。';

  @override
  String get errorServerDetail => 'サービスは応答しましたが、処理を完了できませんでした。少し待ってからお試しください。';

  @override
  String get errorRejectedHeadline => 'プロフィール情報の一部を確認してください。';

  @override
  String get errorRejectedDetail => '出生情報を確認し、新しいリーディングを始めてください。';

  @override
  String get errorInvalidHeadline => 'このバージョンでは結果を読み取れませんでした。';

  @override
  String get errorInvalidDetail => 'アプリを更新すると、再び結果を読める可能性があります。';

  @override
  String get errorConfigurationHeadline => 'このビルドにはリーディングサービスが設定されていません。';

  @override
  String get errorConfigurationDetail => '開発用ビルド：計算サービスが設定されていません。';

  @override
  String get errorNothingRecorded => '今回はリーディングが記録されませんでした。';

  @override
  String get insufficientHeading => '読み解く情報が不足しています';

  @override
  String get insufficientBody =>
      '今回の方向性を示すには、プロフィール情報がまだ足りません。出生時刻と出生国を追加すると、サイクルをより詳しく読み解けます。';

  @override
  String get periodElapsedHeading => 'その時間帯は過ぎました';

  @override
  String get periodElapsedBody =>
      'お住まいの地域では、その時間帯はすでに過ぎています。後の時間帯を選ぶか、今この瞬間を読み解いてください。今日の結果が明日に繰り越されることはありません。';

  @override
  String colorsToKeepNear(String first, String second) {
    return 'そばに置きたい色：$firstと$second';
  }

  @override
  String colorToKeepNear(String name) {
    return 'そばに置きたい色：$name';
  }

  @override
  String get shareTooltip => 'この結果を共有';

  @override
  String get shareUnavailable => '現在は共有できません。';

  @override
  String get shareDisclaimer => '日々の振り返りのための象徴的な視点であり、予言や確率ではありません。';

  @override
  String get backToHistory => '履歴に戻る';

  @override
  String get saveFailedRetry => '保存できませんでした · 再試行';

  @override
  String get savingToHistory => '履歴に保存中…';

  @override
  String get responsibleUseLink => '責任ある利用と安全に関する方針';

  @override
  String get historyToday => '今日';

  @override
  String get historyCouldNotOpen => 'リーディング履歴を開けませんでした。';

  @override
  String get historyNotEnoughData => '情報が不足しています';

  @override
  String get historyPeriodPassed => '時間帯が過ぎました';

  @override
  String get zodiacAries => '牡羊座';

  @override
  String get zodiacTaurus => '牡牛座';

  @override
  String get zodiacGemini => '双子座';

  @override
  String get zodiacCancer => '蟹座';

  @override
  String get zodiacLeo => '獅子座';

  @override
  String get zodiacVirgo => '乙女座';

  @override
  String get zodiacLibra => '天秤座';

  @override
  String get zodiacScorpio => '蠍座';

  @override
  String get zodiacSagittarius => '射手座';

  @override
  String get zodiacCapricorn => '山羊座';

  @override
  String get zodiacAquarius => '水瓶座';

  @override
  String get zodiacPisces => '魚座';

  @override
  String zodiacAvatarSemantics(String sign) {
    return '$signの星座アバター';
  }
}
