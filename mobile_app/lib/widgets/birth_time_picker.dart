import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Asks for a birth time, starting from no answer at all.
///
/// Material's own dialog cannot express this. It has no empty state, so it
/// opens pointing at some hour, and pressing OK returns that hour — there is
/// no way to tell "the reader chose 9:00" from "the reader never answered".
/// Its dial is also wrapped in `ExcludeSemantics`, so a screen reader cannot
/// select an hour on it at all; and the ring it draws follows the locale's
/// clock, which for Vietnamese, Japanese, Chinese and Thai is a crowded
/// double ring of 00–23.
///
/// So this is its own dialog. The selection starts null, OK stays disabled
/// until an hour *and* a minute have been chosen, and every hour is a real
/// button — which means a screen reader can pick one, and so can a test.
///
/// Only the question changes. The answer is a [TimeOfDay], which is 24-hour,
/// and the profile stores `HH:mm`: midnight is `00:00` and noon is `12:00`,
/// exactly as the calculation engine expects.
///
/// Returns null when the reader gave no answer — cancelled, dismissed, or
/// never completed a selection.
Future<TimeOfDay?> showBirthTimePicker({
  required BuildContext context,
  TimeOfDay? current,
  String? helpText,
}) {
  return showDialog<TimeOfDay>(
    context: context,
    builder: (context) =>
        BirthTimePickerDialog(initialTime: current, helpText: helpText),
  );
}

/// The dialog itself. Public so a test can mount it without the whole flow.
class BirthTimePickerDialog extends StatefulWidget {
  const BirthTimePickerDialog({super.key, this.initialTime, this.helpText});

  /// The answer the reader has already given, if any. Null means the question
  /// is unanswered, and the dial opens with nothing selected.
  final TimeOfDay? initialTime;

  final String? helpText;

  @override
  State<BirthTimePickerDialog> createState() => _BirthTimePickerDialogState();
}

/// Which ring the dial is showing.
enum _Ring { hour, minute }

class _BirthTimePickerDialogState extends State<BirthTimePickerDialog> {
  /// 1–12, or null while the hour is unanswered.
  int? _hour12;

  /// 0–59, or null while the minute is unanswered.
  int? _minute;

  /// Defaults to morning, the way every twelve-hour clock does. It is only
  /// ever *part* of an answer: on its own it confirms nothing, because the
  /// hour and the minute still have to be chosen.
  late DayPeriod _period;

  late _Ring _ring;
  var _keyboardEntry = false;

