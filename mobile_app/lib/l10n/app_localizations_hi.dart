// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'AstraCue';

  @override
  String get continueAction => 'आगे बढ़ें';

  @override
  String get backAction => 'वापस';

  @override
  String get closeAction => 'बंद करें';

  @override
  String get tryAgain => 'फिर से कोशिश करें';

  @override
  String get responsibleUse => 'ज़िम्मेदार उपयोग';

  @override
  String get history => 'इतिहास';

  @override
  String get onboardingTitle =>
      'ब्रह्मांड के संकेतों और अपने अंतर्ज्ञान को सुनें।';

  @override
  String get onboardingLanguageHint =>
      'भाषा बदलने के लिए ऊपर ग्लोब आइकन पर टैप करें।';

  @override
  String get yourProfile => 'आपकी प्रोफ़ाइल';

  @override
  String get signAfterBirthDate =>
      'जन्मतिथि चुनने पर आपकी पश्चिमी सूर्य राशि दिखेगी';

  @override
  String get buildPattern => 'अपनी अनूठी ऊर्जा को पहचानें।';

  @override
  String get profileExplainer =>
      'विश्लेषण में उपयोग किए जाने वाले चक्रों को निर्धारित करता है।';

  @override
  String get nameField => 'नाम';

  @override
  String get dateOfBirth => 'जन्मतिथि';

  @override
  String get selectBirthDate => 'अपनी जन्मतिथि चुनें';

  @override
  String get birthDateRequired => 'आगे बढ़ने के लिए जन्मतिथि चुनें।';

  @override
  String get birthDay => 'दिन';

  @override
  String get birthMonth => 'महीना';

  @override
  String get birthYear => 'वर्ष';

  @override
  String get birthDateInvalid => '1900 से आज तक की मान्य तारीख दर्ज करें।';

  @override
  String get birthTimeUnknown => 'जन्म का समय पता नहीं';

  @override
  String get birthTimeUnknownDetail =>
      'यदि आपको अपना जन्म समय नहीं पता, तो एल्गोरिदम आपके व्यक्तित्व के सबसे करीब के समय का उपयोग करेगा।';

  @override
  String get timeOfBirth => 'जन्म का समय';

  @override
  String get countryOfBirth => 'जन्म का देश';

  @override
  String get selectBirthCountry => 'देश खोजें और चुनें';

  @override
  String get birthCountryRequired => 'आगे बढ़ने के लिए जन्म का देश चुनें।';

  @override
  String get createCompass => 'मेरा दिशासूचक बनाएँ';

  @override
  String get birthPrivacyPrototype =>
      'इस प्रोटोटाइप में आपके जन्म से जुड़े विवरण निजी रहते हैं।';

  @override
  String get homeEyebrow => 'आपका मार्गदर्शन करने वाला दिशासूचक';

  @override
  String get homeTitle => 'दो विकल्पों के बीच उलझे हैं?';

  @override
  String get areaQuestion => 'यह किस विषय से जुड़ा है?';

  @override
  String get findDirection => 'अपनी दिशा खोजें';

  @override
  String get todaySignals => 'आज के संकेत';

  @override
  String get dailyEnergy => 'आज की ऊर्जा';

  @override
  String get yourColorsToday => 'आज आपके रंग:';

  @override
  String get luckyNumberToday => 'आज का शुभ अंक:';

  @override
  String get categoryOverall => 'समग्र';

  @override
  String get categoryLove => 'प्यार और रिश्ते';

  @override
  String get categoryCareer => 'करियर';

  @override
  String get categoryMoney => 'वित्त';

  @override
  String get categoryStudy => 'पढ़ाई और विकास';

  @override
  String get categoryFriends => 'दोस्त';

  @override
  String get categoryOther => 'कुछ और';

  @override
  String get periodQuestion => 'आप किस समय के बारे में सोच रहे हैं?';

  @override
  String get periodNow => 'अभी';

  @override
  String get periodMorning => 'सुबह';

  @override
  String get periodMidday => 'दोपहर';

  @override
  String get periodAfternoon => 'दोपहर बाद';

  @override
  String get periodEvening => 'शाम';

  @override
  String get periodPassed => 'बीत चुका';

  @override
  String get periodTooLittleTime => 'समय कम है';

  @override
  String periodHasPassed(String period) {
    return '$period का समय बीत चुका है। कोई दूसरा समय चुनें।';
  }

  @override
  String periodNotEnoughTimeLeft(String period) {
    return 'आज $period में पर्याप्त समय नहीं बचा है। कोई दूसरा समय चुनें।';
  }

  @override
  String get reveal => 'विश्लेषण करें';

  @override
  String get aligning => 'संकेत मिला रहे हैं';

  @override
  String get tapWhenReady => 'तैयार हों तो टैप करें';

  @override
  String get keepChoiceInMind =>
      'जिस विकल्प को लेकर उलझन है, उसे मन में स्पष्ट रखें।';

  @override
  String get ritualSafety =>
      'सिर्फ़ रोज़मर्रा के आत्मचिंतन के लिए • चिकित्सा, निवेश, कर्ज़, राजनीति या नुकसान पहुँचा सकने वाले फैसलों के लिए कभी नहीं।';

  @override
  String get loadingLocalMoment => 'इस पल के संकेत पढ़े जा रहे हैं';

  @override
  String get loadingReassurance =>
      'कृपया थोड़ा इंतज़ार करें — इस समय के ब्रह्मांडीय संकेत संरेखित हो रहे हैं।';

  @override
  String readingForCategory(String category) {
    return '$category से जुड़ा विश्लेषण';
  }

  @override
  String get yourDirection => 'आपकी दिशा';

  @override
  String get resultBasis =>
      'इस समय आपके लिए संरेखित ऊर्जा और ब्रह्मांडीय संकेतों के आधार पर।';

  @override
  String get percentageCaveat =>
      'प्रतिशत केवल प्रतीकात्मक मेल दिखाते हैं, वास्तविक दुनिया की संभावना नहीं।';

  @override
  String get balancedHeading => 'दोनों ओर बराबर संकेत';

  @override
  String get balancedResult => 'संतुलित';

  @override
  String get balancedExplanation =>
      'अभी कोई भी पक्ष आगे नहीं है। यह संतुलन का संकेत है, कोई छिपा हुआ जवाब नहीं।';

  @override
  String get currentMoment => 'यह विश्लेषण आपके वर्तमान पल को दर्शाता है।';

  @override
  String get luckyTimesCaveat =>
      'हर प्रतिशत समय से जुड़ा एक प्रतीकात्मक मेल स्कोर है; यह सफलता की संभावना नहीं है। हर समय-खंड अलग से आँका जाता है, इसलिए इनका योग 100% नहीं होगा।';

  @override
  String get tryAnotherDirection => 'कोई दूसरी दिशा देखें';

  @override
  String get viewHistory => 'इतिहास में देखें';

  @override
  String get yourReadings => 'आपके विश्लेषण';

  @override
  String get noReadings =>
      'अभी कोई विश्लेषण नहीं है। पहला परिणाम देखकर अपना इतिहास शुरू करें।';

  @override
  String get historySnapshot =>
      'परिणाम उसी समय के रूप में सहेजे जाते हैं; उन्हें दोबारा नहीं निकाला जाता।';

  @override
  String get everydayReflection =>
      'केवल रोज़मर्रा के आत्मचिंतन के लिए। महत्वपूर्ण फैसलों के लिए वास्तविक जानकारी और योग्य विशेषज्ञ की मदद ज़रूरी है।';

  @override
  String get luckyTimesMorning => 'आज सुबह के सबसे शुभ समय';

  @override
  String get luckyTimesMidday => 'आज दोपहर के आसपास के सबसे शुभ समय';

  @override
  String get luckyTimesAfternoon => 'आज दोपहर बाद के सबसे शुभ समय';

  @override
  String get luckyTimesEvening => 'आज शाम के सबसे शुभ समय';

  @override
  String get loadingLocalTime => 'आपके स्थानीय दिन और समय से मिलान कर रहे हैं';

  @override
  String get loadingBaZi => 'आपके BaZi के तत्वों का संतुलन देख रहे हैं';

  @override
  String get loadingZiWei => 'इस पल से जुड़े Zi Wei चक्रों को देख रहे हैं';

  @override
  String get loadingVedic =>
      'वैदिक नक्षत्र और चंद्र-मंडलों का मिलान कर रहे हैं';

  @override
  String get loadingNumerology =>
      'अंकशास्त्र, चंद्रमा और ग्रहों की लय देख रहे हैं';

  @override
  String get loadingYinYang =>
      'यिन और यांग के संकेतों को एक दिशा में संतुलित कर रहे हैं';

  @override
  String get loadingModeYesNo =>
      'खुलेपन और रुकावट के संकेतों की तुलना कर रहे हैं';

  @override
  String get loadingModeActWait => 'गति और धैर्य को संतुलित कर रहे हैं';

  @override
  String get loadingModeAdvanceRetreat =>
      'आज की गति को पिछले कुछ दिनों से तौल रहे हैं';

  @override
  String get loadingModeStayGo =>
      'जुड़ाव और आगे बढ़ने की प्रवृत्ति की तुलना कर रहे हैं';

  @override
  String get loadingModeKeepLetGo =>
      'जारी रखने और छोड़ने की प्रवृत्ति तौल रहे हैं';

  @override
  String get loadingModeForwardBackward =>
      'आगे की गति और लौटने की ऊर्जा देख रहे हैं';

  @override
  String get loadingModeCommitWithdraw =>
      'प्रतिबद्धता और अलग होने की प्रवृत्ति देख रहे हैं';

  @override
  String get loadingModeLeftRight =>
      'ग्रहण करने और व्यक्त करने की प्रवृत्ति संतुलित कर रहे हैं';

  @override
  String get orbitMoment => 'यह पल';

  @override
  String get orbitRhythm => 'लय';

  @override
  String get orbitBalance => 'संतुलन';

  @override
  String get orbitAlmanac => 'पंचांग';

  @override
  String get orbitBaZi => 'BaZi';

  @override
  String get orbitZiWei => 'Zi Wei';

  @override
  String get orbitVedic => 'वैदिक ज्योतिष';

  @override
  String get orbitNumerology => 'अंकशास्त्र';

  @override
  String get orbitLunarPhase => 'चंद्र चरण';

  @override
  String get orbitPlanetary => 'ग्रह';

  @override
  String get orbitYinYang => 'यिन / यांग';

  @override
  String get safetyHeading => 'सीमाएँ और ज़िम्मेदार उपयोग';

  @override
  String get safetyTitle => 'रोज़मर्रा के पलों का एक आईना';

  @override
  String get safetyIntro =>
      'AstraCue खगोलीय लय और व्यक्तिगत चक्रों से प्रेरित प्रतीकात्मक नज़रिए देता है। यह रोज़मर्रा के आत्मचिंतन और मनोरंजन के लिए है, न कि आदेश, भविष्यवाणी या पक्के तथ्य के रूप में।';

  @override
  String get prohibitedUses => 'इन कामों के लिए उपयोग न करें';

  @override
  String get harmTitle => 'खुद को या दूसरों को नुकसान';

  @override
  String get harmDetail =>
      'खुद को नुकसान पहुँचाने, आत्महत्या, शारीरिक हिंसा या किसी को भी खतरे में डालने के लिए इसका उपयोग कभी न करें।';

  @override
  String get navigationTitle => 'गाड़ी चलाना और वास्तविक दिशा';

  @override
  String get navigationDetail =>
      'बाएँ / दाएँ और आगे बढ़ें / पीछे लौटें केवल प्रतीकात्मक विकल्प हैं। इन्हें यातायात, गाड़ी चलाने, रास्ता खोजने या शारीरिक सुरक्षा के लिए कभी न अपनाएँ।';

  @override
  String get politicsTitle => 'राजनीति और सामाजिक टकराव';

  @override
  String get politicsDetail =>
      'राजनीतिक प्रचार, मतदान के फैसले, नागरिक अशांति या चरमपंथी गतिविधियों के लिए इसका उपयोग कभी न करें।';

  @override
  String get medicalTitle => 'स्वास्थ्य, चिकित्सा और आपात स्थिति';

  @override
  String get medicalDetail =>
      'यह पेशेवर चिकित्सा देखभाल, मानसिक स्वास्थ्य उपचार, दवाओं या आपात सहायता का विकल्प नहीं है।';

  @override
  String get legalTitle => 'कानूनी मामले, अपराध और महत्वपूर्ण अनुबंध';

  @override
  String get legalDetail =>
      'अपराध, अदालती कार्यवाही, गवाही या बड़े असर वाले कानूनी अनुबंधों के लिए इसका उपयोग कभी न करें।';

  @override
  String get financeTitle => 'निवेश और जुआ';

  @override
  String get financeDetail =>
      'वित्त वाला विषय केवल छोटे खर्चों पर सोचने के लिए है। निवेश, उधार, क्रिप्टो पर दाँव, जुए या बड़े आर्थिक फैसलों के लिए किसी विश्लेषण का उपयोग न करें।';

  @override
  String get consentTitle => 'सहमति, नाबालिग और रिश्ते';

  @override
  String get consentDetail =>
      'किसी दूसरे व्यक्ति की सहमति या स्वतंत्र निर्णय को नज़रअंदाज़ करने, या बच्चों की अभिरक्षा और संरक्षकता तय करने के लिए इसका उपयोग न करें।';

  @override
  String get importantLimitsHeading => 'ज़रूरी सीमाएँ';

  @override
  String get importantLimitsBody =>
      'AstraCue बच्चों के लिए नहीं बनाया गया है। यह चिकित्सा, कानूनी या वित्तीय सलाह नहीं देता। महत्वपूर्ण फैसलों के लिए भरोसेमंद जानकारी और उपयुक्त पेशेवर मदद लें। चुनाव आपके हाथ में रहता है।';

  @override
  String get crisisSupport =>
      'यदि आप या कोई और तत्काल खतरे या भावनात्मक संकट में हैं, तो अभी स्थानीय आपात सेवा या भरोसेमंद स्थानीय संकट हेल्पलाइन से संपर्क करें।';

  @override
  String get acknowledge => 'मैं समझता हूँ और सहमत हूँ';

  @override
  String get acknowledgementOnce =>
      'यह पुष्टि पहले विश्लेषण से पहले केवल एक बार दिखाई देगी।';

  @override
  String get knowBirthTime => 'मुझे अपना जन्म समय पता है';

  @override
  String get knowBirthTimeDetail =>
      'सटीक समय से घंटे पर आधारित चक्र और स्पष्ट होते हैं।';

  @override
  String get selectBirthTime => 'अपना जन्म समय चुनें';

  @override
  String get birthTimeRequired =>
      'आगे बढ़ने के लिए जन्म समय चुनें, या यदि आपको पता नहीं है तो इसे बंद कर दें।';

  @override
  String get languageSetting => 'भाषा';

  @override
  String get chooseLanguage => 'अपनी भाषा चुनें';

  @override
  String get changeLanguage => 'भाषा बदलें';

  @override
  String get choiceYes => 'हाँ';

  @override
  String get choiceNo => 'नहीं';

  @override
  String get choiceAct => 'कदम उठाएँ';

  @override
  String get choiceWait => 'प्रतीक्षा करें';

  @override
  String get choiceAdvance => 'आगे बढ़ें';

  @override
  String get choiceRetreat => 'पीछे लौटें';

  @override
  String get choiceStay => 'रुकें';

  @override
  String get choiceGo => 'चले जाएँ';

  @override
  String get choiceKeep => 'रखें';

  @override
  String get choiceLetGo => 'छोड़ दें';

  @override
  String get choiceForward => 'आगे की ओर';

  @override
  String get choiceBackward => 'पीछे की ओर';

  @override
  String get choiceCommit => 'प्रतिबद्ध हों';

  @override
  String get choiceWithdraw => 'पीछे हटें';

  @override
  String get choiceLeft => 'बाएँ';

  @override
  String get choiceRight => 'दाएँ';

  @override
  String get energyLevelQuiet => 'शांत';

  @override
  String get energyLevelSoft => 'कोमल';

  @override
  String get energyLevelSteady => 'स्थिर';

  @override
  String get energyLevelLively => 'जीवंत';

  @override
  String get energyLevelBright => 'उज्ज्वल';

  @override
  String get energyLevelRadiant => 'दीप्तिमान';

  @override
  String get energyLevelFocused => 'केंद्रित';

  @override
  String get energyLevelFlowing => 'प्रवाहमान';

  @override
  String get colorCedar => 'देवदार';

  @override
  String get colorJade => 'जेड';

  @override
  String get colorSage => 'सेज';

  @override
  String get colorMint => 'पुदीना';

  @override
  String get colorEmber => 'अंगारा';

  @override
  String get colorSolarCoral => 'धूपिया मूँगा';

  @override
  String get colorRose => 'गुलाबी';

  @override
  String get colorBlossom => 'फूलों सा गुलाबी';

  @override
  String get colorOchre => 'गेरू';

  @override
  String get colorAmber => 'अंबर';

  @override
  String get colorSand => 'रेत';

  @override
  String get colorClay => 'चिकनी मिट्टी';

  @override
  String get colorSilver => 'चाँदी';

  @override
  String get colorSteel => 'इस्पात';

  @override
  String get colorPearl => 'मोती';

  @override
  String get colorChampagne => 'शैम्पेन';

  @override
  String get colorOceanBlue => 'समुद्री नीला';

  @override
  String get colorAzure => 'आसमानी नीला';

  @override
  String get colorIndigo => 'नील';

  @override
  String get colorMistBlue => 'धुँधला नीला';

  @override
  String get homeDescription00 =>
      'आज ब्रह्मांड आपको क्या संकेत दे रहा होगा? जो बात मन में है, उसे चुनें और इस पल के आसपास के संकेत देखें।';

  @override
  String get homeDescription01 =>
      'क्या आप दो दिशाओं में खिंचे महसूस कर रहे हैं? आज के ब्रह्मांडीय संकेत आपके चुनाव को देखने का नया तरीका दे सकते हैं।';

  @override
  String get homeDescription02 =>
      'तारे आपके लिए फैसला नहीं करते, लेकिन उनके पैटर्न अगले कदम को अलग नज़रिए से देखने में मदद कर सकते हैं।';

  @override
  String get homeDescription03 =>
      'जब आगे का रास्ता साफ़ न दिखे, थोड़ा रुककर गौर से देखें। आज के संकेत क्या सुझाते हैं?';

  @override
  String get homeDescription04 =>
      'हर पल की अपनी ऊर्जा होती है। मन की बात चुनें और देखें कि यह पल किस दिशा की ओर इशारा कर सकता है।';

  @override
  String get homeDescription05 =>
      'शायद ब्रह्मांड आपको थोड़ा धीमा चलने को कह रहा है। राह चुनने से पहले आज के संकेत देखें।';

  @override
  String get homeDescription06 =>
      'क्या आप किसी मोड़ पर खड़े हैं? देखें कि आज के आकाशीय पैटर्न आपके मन के सवाल से कैसे जुड़ते हैं।';

  @override
  String get homeDescription07 =>
      'इस पल की लय को सुनें। आज के प्रतीक सोचने लायक एक दिशा दिखा सकते हैं।';

  @override
  String get homeDescription08 =>
      'यह पल आपको क्या दिखाना चाहता है? संकेतों को देखें, फिर चुनाव करते समय खुद पर भरोसा रखें।';

  @override
  String get homeDescription09 =>
      'ब्रह्मांड से मिला एक नया नज़रिया मन साफ़ करने में मदद कर सकता है। आज की अहम बात चुनें और देखें संकेत किधर इशारा करते हैं।';

  @override
  String get homeDescription10 =>
      'क्या आप उसी चुनाव पर बार-बार सोच रहे हैं? देखें कि आज की ब्रह्मांडीय ऊर्जा किस बात को उभारती है।';

  @override
  String get homeDescription11 =>
      'जब विचार एक ओर और अंतर्ज्ञान दूसरी ओर ले जाए, आज के आसपास के संकेतों को देखें।';

  @override
  String get homeDescription12 =>
      'आगे बढ़ें या रुकें, समझ नहीं आ रहा? आज की लय आपको सोचने की एक शांत शुरुआत दे सकती है।';

  @override
  String get homeDescription13 =>
      'क्या स्पष्टता एक नए नज़रिए से शुरू हो सकती है? आज के आकाशीय पैटर्न देखें।';

  @override
  String get homeDescription14 =>
      'एक सवाल बार-बार मन में लौट रहा है। देखें कि आज के प्रतीक आपको किस बात पर ध्यान दिलाते हैं।';

  @override
  String get homeDescription15 =>
      'कुछ चुनाव किसी खास पल में ज़्यादा भारी लगते हैं। फैसला करने से पहले इस पल की ऊर्जा देखें।';

  @override
  String get homeDescription16 =>
      'अभी रास्ता धुंधला लग सकता है। इस उलझन के पीछे तारे क्या रोशन कर सकते हैं?';

  @override
  String get homeDescription17 =>
      'अचानक आए आवेग में कदम उठाने से पहले एक साँस लें और देखें कि आज के ब्रह्मांडीय संकेत क्या सुझाते हैं।';

  @override
  String get homeDescription18 =>
      'हर मोड़ पर तुरंत जवाब ज़रूरी नहीं। आज का विश्लेषण आपको सोचने के लिए थोड़ी जगह दे।';

  @override
  String get homeDescription19 =>
      'क्या आप सोच रहे हैं कि समय सही है या नहीं? आज के पैटर्न देखें और अधिक स्थिर नज़रिया पाएँ।';

  @override
  String get homeDescription20 =>
      'जब सब कुछ संभव लगे, पर कुछ भी निश्चित न हो, आकाश के पैटर्न आपको नया नज़रिया दे सकते हैं।';

  @override
  String get homeDescription21 =>
      'चुनाव आपका है। आज के संकेत आपको समझने में मदद कर सकते हैं कि सबसे ज़रूरी क्या है।';

  @override
  String get homeDescription22 =>
      'जब संदेह अगला कदम छिपा दे, देखें कि आपकी पश्चिमी सूर्य राशि और आज की ऊर्जा क्या सामने लाती है।';

  @override
  String get homeDescription23 =>
      'शायद आपको ऊँचा जवाब नहीं, बस आज के प्रतीकों के साथ एक शांत पल चाहिए।';

  @override
  String get homeDescription24 =>
      'आपका मन कदम उठाने को कह रहा है या रुकने को? देखें कि आज की ब्रह्मांडीय लय क्या दिखाती है।';

  @override
  String get homeDescription25 =>
      'इच्छा और डर के बीच ठहरने की जगह है। आज के संकेतों के साथ एक बार फिर देखें।';

  @override
  String get homeDescription26 =>
      'सवाल पर ध्यान दे चुके हैं। अब इस पल पर ध्यान दें। आज के आकाशीय संकेत क्या सुझाते हैं?';

  @override
  String get homeDescription27 =>
      'जब फैसला उलझा लगे, पुराने प्रतीक और आज का समय दूसरा पहलू दिखा सकते हैं।';

  @override
  String get homeDescription28 =>
      'शायद यह करीब आने का पल है, या कुछ जगह देने का। अपने चुनाव के आसपास की ऊर्जा देखें।';

  @override
  String get homeDescription29 =>
      'यहाँ आपको निश्चित जवाब नहीं खोजना। बस थोड़ा सुकून, एक ब्रह्मांडीय संकेत और सोचने के लिए एक दिशा।';

  @override
  String get energyQuiet00 =>
      'आज की प्रतीकात्मक ऊर्जा भीतर की ओर मुड़ती है और शांत मनन के लिए जगह देती है।';

  @override
  String get energyQuiet01 =>
      'आज की ब्रह्मांडीय लय भीतर की ओर है; शांति शायद वह दिखाए जो शोर में छिपा था।';

  @override
  String get energyQuiet02 =>
      'आज आकाश का प्रतीकात्मक स्वर धीमा है; अपने विचारों को ठहरने दें।';

  @override
  String get energyQuiet03 =>
      'आज एक शांत धारा बह रही है, जो जल्दबाज़ी से ज़्यादा ध्यान देने को कहती है।';

  @override
  String get energyQuiet04 =>
      'आज के संकेत मनन की ओर हैं; रुकना भी आगे बढ़ने का हिस्सा हो सकता है।';

  @override
  String get energyQuiet05 =>
      'जब दिन धीमा लगे, आपके भीतर का दिशासूचक और साफ़ सुनाई दे सकता है।';

  @override
  String get energyQuiet06 =>
      'आज की ऊर्जा जवाब तय करने से पहले सुनने की जगह देती है।';

  @override
  String get energyQuiet07 =>
      'हर संकेत तेज़ आवाज़ में नहीं आता; आज का संकेत धीमा होने पर ज़्यादा साफ़ दिख सकता है।';

  @override
  String get energySoft00 =>
      'आज की प्रतीकात्मक ऊर्जा नरम है और देखभाल व छोटे कदमों के लिए जगह देती है।';

  @override
  String get energySoft01 =>
      'आज ब्रह्मांड की धारा कोमल है; बड़ी छलांग से छोटे कदम ज़्यादा सहज लग सकते हैं।';

  @override
  String get energySoft02 =>
      'आज की ऊर्जा देखभाल के लिए जगह देती है; निश्चित जवाब का दबाव डाले बिना चुनाव को देखें।';

  @override
  String get energySoft03 =>
      'दिन की नरम लय आपको उस काम से शुरू करने में मदद कर सकती है जो अभी संभल सके।';

  @override
  String get energySoft04 =>
      'नरमी में भी ताकत है; देखें कहाँ आपको दबाव नहीं, सहजता चाहिए।';

  @override
  String get energySoft05 =>
      'आज के संकेत हल्के कदम का सुझाव देते हैं: शुरुआत के लिए काफ़ी, बिना रफ़्तार थोपे।';

  @override
  String get energySoft06 =>
      'आज की धारा सूक्ष्म है; सरल और सोच-समझकर किए काम अधिक मायने रख सकते हैं।';

  @override
  String get energySoft07 =>
      'छोटा अवसर भी महत्वपूर्ण हो सकता है; आज का कोमल पैटर्न उसे देखने की जगह देता है।';

  @override
  String get energySteady00 =>
      'आज की प्रतीकात्मक ऊर्जा संतुलित और ज़मीन से जुड़ी लय में है।';

  @override
  String get energySteady01 =>
      'आज की प्रतीकात्मक ऊर्जा की लय समान है; अपनी निभ सकने वाली रफ़्तार पर भरोसा रखें।';

  @override
  String get energySteady02 =>
      'ब्रह्मांडीय पैटर्न स्थिर लगता है और सोचकर आगे बढ़ने की जगह देता है।';

  @override
  String get energySteady03 =>
      'आज स्थिर धारा बह रही है; जल्दबाज़ी से ज़्यादा ध्यान देना काम आ सकता है।';

  @override
  String get energySteady04 =>
      'आज के संकेत संतुलन की ओर हैं, पर आपको ठहरने के लिए नहीं कहते।';

  @override
  String get energySteady05 =>
      'लगातार बने रहने में ताकत है; देखें रुककर सोचने के बाद भी कौन सा कदम सही लगता है।';

  @override
  String get energySteady06 =>
      'आज की ऊर्जा नपी-तुली है और आपके चुनाव को आकार लेने का समय देती है।';

  @override
  String get energySteady07 =>
      'शांत लय भी राह दिखा सकती है; आज की प्रगति बड़ी होना ज़रूरी नहीं।';

  @override
  String get energyLively00 =>
      'एक चंचल चमक आज की प्रतीकात्मक ऊर्जा में जिज्ञासा और गति लाती है।';

  @override
  String get energyLively01 =>
      'जिज्ञासा की चमक आज की प्रतीकात्मक ऊर्जा में है; नया पहलू देखना उपयोगी हो सकता है।';

  @override
  String get energyLively02 =>
      'दिन कुछ अधिक सक्रिय लगता है; जो ध्यान खींचे उसे देखें, पर तुरंत उसकी ओर न भागें।';

  @override
  String get energyLively03 =>
      'आज की ब्रह्मांडीय लय खोजने को कहती है, साथ ही समझदारी बनाए रखने की जगह देती है।';

  @override
  String get energyLively04 =>
      'आज एक चंचल धारा बह रही है; अनपेक्षित जगहों पर नई संभावनाएँ दिख सकती हैं।';

  @override
  String get energyLively05 =>
      'आज जिज्ञासा एक उपयोगी संकेत हो सकती है; निर्णय से पहले देखें वह किधर ले जा रही है।';

  @override
  String get energyLively06 =>
      'आज के संकेतों में गति है; बहुत जल्दी तय किए बिना भी आप खोज कर सकते हैं।';

  @override
  String get energyLively07 =>
      'ऊर्जा जीवंत लगती है; विकल्प घटाने से पहले उसे आपके सामने और विकल्प लाने दें।';

  @override
  String get energyBright00 =>
      'आज की प्रतीकात्मक ऊर्जा में चमक, गति और खुद को व्यक्त करने की जगह है।';

  @override
  String get energyBright01 =>
      'आज की प्रतीकात्मक ऊर्जा उस बात पर और रोशनी डालती है जिसे आप कहना चाहते हैं।';

  @override
  String get energyBright02 =>
      'ब्रह्मांड की उजली धारा आपको दिखा सकती है कि किस संभावना पर ध्यान देना चाहिए।';

  @override
  String get energyBright03 =>
      'आज के संकेत खुले लगते हैं; अगला कदम शब्दों में कहना आसान हो सकता है।';

  @override
  String get energyBright04 =>
      'आज अपनी बात रखने की ऊर्जा है; सही पल लगे तो ज़रूरी बात साझा करें।';

  @override
  String get energyBright05 =>
      'आज की लय में एक खुलापन है जो बिना जल्दबाज़ी के स्पष्टता दे सकता है।';

  @override
  String get energyBright06 =>
      'आज की ऊर्जा बाहर की ओर है; देखें आप क्या सामने लाने के लिए तैयार हैं।';

  @override
  String get energyBright07 =>
      'थोड़ी चमक नज़रिया बदल सकती है; आज के पैटर्न आगे देखने को कहते हैं।';

  @override
  String get energyRadiant00 =>
      'आज की प्रतीकात्मक ऊर्जा अपनी पूरी चमक पर है: खुली और विस्तार वाली।';

  @override
  String get energyRadiant01 =>
      'आज की प्रतीकात्मक ऊर्जा खुलती है और एक से अधिक संभावित रास्ते दिखाती है।';

  @override
  String get energyRadiant02 =>
      'आज एक उजली धारा बह रही है; अपना संतुलन बनाए रखते हुए संभावनाओं को बढ़ने दें।';

  @override
  String get energyRadiant03 =>
      'ब्रह्मांडीय पैटर्न खास तौर पर खुला लगता है; जो प्रेरित करे उसके लिए जगह बनाएँ।';

  @override
  String get energyRadiant04 =>
      'आज की ऊर्जा में भरपूर चमक है, जिससे संभावनाएँ बड़े नज़रिए में दिखती हैं।';

  @override
  String get energyRadiant05 =>
      'आज के संकेत विस्तार वाले हैं; आगे क्या हो सकता है, यह सोचना आसान लग सकता है।';

  @override
  String get energyRadiant06 =>
      'दिन की गर्माहट से नज़रिया फैलने दें, लेकिन अंतिम चुनाव अपने हाथ में रखें।';

  @override
  String get energyRadiant07 =>
      'आज आकाश की प्रतीकात्मक लय उदार लगती है; संभावनाओं को समझदारी से अपनाएँ।';

  @override
  String get energyFocused00 =>
      'आज की प्रतीकात्मक ऊर्जा एक स्पष्ट दिशा में सिमटती है; कदम उठाने का संकेत आगे है।';

  @override
  String get energyFocused01 =>
      'आज कदम उठाने का संकेत साफ़ होता है; एक सोच-समझा अगला कदम देखें।';

  @override
  String get energyFocused02 =>
      'प्रतीकात्मक धारा काम करने की ओर झुकती है, पर रफ़्तार आप चुनते हैं।';

  @override
  String get energyFocused03 =>
      'आज दिशा का एहसास है; उस बात पर ध्यान दें जिस पर आप सच में असर डाल सकते हैं।';

  @override
  String get energyFocused04 =>
      'जब विकल्प टकराएँ, आज के संकेत एक व्यावहारिक कदम पर ध्यान देने को कहते हैं।';

  @override
  String get energyFocused05 =>
      'आज के संकेत एक इरादे के आसपास हैं; बिना जल्दबाज़ी उसे ध्यान दें।';

  @override
  String get energyFocused06 =>
      'आज कदम उठाने का प्रतीकात्मक खिंचाव ज़्यादा है; आगे बढ़ने से पहले वजह साफ़ रखें।';

  @override
  String get energyFocused07 =>
      'आज इरादा अहम है, तीव्रता नहीं; चुनी हुई दिशा को आकार लेने दें।';

  @override
  String get energyFlowing00 =>
      'आज की प्रतीकात्मक ऊर्जा लहरों की तरह चलती है; बदलाव का संकेत आगे है।';

  @override
  String get energyFlowing01 =>
      'आज बदलाव का संकेत सामने है; अपनी योजनाओं में थोड़ा लचीलापन रखें।';

  @override
  String get energyFlowing02 =>
      'आज ब्रह्मांड की बदलती धारा बह रही है; ढलने की क्षमता दूसरी राह दिखा सकती है।';

  @override
  String get energyFlowing03 =>
      'बदलाव की ऊर्जा अधिक दिखती है; नए नज़रिए से सामने आने वाली बात के लिए खुले रहें।';

  @override
  String get energyFlowing04 =>
      'आज के संकेत संभावनाओं के बीच चलने की बात करते हैं, किसी तय मंज़िल की नहीं।';

  @override
  String get energyFlowing05 =>
      'हालात बदलें तो कठोर योजना से लचीला जवाब अधिक काम आ सकता है।';

  @override
  String get energyFlowing06 =>
      'आज एक बहती लय है; जवाब थोपे बिना देखें क्या बदल सकता है।';

  @override
  String get energyFlowing07 =>
      'प्रतीकात्मक धारा बदलाव की ओर झुकती है; आप अपनी रफ़्तार से आगे बढ़ सकते हैं।';

  @override
  String get defaultUserName => 'खोजी';

  @override
  String get searchCountries => 'देश खोजें';

  @override
  String get greetingMorning => 'सुप्रभात,';

  @override
  String get greetingAfternoon => 'नमस्कार,';

  @override
  String get greetingEvening => 'शुभ संध्या,';

  @override
  String get colorRoleLead => 'मुख्य';

  @override
  String get colorRoleSupporting => 'सहायक';

  @override
  String colorRoleSemantics(String role, String name) {
    return '$role रंग: $name';
  }

  @override
  String colorRoleUnavailableSemantics(String role) {
    return '$role रंग अभी उपलब्ध नहीं है';
  }

  @override
  String readingAreaSemantics(String category) {
    return 'रीडिंग का विषय: $category';
  }

  @override
  String get energyInsightNewTooltip => 'आज की ऊर्जा पर नया संकेत';

  @override
  String get energyInsightReadTooltip => 'आज की ऊर्जा का अर्थ पढ़ें';

  @override
  String get energyInsightHideTooltip => 'आज की ऊर्जा का अर्थ छिपाएँ';

  @override
  String get energyInsightCoachMark =>
      'यहाँ हर दिन आपकी ऊर्जा पर एक नया संकेत मिलेगा।';

  @override
  String get ritualLocked => 'आपका यह क्षण तय हो गया है।';

  @override
  String get periodPassedShort => 'बीत गया';

  @override
  String get errorNetworkHeadline => 'कनेक्शन टूट गया है।';

  @override
  String get errorNetworkDetail => 'कनेक्शन जाँचें, फिर दोबारा कोशिश करें।';

  @override
  String get errorServerHeadline => 'अभी रीडिंग पूरी नहीं हो सकी।';

  @override
  String get errorServerDetail =>
      'सेवा उपलब्ध है, लेकिन प्रक्रिया पूरी नहीं कर सकी। थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get errorRejectedHeadline => 'प्रोफ़ाइल की कुछ जानकारी जाँचनी होगी।';

  @override
  String get errorRejectedDetail =>
      'जन्म संबंधी जानकारी फिर जाँचें और नई रीडिंग शुरू करें।';

  @override
  String get errorInvalidHeadline => 'ऐप का यह संस्करण परिणाम नहीं पढ़ सका।';

  @override
  String get errorInvalidDetail =>
      'ऐप अपडेट करने से रीडिंग फिर उपलब्ध हो सकती है।';

  @override
  String get errorConfigurationHeadline =>
      'इस बिल्ड में रीडिंग सेवा कॉन्फ़िगर नहीं है।';

  @override
  String get errorConfigurationDetail =>
      'डेवलपर बिल्ड: गणना सेवा कॉन्फ़िगर नहीं है।';

  @override
  String get errorNothingRecorded =>
      'इस कोशिश के लिए कोई रीडिंग दर्ज नहीं हुई।';

  @override
  String get insufficientHeading => 'रीडिंग के लिए पर्याप्त जानकारी नहीं';

  @override
  String get insufficientBody =>
      'इस बार दिशा बताने के लिए आपकी प्रोफ़ाइल में अभी पर्याप्त जानकारी नहीं है। जन्म का समय और देश जोड़ने से चक्रों को समझने में अधिक मदद मिलेगी।';

  @override
  String get periodElapsedHeading => 'वह समय बीत चुका है';

  @override
  String get periodElapsedBody =>
      'आपके स्थान पर वह समय बीत चुका है, इसलिए विश्लेषण के लिए कोई समय-खिड़की नहीं बची है। बाद का समय चुनें या वर्तमान क्षण की रीडिंग लें। आज की रीडिंग कल के लिए नहीं बढ़ाई जाती।';

  @override
  String colorsToKeepNear(String first, String second) {
    return 'अपने पास रखने के लिए रंग: $first और $second';
  }

  @override
  String colorToKeepNear(String name) {
    return 'अपने पास रखने के लिए रंग: $name';
  }

  @override
  String get shareTooltip => 'यह रीडिंग साझा करें';

  @override
  String get shareUnavailable => 'अभी साझा नहीं किया जा सकता।';

  @override
  String get shareDisclaimer =>
      'रोज़मर्रा के चिंतन के लिए एक प्रतीकात्मक दृष्टिकोण; यह भविष्यवाणी या संभावना नहीं है।';

  @override
  String get backToHistory => 'इतिहास पर वापस जाएँ';

  @override
  String get saveFailedRetry => 'सहेजा नहीं जा सका · फिर कोशिश करें';

  @override
  String get savingToHistory => 'इतिहास में सहेजा जा रहा है…';

  @override
  String get responsibleUseLink => 'ज़िम्मेदार उपयोग और सुरक्षा नीति';

  @override
  String get historyToday => 'आज';

  @override
  String get historyCouldNotOpen => 'आपकी रीडिंग का इतिहास नहीं खुल सका।';

  @override
  String get historyNotEnoughData => 'पर्याप्त जानकारी नहीं';

  @override
  String get historyPeriodPassed => 'समय बीत चुका है';

  @override
  String get zodiacAries => 'मेष';

  @override
  String get zodiacTaurus => 'वृषभ';

  @override
  String get zodiacGemini => 'मिथुन';

  @override
  String get zodiacCancer => 'कर्क';

  @override
  String get zodiacLeo => 'सिंह';

  @override
  String get zodiacVirgo => 'कन्या';

  @override
  String get zodiacLibra => 'तुला';

  @override
  String get zodiacScorpio => 'वृश्चिक';

  @override
  String get zodiacSagittarius => 'धनु';

  @override
  String get zodiacCapricorn => 'मकर';

  @override
  String get zodiacAquarius => 'कुंभ';

  @override
  String get zodiacPisces => 'मीन';

  @override
  String zodiacAvatarSemantics(String sign) {
    return '$sign राशि का अवतार';
  }
}

