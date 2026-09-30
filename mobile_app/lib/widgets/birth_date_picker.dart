import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';

/// A birth date is usually known already, so its three parts can be entered
/// directly. The calendar remains available for readers who prefer tapping.
Future<DateTime?> showBirthDatePicker({
  required BuildContext context,
  DateTime? initialDate,
}) => showDialog<DateTime>(
  context: context,
  builder: (context) => BirthDatePickerDialog(initialDate: initialDate),
);

class BirthDatePickerDialog extends StatefulWidget {
  const BirthDatePickerDialog({super.key, this.initialDate, this.lastDate});

  final DateTime? initialDate;

  /// Injectable so date-boundary behavior can be checked without the clock.
  final DateTime? lastDate;

  @override
  State<BirthDatePickerDialog> createState() => _BirthDatePickerDialogState();
}

class _BirthDatePickerDialogState extends State<BirthDatePickerDialog> {
  late final _day = TextEditingController(
    text: widget.initialDate?.day.toString().padLeft(2, '0') ?? '',
  );
  late final _month = TextEditingController(
    text: widget.initialDate?.month.toString().padLeft(2, '0') ?? '',
  );
  late final _year = TextEditingController(
    text: widget.initialDate?.year.toString() ?? '',
  );
  final _monthFocus = FocusNode();
  final _yearFocus = FocusNode();
  var _showError = false;

  DateTime get _lastDate =>
      DateUtils.dateOnly(widget.lastDate ?? DateTime.now());

  DateTime? get _candidate {
    final day = int.tryParse(_day.text);
    final month = int.tryParse(_month.text);
    final year = int.tryParse(_year.text);
    if (day == null || month == null || year == null) return null;
    if (year < 1900 || year > _lastDate.year || month < 1 || month > 12) {
      return null;
    }
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    if (date.isAfter(_lastDate)) return null;
    return date;
  }

  bool get _complete =>
      _day.text.isNotEmpty && _month.text.isNotEmpty && _year.text.length == 4;

  void _onChanged(String value, {FocusNode? next, int? length}) {
    setState(() => _showError = false);
    if (next != null && value.length == length) next.requestFocus();
  }

  void _confirm() {
    final date = _candidate;
    if (date == null) {
      setState(() => _showError = true);
      return;
    }
    Navigator.of(context).pop(date);
  }

  Future<void> _openCalendar() async {
    FocusScope.of(context).unfocus();
    final current = _candidate ?? widget.initialDate;
    final initial =
        current != null &&
            !current.isBefore(DateTime(1900)) &&
            !current.isAfter(_lastDate)
        ? current
        : DateTime(2000, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: _lastDate,
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _day.text = picked.day.toString().padLeft(2, '0');
      _month.text = picked.month.toString().padLeft(2, '0');
      _year.text = picked.year.toString();
      _showError = false;
    });
  }

  @override
  void dispose() {
    _day.dispose();
    _month.dispose();
    _year.dispose();
    _monthFocus.dispose();
    _yearFocus.dispose();
    super.dispose();
  }

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
    final candidate = _candidate;
    final invalid = candidate == null && (_showError || _complete);

    return AlertDialog(
      key: const Key('birth_date_dialog'),
      scrollable: true,
      title: Text(l10n.dateOfBirth),
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            if (candidate != null || invalid) ...[
              const SizedBox(height: 12),
              Text(
                invalid
                    ? l10n.birthDateInvalid
                    : material.formatMediumDate(candidate!),
                key: const Key('birth_date_feedback'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: invalid ? Theme.of(context).colorScheme.error : null,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        IconButton(
          key: const Key('birth_date_calendar'),
          onPressed: _openCalendar,
          icon: const Icon(Icons.calendar_month_rounded),
          tooltip: material.calendarModeButtonLabel,
        ),
        TextButton(
          key: const Key('birth_date_cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(material.cancelButtonLabel),
        ),
        FilledButton(
          key: const Key('birth_date_confirm'),
          onPressed: _confirm,
          child: Text(material.okButtonLabel),
        ),
      ],
    );
  }
}
