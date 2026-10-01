import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../local_engine/calendar/chinese_calendar.dart';
import '../localized_presentation.dart';
import '../theme.dart';

/// Returns localized Chinese zodiac (Con giáp / Can Chi) for the given solar date.
String chineseZodiacLabel(String localeName, DateTime date) {
  var year = date.year;
  try {
    final lunar = lunarFromSolar(date.year, date.month, date.day);
    if (lunar.year > 0) {
      year = lunar.year;
    }
  } catch (_) {
    year = date.year;
  }

  var branchIndex = (year - 4) % 12;
  if (branchIndex < 0) branchIndex += 12;
  var stemIndex = (year - 4) % 10;
  if (stemIndex < 0) stemIndex += 10;

  const animalsVi = [
    'Chuột',
    'Trâu',
    'Hổ',
    'Mèo / Thỏ',
    'Rồng',
    'Rắn',
    'Ngựa',
    'Dê',
    'Khỉ',
    'Gà',
    'Chó',
    'Lợn',
  ];
  const stemsVi = [
    'Giáp',
    'Ất',
    'Bính',
    'Đinh',
    'Mậu',
    'Kỷ',
    'Canh',
    'Tân',
    'Nhâm',
    'Quý',
  ];
  const branchesVi = [
    'Tý',
    'Sửu',
    'Dần',
    'Mão',
    'Thìn',
    'Tỵ',
    'Ngọ',
    'Mùi',
    'Thân',
    'Dậu',
    'Tuất',
    'Hợi',
  ];
  const emojis = [
    '🐀',
    '🐂',
    '🐅',
    '🐱',
    '🐉',
    '🐍',
    '🐎',
    '🐐',
    '🐒',
    '🐓',
    '🐕',
    '🐖',
  ];

  const animalsEn = [
    'Rat',
    'Ox',
    'Tiger',
    'Rabbit / Cat',
    'Dragon',
    'Snake',
    'Horse',
    'Goat',
    'Monkey',
    'Rooster',
    'Dog',
    'Pig',
  ];
  const animalsEs = [
    'Rata',
    'Buey',
    'Tigre',
    'Conejo',
    'Dragón',
    'Serpiente',
    'Caballo',
    'Cabra',
    'Mono',
    'Gallo',
    'Perro',
    'Cerdo',
  ];
  const stemsZh = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];
  const branchesZh = [
    '子',
    '丑',
    '寅',
    '卯',
    '辰',
    '巳',
    '午',
    '未',
    '申',
    '酉',
    '戌',
    '亥',
  ];
  const animalsZh = [
    '鼠',
    '牛',
    '虎',
    '兔',
    '龙',
    '蛇',
    '马',
    '羊',
    '猴',
    '鸡',
    '狗',
    '猪',
  ];
  const animalsJa = [
    '子',
    '丑',
    '寅',
    '卯',
    '辰',
    '巳',
    '午',
    '未',
    '申',
    '酉',
    '戌',
    '亥',
  ];
  const animalsTh = [
    'ปีชวด (หนู)',
    'ปีฉลู (วัว)',
    'ปีขาล (เสือ)',
    'ปีเถาะ (กระต่าย)',
    'ปีมะโรง (มังกร)',
    'ปีมะเส็ง (งูเล็ก)',
    'ปีมะเมีย (ม้า)',
    'ปีมะแม (แพะ)',
    'ปีวอก (ลิง)',
    'ปีระกา (ไก่)',
    'ปีจอ (หมา)',
    'ปีกุน (หมู)',
  ];

  final lang = localeName.split(RegExp('[-_]')).first.toLowerCase();
  return switch (lang) {
    'vi' =>
      'Tuổi ${stemsVi[stemIndex]} ${branchesVi[branchIndex]} (${animalsVi[branchIndex]}) ${emojis[branchIndex]}',
    'es' => 'Año del ${animalsEs[branchIndex]} ${emojis[branchIndex]}',
    'zh' =>
      '${stemsZh[stemIndex]}${branchesZh[branchIndex]}年 (${animalsZh[branchIndex]}) ${emojis[branchIndex]}',
    'ja' => '${animalsJa[branchIndex]}年 ${emojis[branchIndex]}',
    'th' => '${animalsTh[branchIndex]} ${emojis[branchIndex]}',
    _ => 'Year of the ${animalsEn[branchIndex]} ${emojis[branchIndex]}',
  };
}