/// The translations for Hindi, as used in India (`hi_IN`).
class AppLocalizationsHiIn extends AppLocalizationsHi {
  AppLocalizationsHiIn() : super('hi_IN');

  @override
  String get appName => 'AstraCue';

  @override
  String get continueAction => 'आगे बढ़ें';

  @override
  String get backAction => 'वापस';

  @override
  String get closeAction => 'बंद करें';

  @override
  String get tryAgain => 'फिर से कोशिश करें';

  @override
  String get responsibleUse => 'ज़िम्मेदार उपयोग';

  @override
  String get history => 'इतिहास';

  @override
  String get onboardingTitle =>
      'ब्रह्मांड के संकेतों और अपने अंतर्ज्ञान को सुनें।';

  @override
  String get onboardingLanguageHint =>
      'भाषा बदलने के लिए ऊपर ग्लोब आइकन पर टैप करें।';

  @override
  String get yourProfile => 'आपकी प्रोफ़ाइल';

  @override
  String get signAfterBirthDate =>
      'जन्मतिथि चुनने पर आपकी पश्चिमी सूर्य राशि दिखेगी';

  @override
  String get buildPattern => 'अपनी अनूठी ऊर्जा को पहचानें।';

  @override
  String get profileExplainer =>
      'विश्लेषण में उपयोग किए जाने वाले चक्रों को निर्धारित करता है।';