  late final TextEditingController _hourField;
  late final TextEditingController _minuteField;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialTime;
    _hour12 = initial?.hourOfPeriod;
    _minute = initial?.minute;
    _period = initial?.period ?? DayPeriod.am;
    // Always starts on the hour ring, fresh or editing an existing answer —
    // the existing hour and minute stay exactly as they were, only the ring
    // shown first changes, so re-opening a saved time still lets the reader
    // walk through both halves from the top instead of landing mid-edit.
    _ring = _Ring.hour;
    _hourField = TextEditingController(text: _hour12 == null ? '' : '$_hour12');
    _minuteField = TextEditingController(
      text: _minute == null ? '' : _minute.toString().padLeft(2, '0'),
    );
  }

  @override
  void dispose() {
    _hourField.dispose();
    _minuteField.dispose();
    super.dispose();
  }

  /// Both halves answered. Until then there is nothing to confirm.
  bool get _complete => _hour12 != null && _minute != null;

  /// The twelve-hour answer as the 24-hour time the engine works in.
  ///
  /// Midnight and noon are the two that catch people out: twelve in the
  /// morning is hour zero, twelve in the afternoon is hour twelve.
  TimeOfDay? get _value => _complete
      ? TimeOfDay(
          hour: _period == DayPeriod.am ? _hour12! % 12 : _hour12! % 12 + 12,
          minute: _minute!,
        )
      : null;

  void _chooseHour(int hour12) => setState(() {
    _hour12 = hour12;
    _hourField.text = '$hour12';
    // Choosing an hour always moves on to the minute ring next — even when
    // editing an already-complete answer — without touching whatever minute
    // was already chosen.
    _ring = _Ring.minute;
  });

  void _chooseMinute(int minute) => setState(() {
    _minute = minute;
    _minuteField.text = minute.toString().padLeft(2, '0');
  });

  void _choosePeriod(DayPeriod period) => setState(() => _period = period);

  void _setEntryMode(bool keyboard) =>
      setState(() => _keyboardEntry = keyboard);

  void _readHourField(String raw) {
    final value = int.tryParse(raw);
    setState(() {
      _hour12 = (value != null && value >= 1 && value <= 12) ? value : null;
    });
  }

  void _readMinuteField(String raw) {
    final value = int.tryParse(raw);
    setState(() {
      _minute = (value != null && value >= 0 && value <= 59) ? value : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final material = MaterialLocalizations.of(context);
    final theme = Theme.of(context);

    return AlertDialog(
      key: const Key('birth_time_dialog'),
      // `AlertDialog` scrolls its own content, which is what keeps the dial
      // reachable at a large text scale on a short screen.
      title: Text(
        widget.helpText ?? material.timePickerDialHelpText,
        style: theme.textTheme.titleMedium,
      ),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      content: SizedBox(
        key: const Key('birth_time_content'),
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              hour: _hour12,
              minute: _minute,
              period: _period,
              ring: _ring,
              keyboardEntry: _keyboardEntry,
              onRing: (ring) => setState(() => _ring = ring),
              onPeriod: _choosePeriod,
              hourField: _hourField,
              minuteField: _minuteField,
              onHourTyped: _readHourField,
              onMinuteTyped: _readMinuteField,
            ),
            if (!_keyboardEntry) ...[
              const SizedBox(height: 16),
              _Dial(
                ring: _ring,
                hour: _hour12,
                minute: _minute,
                onHour: _chooseHour,
                onMinute: _chooseMinute,
              ),
            ],
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      actions: [
        Row(
          children: [
            IconButton(
              key: const Key('birth_time_entry_mode'),
              onPressed: () => _setEntryMode(!_keyboardEntry),
              icon: Icon(
                _keyboardEntry ? Icons.access_time : Icons.keyboard_outlined,
              ),
              tooltip: _keyboardEntry
                  ? material.dialModeButtonLabel
                  : material.inputTimeModeButtonLabel,
            ),
            const Spacer(),
            TextButton(
              key: const Key('birth_time_cancel'),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(material.cancelButtonLabel),
            ),
            TextButton(
              key: const Key('birth_time_confirm'),
              // Disabled until the question is answered. Nothing about the
              // dialog's own starting state can become a birth time.
              onPressed: _complete
                  ? () => Navigator.of(context).pop(_value)
                  : null,
              child: Text(material.okButtonLabel),
            ),
          ],
        ),
      ],
    );
  }
}

/// The chosen time so far, and the AM/PM selector.
class _Header extends StatelessWidget {
  const _Header({
    required this.hour,
    required this.minute,
    required this.period,
    required this.ring,
    required this.keyboardEntry,
    required this.onRing,
    required this.onPeriod,
    required this.hourField,
    required this.minuteField,
    required this.onHourTyped,
    required this.onMinuteTyped,
  });

  final int? hour;
  final int? minute;
  final DayPeriod period;
  final _Ring ring;
  final bool keyboardEntry;
  final ValueChanged<_Ring> onRing;
  final ValueChanged<DayPeriod> onPeriod;
  final TextEditingController hourField;
  final TextEditingController minuteField;
  final ValueChanged<String> onHourTyped;
  final ValueChanged<String> onMinuteTyped;

  /// An unanswered half reads as dashes rather than as a plausible number.
  static const _blank = '--';

  @override
  Widget build(BuildContext context) {
    final material = MaterialLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: keyboardEntry
              ? _Field(
                  fieldKey: const Key('birth_time_hour_field'),
                  controller: hourField,
                  label: material.timePickerHourLabel,
                  onChanged: onHourTyped,
                )
              : _HeaderValue(
                  testKey: const Key('birth_time_header_hour'),
                  value: hour == null ? _blank : material.formatDecimal(hour!),
                  semanticsLabel: material.timePickerHourLabel,
                  selected: ring == _Ring.hour,
                  onTap: () => onRing(_Ring.hour),
                ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(':', style: Theme.of(context).textTheme.headlineMedium),
        ),
        Expanded(
          child: keyboardEntry
              ? _Field(
                  fieldKey: const Key('birth_time_minute_field'),
                  controller: minuteField,
                  label: material.timePickerMinuteLabel,
                  onChanged: onMinuteTyped,
                )
              : _HeaderValue(
                  testKey: const Key('birth_time_header_minute'),
                  value: minute == null
                      ? _blank
                      : material.formatMinute(
                          TimeOfDay(hour: 0, minute: minute!),
                        ),
                  semanticsLabel: material.timePickerMinuteLabel,
                  selected: ring == _Ring.minute,
                  onTap: () => onRing(_Ring.minute),
                ),
        ),
        const SizedBox(width: 10),
        _PeriodSelector(period: period, onChanged: onPeriod),
      ],
    );
  }
}

