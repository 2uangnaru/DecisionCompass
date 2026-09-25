import 'dart:async';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../category_presentation.dart';
import '../data/history_entry.dart';
import '../data/daily_energy_insight_deck.dart';
import '../data/models/models.dart' as engine;
import '../models.dart';
import '../reading_dependencies.dart';
import '../reading_mapping.dart';
import '../text_formatting.dart';
import '../theme.dart';
import '../widgets/celestial_ui.dart';
import '../widgets/daily_energy_info.dart';
import '../widgets/responsible_use_sheet.dart';
import 'history_page.dart';

/// Renders a real engine reading. Nothing here invents a direction: every
/// status the contract defines gets its own explicit presentation.
///
/// Every reading reaching this page is saved to history exactly once, per
/// the UX spec's "auto-saved" behavior — there is no separate save action to
/// forget to wire up.
class ResultPage extends StatefulWidget {
  const ResultPage({
    super.key,
    required this.reading,
    required this.dependencies,
    this.autoSave = true,
  });

  final engine.ReadingResponse reading;
  final ReadingDependencies dependencies;

  /// False when reopening an immutable snapshot from History.
  final bool autoSave;

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> with WidgetsBindingObserver {
  engine.ReadingResponse get reading => widget.reading;

  /// The reader's current local day, watched rather than read once at build:
  /// a Result left open past midnight stops being "today", and its unread
  /// mark has to go with it.
  late String _today;
  Timer? _dayChangeTimer;
  bool _saving = false;
  bool _saved = false;
  bool _saveFailed = false;

  DecisionMode get _mode => fromEngineMode(reading.mode);
  TimePeriod get _period => fromEnginePeriod(reading.period);

  /// The mode's second side is the cautionary one for every mode, not just
  /// NO and LET GO.
  bool get _isCaution => reading.winner == _mode.second;

  /// Label/percentage pairs straight from the response, winner first.
  List<({String label, String percent})> get _splits {
    final values = reading.percentages?.values;
    if (values == null) return const [];
    // One decimal, formatted once here: the two sides are integer tenths in
    // the DTO, so they always read as adding to 100.0.
    final entries = values.entries
        .map(
          (entry) =>
              (label: entry.key, percent: entry.value.toStringAsFixed(1)),
        )
        .toList();
    final leading = reading.winner ?? _mode.first;
    return [
      ...entries.where((entry) => entry.label == leading),
      ...entries.where((entry) => entry.label != leading),
    ];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _today = dailyEnergyDayKey(widget.dependencies.nowLocal());
    _scheduleDayChange();
    if (widget.autoSave) {
      _saving = true;
      unawaited(_saveToHistory());
    } else {
      _saved = true;
    }
  }

  @override
  void dispose() {
    _dayChangeTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshIfNewDay();
  }

  void _refreshIfNewDay() {
    final day = dailyEnergyDayKey(widget.dependencies.nowLocal());
    if (day != _today) setState(() => _today = day);
    _scheduleDayChange();
  }

  void _scheduleDayChange() {
    _dayChangeTimer?.cancel();
    final local = widget.dependencies.nowLocal();
    final next = DateTime(local.year, local.month, local.day + 1);
    final remaining = next.difference(local);
    _dayChangeTimer = Timer(
      remaining > Duration.zero ? remaining : const Duration(seconds: 1),
      () {
        if (mounted) _refreshIfNewDay();
      },
    );
  }

  /// A reading's own `readingKey` already varies by profile, mode, period
  /// and category (see `eb88f48`); some statuses (e.g. `period_elapsed`)
  /// omit it, so those fall back to a key built from the same fields plus
  /// the reveal instant.
  String get _historyId =>
      reading.readingKey ??
      '${reading.context.instantUtc}_${reading.mode.toJson()}_'
          '${reading.period.toJson()}_${reading.category.toJson()}';

  Future<void> _saveToHistory() async {
    if (!_saving)
      setState(() {
        _saving = true;
        _saveFailed = false;
      });
    try {
      await widget.dependencies.historyRepository.save(
        HistoryEntry(
          id: _historyId,
          reading: reading,
          savedAtUtc: DateTime.parse(reading.context.instantUtc),
        ),
      );
      if (mounted)
        setState(() {
          _saving = false;
          _saved = true;
          _saveFailed = false;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _saving = false;
          _saved = false;
          _saveFailed = true;
        });
    }
  }

  Future<void> _shareReading() async {
    try {
      await SharePlus.instance.share(
        ShareParams(text: shareTextForReading(reading)),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sharing is unavailable right now.')),
        );
      }
    }
  }