  @override
  String get nameField => 'नाम';

  @override
  String get dateOfBirth => 'जन्मतिथि';

  @override
  String get selectBirthDate => 'अपनी जन्मतिथि चुनें';

  @override
  String get birthDateRequired => 'आगे बढ़ने के लिए जन्मतिथि चुनें।';

  @override
  String get birthDay => 'दिन';

  @override
  String get birthMonth => 'महीना';

  @override
  String get birthYear => 'वर्ष';

  @override
  String get birthDateInvalid => '1900 से आज तक की मान्य तारीख दर्ज करें।';

  @override
  String get birthTimeUnknown => 'जन्म का समय पता नहीं';

  @override
  String get birthTimeUnknownDetail =>
      'यदि आपको अपना जन्म समय नहीं पता, तो एल्गोरिदम आपके व्यक्तित्व के सबसे करीब के समय का उपयोग करेगा।';

  @override
  String get timeOfBirth => 'जन्म का समय';

  @override
  String get countryOfBirth => 'जन्म का देश';

  @override
  String get selectBirthCountry => 'देश खोजें और चुनें';

  @override
  String get birthCountryRequired => 'आगे बढ़ने के लिए जन्म का देश चुनें।';

  @override
  String get createCompass => 'मेरा दिशासूचक बनाएँ';