class _HeaderValue extends StatelessWidget {
  const _HeaderValue({
    required this.testKey,
    required this.value,
    required this.semanticsLabel,
    required this.selected,
    required this.onTap,
  });

  final Key testKey;
  final String value;
  final String semanticsLabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: semanticsLabel,
      value: value,
      child: InkWell(
        key: testKey,
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? scheme.primary.withValues(alpha: 0.18)
                : scheme.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(10),
          ),
          // Excluded, not the whole button: the label is already on the
          // Semantics above, and the InkWell's tap action has to survive.
          child: ExcludeSemantics(
            child: Text(
              value,
              maxLines: 1,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: selected ? scheme.primary : null,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Typed entry, for an exact minute or for anyone who would rather not aim at
/// a circle. Starts empty when the question is unanswered.
class _Field extends StatelessWidget {
  const _Field({
    required this.fieldKey,
    required this.controller,
    required this.label,
    required this.onChanged,
  });

  /// On the `TextField` itself, so a test can read what it holds.
  final Key fieldKey;

  final TextEditingController controller;
  final String label;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: fieldKey,
      controller: controller,
      onChanged: onChanged,
      textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(2),
      ],
      decoration: InputDecoration(labelText: label, isDense: true),
      style: Theme.of(context).textTheme.headlineSmall,
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.period, required this.onChanged});

  final DayPeriod period;
  final ValueChanged<DayPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    final material = MaterialLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    Widget half(DayPeriod value, String label, Key key) {
      final selected = value == period;
      return Semantics(
        button: true,
        inMutuallyExclusiveGroup: true,
        selected: selected,
        label: label,
        child: InkWell(
          key: key,
          onTap: () => onChanged(value),
          child: Container(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 34),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            color: selected
                ? scheme.primary.withValues(alpha: 0.22)
                : Colors.transparent,
            child: ExcludeSemantics(
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      );
    }

    final isVi = Localizations.localeOf(context).languageCode == 'vi';
    final amLabel = isVi ? 'AM' : material.anteMeridiemAbbreviation;
    final pmLabel = isVi ? 'PM' : material.postMeridiemAbbreviation;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            half(
              DayPeriod.am,
              amLabel,
              const Key('birth_time_am'),
            ),
            Divider(height: 1, color: scheme.outline),
            half(
              DayPeriod.pm,
              pmLabel,
              const Key('birth_time_pm'),
            ),
          ],
        ),
      ),
    );
  }
}

