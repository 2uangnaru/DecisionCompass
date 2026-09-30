// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get appName => 'AstraCue';

  @override
  String get continueAction => 'ดำเนินต่อ';

  @override
  String get backAction => 'กลับ';

  @override
  String get closeAction => 'ปิด';

  @override
  String get tryAgain => 'ลองอีกครั้ง';

  @override
  String get responsibleUse => 'การใช้งานอย่างรับผิดชอบ';

  @override
  String get history => 'ประวัติ';

  @override
  String get onboardingTitle => 'ฟังสัญญาณจากจักรวาลและสัญชาตญาณของคุณ';

  @override
  String get onboardingLanguageHint => 'แตะไอคอนรูปโลกด้านบนเพื่อเปลี่ยนภาษา';

  @override
  String get yourProfile => 'โปรไฟล์ของคุณ';

  @override
  String get signAfterBirthDate => 'ใส่วันเกิดเพื่อดูราศีของคุณ';

  @override
  String get buildPattern => 'ค้นพบพลังงานเฉพาะตัวของคุณ';

  @override
  String get profileExplainer => 'กำหนดรอบเวลาที่ใช้ในการวิเคราะห์';

  @override
  String get nameField => 'ชื่อ';

  @override
  String get dateOfBirth => 'วันเกิด';

  @override
  String get selectBirthDate => 'เลือกวันเกิดของคุณ';

  @override
  String get birthDateRequired => 'โปรดเลือกวันเกิดก่อนดำเนินต่อ';

  @override
  String get birthTimeUnknown => 'ไม่ทราบเวลาเกิด';

  @override
  String get birthTimeUnknownDetail =>
      'หากคุณไม่ทราบเวลาเกิด ระบบจะใช้ช่วงเวลาที่ใกล้เคียงกับบุคลิกของคุณมากที่สุดในการคำนวณ';

  @override
  String get timeOfBirth => 'เวลาเกิด';

  @override
  String get countryOfBirth => 'ประเทศที่เกิด';

  @override
  String get selectBirthCountry => 'ค้นหาและเลือกประเทศ';

  @override
  String get birthCountryRequired => 'โปรดเลือกประเทศที่เกิดก่อนดำเนินต่อ';

  @override
  String get createCompass => 'สร้างเข็มทิศของฉัน';

  @override
  String get birthPrivacyPrototype =>
      'ในต้นแบบนี้ ข้อมูลการเกิดของคุณจะยังเป็นส่วนตัว';

  @override
  String get homeEyebrow => 'เข็มทิศนำทางเพื่อช่วยคุณ';

  @override
  String get homeTitle => 'กำลังลังเลระหว่างตัวเลือกใช่ไหม';

  @override
  String get areaQuestion => 'เรื่องที่คุณกำลังคิดอยู่เกี่ยวกับอะไร';

  @override
  String get findDirection => 'ค้นหาเส้นทางของคุณ';

  @override
  String get todaySignals => 'สัญญาณวันนี้';

  @override
  String get dailyEnergy => 'พลังงานวันนี้';

  @override
  String get yourColorsToday => 'สีของคุณวันนี้:';

  @override
  String get luckyNumberToday => 'เลขนำโชควันนี้:';

  @override
  String get categoryOverall => 'ภาพรวม';

  @override
  String get categoryLove => 'ความรักและความสัมพันธ์';

  @override
  String get categoryCareer => 'การงาน';

  @override
  String get categoryMoney => 'การเงิน';

  @override
  String get categoryStudy => 'การเรียนรู้และเติบโต';

  @override
  String get categoryFriends => 'เพื่อน';

  @override
  String get categoryOther => 'เรื่องอื่น ๆ';

  @override
  String get periodQuestion => 'คุณกำลังคิดถึงช่วงเวลาไหน';

  @override
  String get periodNow => 'ตอนนี้';

  @override
  String get periodMorning => 'ช่วงเช้า';

  @override
  String get periodMidday => 'ช่วงเที่ยง';

  @override
  String get periodAfternoon => 'ช่วงบ่าย';

  @override
  String get periodEvening => 'ช่วงเย็น';

  @override
  String get periodPassed => 'ผ่านไปแล้ว';

  @override
  String periodHasPassed(String period) {
    return 'ช่วง$periodผ่านไปแล้ว โปรดเลือกช่วงเวลาอื่น';
  }

  @override
  String get reveal => 'วิเคราะห์';

  @override
  String get aligning => 'กำลังปรับสัญญาณ';

  @override
  String get tapWhenReady => 'แตะเมื่อคุณพร้อม';

  @override
  String get keepChoiceInMind => 'นึกถึงสิ่งที่คุณกำลังลังเลให้ชัดเจน';

  @override
  String get ritualSafety =>
      'ใช้เพื่อทบทวนเรื่องทั่วไปในชีวิตประจำวันเท่านั้น ห้ามใช้ตัดสินใจเรื่องการแพทย์ การลงทุน การกู้ยืม การเมือง หรือสิ่งที่อาจก่ออันตราย';

  @override
  String get loadingLocalMoment => 'กำลังอ่านสัญญาณ ณ เวลาของคุณ';

  @override
  String get loadingReassurance =>
      'โปรดรอสักครู่ สัญญาณจากจักรวาลกำลังรวมตัวกัน';

  @override
  String readingForCategory(String category) {
    return 'กำลังอ่านเรื่อง$category';
  }

  @override
  String get yourDirection => 'แนวทางของคุณ';

  @override
  String get resultBasis =>
      'อิงตามพลังงานและสัญญาณจักรวาลที่สอดคล้องกับคุณในขณะนี้';

  @override
  String get percentageCaveat =>
      'เปอร์เซ็นต์แสดงความสอดคล้องเชิงสัญลักษณ์ ไม่ใช่ความน่าจะเป็นจริง';

  @override
  String get balancedHeading => 'สมดุลทั้งสองด้าน';

  @override
  String get balancedResult => 'สมดุล';

  @override
  String get balancedExplanation =>
      'ตอนนี้ยังไม่มีด้านใดเด่นกว่า ผลนี้บอกถึงความสมดุล ไม่ใช่คำตอบที่ซ่อนอยู่';

  @override
  String get currentMoment => 'ผลนี้สะท้อนช่วงเวลาปัจจุบันของคุณ';

  @override
  String get luckyTimesCaveat =>
      'แต่ละเปอร์เซ็นต์คือคะแนนความสอดคล้องเชิงสัญลักษณ์ของช่วงเวลา ไม่ใช่โอกาสสำเร็จหรือความน่าจะเป็น แต่ละช่วงคำนวณแยกกัน จึงไม่จำเป็นต้องรวมเป็น 100%';

  @override
  String get tryAnotherDirection => 'ดูแนวทางอื่น';

  @override
  String get viewHistory => 'ดูในประวัติ';

  @override
  String get yourReadings => 'ผลการอ่านของคุณ';

  @override
  String get noReadings =>
      'ยังไม่มีผลการอ่าน ลองดูแนวทางครั้งแรกเพื่อเริ่มบันทึกประวัติ';

  @override
  String get historySnapshot =>
      'ผลจะถูกบันทึกตามที่แสดงในขณะนั้น และไม่คำนวณใหม่';

  @override
  String get everydayReflection =>
      'ใช้เพื่อทบทวนเรื่องทั่วไปในชีวิตประจำวันเท่านั้น การตัดสินใจสำคัญต้องอาศัยข้อมูลจริงและคำแนะนำจากผู้เชี่ยวชาญ';

  @override
  String get luckyTimesMorning => 'ช่วงเวลาที่โชคเข้าข้างคุณที่สุดในเช้าวันนี้';

  @override
  String get luckyTimesMidday =>
      'ช่วงเวลาที่โชคเข้าข้างคุณที่สุดในช่วงเที่ยงวันนี้';

  @override
  String get luckyTimesAfternoon =>
      'ช่วงเวลาที่โชคเข้าข้างคุณที่สุดในบ่ายวันนี้';

  @override
  String get luckyTimesEvening => 'ช่วงเวลาที่โชคเข้าข้างคุณที่สุดในเย็นวันนี้';

  @override
  String get loadingLocalTime => 'กำลังปรับข้อมูลตามวันและเวลาในพื้นที่ของคุณ';

  @override
  String get loadingBaZi => 'กำลังอ่านสมดุลธาตุในดวง BaZi ของคุณ';

  @override
  String get loadingZiWei => 'กำลังดูวงจร Zi Wei ที่สัมพันธ์กับช่วงเวลานี้';

  @override
  String get loadingVedic =>
      'กำลังเทียบ Nakshatra ตามโหราศาสตร์เวทกับกลุ่มดาวจันทรคติ';

  @override
  String get loadingNumerology =>
      'กำลังเชื่อมเลขศาสตร์กับจังหวะของดวงจันทร์และดาวเคราะห์';

  @override
  String get loadingYinYang => 'กำลังปรับสัญญาณหยินและหยางให้เห็นแนวทางหนึ่ง';

  @override
  String get loadingModeYesNo => 'กำลังเทียบความเปิดรับกับแรงต้าน';

  @override
  String get loadingModeActWait => 'กำลังชั่งแรงขับกับความอดทน';

  @override
  String get loadingModeAdvanceRetreat =>
      'กำลังเทียบแรงผลักของวันนี้กับไม่กี่วันก่อน';

  @override
  String get loadingModeStayGo => 'กำลังเทียบความผูกพันกับการเคลื่อนไหว';

  @override
  String get loadingModeKeepLetGo => 'กำลังชั่งความต่อเนื่องกับการปล่อยวาง';

  @override
  String get loadingModeForwardBackward =>
      'กำลังดูแรงไปข้างหน้ากับพลังที่หวนกลับ';

  @override
  String get loadingModeCommitWithdraw => 'กำลังเทียบความผูกพันกับการยุติ';

  @override
  String get loadingModeLeftRight => 'กำลังปรับสมดุลระหว่างการรับและการแสดงออก';

  @override
  String get orbitMoment => 'ช่วงเวลา';

  @override
  String get orbitRhythm => 'จังหวะ';

  @override
  String get orbitBalance => 'สมดุล';

  @override
  String get orbitAlmanac => 'ปฏิทินฤกษ์';

  @override
  String get orbitBaZi => 'BaZi';

  @override
  String get orbitZiWei => 'Zi Wei';

  @override
  String get orbitVedic => 'โหราศาสตร์เวท';

  @override
  String get orbitNumerology => 'เลขศาสตร์';

  @override
  String get orbitLunarPhase => 'ข้างขึ้นข้างแรม';

  @override
  String get orbitPlanetary => 'ดาวเคราะห์';

  @override
  String get orbitYinYang => 'หยิน / หยาง';

  @override
  String get safetyHeading => 'ขอบเขตและการใช้งานอย่างรับผิดชอบ';

  @override
  String get safetyTitle => 'มุมสะท้อนสำหรับเรื่องในชีวิตประจำวัน';

  @override
  String get safetyIntro =>
      'AstraCue นำเสนอมุมมองเชิงสัญลักษณ์จากจังหวะทางดาราศาสตร์และวงจรเฉพาะตัว ใช้เพื่อทบทวนเรื่องทั่วไปและความบันเทิงเท่านั้น ไม่ใช่คำสั่ง คำทำนาย หรือข้อเท็จจริงที่แน่นอน';

  @override
  String get prohibitedUses => 'ห้ามใช้เพื่อวัตถุประสงค์ต่อไปนี้';

  @override
  String get harmTitle => 'ทำร้ายตนเองหรือผู้อื่น';

  @override
  String get harmDetail =>
      'ห้ามใช้เพื่อทำร้ายตนเอง ฆ่าตัวตาย ใช้ความรุนแรงทางกาย หรือทำให้ใครตกอยู่ในอันตราย';

  @override
  String get navigationTitle => 'การขับขี่และการนำทางจริง';

  @override
  String get navigationDetail =>
      'ซ้าย / ขวา และ เดินหน้า / ถอยกลับ เป็นเพียงตัวเลือกเชิงสัญลักษณ์ ห้ามใช้กับการจราจร การขับรถ การหาเส้นทาง หรือความปลอดภัยทางกาย';

  @override
  String get politicsTitle => 'การเมืองและความขัดแย้งทางสังคม';

  @override
  String get politicsDetail =>
      'ห้ามใช้เพื่อหาเสียง ตัดสินใจเลือกตั้ง เหตุการณ์ความไม่สงบ หรือกิจกรรมสุดโต่ง';

  @override
  String get medicalTitle => 'สุขภาพ การแพทย์ และเหตุฉุกเฉิน';

  @override
  String get medicalDetail =>
      'ไม่ใช่สิ่งทดแทนการดูแลจากผู้เชี่ยวชาญทางการแพทย์ การรักษาสุขภาพจิต ยา หรือความช่วยเหลือฉุกเฉิน';

  @override
  String get legalTitle => 'กฎหมาย อาชญากรรม และสัญญาสำคัญ';

  @override
  String get legalDetail =>
      'ห้ามใช้เพื่อตัดสินใจเกี่ยวกับการกระทำผิดกฎหมาย คดีความ คำให้การ หรือสัญญาทางกฎหมายที่มีผลกระทบสูง';

  @override
  String get financeTitle => 'การลงทุนและการพนัน';

  @override
  String get financeDetail =>
      'หมวดการเงินมีไว้ทบทวนรายจ่ายเล็กน้อยเท่านั้น ห้ามใช้ผลการอ่านเพื่อลงทุน กู้ยืม เดิมพันคริปโต เล่นพนัน หรือตัดสินใจทางการเงินเรื่องใหญ่';

  @override
  String get consentTitle => 'ความยินยอม ผู้เยาว์ และความสัมพันธ์';

  @override
  String get consentDetail =>
      'ห้ามใช้เพื่อละเมิดความยินยอมหรือสิทธิในการตัดสินใจของผู้อื่น หรือเพื่อตัดสินเรื่องการดูแลและการเป็นผู้ปกครองเด็ก';

  @override
  String get importantLimitsHeading => 'ข้อจำกัดสำคัญ';

  @override
  String get importantLimitsBody =>
      'AstraCue ไม่ได้ออกแบบมาสำหรับเด็ก และไม่ได้ให้คำแนะนำด้านการแพทย์ กฎหมาย หรือการเงิน สำหรับการตัดสินใจสำคัญ ควรใช้ข้อมูลที่เชื่อถือได้และขอความช่วยเหลือจากผู้เชี่ยวชาญที่เหมาะสม ทางเลือกยังอยู่ในมือคุณ';

  @override
  String get crisisSupport =>
      'หากคุณหรือผู้อื่นกำลังตกอยู่ในอันตรายทันทีหรือภาวะวิกฤตทางใจ ให้ติดต่อบริการฉุกเฉินหรือสายด่วนช่วยเหลือในพื้นที่ที่เชื่อถือได้ทันที';

  @override
  String get acknowledge => 'ฉันเข้าใจและยอมรับ';

  @override
  String get acknowledgementOnce =>
      'การยืนยันนี้จะแสดงเพียงครั้งเดียวก่อนการอ่านครั้งแรก';

  @override
  String get knowBirthTime => 'ฉันทราบเวลาเกิดของฉัน';

  @override
  String get knowBirthTimeDetail =>
      'เวลาที่แม่นยำช่วยให้วงจรตามชั่วโมงชัดเจนขึ้น';

  @override
  String get selectBirthTime => 'เลือกเวลาเกิดของคุณ';

  @override
  String get birthTimeRequired =>
      'โปรดเลือกเวลาเกิดก่อนดำเนินต่อ หรือปิดตัวเลือกนี้หากคุณไม่ทราบ';

  @override
  String get languageSetting => 'ภาษา';

  @override
  String get chooseLanguage => 'เลือกภาษา';

  @override
  String get changeLanguage => 'เปลี่ยนภาษา';

  @override
  String get choiceYes => 'ใช่';

  @override
  String get choiceNo => 'ไม่';

  @override
  String get choiceAct => 'ลงมือ';

  @override
  String get choiceWait => 'รอ';

  @override
  String get choiceAdvance => 'เดินหน้า';

  @override
  String get choiceRetreat => 'ถอยกลับ';

  @override
  String get choiceStay => 'อยู่ต่อ';

  @override
  String get choiceGo => 'ออกไป';

  @override
  String get choiceKeep => 'เก็บไว้';

  @override
  String get choiceLetGo => 'ปล่อยวาง';

  @override
  String get choiceForward => 'ไปข้างหน้า';

  @override
  String get choiceBackward => 'ย้อนกลับ';

  @override
  String get choiceCommit => 'ผูกพัน';

  @override
  String get choiceWithdraw => 'ถอย';

  @override
  String get choiceLeft => 'ซ้าย';

  @override
  String get choiceRight => 'ขวา';

  @override
  String get energyLevelQuiet => 'สงบ';

  @override
  String get energyLevelSoft => 'อ่อนโยน';

  @override
  String get energyLevelSteady => 'มั่นคง';

  @override
  String get energyLevelLively => 'มีชีวิตชีวา';

  @override
  String get energyLevelBright => 'สดใส';

  @override
  String get energyLevelRadiant => 'เปล่งประกาย';

  @override
  String get energyLevelFocused => 'มุ่งมั่น';

  @override
  String get energyLevelFlowing => 'ลื่นไหล';

  @override
  String get colorCedar => 'ซีดาร์';

  @override
  String get colorJade => 'หยก';

  @override
  String get colorSage => 'เขียวเสจ';

  @override
  String get colorMint => 'เขียวมิ้นต์';

  @override
  String get colorEmber => 'ถ่านแดง';

  @override
  String get colorSolarCoral => 'ปะการังแดด';

  @override
  String get colorRose => 'กุหลาบ';

  @override
  String get colorBlossom => 'ชมพูดอกไม้';

  @override
  String get colorOchre => 'เหลืองดิน';

  @override
  String get colorAmber => 'อำพัน';

  @override
  String get colorSand => 'ทราย';

  @override
  String get colorClay => 'ดินเผา';

  @override
  String get colorSilver => 'เงิน';

  @override
  String get colorSteel => 'เหล็ก';

  @override
  String get colorPearl => 'ไข่มุก';

  @override
  String get colorChampagne => 'แชมเปญ';

  @override
  String get colorOceanBlue => 'ฟ้าน้ำทะเล';

  @override
  String get colorAzure => 'ฟ้าคราม';

  @override
  String get colorIndigo => 'คราม';

  @override
  String get colorMistBlue => 'ฟ้าหมอก';

  @override
  String get homeDescription00 =>
      'วันนี้จักรวาลอาจกำลังบอกอะไรคุณอยู่ ลองนึกถึงเรื่องที่ค้างคาใจ แล้วสำรวจสัญญาณรอบช่วงเวลานี้';

  @override
  String get homeDescription01 =>
      'รู้สึกเหมือนถูกดึงไปคนละทางใช่ไหม ให้สัญญาณจากจักรวาลวันนี้ช่วยเปิดมุมมองใหม่ต่อทางเลือกของคุณ';

  @override
  String get homeDescription02 =>
      'ดวงดาวไม่ได้ตัดสินใจแทนคุณ แต่รูปแบบของมันอาจช่วยให้คุณมองก้าวต่อไปต่างออกไป';

  @override
  String get homeDescription03 =>
      'เมื่อเส้นทางยังไม่ชัด ลองหยุดและมองให้ใกล้ขึ้น สัญญาณวันนี้กำลังชวนให้คิดถึงอะไร';

  @override
  String get homeDescription04 =>
      'ทุกช่วงเวลามีพลังงานในแบบของตัวเอง ลองนึกถึงเรื่องที่ค้างคาใจ และดูว่าช่วงเวลานี้อาจชี้ไปทางไหน';

  @override
  String get homeDescription05 =>
      'บางทีจักรวาลอาจกำลังชวนให้คุณช้าลง สำรวจสัญญาณวันนี้ก่อนเลือกทางเดิน';

  @override
  String get homeDescription06 =>
      'อยู่ตรงทางแยกใช่ไหม ลองดูว่ารูปแบบบนท้องฟ้าวันนี้สะท้อนคำถามในใจคุณอย่างไร';

  @override
  String get homeDescription07 =>
      'ฟังจังหวะของช่วงเวลานี้ สัญลักษณ์วันนี้อาจเผยแนวทางที่น่าลองพิจารณา';

  @override
  String get homeDescription08 =>
      'ช่วงเวลานี้กำลังให้คุณเห็นอะไร สำรวจสัญญาณ แล้วเชื่อใจตัวเองในการเลือก';

  @override
  String get homeDescription09 =>
      'มุมมองจากจักรวาลอาจช่วยให้เห็นชัดขึ้น เลือกเรื่องที่สำคัญวันนี้แล้วดูว่าสัญญาณชี้ไปทางไหน';

  @override
  String get homeDescription10 =>
      'ยังคิดวนกับทางเลือกเดิมอยู่หรือเปล่า ลองดูว่าพลังงานจากจักรวาลวันนี้ทำให้เรื่องใดเด่นชัดขึ้น';

  @override
  String get homeDescription11 =>
      'เมื่อความคิดชี้ไปทางหนึ่ง แต่สัญชาตญาณชี้ไปอีกทาง ลองสำรวจสัญญาณของวันนี้';

  @override
  String get homeDescription12 =>
      'ไม่แน่ใจว่าจะก้าวต่อหรือหยุดพัก ให้จังหวะของวันนี้เป็นจุดเริ่มต้นที่สงบขึ้น';

  @override
  String get homeDescription13 =>
      'ถ้าความชัดเจนเริ่มจากมุมมองใหม่ล่ะ ลองมองรูปแบบบนท้องฟ้าวันนี้';

  @override
  String get homeDescription14 =>
      'มีคำถามหนึ่งวนกลับมาในใจ ลองดูว่าสัญลักษณ์วันนี้ชวนให้คุณสังเกตอะไร';

  @override
  String get homeDescription15 =>
      'บางทางเลือกอาจรู้สึกหนักขึ้นในบางช่วงเวลา ลองสำรวจพลังงานของตอนนี้ก่อนตัดสินใจ';

  @override
  String get homeDescription16 =>
      'ตอนนี้เส้นทางอาจยังไม่ชัด ดวงดาวอาจส่องให้เห็นอะไรภายใต้ความลังเลนั้น';

  @override
  String get homeDescription17 =>
      'ก่อนทำตามแรงกระตุ้นฉับพลัน ลองหายใจลึก ๆ แล้วดูว่าสัญญาณจากจักรวาลวันนี้บอกอะไร';

  @override
  String get homeDescription18 =>
      'ไม่ใช่ทุกทางแยกที่ต้องมีคำตอบทันที ให้การอ่านวันนี้เป็นพื้นที่สำหรับทบทวน';

  @override
  String get homeDescription19 =>
      'สงสัยว่านี่ใช่เวลาหรือยัง ลองสำรวจรูปแบบของวันนี้เพื่อหามุมมองที่มั่นคงขึ้น';

  @override
  String get homeDescription20 =>
      'เมื่อทุกอย่างดูเป็นไปได้แต่ไม่มีอะไรแน่นอน ให้รูปแบบบนท้องฟ้าจุดประกายมุมมองใหม่';

  @override
  String get homeDescription21 =>
      'การเลือกยังเป็นของคุณ สัญญาณวันนี้อาจช่วยให้เข้าใจว่าอะไรสำคัญที่สุด';

  @override
  String get homeDescription22 =>
      'เมื่อความสงสัยบดบังก้าวต่อไป ลองดูว่าราศีและพลังงานวันนี้ทำให้คุณมองเห็นอะไร';

  @override
  String get homeDescription23 =>
      'บางทีคุณไม่ต้องการคำตอบที่ดังขึ้น แค่ช่วงเวลาเงียบ ๆ อยู่กับสัญลักษณ์ของวันนี้';

  @override
  String get homeDescription24 =>
      'สัญชาตญาณกำลังชวนให้ลงมือหรือรอ ลองดูว่าจังหวะจักรวาลวันนี้สะท้อนอะไร';

  @override
  String get homeDescription25 =>
      'ระหว่างสิ่งที่ต้องการกับสิ่งที่กลัว ยังมีที่ให้หยุดพัก ให้สัญญาณวันนี้ช่วยคุณมองอีกครั้ง';

  @override
  String get homeDescription26 =>
      'คุณเห็นคำถามแล้ว คราวนี้ลองสังเกตช่วงเวลา สัญญาณบนท้องฟ้าวันนี้ชวนให้คิดอะไร';

  @override
  String get homeDescription27 =>
      'เมื่อการตัดสินใจดูยุ่งเหยิง สัญลักษณ์โบราณและจังหวะของวันนี้อาจเปิดอีกมุมหนึ่ง';

  @override
  String get homeDescription28 =>
      'บางทีนี่อาจเป็นเวลาขยับเข้าใกล้ หรือเว้นระยะสักหน่อย ลองสำรวจพลังงานรอบทางเลือกของคุณ';

  @override
  String get homeDescription29 =>
      'คุณไม่จำเป็นต้องพบความแน่นอนที่นี่ แค่ช่วงเวลาสงบ สัญญาณจากจักรวาล และทิศทางหนึ่งให้พิจารณา';

  @override
  String get energyQuiet00 =>
      'พลังงานเชิงสัญลักษณ์วันนี้หันเข้าสู่ภายใน เปิดพื้นที่ให้ทบทวนอย่างเงียบ ๆ';

  @override
  String get energyQuiet01 =>
      'จังหวะจักรวาลวันนี้หันเข้าด้านใน ความนิ่งอาจเผยสิ่งที่ความวุ่นวายเคยกลบไว้';

  @override
  String get energyQuiet02 =>
      'ท้องฟ้าวันนี้มีโทนเงียบสงบ ลองให้ความคิดของคุณมีเวลาตกผลึก';

  @override
  String get energyQuiet03 =>
      'กระแสที่สงบไหลผ่านวันนี้ ชวนให้สังเกตมากกว่าเร่งรีบ';

  @override
  String get energyQuiet04 =>
      'สัญญาณวันนี้ชวนให้ทบทวน การหยุดพักก็เป็นส่วนหนึ่งของการก้าวต่อได้';

  @override
  String get energyQuiet05 =>
      'เมื่อวันดูเงียบลง เข็มทิศในใจคุณอาจส่งเสียงชัดขึ้น';

  @override
  String get energyQuiet06 =>
      'พลังงานวันนี้เปิดพื้นที่ให้ฟังก่อนจะเรียกสิ่งใดว่าคำตอบ';

  @override
  String get energyQuiet07 =>
      'ไม่ใช่ทุกสัญญาณจะมาถึงอย่างชัดเจน วันนี้คุณอาจเห็นมันง่ายขึ้นเมื่อช้าลง';

  @override
  String get energySoft00 =>
      'พลังงานเชิงสัญลักษณ์วันนี้เคลื่อนไหวอย่างนุ่มนวล มีพื้นที่ให้ดูแลตัวเองและก้าวเล็ก ๆ';

  @override
  String get energySoft01 =>
      'กระแสจักรวาลวันนี้อ่อนโยน ก้าวเล็ก ๆ อาจเป็นธรรมชาติกว่าการกระโดดครั้งใหญ่';

  @override
  String get energySoft02 =>
      'พลังงานวันนี้เปิดพื้นที่ให้เอาใจใส่ มองทางเลือกโดยไม่กดดันตัวเองให้มั่นใจทันที';

  @override
  String get energySoft03 =>
      'จังหวะที่นุ่มนวลของวันนี้อาจช่วยให้คุณเริ่มจากสิ่งที่รับมือไหว';

  @override
  String get energySoft04 =>
      'ความอ่อนโยนก็เข้มแข็งได้ ลองสังเกตว่าตรงไหนคุณต้องการความสบายมากกว่าความกดดัน';

  @override
  String get energySoft05 =>
      'สัญญาณวันนี้ชวนให้ขยับเบา ๆ พอให้เริ่มได้โดยไม่ต้องเร่งจังหวะ';

  @override
  String get energySoft06 =>
      'กระแสวันนี้ละเอียดอ่อน การกระทำเรียบง่ายที่ผ่านการคิดอาจมีความหมายมาก';

  @override
  String get energySoft07 =>
      'แม้โอกาสเล็ก ๆ ก็สำคัญได้ รูปแบบอ่อนโยนของวันนี้เปิดที่ให้คุณสำรวจมัน';

  @override
  String get energySteady00 =>
      'พลังงานเชิงสัญลักษณ์วันนี้มีจังหวะสม่ำเสมอและมั่นคง';

  @override
  String get energySteady01 =>
      'พลังงานเชิงสัญลักษณ์วันนี้สม่ำเสมอ เชื่อในจังหวะที่คุณรักษาได้';

  @override
  String get energySteady02 =>
      'รูปแบบจักรวาลวันนี้ให้ความรู้สึกมั่นคง เปิดที่ให้คิดและลงมืออย่างตั้งใจ';

  @override
  String get energySteady03 =>
      'กระแสที่มั่นคงอยู่ใต้วันนี้ ความใส่ใจอาจเป็นประโยชน์กว่าความรีบ';

  @override
  String get energySteady04 =>
      'สัญญาณวันนี้ชี้ถึงความสมดุล โดยไม่ได้ขอให้คุณหยุดนิ่ง';

  @override
  String get energySteady05 =>
      'ความสม่ำเสมอก็มีพลัง ลองดูว่าก้าวต่อไปใดยังสมเหตุสมผลหลังหยุดคิด';

  @override
  String get energySteady06 =>
      'วันนี้มีพลังงานที่พอดี ให้ทางเลือกของคุณค่อย ๆ เป็นรูปเป็นร่าง';

  @override
  String get energySteady07 =>
      'จังหวะสงบก็เป็นเครื่องนำทางได้ ความคืบหน้าวันนี้ไม่จำเป็นต้องยิ่งใหญ่';

  @override
  String get energyLively00 =>
      'ประกายสนุกสนานกระตุ้นพลังงานเชิงสัญลักษณ์วันนี้ ให้เกิดความสงสัยใคร่รู้และการเคลื่อนไหว';

  @override
  String get energyLively01 =>
      'ประกายความอยากรู้อยากเห็นทำให้พลังงานวันนี้มีชีวิตชีวา มุมมองใหม่อาจน่าสำรวจ';

  @override
  String get energyLively02 =>
      'วันนี้ดูคึกคักขึ้น สังเกตสิ่งที่ดึงความสนใจโดยไม่ต้องรีบเข้าไปหา';

  @override
  String get energyLively03 =>
      'จังหวะจักรวาลวันนี้ชวนให้ค้นพบ พร้อมเหลือที่ให้ใช้วิจารณญาณ';

  @override
  String get energyLively04 =>
      'กระแสขี้เล่นไหลผ่านวันนี้ ความเป็นไปได้อาจปรากฏในที่ที่ไม่คาดคิด';

  @override
  String get energyLively05 =>
      'ความอยากรู้อาจเป็นสัญญาณที่มีประโยชน์ ดูว่ามันชี้ไปไหนก่อนตกลงใจ';

  @override
  String get energyLively06 =>
      'สัญญาณวันนี้มีการเคลื่อนไหว คุณสำรวจได้โดยไม่ต้องรีบตัดสินใจ';

  @override
  String get energyLively07 =>
      'พลังงานวันนี้มีชีวิตชีวา ให้มันขยายตัวเลือกก่อนค่อยเลือกให้แคบลง';

  @override
  String get energyBright00 =>
      'พลังงานเชิงสัญลักษณ์วันนี้ส่องสว่าง มีแรงส่งและพื้นที่ให้แสดงออก';

  @override
  String get energyBright01 =>
      'พลังงานเชิงสัญลักษณ์วันนี้ช่วยให้สิ่งที่คุณอยากสื่อสารชัดขึ้น';

  @override
  String get energyBright02 =>
      'กระแสจักรวาลที่สว่างขึ้นอาจช่วยให้เห็นว่าความเป็นไปได้ใดควรได้รับความสนใจ';

  @override
  String get energyBright03 =>
      'สัญญาณวันนี้ดูเปิดกว้าง ก้าวต่อไปอาจเรียกชื่อได้ง่ายขึ้น';

  @override
  String get energyBright04 =>
      'วันนี้มีแรงส่งให้แสดงออก บอกสิ่งสำคัญเมื่อรู้สึกว่าถึงเวลา';

  @override
  String get energyBright05 =>
      'ช่องว่างที่เปิดในจังหวะวันนี้อาจทำให้เห็นชัดขึ้นโดยไม่ต้องรีบ';

  @override
  String get energyBright06 =>
      'พลังงานวันนี้มุ่งออกภายนอก ลองสังเกตสิ่งที่คุณพร้อมจะนำเสนอ';

  @override
  String get energyBright07 =>
      'ความสว่างเพียงเล็กน้อยอาจเปลี่ยนมุมมอง รูปแบบวันนี้ชวนให้มองไปข้างหน้า';

  @override
  String get energyRadiant00 =>
      'พลังงานเชิงสัญลักษณ์วันนี้เปล่งประกายเต็มที่ เปิดกว้างและขยายออก';

  @override
  String get energyRadiant01 =>
      'พลังงานเชิงสัญลักษณ์วันนี้เปิดกว้าง ชวนให้เห็นเส้นทางที่เป็นไปได้มากกว่าหนึ่ง';

  @override
  String get energyRadiant02 =>
      'กระแสที่เปล่งประกายไหลผ่านวันนี้ เปิดรับความเป็นไปได้โดยไม่เสียศูนย์ของตัวเอง';

  @override
  String get energyRadiant03 =>
      'รูปแบบจักรวาลวันนี้เปิดกว้างเป็นพิเศษ เผื่อพื้นที่ให้สิ่งที่สร้างแรงบันดาลใจ';

  @override
  String get energyRadiant04 =>
      'แสงที่เต็มขึ้นแต่งแต้มพลังงานวันนี้ ทำให้เห็นความเป็นไปได้ในมุมที่กว้างขึ้น';

  @override
  String get energyRadiant05 =>
      'สัญญาณวันนี้มีโทนขยายกว้าง คุณอาจจินตนาการก้าวต่อไปได้ง่ายขึ้น';

  @override
  String get energyRadiant06 =>
      'ให้ความอบอุ่นของวันนี้ขยายมุมมอง โดยยังถือการตัดสินใจสุดท้ายไว้ในมือคุณ';

  @override
  String get energyRadiant07 =>
      'จังหวะเชิงสัญลักษณ์ของท้องฟ้าวันนี้ดูเอื้ออารี เปิดรับความเป็นไปได้อย่างมีสติ';

  @override
  String get energyFocused00 =>
      'พลังงานเชิงสัญลักษณ์วันนี้รวมตัวรอบทิศทางที่ชัด สัญญาณของการลงมือเด่นกว่า';

  @override
  String get energyFocused01 =>
      'สัญญาณของการลงมือวันนี้ชัดขึ้น ลองมองหาก้าวหนึ่งที่มีความตั้งใจ';

  @override
  String get energyFocused02 =>
      'กระแสเชิงสัญลักษณ์เอนมาทางการลงมือ แต่คุณยังเลือกจังหวะเองได้';

  @override
  String get energyFocused03 =>
      'วันนี้มีความรู้สึกถึงทิศทาง ใส่ใจสิ่งที่คุณมีอิทธิพลต่อมันได้จริง';

  @override
  String get energyFocused04 =>
      'เมื่อหลายตัวเลือกแข่งกัน สัญญาณวันนี้ชวนให้โฟกัสที่ก้าวหนึ่งซึ่งทำได้จริง';

  @override
  String get energyFocused05 =>
      'สัญญาณวันนี้รวมรอบความตั้งใจหนึ่งข้อ ให้ความสนใจกับมันโดยไม่ต้องรีบ';

  @override
  String get energyFocused06 =>
      'วันนี้การลงมือมีแรงดึงดูดเชิงสัญลักษณ์มากขึ้น รู้เหตุผลของตัวเองให้ชัดก่อนขยับ';

  @override
  String get energyFocused07 =>
      'วันนี้เป็นวันของความตั้งใจ ไม่ใช่ความหักโหม ให้ทิศทางที่คุณเลือกค่อย ๆ เป็นรูป';

  @override
  String get energyFlowing00 =>
      'พลังงานเชิงสัญลักษณ์วันนี้เคลื่อนไหวเหมือนน้ำขึ้นลง สัญญาณของการเปลี่ยนแปลงเด่นกว่า';

  @override
  String get energyFlowing01 =>
      'สัญญาณการเปลี่ยนแปลงวันนี้ชัดขึ้น เผื่อพื้นที่ให้แผนของคุณยืดหยุ่นได้';

  @override
  String get energyFlowing02 =>
      'กระแสจักรวาลที่เปลี่ยนทิศไหลผ่านวันนี้ ความยืดหยุ่นอาจเผยทางอีกเส้น';

  @override
  String get energyFlowing03 =>
      'พลังงานแห่งการเปลี่ยนแปลงเห็นชัดขึ้น เปิดใจดูว่ามุมใหม่ทำให้เห็นอะไร';

  @override
  String get energyFlowing04 =>
      'สัญญาณวันนี้พูดถึงการเคลื่อนระหว่างความเป็นไปได้ ไม่ใช่จุดหมายที่ตายตัว';

  @override
  String get energyFlowing05 =>
      'เมื่อสถานการณ์เปลี่ยน การตอบสนองอย่างยืดหยุ่นอาจช่วยได้มากกว่าแผนที่แข็งเกินไป';

  @override
  String get energyFlowing06 =>
      'จังหวะที่ไหลลื่นผ่านวันนี้ ลองดูว่าสิ่งใดเปลี่ยนได้โดยไม่ต้องฝืนหาคำตอบ';

  @override
  String get energyFlowing07 =>
      'กระแสเชิงสัญลักษณ์เอนสู่ช่วงเปลี่ยนผ่าน คุณขยับไปกับมันตามจังหวะตัวเองได้';

  @override
  String get defaultUserName => 'นักสำรวจ';

  @override
  String get searchCountries => 'ค้นหาประเทศ';

  @override
  String get greetingMorning => 'สวัสดีตอนเช้า,';

  @override
  String get greetingAfternoon => 'สวัสดีตอนบ่าย,';

  @override
  String get greetingEvening => 'สวัสดีตอนเย็น,';

  @override
  String get colorRoleLead => 'สีหลัก';

  @override
  String get colorRoleSupporting => 'สีเสริม';

  @override
  String colorRoleSemantics(String role, String name) {
    return '$role: $name';
  }

  @override
  String colorRoleUnavailableSemantics(String role) {
    return 'ยังไม่มี$role';
  }

  @override
  String readingAreaSemantics(String category) {
    return 'หัวข้อที่อ่าน: $category';
  }

  @override
  String get energyInsightNewTooltip => 'มุมมองใหม่เกี่ยวกับพลังงานวันนี้';

  @override
  String get energyInsightReadTooltip => 'อ่านความหมายของพลังงานวันนี้';

  @override
  String get energyInsightHideTooltip => 'ซ่อนความหมายของพลังงานวันนี้';

  @override
  String get energyInsightCoachMark =>
      'ที่นี่มีมุมมองใหม่เกี่ยวกับพลังงานของคุณในทุกวัน';

  @override
  String get ritualLocked => 'บันทึกช่วงเวลาของคุณแล้ว';

  @override
  String get periodPassedShort => 'ผ่านไปแล้ว';

  @override
  String get errorNetworkHeadline => 'การเชื่อมต่อขาดหายไป';

  @override
  String get errorNetworkDetail => 'ตรวจสอบการเชื่อมต่อแล้วลองอีกครั้ง';

  @override
  String get errorServerHeadline => 'ขณะนี้ยังอ่านคำตอบให้เสร็จไม่ได้';

  @override
  String get errorServerDetail =>
      'บริการตอบสนองแล้วแต่ยังทำงานไม่เสร็จ โปรดลองอีกครั้งในอีกสักครู่';

  @override
  String get errorRejectedHeadline => 'ข้อมูลบางส่วนในโปรไฟล์ต้องตรวจสอบ';

  @override
  String get errorRejectedDetail =>
      'ตรวจสอบข้อมูลการเกิดของคุณ แล้วเริ่มอ่านคำตอบใหม่';

  @override
  String get errorInvalidHeadline => 'แอปเวอร์ชันนี้ไม่สามารถอ่านผลลัพธ์ได้';

  @override
  String get errorInvalidDetail => 'การอัปเดตแอปอาจช่วยให้กลับมาอ่านผลได้';

  @override
  String get errorConfigurationHeadline =>
      'แอปเวอร์ชันนี้ยังไม่ได้ตั้งค่าบริการอ่านคำตอบ';

  @override
  String get errorConfigurationDetail =>
      'เวอร์ชันสำหรับนักพัฒนา: ยังไม่ได้ตั้งค่าบริการคำนวณ';

  @override
  String get errorNothingRecorded => 'ครั้งนี้ไม่มีการบันทึกคำอ่าน';

  @override
  String get insufficientHeading => 'ข้อมูลยังไม่เพียงพอ';

  @override
  String get insufficientBody =>
      'ข้อมูลในโปรไฟล์ของคุณยังไม่เพียงพอที่จะเสนอทิศทางในครั้งนี้ การเพิ่มเวลาเกิดและประเทศเกิดจะช่วยให้วิเคราะห์วัฏจักรได้ละเอียดขึ้น';

  @override
  String get periodElapsedHeading => 'ช่วงเวลานั้นผ่านไปแล้ว';

  @override
  String get periodElapsedBody =>
      'ช่วงเวลานั้นผ่านไปแล้วในพื้นที่ของคุณ จึงไม่มีเวลาเหลือให้วิเคราะห์ เลือกช่วงเวลาถัดไปหรืออ่านช่วงเวลาปัจจุบันแทน ผลอ่านของวันนี้จะไม่ยกไปเป็นของวันพรุ่งนี้';

  @override
  String colorsToKeepNear(String first, String second) {
    return 'สีที่ควรอยู่ใกล้ตัว: $first และ $second';
  }

  @override
  String colorToKeepNear(String name) {
    return 'สีที่ควรอยู่ใกล้ตัว: $name';
  }

  @override
  String get shareTooltip => 'แชร์คำอ่านนี้';

  @override
  String get shareUnavailable => 'ขณะนี้ยังแชร์ไม่ได้';

  @override
  String get shareDisclaimer =>
      'มุมมองเชิงสัญลักษณ์สำหรับการทบทวนในชีวิตประจำวัน ไม่ใช่คำทำนายหรือความน่าจะเป็น';

  @override
  String get backToHistory => 'กลับไปที่ประวัติ';

  @override
  String get saveFailedRetry => 'บันทึกไม่สำเร็จ · ลองอีกครั้ง';

  @override
  String get savingToHistory => 'กำลังบันทึกลงประวัติ…';

  @override
  String get responsibleUseLink =>
      'นโยบายการใช้งานอย่างรับผิดชอบและความปลอดภัย';

  @override
  String get historyToday => 'วันนี้';

  @override
  String get historyCouldNotOpen => 'ไม่สามารถเปิดประวัติคำอ่านของคุณได้';

  @override
  String get historyNotEnoughData => 'ข้อมูลไม่เพียงพอ';

  @override
  String get historyPeriodPassed => 'ช่วงเวลาผ่านไปแล้ว';

  @override
  String get zodiacAries => 'ราศีเมษ';

  @override
  String get zodiacTaurus => 'ราศีพฤษภ';

  @override
  String get zodiacGemini => 'ราศีเมถุน';

  @override
  String get zodiacCancer => 'ราศีกรกฎ';

  @override
  String get zodiacLeo => 'ราศีสิงห์';

  @override
  String get zodiacVirgo => 'ราศีกันย์';

  @override
  String get zodiacLibra => 'ราศีตุลย์';

  @override
  String get zodiacScorpio => 'ราศีพิจิก';

  @override
  String get zodiacSagittarius => 'ราศีธนู';

  @override
  String get zodiacCapricorn => 'ราศีมังกร';

  @override
  String get zodiacAquarius => 'ราศีกุมภ์';

  @override
  String get zodiacPisces => 'ราศีมีน';

  @override
  String zodiacAvatarSemantics(String sign) {
    return 'อวตารจักรราศี $sign';
  }
}