Future<DateTime?> showBirthDatePicker({
  required BuildContext context,
  DateTime? initialDate,
}) => showModalBottomSheet<DateTime>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (_) => BirthDatePickerSheet(initialDate: initialDate),
);

enum _EntryMode { wheel, manual }

class BirthDatePickerSheet extends StatefulWidget {
  const BirthDatePickerSheet({super.key, this.initialDate, this.lastDate});

  final DateTime? initialDate;

  /// Injectable so date-boundary behavior can be checked without the clock.
  final DateTime? lastDate;

  @override
  State<BirthDatePickerSheet> createState() => _BirthDatePickerSheetState();
}

class _BirthDatePickerSheetState extends State<BirthDatePickerSheet> {
  static final _firstDate = DateTime(1900);

  late DateTime _wheelDate;
  late FixedExtentScrollController _dayWheel;
  late FixedExtentScrollController _monthWheel;
  late FixedExtentScrollController _yearWheel;
  late final TextEditingController _day;
  late final TextEditingController _month;
  late final TextEditingController _year;
  final _monthFocus = FocusNode();
  final _yearFocus = FocusNode();
  var _mode = _EntryMode.wheel;
  var _wheelTouched = false;
  var _showError = false;

  DateTime get _lastDate =>
      DateUtils.dateOnly(widget.lastDate ?? DateTime.now());

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDate;
    final today = DateUtils.dateOnly(widget.lastDate ?? DateTime.now());
    final defaultDate = DateTime(2000);
    _wheelDate =
        initial != null &&
            !initial.isBefore(_firstDate) &&
            !initial.isAfter(today)
        ? DateUtils.dateOnly(initial)
        : defaultDate.isAfter(today)
        ? today
        : defaultDate;
    _day = TextEditingController(text: initial?.day.toString().padLeft(2, '0'));
    _month = TextEditingController(
      text: initial?.month.toString().padLeft(2, '0'),
    );
    _year = TextEditingController(text: initial?.year.toString());
    _createWheelControllers();
  }

  void _createWheelControllers() {
    _dayWheel = FixedExtentScrollController(
      initialItem: _wheelDate.day - 1,
      keepScrollOffset: false,
    );
    _monthWheel = FixedExtentScrollController(
      initialItem: _wheelDate.month - 1,
      keepScrollOffset: false,
    );
    _yearWheel = FixedExtentScrollController(
      initialItem: _wheelDate.year - 1900,
      keepScrollOffset: false,
    );
  }

  int _monthCount(int year) => year == _lastDate.year ? _lastDate.month : 12;

  int _dayCount(int year, int month) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    return year == _lastDate.year && month == _lastDate.month
        ? math.min(daysInMonth, _lastDate.day)
        : daysInMonth;
  }

  void _chooseYear(int year) {
    final old = _wheelDate;
    final month = math.min(old.month, _monthCount(year));
    final day = math.min(old.day, _dayCount(year, month));
    setState(() {
      _wheelDate = DateTime(year, month, day);
      _wheelTouched = true;
    });
    if (month != old.month) _monthWheel.jumpToItem(month - 1);
    if (day != old.day) _dayWheel.jumpToItem(day - 1);
  }

  void _chooseMonth(int month) {
    final old = _wheelDate;
    final day = math.min(old.day, _dayCount(old.year, month));
    setState(() {
      _wheelDate = DateTime(old.year, month, day);
      _wheelTouched = true;
    });
    if (day != old.day) _dayWheel.jumpToItem(day - 1);
  }

  void _chooseDay(int day) => setState(() {
    _wheelDate = DateTime(_wheelDate.year, _wheelDate.month, day);
    _wheelTouched = true;
  });

  DateTime? get _manualDate {
    final day = int.tryParse(_day.text);
    final month = int.tryParse(_month.text);
    final year = int.tryParse(_year.text);
    if (day == null || month == null || year == null) return null;
    if (year < 1900 || year > _lastDate.year || month < 1 || month > 12) {
      return null;
    }
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day)
      return null;
    if (date.isAfter(_lastDate)) return null;
    return date;
  }

  bool get _manualComplete =>
      _day.text.isNotEmpty && _month.text.isNotEmpty && _year.text.length == 4;

  void _setManualFields(DateTime date) {
    _day.text = date.day.toString().padLeft(2, '0');
    _month.text = date.month.toString().padLeft(2, '0');
    _year.text = date.year.toString();
  }

  void _setMode(_EntryMode mode) {
    if (mode == _mode) return;
    FocusScope.of(context).unfocus();
    setState(() {
      if (mode == _EntryMode.manual &&
          _day.text.isEmpty &&
          _month.text.isEmpty &&
          _year.text.isEmpty &&
          _wheelTouched) {
        _setManualFields(_wheelDate);
      } else if (mode == _EntryMode.wheel && _manualDate != null) {
        _wheelDate = _manualDate!;
        _dayWheel.dispose();
        _monthWheel.dispose();
        _yearWheel.dispose();
        _createWheelControllers();
      }
      _mode = mode;
      _showError = false;
    });
  }

  void _onChanged(String value, {FocusNode? next, int? length}) {
    setState(() => _showError = false);
    if (next != null && value.length == length) next.requestFocus();
  }

  void _confirm() {
    final date = _mode == _EntryMode.wheel ? _wheelDate : _manualDate;
    if (date == null) {
      setState(() => _showError = true);
      return;
    }
    Navigator.of(context).pop(date);
  }

  @override
  void dispose() {
    _day.dispose();
    _month.dispose();
    _year.dispose();
    _monthFocus.dispose();
    _yearFocus.dispose();
    _dayWheel.dispose();
    _monthWheel.dispose();
    _yearWheel.dispose();
    super.dispose();
  }

  Widget _wheelColumn({
    required Key key,
    required FixedExtentScrollController controller,
    required int count,
    required int Function(int) valueAt,
    required ValueChanged<int> onSelected,
    required String label,
    int digits = 2,
  }) => Expanded(
    child: CupertinoPicker.builder(
      key: key,
      scrollController: controller,
      itemExtent: 44,
      useMagnifier: true,
      magnification: 1.07,
      selectionOverlay: null,
      childCount: count,
      onSelectedItemChanged: (index) => onSelected(valueAt(index)),
      itemBuilder: (context, index) {
        final value = valueAt(index);
        return Center(
          child: Semantics(
            label: '$label $value',
            child: Text(value.toString().padLeft(digits, '0')),
          ),
        );
      },
    ),
  );

  Widget _part({
    required Key key,
    required TextEditingController controller,
    required String label,
    required String hint,
    required int length,
    FocusNode? focus,
    FocusNode? next,
    int flex = 2,
  }) => Expanded(
    flex: flex,
    child: TextField(
      key: key,
      controller: controller,
      focusNode: focus,
      keyboardType: TextInputType.number,
      textInputAction: next == null
          ? TextInputAction.done
          : TextInputAction.next,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(length),
      ],
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
      ),
      onChanged: (value) => _onChanged(value, next: next, length: length),
      onSubmitted: next == null
          ? (_) => _confirm()
          : (_) => next.requestFocus(),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final material = MaterialLocalizations.of(context);
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final manualDate = _manualDate;
    final invalid =
        _mode == _EntryMode.manual &&
        manualDate == null &&
        (_showError || _manualComplete);
    final selectedDate = _mode == _EntryMode.wheel ? _wheelDate : manualDate;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Container(
        key: const Key('birth_date_sheet'),
        constraints: BoxConstraints(
          maxHeight: (media.size.height - media.viewInsets.bottom) * 0.9,
        ),
        decoration: BoxDecoration(
          color: CompassColors.raised,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: CompassColors.line),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(l10n.dateOfBirth, style: theme.textTheme.headlineMedium),
                const SizedBox(height: 18),
                SegmentedButton<_EntryMode>(
                  key: const Key('birth_date_mode'),
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    backgroundColor: CompassColors.glass,
                    selectedBackgroundColor:
                        CompassColors.gold.withValues(alpha: 0.16),
                    selectedForegroundColor: CompassColors.gold,
                    foregroundColor: CompassColors.secondary,
                    side: BorderSide(
                      color: CompassColors.line.withValues(alpha: 0.6),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  segments: [
                    ButtonSegment(
                      value: _EntryMode.wheel,
                      icon: const Icon(Icons.swipe_vertical_rounded, size: 18),
                      label: Text(
                        l10n.birthDateScroll,
                        key: const Key('birth_date_scroll_tab'),
                      ),
                    ),
                    ButtonSegment(
                      value: _EntryMode.manual,
                      icon: const Icon(Icons.keyboard_rounded, size: 18),
                      label: Text(
                        l10n.birthDateType,
                        key: const Key('birth_date_type_tab'),
                      ),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (selection) => _setMode(selection.first),
                ),
                const SizedBox(height: 12),
                if (_mode == _EntryMode.wheel)
                  CupertinoTheme(
                    data: CupertinoThemeData(
                      brightness: Brightness.dark,
                      primaryColor: CompassColors.gold,
                      textTheme: CupertinoTextThemeData(
                        pickerTextStyle: theme.textTheme.titleLarge?.copyWith(
                          color: CompassColors.text,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            for (final label in [
                              l10n.birthDay,
                              l10n.birthMonth,
                              l10n.birthYear,
                            ])
                              Expanded(
                                child: Text(
                                  label,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: CompassColors.gold,
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 200,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                height: 46,
                                decoration: BoxDecoration(
                                  color: CompassColors.gold.withValues(
                                    alpha: 0.08,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: CompassColors.gold.withValues(
                                      alpha: 0.45,
                                    ),
                                    width: 1.2,
                                  ),
                                ),
                              ),
                              ShaderMask(
                                shaderCallback: (bounds) =>
                                    const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black,
                                    Colors.black,
                                    Colors.transparent,
                                  ],
                                  stops: [0.0, 0.2, 0.8, 1.0],
                                ).createShader(bounds),
                                blendMode: BlendMode.dstIn,
                                child: Row(
                                  children: [
                                    _wheelColumn(
                                      key: const Key('birth_date_day_wheel'),
                                      controller: _dayWheel,
                                      count: _dayCount(
                                        _wheelDate.year,
                                        _wheelDate.month,
                                      ),
                                      valueAt: (index) => index + 1,
                                      onSelected: _chooseDay,
                                      label: l10n.birthDay,
                                    ),
                                    _wheelColumn(
                                      key: const Key('birth_date_month_wheel'),
                                      controller: _monthWheel,
                                      count: _monthCount(_wheelDate.year),
                                      valueAt: (index) => index + 1,
                                      onSelected: _chooseMonth,
                                      label: l10n.birthMonth,
                                    ),
                                    _wheelColumn(
                                      key: const Key('birth_date_year_wheel'),
                                      controller: _yearWheel,
                                      count: _lastDate.year - 1899,
                                      valueAt: (index) => index + 1900,
                                      onSelected: _chooseYear,
                                      label: l10n.birthYear,
                                      digits: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _part(
                        key: const Key('birth_date_day'),
                        controller: _day,
                        label: l10n.birthDay,
                        hint: 'DD',
                        length: 2,
                        next: _monthFocus,
                      ),
                      const SizedBox(width: 8),
                      _part(
                        key: const Key('birth_date_month'),
                        controller: _month,
                        label: l10n.birthMonth,
                        hint: 'MM',
                        length: 2,
                        focus: _monthFocus,
                        next: _yearFocus,
                      ),
                      const SizedBox(width: 8),
                      _part(
                        key: const Key('birth_date_year'),
                        controller: _year,
                        label: l10n.birthYear,
                        hint: 'YYYY',
                        length: 4,
                        focus: _yearFocus,
                        flex: 3,
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 18),
                if (invalid)
                  Text(
                    l10n.birthDateInvalid,
                    key: const Key('birth_date_feedback'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else if (selectedDate != null)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: CompassColors.glass,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: CompassColors.gold.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        chineseZodiacLabel(
                          intlLocaleOf(context),
                          selectedDate,
                        ),
                        key: const Key('birth_date_feedback'),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: CompassColors.gold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                else
                  Text(
                    l10n.selectBirthDate,
                    key: const Key('birth_date_feedback'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: CompassColors.secondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        key: const Key('birth_date_cancel'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          foregroundColor: CompassColors.secondary,
                          side: const BorderSide(color: CompassColors.line),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(material.cancelButtonLabel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        key: const Key('birth_date_confirm'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          backgroundColor: CompassColors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onPressed: _confirm,
                        child: Text(l10n.continueAction),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