  @override
  String get birthPrivacyPrototype =>
      'इस प्रोटोटाइप में आपके जन्म से जुड़े विवरण निजी रहते हैं।';

  @override
  String get homeEyebrow => 'आपका मार्गदर्शन करने वाला दिशासूचक';

  @override
  String get homeTitle => 'दो विकल्पों के बीच उलझे हैं?';

  @override
  String get areaQuestion => 'यह किस विषय से जुड़ा है?';

  @override
  String get findDirection => 'अपनी दिशा खोजें';

  @override
  String get todaySignals => 'आज के संकेत';

  @override
  String get dailyEnergy => 'आज की ऊर्जा';

  @override
  String get yourColorsToday => 'आज आपके रंग:';

  @override
  String get luckyNumberToday => 'आज का शुभ अंक:';

  @override
  String get categoryOverall => 'समग्र';

  @override
  String get categoryLove => 'प्यार और रिश्ते';

  @override
  String get categoryCareer => 'करियर';

  @override
  String get categoryMoney => 'वित्त';

  @override
  String get categoryStudy => 'पढ़ाई और विकास';

  @override
  String get categoryFriends => 'दोस्त';

  @override
  String get categoryOther => 'कुछ और';

  @override
  String get periodQuestion => 'आप किस समय के बारे में सोच रहे हैं?';