/// One ring of twelve, drawn as twelve real buttons.
///
/// Material paints its numbers with a `TextPainter` inside `ExcludeSemantics`,
/// which is why a screen reader cannot use its dial. These are ordinary
/// widgets, so they are reachable by touch, by a screen reader, and by a test.
class _Dial extends StatelessWidget {
  const _Dial({
    required this.ring,
    required this.hour,
    required this.minute,
    required this.onHour,
    required this.onMinute,
  });

  final _Ring ring;
  final int? hour;
  final int? minute;
  final ValueChanged<int> onHour;
  final ValueChanged<int> onMinute;

  /// Android's minimum accessible touch target.
  static const _tile = 48.0;

  /// The clockwise angle (from twelve o'clock) the hour hand should point at,
  /// or null while no hour has been chosen yet.
  double? get _hourAngle {
    if (hour == null) return null;
    final value = hour == 12 ? 0 : hour!;
    return value * math.pi / 6;
  }

  /// The clockwise angle the minute hand should point at, or null while no
  /// minute has been chosen yet. Continuous rather than snapped to one of the
  /// twelve markers, so a value typed on the keyboard (e.g. 17) still points
  /// to a real position between "15" and "20" instead of matching no marker.
  double? get _minuteAngle {
    if (minute == null) return null;
    return minute! * math.pi / 30;
  }