  void _openHistory() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HistoryPage(dependencies: widget.dependencies),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CelestialScaffold(
      topColor: _isCaution ? const Color(0xFF1A1018) : const Color(0xFF071729),
      bottomColor: _isCaution
          ? const Color(0xFF552D36)
          : const Color(0xFF103B68),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 30),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
                Expanded(
                  child: Text(
                    _mode.label,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: CompassColors.gold,
                      letterSpacing: 1.7,
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('result_share'),
                  tooltip: 'Share this reading',
                  onPressed:
                      reading.status == engine.ReadingStatus.ready ||
                          reading.status == engine.ReadingStatus.balanced
                      ? _shareReading
                      : null,
                  icon: const Icon(Icons.ios_share_rounded),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Sourced from the response, so a server that evaluated a
            // different legal category is shown truthfully.
            Semantics(
              label: 'Reading area: ${categoryLabel(reading.category)}',
              child: Container(
                key: const Key('result_category_badge'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(
                  categoryLabel(reading.category),
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: Colors.white, letterSpacing: 0.9),
                ),
              ),
            ),
            const SizedBox(height: 18),
            switch (reading.status) {
              engine.ReadingStatus.ready => _Direction(
                reading: reading,
                splits: _splits,
              ),
              engine.ReadingStatus.balanced => _Balanced(splits: _splits),
              engine.ReadingStatus.insufficientData => const _Explanation(
                key: Key('result_insufficient_data'),
                headline: 'NOT ENOUGH TO READ',
                body:
                    'Your profile does not yet contain enough detail for a '
                    'direction on this one. Adding your birth time and '
                    'country of birth gives the cycles more to work with.',
              ),
              engine.ReadingStatus.periodElapsed => _Explanation(
                key: const Key('result_period_elapsed'),
                headline: 'THAT PERIOD HAS PASSED',
                body:
                    '${_period.label} is already over where you are, so there '
                    'is no window left to read. Pick a later period, or read '
                    'your current moment instead — today’s reading is not '
                    'rolled into tomorrow.',
              ),
            },
            const SizedBox(height: 30),
            if (_period == TimePeriod.now)
              const GlassCard(
                child: Row(
                  children: [
                    Icon(Icons.schedule_rounded, color: CompassColors.gold),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text('This reading reflects your current moment.'),
                    ),
                  ],
                ),
              )
            else if (reading.luckyWindows.isNotEmpty)
              _LuckyWindows(reading: reading, period: _period),
            if (reading.dailyBrief != null) ...[
              const SizedBox(height: 14),
              _DailyBrief(
                brief: reading.dailyBrief!,
                // The reading's own local date, not the device's: a Result
                // left open past midnight keeps the insight it was read
                // for, and a past one never announces "new today".
                day: reading.context.localDate,
                isCurrentDay: reading.context.localDate == _today,
                insights: widget.dependencies.dailyEnergyInsights,
              ),
            ],
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.explore_rounded),
              label: const Text('Try Another Direction'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              key: const Key('result_history_action'),
              onPressed: !widget.autoSave
                  ? () => Navigator.of(context).pop()
                  : _saveFailed
                  ? _saveToHistory
                  : _saved
                  ? _openHistory
                  : null,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                side: const BorderSide(color: Colors.white30),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: Icon(
                _saveFailed
                    ? Icons.refresh_rounded
                    : Icons.bookmark_added_rounded,
              ),
              label: Text(
                !widget.autoSave
                    ? 'Back to History'
                    : _saveFailed
                    ? 'Couldn’t save · Retry'
                    : _saving
                    ? 'Saving to History…'
                    : 'View in History',
              ),
            ),
            const SizedBox(height: 18),
            InkWell(
              key: const Key('result_responsible_use_link'),
              onTap: () => showResponsibleUseSheet(context),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: Text.rich(
                  TextSpan(
                    text: 'For everyday reflection only. Important decisions need real information and qualified help.\n',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: Colors.white60, height: 1.45),
                    children: const [
                      TextSpan(
                        text: 'Responsible Use & Safety Policy',
                        style: TextStyle(
                          color: CompassColors.gold,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Share only the result the user chose to disclose, never birth details,
/// location, input snapshots or diagnostics.
String shareTextForReading(engine.ReadingResponse reading) {
  final mode = fromEngineMode(reading.mode);
  final winner = reading.winner;
  final percent = winner == null ? null : reading.percentages?[winner];
  final direction = winner == null
      ? 'Balanced'
      : percent == null
      ? winner
      : '$winner · ${percent.toStringAsFixed(1)}%';
  return 'AstraCue · ${categoryLabel(reading.category)} · ${mode.label}\n'
      '$direction\n'
      'A symbolic perspective for everyday reflection, not a prediction or probability.';
}

class _Direction extends StatelessWidget {
  const _Direction({required this.reading, required this.splits});

  final engine.ReadingResponse reading;
  final List<({String label, String percent})> splits;

  @override
  Widget build(BuildContext context) {
    final winner = splits.isEmpty ? null : splits.first;
    final counterpart = splits.length < 2 ? null : splits[1];
    final winnerColor = reading.winner == fromEngineMode(reading.mode).second
        ? const Color(0xFFD88990)
        : CompassColors.blueLight;
    return Column(
      key: const Key('result_ready'),
      children: [
        Text(
          'YOUR DIRECTION',
          key: const Key('result_direction_heading'),
          style: Theme.of(context).textTheme.labelLarge
              ?.copyWith(color: Colors.white70, letterSpacing: 2.4),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              reading.winner ?? winner?.label ?? '',
              key: const Key('result_winner_label'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: winnerColor,
                fontSize: 114,
                height: 1,
                fontWeight: FontWeight.w900,
                letterSpacing: -2,
                shadows: [
                  Shadow(
                    color: winnerColor.withValues(alpha: 0.28),
                    blurRadius: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (winner != null) ...[
          const SizedBox(height: 8),
          Text(
            '${winner.percent}%',
            style: Theme.of(context).textTheme.headlineLarge
                ?.copyWith(color: winnerColor, fontSize: 38),
          ),
        ],
        if (counterpart != null) ...[
          const SizedBox(height: 14),
          Text(
            '${counterpart.label}  ${counterpart.percent}%',
            style: Theme.of(context).textTheme.headlineMedium
                ?.copyWith(color: Colors.white70),
          ),
        ],
        const SizedBox(height: 18),
        Text(
          'Based on your personal cycles and this moment.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 6),
        Text(
          'Percentages show symbolic alignment, not a real-world probability.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: Colors.white60),
        ),
      ],
    );
  }
}

class _Balanced extends StatelessWidget {
  const _Balanced({required this.splits});

  final List<({String label, String percent})> splits;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('result_balanced'),
      children: [
        Text(
          'EVENLY BALANCED',
          style: Theme.of(context).textTheme.labelLarge
              ?.copyWith(color: Colors.white70, letterSpacing: 2.4),
        ),
        const SizedBox(height: 20),
        Text(
          'BALANCED',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displayLarge,
        ),
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 18,
          children: splits
              .map(
                (split) => Text(
                  '${split.label}  ${split.percent}%',
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(color: Colors.white70),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 18),
        Text(
          'Neither side leads right now. This is a reading of balance, not a '
          'hidden answer.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: Colors.white70),
        ),
      ],
    );
  }
}

class _Explanation extends StatelessWidget {
  const _Explanation({super.key, required this.headline, required this.body});

  final String headline;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          headline,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelLarge
              ?.copyWith(color: Colors.white70, letterSpacing: 2.4),
        ),
        const SizedBox(height: 18),
        const Icon(Icons.blur_on_rounded, size: 58, color: CompassColors.gold),
        const SizedBox(height: 18),
        Text(
          body,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: Colors.white70, height: 1.5),
        ),
      ],
    );
  }
}

class _DailyBrief extends StatelessWidget {
  const _DailyBrief({
    required this.brief,
    required this.day,
    required this.isCurrentDay,
    required this.insights,
  });

  final engine.DailyBrief brief;
  final String day;
  final bool isCurrentDay;
  final DailyEnergyInsightController insights;

  @override
  Widget build(BuildContext context) {
    final colors = brief.colors;
    final colourDescription = colors == null
        ? 'Colour to keep near you: '
              '${titleCaseWords(brief.legacyColorInspiration!)}'
        : 'Colours to keep near you: ${colors.lead.name} '
              'and ${colors.supporting.name}';
    return GlassCard(
      key: const Key('result_daily_brief'),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.wb_twilight_rounded, color: CompassColors.gold),
              const SizedBox(width: 12),
              Expanded(child: Text(colourDescription)),
              const SizedBox(width: 10),
              Text(
                '${brief.luckyNumber}',
                style: const TextStyle(
                  color: CompassColors.blueLight,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          if (brief.energy != null) ...[
            const Divider(height: 28, color: CompassColors.line),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Flexible so the ⓘ can never push the row past the card, at
                // a large text scale or in a language with a longer word for
                // this than English has.
                const Expanded(child: Text('Daily energy')),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      brief.energy!.displayLabel,
                      key: const Key('result_daily_energy_label'),
                      style: const TextStyle(
                        color: CompassColors.teal,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(width: 2),
                    DailyEnergyInfoButton(
                      level: brief.energy!.level,
                      controller: insights,
                      day: day,
                      isCurrentDay: isCurrentDay,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LuckyWindows extends StatelessWidget {
  const _LuckyWindows({required this.reading, required this.period});

  final engine.ReadingResponse reading;
  final TimePeriod period;

  /// Reads the wall clock the engine already resolved for the user's zone.
  /// The offset is intentionally ignored rather than re-applied through the
  /// device timezone, which would shift the window.
  static String _clock(String localIso) {
    final match = RegExp(r'T(\d{2}):(\d{2})').firstMatch(localIso);
    if (match == null) return '';
    final hour24 = int.parse(match.group(1)!);
    final minute = match.group(2)!;
    final suffix = hour24 >= 12 && hour24 < 24 ? 'PM' : 'AM';
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    return '$hour12:$minute $suffix';
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      key: const Key('result_lucky_windows'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Luckiest Times This ${period.label}',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          ...reading.luckyWindows
              .take(2)
              .map(
                (window) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          size: 18,
                          color: CompassColors.gold,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${_clock(window.startLocal)} – ${_clock(window.endLocal)}',
                          ),
                        ),
                        Text(
                          '${window.score.round()}%',
                          style: const TextStyle(
                            color: CompassColors.blueLight,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          Text(
            'Each percentage is a symbolic timing alignment score, not a '
            'probability and not a chance of success. Windows are scored '
            'independently, so they do not add up to 100%.',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: CompassColors.muted),
          ),
        ],
      ),
    );
  }
}