  @override
  String get periodNow => 'अभी';

  @override
  String get periodMorning => 'सुबह';

  @override
  String get periodMidday => 'दोपहर';

  @override
  String get periodAfternoon => 'दोपहर बाद';

  @override
  String get periodEvening => 'शाम';

  @override
  String get periodPassed => 'बीत चुका';

  @override
  String get periodTooLittleTime => 'समय कम है';

  @override
  String periodHasPassed(String period) {
    return '$period का समय बीत चुका है। कोई दूसरा समय चुनें।';
  }

  @override
  String periodNotEnoughTimeLeft(String period) {
    return 'आज $period में पर्याप्त समय नहीं बचा है। कोई दूसरा समय चुनें।';
  }

  @override
  String get reveal => 'विश्लेषण करें';

  @override
  String get aligning => 'संकेत मिला रहे हैं';

  @override
  String get tapWhenReady => 'तैयार हों तो टैप करें';

  @override
  String get keepChoiceInMind =>
      'जिस विकल्प को लेकर उलझन है, उसे मन में स्पष्ट रखें।';

  @override
  String get ritualSafety =>
      'सिर्फ़ रोज़मर्रा के आत्मचिंतन के लिए • चिकित्सा, निवेश, कर्ज़, राजनीति या नुकसान पहुँचा सकने वाले फैसलों के लिए कभी नहीं।';

  @override
  String get loadingLocalMoment => 'इस पल के संकेत पढ़े जा रहे हैं';

  @override
  String get loadingReassurance =>
      'कृपया थोड़ा इंतज़ार करें — इस समय के ब्रह्मांडीय संकेत संरेखित हो रहे हैं।';

  @override
  String readingForCategory(String category) {
    return '$category से जुड़ा विश्लेषण';
  }

  @override
  String get yourDirection => 'आपकी दिशा';

  @override
  String get resultBasis =>
      'इस समय आपके लिए संरेखित ऊर्जा और ब्रह्मांडीय संकेतों के आधार पर।';

  @override
  String get percentageCaveat =>
      'प्रतिशत केवल प्रतीकात्मक मेल दिखाते हैं, वास्तविक दुनिया की संभावना नहीं।';

  @override
  String get balancedHeading => 'दोनों ओर बराबर संकेत';

  @override
  String get balancedResult => 'संतुलित';

  @override
  String get balancedExplanation =>
      'अभी कोई भी पक्ष आगे नहीं है। यह संतुलन का संकेत है, कोई छिपा हुआ जवाब नहीं।';

  @override
  String get currentMoment => 'यह विश्लेषण आपके वर्तमान पल को दर्शाता है।';

  @override
  String get luckyTimesCaveat =>
      'हर प्रतिशत समय से जुड़ा एक प्रतीकात्मक मेल स्कोर है; यह सफलता की संभावना नहीं है। हर समय-खंड अलग से आँका जाता है, इसलिए इनका योग 100% नहीं होगा।';

  @override
  String get tryAnotherDirection => 'कोई दूसरी दिशा देखें';

  @override
  String get viewHistory => 'इतिहास में देखें';

  @override
  String get yourReadings => 'आपके विश्लेषण';

  @override
  String get noReadings =>
      'अभी कोई विश्लेषण नहीं है। पहला परिणाम देखकर अपना इतिहास शुरू करें।';

  @override
  String get historySnapshot =>
      'परिणाम उसी समय के रूप में सहेजे जाते हैं; उन्हें दोबारा नहीं निकाला जाता।';

  @override
  String get everydayReflection =>
      'केवल रोज़मर्रा के आत्मचिंतन के लिए। महत्वपूर्ण फैसलों के लिए वास्तविक जानकारी और योग्य विशेषज्ञ की मदद ज़रूरी है।';

  @override
  String get luckyTimesMorning => 'आज सुबह के सबसे शुभ समय';

  @override
  String get luckyTimesMidday => 'आज दोपहर के आसपास के सबसे शुभ समय';

  @override
  String get luckyTimesAfternoon => 'आज दोपहर बाद के सबसे शुभ समय';

  @override
  String get luckyTimesEvening => 'आज शाम के सबसे शुभ समय';

  @override
  String get loadingLocalTime => 'आपके स्थानीय दिन और समय से मिलान कर रहे हैं';

  @override
  String get loadingBaZi => 'आपके BaZi के तत्वों का संतुलन देख रहे हैं';

  @override
  String get loadingZiWei => 'इस पल से जुड़े Zi Wei चक्रों को देख रहे हैं';

  @override
  String get loadingVedic =>
      'वैदिक नक्षत्र और चंद्र-मंडलों का मिलान कर रहे हैं';

  @override
  String get loadingNumerology =>
      'अंकशास्त्र, चंद्रमा और ग्रहों की लय देख रहे हैं';

  @override
  String get loadingYinYang =>
      'यिन और यांग के संकेतों को एक दिशा में संतुलित कर रहे हैं';

  @override
  String get loadingModeYesNo =>
      'खुलेपन और रुकावट के संकेतों की तुलना कर रहे हैं';

  @override
  String get loadingModeActWait => 'गति और धैर्य को संतुलित कर रहे हैं';

  @override
  String get loadingModeAdvanceRetreat =>
      'आज की गति को पिछले कुछ दिनों से तौल रहे हैं';

  @override
  String get loadingModeStayGo =>
      'जुड़ाव और आगे बढ़ने की प्रवृत्ति की तुलना कर रहे हैं';

  @override
  String get loadingModeKeepLetGo =>
      'जारी रखने और छोड़ने की प्रवृत्ति तौल रहे हैं';

  @override
  String get loadingModeForwardBackward =>
      'आगे की गति और लौटने की ऊर्जा देख रहे हैं';

  @override
  String get loadingModeCommitWithdraw =>
      'प्रतिबद्धता और अलग होने की प्रवृत्ति देख रहे हैं';

  @override
  String get loadingModeLeftRight =>
      'ग्रहण करने और व्यक्त करने की प्रवृत्ति संतुलित कर रहे हैं';

  @override
  String get orbitMoment => 'यह पल';

  @override
  String get orbitRhythm => 'लय';

  @override
  String get orbitBalance => 'संतुलन';

  @override
  String get orbitAlmanac => 'पंचांग';

  @override
  String get orbitBaZi => 'BaZi';

  @override
  String get orbitZiWei => 'Zi Wei';