  @override
  Widget build(BuildContext context) {
    final material = MaterialLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        // All the width the dialog can give it, up to a point. A 360dp phone
        // leaves 240 here, which puts the twelve targets 49dp apart around
        // the ring — just over the 48dp minimum, so no two of them compete
        // for the same finger.
        final size = math.min(constraints.maxWidth, 280.0);
        final radius = (size - _tile) / 2;

        return Center(
          child: SizedBox(
            width: size,
            height: size,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
              ),
              // The numerals are clamped rather than left to grow with the
              // text scale: past about a third larger they stop fitting
              // inside their own touch target and start colliding with their
              // neighbours on the ring. Everything else in the dialog — the
              // chosen time, AM/PM, the buttons — scales without a cap.
              child: MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.3,
                child: Stack(
                  children: [
                    // Under the number buttons, so the filled circle at each
                    // hand's tip still reads as "this one is selected" rather
                    // than being covered by the hand itself. Both hands show
                    // at once, the way a real clock face always has both —
                    // the ring currently being edited draws in full colour,
                    // the other stays dim so it reads as "already chosen"
                    // rather than competing for attention.
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _DialHandPainter(
                          // The hour hand reads as an hour hand — shorter
                          // than the minute hand, the way an analog clock
                          // draws it — rather than reaching all the way to
                          // the ring, which is where only the minute values
                          // actually sit. The minute hand stops at the near
                          // edge of its target button rather than its centre,
                          // so it touches the selected number instead of
                          // spearing through the middle of it.
                          hourLength: radius * 0.55,
                          minuteLength: radius - _tile / 2,
                          hourAngle: _hourAngle,
                          minuteAngle: _minuteAngle,
                          activeRing: ring,
                          activeColor: scheme.primary,
                          inactiveColor: scheme.primary.withValues(
                            alpha: 0.35,
                          ),
                        ),
                      ),
                    ),
                    for (var index = 0; index < 12; index++)
                      _dialButton(
                        context,
                        index,
                        radius,
                        size,
                        material,
                        scheme,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _dialButton(
    BuildContext context,
    int index,
    double radius,
    double size,
    MaterialLocalizations material,
    ColorScheme scheme,
  ) {
    // Twelve at the top, running clockwise: thirty degrees per position.
    final angle = index * math.pi / 6;
    final centre =
        Offset(size / 2, size / 2) +
        Offset(math.sin(angle) * radius, -math.cos(angle) * radius);

    final isHour = ring == _Ring.hour;
    // The hour ring reads 12, 1, 2 … 11; the minute ring 00, 05 … 55.
    final value = isHour ? (index == 0 ? 12 : index) : index * 5;
    final selected = isHour ? hour == value : minute == value;
    final label = isHour
        ? material.formatDecimal(value)
        : material.formatMinute(TimeOfDay(hour: 0, minute: value));

    return Positioned(
      left: centre.dx - _tile / 2,
      top: centre.dy - _tile / 2,
      width: _tile,
      height: _tile,
      child: Semantics(
        button: true,
        inMutuallyExclusiveGroup: true,
        selected: selected,
        label: label,
        child: InkResponse(
          key: Key(
            isHour ? 'birth_time_hour_$value' : 'birth_time_minute_$value',
          ),
          radius: _tile / 2,
          onTap: () => isHour ? onHour(value) : onMinute(value),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? scheme.primary : Colors.transparent,
            ),
            child: ExcludeSemantics(
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? scheme.onPrimary : scheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The pivot dot at the dial's centre, plus both an hour hand and a minute
/// hand — the way a real clock face always shows both at once, not just
/// whichever ring is currently being edited. This is the piece Material's
/// own dial has that a plain filled number alone does not: something to
/// visually anchor each chosen value to the centre of the clock face.
class _DialHandPainter extends CustomPainter {
  const _DialHandPainter({
    required this.hourLength,
    required this.minuteLength,
    required this.hourAngle,
    required this.minuteAngle,
    required this.activeRing,
    required this.activeColor,
    required this.inactiveColor,
  });

  /// How far each hand reaches from the centre. The minute hand matches the
  /// ring's own radius, so its tip lands exactly under the selected minute's
  /// button; the hour hand is shorter, the way an analog clock draws it.
  final double hourLength;
  final double minuteLength;

  /// Clockwise from twelve o'clock, or null while that half has no answer
  /// yet — that hand simply is not drawn then.
  final double? hourAngle;
  final double? minuteAngle;

  /// Which ring is currently being edited, so its hand can be drawn in full
  /// colour while the other stays dim.
  final _Ring activeRing;

  final Color activeColor;
  final Color inactiveColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // A faint tick dot behind each of the twelve positions, so every number
    // reads as anchored to the dial even when it is not the one selected.
    final tickPaint = Paint()..color = inactiveColor.withValues(alpha: 0.5);
    for (var i = 0; i < 12; i++) {
      final tickAngle = i * math.pi / 6;
      final pos =
          center +
          Offset(
            math.sin(tickAngle) * minuteLength,
            -math.cos(tickAngle) * minuteLength,
          );
      canvas.drawCircle(pos, 2, tickPaint);
    }

    void drawHand(double? angle, double length, bool active) {
      if (angle == null) return;
      final tip =
          center + Offset(math.sin(angle) * length, -math.cos(angle) * length);
      canvas.drawLine(
        center,
        tip,
        Paint()
          ..color = active ? activeColor : inactiveColor
          ..strokeWidth = active ? 2.5 : 1.5
          ..strokeCap = StrokeCap.round,
      );
    }

    // The dim hand first, so the active one always draws on top of it where
    // the two would otherwise overlap near the centre.
    drawHand(
      activeRing == _Ring.hour ? minuteAngle : hourAngle,
      activeRing == _Ring.hour ? minuteLength : hourLength,
      false,
    );
    drawHand(
      activeRing == _Ring.hour ? hourAngle : minuteAngle,
      activeRing == _Ring.hour ? hourLength : minuteLength,
      true,
    );

    canvas.drawCircle(center, 4, Paint()..color = activeColor);
  }

  @override
  bool shouldRepaint(covariant _DialHandPainter oldDelegate) =>
      oldDelegate.hourLength != hourLength ||
      oldDelegate.minuteLength != minuteLength ||
      oldDelegate.hourAngle != hourAngle ||
      oldDelegate.minuteAngle != minuteAngle ||
      oldDelegate.activeRing != activeRing ||
      oldDelegate.activeColor != activeColor ||
      oldDelegate.inactiveColor != inactiveColor;
}
