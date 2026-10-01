import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../localized_presentation.dart';
import '../theme.dart';

/// Returns localized Earthly Branch (Canh Giờ) for the given 24-hour time.
/// E.g. for hour 8: "Giờ Thìn (Rồng 🐲)"
String birthHourZodiacLabel(String localeName, int hour24) {
  final branchIndex = ((hour24 + 1) ~/ 2) % 12;
  final lang = localeName.split(RegExp('[-_]')).first.toLowerCase();

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
  const animalsVi = [
    'Chuột 🐀',
    'Trâu 🐂',
    'Hổ 🐅',
    'Mão 🐱',
    'Rồng 🐲',
    'Rắn 🐍',
    'Ngựa 🐎',
    'Dê 🐐',
    'Khỉ 🐒',
    'Gà 🐓',
    'Chó 🐕',
    'Lợn 🐖',
  ];

  const animalsEn = [
    'Rat 🐀',
    'Ox 🐂',
    'Tiger 🐅',
    'Rabbit / Cat 🐱',
    'Dragon 🐲',
    'Snake 🐍',
    'Horse 🐎',
    'Goat 🐐',
    'Monkey 🐒',
    'Rooster 🐓',
    'Dog 🐕',
    'Pig 🐖',
  ];

  if (lang == 'vi') {
    return 'Giờ ${branchesVi[branchIndex]} (${animalsVi[branchIndex]})';
  }
  return 'Hour of the ${animalsEn[branchIndex]}';
}

/// Asks for a birth time using a celestial wheel bottom sheet or manual input.
Future<TimeOfDay?> showBirthTimePicker({
  required BuildContext context,
  TimeOfDay? current,
  String? helpText,
}) => showModalBottomSheet<TimeOfDay>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (_) =>
      BirthTimePickerSheet(initialTime: current, helpText: helpText),
);

typedef BirthTimePickerDialog = BirthTimePickerSheet;

enum _EntryMode { wheel, manual }

class BirthTimePickerSheet extends StatefulWidget {
  const BirthTimePickerSheet({super.key, this.initialTime, this.helpText});

  final TimeOfDay? initialTime;
  final String? helpText;

  @override
  State<BirthTimePickerSheet> createState() => _BirthTimePickerSheetState();
}

class _BirthTimePickerSheetState extends State<BirthTimePickerSheet> {
  late int _hour12;
  late int _minute;
  late DayPeriod _period;

  late FixedExtentScrollController _hourWheel;
  late FixedExtentScrollController _minuteWheel;
  late FixedExtentScrollController _periodWheel;

  late final TextEditingController _hourController;
  late final TextEditingController _minuteController;
  late DayPeriod _manualPeriod;

  final _hourFocus = FocusNode();
  final _minuteFocus = FocusNode();

  var _mode = _EntryMode.wheel;
  var _wheelTouched = false;
  var _showError = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialTime;
    _hour12 = initial != null ? initial.hourOfPeriod : 8;
    _minute = initial != null ? initial.minute : 0;
    _period = initial != null ? initial.period : DayPeriod.am;

    _manualPeriod = _period;
    _hourController = TextEditingController(
      text: initial != null ? '$_hour12' : '',
    );
    _minuteController = TextEditingController(
      text: initial != null ? _minute.toString().padLeft(2, '0') : '',
    );