  @override
  String get orbitVedic => 'वैदिक ज्योतिष';

  @override
  String get orbitNumerology => 'अंकशास्त्र';

  @override
  String get orbitLunarPhase => 'चंद्र चरण';

  @override
  String get orbitPlanetary => 'ग्रह';

  @override
  String get orbitYinYang => 'यिन / यांग';

  @override
  String get safetyHeading => 'सीमाएँ और ज़िम्मेदार उपयोग';

  @override
  String get safetyTitle => 'रोज़मर्रा के पलों का एक आईना';

  @override
  String get safetyIntro =>
      'AstraCue खगोलीय लय और व्यक्तिगत चक्रों से प्रेरित प्रतीकात्मक नज़रिए देता है। यह रोज़मर्रा के आत्मचिंतन और मनोरंजन के लिए है, न कि आदेश, भविष्यवाणी या पक्के तथ्य के रूप में।';

  @override
  String get prohibitedUses => 'इन कामों के लिए उपयोग न करें';

  @override
  String get harmTitle => 'खुद को या दूसरों को नुकसान';

  @override
  String get harmDetail =>
      'खुद को नुकसान पहुँचाने, आत्महत्या, शारीरिक हिंसा या किसी को भी खतरे में डालने के लिए इसका उपयोग कभी न करें।';

  @override
  String get navigationTitle => 'गाड़ी चलाना और वास्तविक दिशा';

  @override
  String get navigationDetail =>
      'बाएँ / दाएँ और आगे बढ़ें / पीछे लौटें केवल प्रतीकात्मक विकल्प हैं। इन्हें यातायात, गाड़ी चलाने, रास्ता खोजने या शारीरिक सुरक्षा के लिए कभी न अपनाएँ।';

  @override
  String get politicsTitle => 'राजनीति और सामाजिक टकराव';

  @override
  String get politicsDetail =>
      'राजनीतिक प्रचार, मतदान के फैसले, नागरिक अशांति या चरमपंथी गतिविधियों के लिए इसका उपयोग कभी न करें।';

  @override
  String get medicalTitle => 'स्वास्थ्य, चिकित्सा और आपात स्थिति';

  @override
  String get medicalDetail =>
      'यह पेशेवर चिकित्सा देखभाल, मानसिक स्वास्थ्य उपचार, दवाओं या आपात सहायता का विकल्प नहीं है।';

  @override
  String get legalTitle => 'कानूनी मामले, अपराध और महत्वपूर्ण अनुबंध';

  @override
  String get legalDetail =>
      'अपराध, अदालती कार्यवाही, गवाही या बड़े असर वाले कानूनी अनुबंधों के लिए इसका उपयोग कभी न करें।';

  @override
  String get financeTitle => 'निवेश और जुआ';

  @override
  String get financeDetail =>
      'वित्त वाला विषय केवल छोटे खर्चों पर सोचने के लिए है। निवेश, उधार, क्रिप्टो पर दाँव, जुए या बड़े आर्थिक फैसलों के लिए किसी विश्लेषण का उपयोग न करें।';

  @override
  String get consentTitle => 'सहमति, नाबालिग और रिश्ते';

  @override
  String get consentDetail =>
      'किसी दूसरे व्यक्ति की सहमति या स्वतंत्र निर्णय को नज़रअंदाज़ करने, या बच्चों की अभिरक्षा और संरक्षकता तय करने के लिए इसका उपयोग न करें।';

  @override
  String get importantLimitsHeading => 'ज़रूरी सीमाएँ';

  @override
  String get importantLimitsBody =>
      'AstraCue बच्चों के लिए नहीं बनाया गया है। यह चिकित्सा, कानूनी या वित्तीय सलाह नहीं देता। महत्वपूर्ण फैसलों के लिए भरोसेमंद जानकारी और उपयुक्त पेशेवर मदद लें। चुनाव आपके हाथ में रहता है।';

  @override
  String get crisisSupport =>
      'यदि आप या कोई और तत्काल खतरे या भावनात्मक संकट में हैं, तो अभी स्थानीय आपात सेवा या भरोसेमंद स्थानीय संकट हेल्पलाइन से संपर्क करें।';

  @override
  String get acknowledge => 'मैं समझता हूँ और सहमत हूँ';

  @override
  String get acknowledgementOnce =>
      'यह पुष्टि पहले विश्लेषण से पहले केवल एक बार दिखाई देगी।';

  @override
  String get knowBirthTime => 'मुझे अपना जन्म समय पता है';

  @override
  String get knowBirthTimeDetail =>
      'सटीक समय से घंटे पर आधारित चक्र और स्पष्ट होते हैं।';

  @override
  String get selectBirthTime => 'अपना जन्म समय चुनें';

  @override
  String get birthTimeRequired =>
      'आगे बढ़ने के लिए जन्म समय चुनें, या यदि आपको पता नहीं है तो इसे बंद कर दें।';

  @override
  String get languageSetting => 'भाषा';

  @override
  String get chooseLanguage => 'अपनी भाषा चुनें';

  @override
  String get changeLanguage => 'भाषा बदलें';

  @override
  String get choiceYes => 'हाँ';

  @override
  String get choiceNo => 'नहीं';

  @override
  String get choiceAct => 'कदम उठाएँ';

  @override
  String get choiceWait => 'प्रतीक्षा करें';

  @override
  String get choiceAdvance => 'आगे बढ़ें';

  @override
  String get choiceRetreat => 'पीछे लौटें';

  @override
  String get choiceStay => 'रुकें';

  @override
  String get choiceGo => 'चले जाएँ';

  @override
  String get choiceKeep => 'रखें';

  @override
  String get choiceLetGo => 'छोड़ दें';

  @override
  String get choiceForward => 'आगे की ओर';

  @override
  String get choiceBackward => 'पीछे की ओर';

  @override
  String get choiceCommit => 'प्रतिबद्ध हों';

  @override
  String get choiceWithdraw => 'पीछे हटें';

  @override
  String get choiceLeft => 'बाएँ';

  @override
  String get choiceRight => 'दाएँ';

  @override
  String get energyLevelQuiet => 'शांत';

  @override
  String get energyLevelSoft => 'कोमल';

  @override
  String get energyLevelSteady => 'स्थिर';

  @override
  String get energyLevelLively => 'जीवंत';

  @override
  String get energyLevelBright => 'उज्ज्वल';

  @override
  String get energyLevelRadiant => 'दीप्तिमान';

  @override
  String get energyLevelFocused => 'केंद्रित';

  @override
  String get energyLevelFlowing => 'प्रवाहमान';

  @override
  String get colorCedar => 'देवदार';

  @override
  String get colorJade => 'जेड';

  @override
  String get colorSage => 'सेज';

  @override
  String get colorMint => 'पुदीना';

  @override
  String get colorEmber => 'अंगारा';

  @override
  String get colorSolarCoral => 'धूपिया मूँगा';

  @override
  String get colorRose => 'गुलाबी';

  @override
  String get colorBlossom => 'फूलों सा गुलाबी';

  @override
  String get colorOchre => 'गेरू';

  @override
  String get colorAmber => 'अंबर';

  @override
  String get colorSand => 'रेत';

  @override
  String get colorClay => 'चिकनी मिट्टी';

  @override
  String get colorSilver => 'चाँदी';

  @override
  String get colorSteel => 'इस्पात';

  @override
  String get colorPearl => 'मोती';

  @override
  String get colorChampagne => 'शैम्पेन';

  @override
  String get colorOceanBlue => 'समुद्री नीला';

  @override
  String get colorAzure => 'आसमानी नीला';

  @override
  String get colorIndigo => 'नील';

  @override
  String get colorMistBlue => 'धुँधला नीला';

  @override
  String get homeDescription00 =>
      'आज ब्रह्मांड आपको क्या संकेत दे रहा होगा? जो बात मन में है, उसे चुनें और इस पल के आसपास के संकेत देखें।';

  @override
  String get homeDescription01 =>
      'क्या आप दो दिशाओं में खिंचे महसूस कर रहे हैं? आज के ब्रह्मांडीय संकेत आपके चुनाव को देखने का नया तरीका दे सकते हैं।';

  @override
  String get homeDescription02 =>
      'तारे आपके लिए फैसला नहीं करते, लेकिन उनके पैटर्न अगले कदम को अलग नज़रिए से देखने में मदद कर सकते हैं।';

  @override
  String get homeDescription03 =>
      'जब आगे का रास्ता साफ़ न दिखे, थोड़ा रुककर गौर से देखें। आज के संकेत क्या सुझाते हैं?';

  @override
  String get homeDescription04 =>
      'हर पल की अपनी ऊर्जा होती है। मन की बात चुनें और देखें कि यह पल किस दिशा की ओर इशारा कर सकता है।';

  @override
  String get homeDescription05 =>
      'शायद ब्रह्मांड आपको थोड़ा धीमा चलने को कह रहा है। राह चुनने से पहले आज के संकेत देखें।';

  @override
  String get homeDescription06 =>
      'क्या आप किसी मोड़ पर खड़े हैं? देखें कि आज के आकाशीय पैटर्न आपके मन के सवाल से कैसे जुड़ते हैं।';

  @override
  String get homeDescription07 =>
      'इस पल की लय को सुनें। आज के प्रतीक सोचने लायक एक दिशा दिखा सकते हैं।';

  @override
  String get homeDescription08 =>
      'यह पल आपको क्या दिखाना चाहता है? संकेतों को देखें, फिर चुनाव करते समय खुद पर भरोसा रखें।';

  @override
  String get homeDescription09 =>
      'ब्रह्मांड से मिला एक नया नज़रिया मन साफ़ करने में मदद कर सकता है। आज की अहम बात चुनें और देखें संकेत किधर इशारा करते हैं।';

  @override
  String get homeDescription10 =>
      'क्या आप उसी चुनाव पर बार-बार सोच रहे हैं? देखें कि आज की ब्रह्मांडीय ऊर्जा किस बात को उभारती है।';

  @override
  String get homeDescription11 =>
      'जब विचार एक ओर और अंतर्ज्ञान दूसरी ओर ले जाए, आज के आसपास के संकेतों को देखें।';

  @override
  String get homeDescription12 =>
      'आगे बढ़ें या रुकें, समझ नहीं आ रहा? आज की लय आपको सोचने की एक शांत शुरुआत दे सकती है।';

  @override
  String get homeDescription13 =>
      'क्या स्पष्टता एक नए नज़रिए से शुरू हो सकती है? आज के आकाशीय पैटर्न देखें।';

  @override
  String get homeDescription14 =>
      'एक सवाल बार-बार मन में लौट रहा है। देखें कि आज के प्रतीक आपको किस बात पर ध्यान दिलाते हैं।';

  @override
  String get homeDescription15 =>
      'कुछ चुनाव किसी खास पल में ज़्यादा भारी लगते हैं। फैसला करने से पहले इस पल की ऊर्जा देखें।';

  @override
  String get homeDescription16 =>
      'अभी रास्ता धुंधला लग सकता है। इस उलझन के पीछे तारे क्या रोशन कर सकते हैं?';

  @override
  String get homeDescription17 =>
      'अचानक आए आवेग में कदम उठाने से पहले एक साँस लें और देखें कि आज के ब्रह्मांडीय संकेत क्या सुझाते हैं।';

  @override
  String get homeDescription18 =>
      'हर मोड़ पर तुरंत जवाब ज़रूरी नहीं। आज का विश्लेषण आपको सोचने के लिए थोड़ी जगह दे।';

  @override
  String get homeDescription19 =>
      'क्या आप सोच रहे हैं कि समय सही है या नहीं? आज के पैटर्न देखें और अधिक स्थिर नज़रिया पाएँ।';

  @override
  String get homeDescription20 =>
      'जब सब कुछ संभव लगे, पर कुछ भी निश्चित न हो, आकाश के पैटर्न आपको नया नज़रिया दे सकते हैं।';

  @override
  String get homeDescription21 =>
      'चुनाव आपका है। आज के संकेत आपको समझने में मदद कर सकते हैं कि सबसे ज़रूरी क्या है।';

  @override
  String get homeDescription22 =>
      'जब संदेह अगला कदम छिपा दे, देखें कि आपकी पश्चिमी सूर्य राशि और आज की ऊर्जा क्या सामने लाती है।';

  @override
  String get homeDescription23 =>
      'शायद आपको ऊँचा जवाब नहीं, बस आज के प्रतीकों के साथ एक शांत पल चाहिए।';

  @override
  String get homeDescription24 =>
      'आपका मन कदम उठाने को कह रहा है या रुकने को? देखें कि आज की ब्रह्मांडीय लय क्या दिखाती है।';

  @override
  String get homeDescription25 =>
      'इच्छा और डर के बीच ठहरने की जगह है। आज के संकेतों के साथ एक बार फिर देखें।';

  @override
  String get homeDescription26 =>
      'सवाल पर ध्यान दे चुके हैं। अब इस पल पर ध्यान दें। आज के आकाशीय संकेत क्या सुझाते हैं?';

  @override
  String get homeDescription27 =>
      'जब फैसला उलझा लगे, पुराने प्रतीक और आज का समय दूसरा पहलू दिखा सकते हैं।';

  @override
  String get homeDescription28 =>
      'शायद यह करीब आने का पल है, या कुछ जगह देने का। अपने चुनाव के आसपास की ऊर्जा देखें।';

  @override
  String get homeDescription29 =>
      'यहाँ आपको निश्चित जवाब नहीं खोजना। बस थोड़ा सुकून, एक ब्रह्मांडीय संकेत और सोचने के लिए एक दिशा।';

  @override
  String get energyQuiet00 =>
      'आज की प्रतीकात्मक ऊर्जा भीतर की ओर मुड़ती है और शांत मनन के लिए जगह देती है।';

  @override
  String get energyQuiet01 =>
      'आज की ब्रह्मांडीय लय भीतर की ओर है; शांति शायद वह दिखाए जो शोर में छिपा था।';

  @override
  String get energyQuiet02 =>
      'आज आकाश का प्रतीकात्मक स्वर धीमा है; अपने विचारों को ठहरने दें।';

  @override
  String get energyQuiet03 =>
      'आज एक शांत धारा बह रही है, जो जल्दबाज़ी से ज़्यादा ध्यान देने को कहती है।';

  @override
  String get energyQuiet04 =>
      'आज के संकेत मनन की ओर हैं; रुकना भी आगे बढ़ने का हिस्सा हो सकता है।';

  @override
  String get energyQuiet05 =>
      'जब दिन धीमा लगे, आपके भीतर का दिशासूचक और साफ़ सुनाई दे सकता है।';

  @override
  String get energyQuiet06 =>
      'आज की ऊर्जा जवाब तय करने से पहले सुनने की जगह देती है।';

  @override
  String get energyQuiet07 =>
      'हर संकेत तेज़ आवाज़ में नहीं आता; आज का संकेत धीमा होने पर ज़्यादा साफ़ दिख सकता है।';

  @override
  String get energySoft00 =>
      'आज की प्रतीकात्मक ऊर्जा नरम है और देखभाल व छोटे कदमों के लिए जगह देती है।';

  @override
  String get energySoft01 =>
      'आज ब्रह्मांड की धारा कोमल है; बड़ी छलांग से छोटे कदम ज़्यादा सहज लग सकते हैं।';

  @override
  String get energySoft02 =>
      'आज की ऊर्जा देखभाल के लिए जगह देती है; निश्चित जवाब का दबाव डाले बिना चुनाव को देखें।';

  @override
  String get energySoft03 =>
      'दिन की नरम लय आपको उस काम से शुरू करने में मदद कर सकती है जो अभी संभल सके।';

  @override
  String get energySoft04 =>
      'नरमी में भी ताकत है; देखें कहाँ आपको दबाव नहीं, सहजता चाहिए।';

  @override
  String get energySoft05 =>
      'आज के संकेत हल्के कदम का सुझाव देते हैं: शुरुआत के लिए काफ़ी, बिना रफ़्तार थोपे।';

  @override
  String get energySoft06 =>
      'आज की धारा सूक्ष्म है; सरल और सोच-समझकर किए काम अधिक मायने रख सकते हैं।';

  @override
  String get energySoft07 =>
      'छोटा अवसर भी महत्वपूर्ण हो सकता है; आज का कोमल पैटर्न उसे देखने की जगह देता है।';

  @override
  String get energySteady00 =>
      'आज की प्रतीकात्मक ऊर्जा संतुलित और ज़मीन से जुड़ी लय में है।';

  @override
  String get energySteady01 =>
      'आज की प्रतीकात्मक ऊर्जा की लय समान है; अपनी निभ सकने वाली रफ़्तार पर भरोसा रखें।';

  @override
  String get energySteady02 =>
      'ब्रह्मांडीय पैटर्न स्थिर लगता है और सोचकर आगे बढ़ने की जगह देता है।';

  @override
  String get energySteady03 =>
      'आज स्थिर धारा बह रही है; जल्दबाज़ी से ज़्यादा ध्यान देना काम आ सकता है।';

  @override
  String get energySteady04 =>
      'आज के संकेत संतुलन की ओर हैं, पर आपको ठहरने के लिए नहीं कहते।';

  @override
  String get energySteady05 =>
      'लगातार बने रहने में ताकत है; देखें रुककर सोचने के बाद भी कौन सा कदम सही लगता है।';

  @override
  String get energySteady06 =>
      'आज की ऊर्जा नपी-तुली है और आपके चुनाव को आकार लेने का समय देती है।';

  @override
  String get energySteady07 =>
      'शांत लय भी राह दिखा सकती है; आज की प्रगति बड़ी होना ज़रूरी नहीं।';

  @override
  String get energyLively00 =>
      'एक चंचल चमक आज की प्रतीकात्मक ऊर्जा में जिज्ञासा और गति लाती है।';

  @override
  String get energyLively01 =>
      'जिज्ञासा की चमक आज की प्रतीकात्मक ऊर्जा में है; नया पहलू देखना उपयोगी हो सकता है।';

  @override
  String get energyLively02 =>
      'दिन कुछ अधिक सक्रिय लगता है; जो ध्यान खींचे उसे देखें, पर तुरंत उसकी ओर न भागें।';

  @override
  String get energyLively03 =>
      'आज की ब्रह्मांडीय लय खोजने को कहती है, साथ ही समझदारी बनाए रखने की जगह देती है।';

  @override
  String get energyLively04 =>
      'आज एक चंचल धारा बह रही है; अनपेक्षित जगहों पर नई संभावनाएँ दिख सकती हैं।';

  @override
  String get energyLively05 =>
      'आज जिज्ञासा एक उपयोगी संकेत हो सकती है; निर्णय से पहले देखें वह किधर ले जा रही है।';

  @override
  String get energyLively06 =>
      'आज के संकेतों में गति है; बहुत जल्दी तय किए बिना भी आप खोज कर सकते हैं।';

  @override
  String get energyLively07 =>
      'ऊर्जा जीवंत लगती है; विकल्प घटाने से पहले उसे आपके सामने और विकल्प लाने दें।';

  @override
  String get energyBright00 =>
      'आज की प्रतीकात्मक ऊर्जा में चमक, गति और खुद को व्यक्त करने की जगह है।';

  @override
  String get energyBright01 =>
      'आज की प्रतीकात्मक ऊर्जा उस बात पर और रोशनी डालती है जिसे आप कहना चाहते हैं।';

  @override
  String get energyBright02 =>
      'ब्रह्मांड की उजली धारा आपको दिखा सकती है कि किस संभावना पर ध्यान देना चाहिए।';

  @override
  String get energyBright03 =>
      'आज के संकेत खुले लगते हैं; अगला कदम शब्दों में कहना आसान हो सकता है।';

  @override
  String get energyBright04 =>
      'आज अपनी बात रखने की ऊर्जा है; सही पल लगे तो ज़रूरी बात साझा करें।';

  @override
  String get energyBright05 =>
      'आज की लय में एक खुलापन है जो बिना जल्दबाज़ी के स्पष्टता दे सकता है।';

  @override
  String get energyBright06 =>
      'आज की ऊर्जा बाहर की ओर है; देखें आप क्या सामने लाने के लिए तैयार हैं।';