    _createWheelControllers();
  }

  void _createWheelControllers() {
    _hourWheel = FixedExtentScrollController(
      initialItem: _hour12 - 1,
      keepScrollOffset: false,
    );
    _minuteWheel = FixedExtentScrollController(
      initialItem: _minute,
      keepScrollOffset: false,
    );
    _periodWheel = FixedExtentScrollController(
      initialItem: _period == DayPeriod.am ? 0 : 1,
      keepScrollOffset: false,
    );
  }

  int get _wheelHour24 {
    if (_period == DayPeriod.am) {
      return _hour12 == 12 ? 0 : _hour12;
    } else {
      return _hour12 == 12 ? 12 : _hour12 + 12;
    }
  }

  int? get _manualHour24 {
    final h = int.tryParse(_hourController.text);
    if (h == null || h < 1 || h > 12) return null;
    if (_manualPeriod == DayPeriod.am) {
      return h == 12 ? 0 : h;
    } else {
      return h == 12 ? 12 : h + 12;
    }
  }

  int? get _manualMinuteValue {
    final m = int.tryParse(_minuteController.text);
    if (m == null || m < 0 || m > 59) return null;
    return m;
  }

  bool get _manualValid => _manualHour24 != null && _manualMinuteValue != null;

  void _chooseHour(int hour) => setState(() {
    _hour12 = hour;
    _wheelTouched = true;
  });

  void _chooseMinute(int minute) => setState(() {
    _minute = minute;
    _wheelTouched = true;
  });

  void _choosePeriod(DayPeriod period) => setState(() {
    _period = period;
    _wheelTouched = true;
  });

  void _setManualFields(int hour12, int minute, DayPeriod period) {
    _hourController.text = '$hour12';
    _minuteController.text = minute.toString().padLeft(2, '0');
    _manualPeriod = period;
  }

  void _setMode(_EntryMode mode) {
    if (mode == _mode) return;
    FocusScope.of(context).unfocus();
    setState(() {
      if (mode == _EntryMode.manual) {
        if (_hourController.text.isEmpty && _minuteController.text.isEmpty) {
          _setManualFields(_hour12, _minute, _period);
        }
      } else if (mode == _EntryMode.wheel && _manualValid) {
        final h = int.parse(_hourController.text);
        final m = int.parse(_minuteController.text);
        _hour12 = h;
        _minute = m;
        _period = _manualPeriod;
        _hourWheel.dispose();
        _minuteWheel.dispose();
        _periodWheel.dispose();
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
    if (_mode == _EntryMode.wheel) {
      final time = TimeOfDay(hour: _wheelHour24, minute: _minute);
      Navigator.of(context).pop(time);
      return;
    }

    if (!_manualValid) {
      setState(() => _showError = true);
      return;
    }

    final time = TimeOfDay(hour: _manualHour24!, minute: _manualMinuteValue!);
    Navigator.of(context).pop(time);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    _hourFocus.dispose();
    _minuteFocus.dispose();
    _hourWheel.dispose();
    _minuteWheel.dispose();
    _periodWheel.dispose();
    super.dispose();
  }

  Widget _wheelNumberColumn({
    required Key key,
    required FixedExtentScrollController controller,
    required int count,
    required int Function(int) valueAt,
    required ValueChanged<int> onSelected,
    required String label,
    int digits = 2,
    String Function(int)? itemKeyPrefix,
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
        final itemKey = itemKeyPrefix != null
            ? Key('${itemKeyPrefix(value)}')
            : null;
        return GestureDetector(
          key: itemKey,
          onTap: () {
            controller.animateToItem(
              index,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
            );
            onSelected(value);
          },
          child: Center(
            child: Semantics(
              label: '$label $value',
              child: Text(value.toString().padLeft(digits, '0')),
            ),
          ),
        );
      },
    ),
  );

  Widget _wheelPeriodColumn({
    required Key key,
    required FixedExtentScrollController controller,
    required ValueChanged<DayPeriod> onSelected,
    required String label,
    required bool isVi,
  }) => Expanded(
    child: CupertinoPicker.builder(
      key: key,
      scrollController: controller,
      itemExtent: 44,
      useMagnifier: true,
      magnification: 1.07,
      selectionOverlay: null,
      childCount: 2,
      onSelectedItemChanged: (index) =>
          onSelected(index == 0 ? DayPeriod.am : DayPeriod.pm),
      itemBuilder: (context, index) {
        final period = index == 0 ? DayPeriod.am : DayPeriod.pm;
        final text = index == 0
            ? (isVi ? 'Sáng' : 'AM')
            : (isVi ? 'Tối' : 'PM');
        final itemKey = Key(
          period == DayPeriod.am ? 'birth_time_am' : 'birth_time_pm',
        );
        return GestureDetector(
          key: itemKey,
          onTap: () {
            controller.animateToItem(
              index,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
            );
            onSelected(period);
          },
          child: Center(
            child: Semantics(label: '$label $text', child: Text(text)),
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
    final isVi = Localizations.localeOf(context).languageCode == 'vi';

    final int? currentHour24 = _mode == _EntryMode.wheel
        ? _wheelHour24
        : _manualHour24;

    final invalid =
        _mode == _EntryMode.manual &&
        (_showError ||
            (_hourController.text.length == 2 &&
                _minuteController.text.length == 2 &&
                !_manualValid));

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Container(
        key: const Key('birth_time_sheet'),
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
            key: const Key('birth_time_content'),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              key: const Key('birth_time_dialog'),
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
                Text(
                  widget.helpText ?? l10n.timeOfBirth,
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 18),
                SegmentedButton<_EntryMode>(
                  key: const Key('birth_time_mode'),
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    backgroundColor: CompassColors.glass,
                    selectedBackgroundColor: CompassColors.gold.withValues(
                      alpha: 0.16,
                    ),
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
                        key: const Key('birth_time_scroll_tab'),
                      ),
                    ),
                    ButtonSegment(
                      value: _EntryMode.manual,
                      icon: const Icon(Icons.keyboard_rounded, size: 18),
                      label: Text(
                        l10n.birthDateType,
                        key: const Key('birth_time_type_tab'),
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
                              isVi ? 'GIỜ' : 'HOUR',
                              isVi ? 'PHÚT' : 'MINUTE',
                              isVi ? 'BUỔI' : 'PERIOD',
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
                                    _wheelNumberColumn(
                                      key: const Key('birth_time_hour_wheel'),
                                      controller: _hourWheel,
                                      count: 12,
                                      valueAt: (index) => index + 1,
                                      onSelected: _chooseHour,
                                      label: isVi ? 'Giờ' : 'Hour',
                                      itemKeyPrefix: (val) =>
                                          'birth_time_hour_$val',
                                    ),
                                    _wheelNumberColumn(
                                      key: const Key('birth_time_minute_wheel'),
                                      controller: _minuteWheel,
                                      count: 60,
                                      valueAt: (index) => index,
                                      onSelected: _chooseMinute,
                                      label: isVi ? 'Phút' : 'Minute',
                                      itemKeyPrefix: (val) =>
                                          'birth_time_minute_$val',
                                    ),
                                    _wheelPeriodColumn(
                                      key: const Key('birth_time_period_wheel'),
                                      controller: _periodWheel,
                                      onSelected: _choosePeriod,
                                      label: isVi ? 'Buổi' : 'Period',
                                      isVi: isVi,
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
                        key: const Key('birth_time_hour_field'),
                        controller: _hourController,
                        label: isVi ? 'Giờ' : 'Hour',
                        hint: 'HH',
                        length: 2,
                        focus: _hourFocus,
                        next: _minuteFocus,
                        flex: 2,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          ':',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: CompassColors.gold,
                          ),
                        ),
                      ),
                      _part(
                        key: const Key('birth_time_minute_field'),
                        controller: _minuteController,
                        label: isVi ? 'Phút' : 'Minute',
                        hint: 'MM',
                        length: 2,
                        focus: _minuteFocus,
                        flex: 2,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 3,
                        child: SegmentedButton<DayPeriod>(
                          key: const Key('birth_time_period_toggle'),
                          showSelectedIcon: false,
                          style: SegmentedButton.styleFrom(
                            backgroundColor: CompassColors.glass,
                            selectedBackgroundColor: CompassColors.gold
                                .withValues(alpha: 0.2),
                            selectedForegroundColor: CompassColors.gold,
                            foregroundColor: CompassColors.secondary,
                            side: BorderSide(
                              color: CompassColors.line.withValues(alpha: 0.6),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          segments: [
                            ButtonSegment(
                              value: DayPeriod.am,
                              label: Text(
                                isVi ? 'Sáng' : 'AM',
                                key: const Key('birth_time_am'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            ButtonSegment(
                              value: DayPeriod.pm,
                              label: Text(
                                isVi ? 'Tối' : 'PM',
                                key: const Key('birth_time_pm'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                          selected: {_manualPeriod},
                          onSelectionChanged: (selection) => setState(() {
                            _manualPeriod = selection.first;
                            _showError = false;
                          }),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 18),
                if (invalid)
                  Text(
                    isVi
                        ? 'Vui lòng nhập giờ (1-12) và phút (0-59) hợp lệ.'
                        : 'Enter a valid time (1-12 hours, 0-59 minutes).',
                    key: const Key('birth_time_feedback'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else if (currentHour24 != null)
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
                        birthHourZodiacLabel(
                          intlLocaleOf(context),
                          currentHour24,
                        ),
                        key: const Key('birth_time_feedback'),
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
                    l10n.selectBirthTime,
                    key: const Key('birth_time_feedback'),
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
                        key: const Key('birth_time_cancel'),
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
                        key: const Key('birth_time_confirm'),
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