  @override
  String get energyBright07 =>
      'थोड़ी चमक नज़रिया बदल सकती है; आज के पैटर्न आगे देखने को कहते हैं।';

  @override
  String get energyRadiant00 =>
      'आज की प्रतीकात्मक ऊर्जा अपनी पूरी चमक पर है: खुली और विस्तार वाली।';

  @override
  String get energyRadiant01 =>
      'आज की प्रतीकात्मक ऊर्जा खुलती है और एक से अधिक संभावित रास्ते दिखाती है।';

  @override
  String get energyRadiant02 =>
      'आज एक उजली धारा बह रही है; अपना संतुलन बनाए रखते हुए संभावनाओं को बढ़ने दें।';

  @override
  String get energyRadiant03 =>
      'ब्रह्मांडीय पैटर्न खास तौर पर खुला लगता है; जो प्रेरित करे उसके लिए जगह बनाएँ।';

  @override
  String get energyRadiant04 =>
      'आज की ऊर्जा में भरपूर चमक है, जिससे संभावनाएँ बड़े नज़रिए में दिखती हैं।';

  @override
  String get energyRadiant05 =>
      'आज के संकेत विस्तार वाले हैं; आगे क्या हो सकता है, यह सोचना आसान लग सकता है।';

  @override
  String get energyRadiant06 =>
      'दिन की गर्माहट से नज़रिया फैलने दें, लेकिन अंतिम चुनाव अपने हाथ में रखें।';

  @override
  String get energyRadiant07 =>
      'आज आकाश की प्रतीकात्मक लय उदार लगती है; संभावनाओं को समझदारी से अपनाएँ।';

  @override
  String get energyFocused00 =>
      'आज की प्रतीकात्मक ऊर्जा एक स्पष्ट दिशा में सिमटती है; कदम उठाने का संकेत आगे है।';

  @override
  String get energyFocused01 =>
      'आज कदम उठाने का संकेत साफ़ होता है; एक सोच-समझा अगला कदम देखें।';

  @override
  String get energyFocused02 =>
      'प्रतीकात्मक धारा काम करने की ओर झुकती है, पर रफ़्तार आप चुनते हैं।';

  @override
  String get energyFocused03 =>
      'आज दिशा का एहसास है; उस बात पर ध्यान दें जिस पर आप सच में असर डाल सकते हैं।';

  @override
  String get energyFocused04 =>
      'जब विकल्प टकराएँ, आज के संकेत एक व्यावहारिक कदम पर ध्यान देने को कहते हैं।';

  @override
  String get energyFocused05 =>
      'आज के संकेत एक इरादे के आसपास हैं; बिना जल्दबाज़ी उसे ध्यान दें।';

  @override
  String get energyFocused06 =>
      'आज कदम उठाने का प्रतीकात्मक खिंचाव ज़्यादा है; आगे बढ़ने से पहले वजह साफ़ रखें।';

  @override
  String get energyFocused07 =>
      'आज इरादा अहम है, तीव्रता नहीं; चुनी हुई दिशा को आकार लेने दें।';

  @override
  String get energyFlowing00 =>
      'आज की प्रतीकात्मक ऊर्जा लहरों की तरह चलती है; बदलाव का संकेत आगे है।';

  @override
  String get energyFlowing01 =>
      'आज बदलाव का संकेत सामने है; अपनी योजनाओं में थोड़ा लचीलापन रखें।';

  @override
  String get energyFlowing02 =>
      'आज ब्रह्मांड की बदलती धारा बह रही है; ढलने की क्षमता दूसरी राह दिखा सकती है।';

  @override
  String get energyFlowing03 =>
      'बदलाव की ऊर्जा अधिक दिखती है; नए नज़रिए से सामने आने वाली बात के लिए खुले रहें।';

  @override
  String get energyFlowing04 =>
      'आज के संकेत संभावनाओं के बीच चलने की बात करते हैं, किसी तय मंज़िल की नहीं।';

  @override
  String get energyFlowing05 =>
      'हालात बदलें तो कठोर योजना से लचीला जवाब अधिक काम आ सकता है।';

  @override
  String get energyFlowing06 =>
      'आज एक बहती लय है; जवाब थोपे बिना देखें क्या बदल सकता है।';

  @override
  String get energyFlowing07 =>
      'प्रतीकात्मक धारा बदलाव की ओर झुकती है; आप अपनी रफ़्तार से आगे बढ़ सकते हैं।';

  @override
  String get defaultUserName => 'खोजी';

  @override
  String get searchCountries => 'देश खोजें';

  @override
  String get greetingMorning => 'सुप्रभात,';

  @override
  String get greetingAfternoon => 'नमस्कार,';

  @override
  String get greetingEvening => 'शुभ संध्या,';

  @override
  String get colorRoleLead => 'मुख्य';

  @override
  String get colorRoleSupporting => 'सहायक';

  @override
  String colorRoleSemantics(String role, String name) {
    return '$role रंग: $name';
  }

  @override
  String colorRoleUnavailableSemantics(String role) {
    return '$role रंग अभी उपलब्ध नहीं है';
  }

  @override
  String readingAreaSemantics(String category) {
    return 'रीडिंग का विषय: $category';
  }

  @override
  String get energyInsightNewTooltip => 'आज की ऊर्जा पर नया संकेत';

  @override
  String get energyInsightReadTooltip => 'आज की ऊर्जा का अर्थ पढ़ें';

  @override
  String get energyInsightHideTooltip => 'आज की ऊर्जा का अर्थ छिपाएँ';

  @override
  String get energyInsightCoachMark =>
      'यहाँ हर दिन आपकी ऊर्जा पर एक नया संकेत मिलेगा।';

  @override
  String get ritualLocked => 'आपका यह क्षण तय हो गया है।';

  @override
  String get periodPassedShort => 'बीत गया';

  @override
  String get errorNetworkHeadline => 'कनेक्शन टूट गया है।';

  @override
  String get errorNetworkDetail => 'कनेक्शन जाँचें, फिर दोबारा कोशिश करें।';

  @override
  String get errorServerHeadline => 'अभी रीडिंग पूरी नहीं हो सकी।';

  @override
  String get errorServerDetail =>
      'सेवा उपलब्ध है, लेकिन प्रक्रिया पूरी नहीं कर सकी। थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get errorRejectedHeadline => 'प्रोफ़ाइल की कुछ जानकारी जाँचनी होगी।';

  @override
  String get errorRejectedDetail =>
      'जन्म संबंधी जानकारी फिर जाँचें और नई रीडिंग शुरू करें।';

  @override
  String get errorInvalidHeadline => 'ऐप का यह संस्करण परिणाम नहीं पढ़ सका।';

  @override
  String get errorInvalidDetail =>
      'ऐप अपडेट करने से रीडिंग फिर उपलब्ध हो सकती है।';

  @override
  String get errorConfigurationHeadline =>
      'इस बिल्ड में रीडिंग सेवा कॉन्फ़िगर नहीं है।';

  @override
  String get errorConfigurationDetail =>
      'डेवलपर बिल्ड: गणना सेवा कॉन्फ़िगर नहीं है।';

  @override
  String get errorNothingRecorded =>
      'इस कोशिश के लिए कोई रीडिंग दर्ज नहीं हुई।';

  @override
  String get insufficientHeading => 'रीडिंग के लिए पर्याप्त जानकारी नहीं';

  @override
  String get insufficientBody =>
      'इस बार दिशा बताने के लिए आपकी प्रोफ़ाइल में अभी पर्याप्त जानकारी नहीं है। जन्म का समय और देश जोड़ने से चक्रों को समझने में अधिक मदद मिलेगी।';

  @override
  String get periodElapsedHeading => 'वह समय बीत चुका है';

  @override
  String get periodElapsedBody =>
      'आपके स्थान पर वह समय बीत चुका है, इसलिए विश्लेषण के लिए कोई समय-खिड़की नहीं बची है। बाद का समय चुनें या वर्तमान क्षण की रीडिंग लें। आज की रीडिंग कल के लिए नहीं बढ़ाई जाती।';

  @override
  String colorsToKeepNear(String first, String second) {
    return 'अपने पास रखने के लिए रंग: $first और $second';
  }

  @override
  String colorToKeepNear(String name) {
    return 'अपने पास रखने के लिए रंग: $name';
  }

  @override
  String get shareTooltip => 'यह रीडिंग साझा करें';

  @override
  String get shareUnavailable => 'अभी साझा नहीं किया जा सकता।';

  @override
  String get shareDisclaimer =>
      'रोज़मर्रा के चिंतन के लिए एक प्रतीकात्मक दृष्टिकोण; यह भविष्यवाणी या संभावना नहीं है।';

  @override
  String get backToHistory => 'इतिहास पर वापस जाएँ';

  @override
  String get saveFailedRetry => 'सहेजा नहीं जा सका · फिर कोशिश करें';

  @override
  String get savingToHistory => 'इतिहास में सहेजा जा रहा है…';

  @override
  String get responsibleUseLink => 'ज़िम्मेदार उपयोग और सुरक्षा नीति';

  @override
  String get historyToday => 'आज';

  @override
  String get historyCouldNotOpen => 'आपकी रीडिंग का इतिहास नहीं खुल सका।';

  @override
  String get historyNotEnoughData => 'पर्याप्त जानकारी नहीं';

  @override
  String get historyPeriodPassed => 'समय बीत चुका है';

  @override
  String get zodiacAries => 'मेष';

  @override
  String get zodiacTaurus => 'वृषभ';

  @override
  String get zodiacGemini => 'मिथुन';

  @override
  String get zodiacCancer => 'कर्क';

  @override
  String get zodiacLeo => 'सिंह';

  @override
  String get zodiacVirgo => 'कन्या';

  @override
  String get zodiacLibra => 'तुला';

  @override
  String get zodiacScorpio => 'वृश्चिक';

  @override
  String get zodiacSagittarius => 'धनु';

  @override
  String get zodiacCapricorn => 'मकर';

  @override
  String get zodiacAquarius => 'कुंभ';

  @override
  String get zodiacPisces => 'मीन';

  @override
  String zodiacAvatarSemantics(String sign) {
    return '$sign राशि का अवतार';
  }
}
