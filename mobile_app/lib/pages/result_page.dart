import 'dart:async';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../data/history_entry.dart';
import '../data/daily_energy_insight_deck.dart';
import '../data/models/models.dart' as engine;
import '../l10n/app_localizations.dart';
import '../localized_presentation.dart';
import '../models.dart';
import '../reading_dependencies.dart';
import '../reading_mapping.dart';
import '../result_palette.dart';
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

  /// Label/percentage pairs from the response, winner first.
  ///
  /// The label is translated from the side of the pair the engine named, not
  /// from the English word it sent, so a reading reopened from History after a
  /// language switch still shows the same side. The number is unchanged: only
  /// its decimal separator follows the language.
  List<({String label, String percent})> _splits(AppLocalizations l10n) {
    final values = reading.percentages?.values;
    if (values == null) return const [];
    final localeName = intlLocaleOf(context);
    // One decimal, formatted once here: the two sides are integer tenths in
    // the DTO, so they always read as adding to 100.0.
    final entries = values.entries
        .map(
          (entry) => (
            label: localizedChoice(l10n, _mode, entry.key),
            percent: formatScore(localeName, entry.value),
            isWinner: entry.key == (reading.winner ?? _englishFirst),
          ),
        )
        .toList();
    return [
      for (final entry in entries)
        if (entry.isWinner) (label: entry.label, percent: entry.percent),
      for (final entry in entries)
        if (!entry.isWinner) (label: entry.label, percent: entry.percent),
    ];
  }

  /// The engine's own word for the first side of this mode's pair. Never
  /// shown — only matched against, when a response omits `winner`.
  String get _englishFirst => englishChoiceLabels[_mode]!.first;

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
    final l10n = AppLocalizations.of(context);
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: shareTextForReading(l10n, intlLocaleOf(context), reading),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.shareUnavailable)));
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
    final l10n = AppLocalizations.of(context);
    final splits = _splits(l10n);
    final category = categoryLabel(l10n, reading.category);
    final palette = resultPaletteFor(
      mode: _mode,
      status: reading.status,
      winner: reading.winner,
    );
    return CelestialScaffold(
      topColor: palette.top,
      bottomColor: palette.bottom,
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
                    modeLabel(l10n, _mode),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: CompassColors.gold,
                      letterSpacing: trackingFor(context, 1.7),
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('result_share'),
                  tooltip: l10n.shareTooltip,
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
              label: l10n.readingAreaSemantics(category),
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
                  category,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    letterSpacing: trackingFor(context, 0.9),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            switch (reading.status) {
              engine.ReadingStatus.ready => _Direction(
                winnerLabel: splits.isEmpty
                    ? ''
                    : localizedChoice(
                        l10n,
                        _mode,
                        reading.winner ?? _englishFirst,
                      ),
                splits: splits,
                accent: palette.accent,
              ),
              engine.ReadingStatus.balanced => _Balanced(splits: splits),
              engine.ReadingStatus.insufficientData => _Explanation(
                key: const Key('result_insufficient_data'),
                headline: l10n.insufficientHeading,
                body: l10n.insufficientBody,
              ),
              // The heading and body are complete sentences that do not name
              // the period: dropping a translated chip label into a sentence
              // frame is ungrammatical in several of these languages, and the
              // period is already on the badge above.
              engine.ReadingStatus.periodElapsed => _Explanation(
                key: const Key('result_period_elapsed'),
                headline: l10n.periodElapsedHeading,
                body: l10n.periodElapsedBody,
              ),
            },
            const SizedBox(height: 30),
            if (_period == TimePeriod.now)
              GlassCard(
                child: Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      color: CompassColors.gold,
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(l10n.currentMoment)),
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
              label: Text(l10n.tryAnotherDirection),
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
                    ? l10n.backToHistory
                    : _saveFailed
                    ? l10n.saveFailedRetry
                    : _saving
                    ? l10n.savingToHistory
                    : l10n.viewHistory,
                textAlign: TextAlign.center,
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
                    text: '${l10n.everydayReflection}\n',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: Colors.white60, height: 1.45),
                    children: [
                      TextSpan(
                        text: l10n.responsibleUseLink,
                        style: const TextStyle(
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
///
/// Written in the language the reader is using, from the same keys the screen
/// renders — the engine's English winner token is translated, never pasted.
String shareTextForReading(
  AppLocalizations l10n,
  String localeName,
  engine.ReadingResponse reading,
) {
  final mode = fromEngineMode(reading.mode);
  final winner = reading.winner;
  final percent = winner == null ? null : reading.percentages?[winner];
  final direction = winner == null
      ? l10n.balancedResult
      : percent == null
      ? localizedChoice(l10n, mode, winner)
      : '${localizedChoice(l10n, mode, winner)} · '
            '${formatScore(localeName, percent)}%';
  return '${l10n.appName} · ${categoryLabel(l10n, reading.category)} · '
      '${modeLabel(l10n, mode)}\n'
      '$direction\n'
      '${l10n.shareDisclaimer}';
}

class _Direction extends StatelessWidget {
  const _Direction({
    required this.winnerLabel,
    required this.splits,
    required this.accent,
  });

  /// Already translated by the mode it belongs to.
  final String winnerLabel;
  final List<({String label, String percent})> splits;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final winner = splits.isEmpty ? null : splits.first;
    final counterpart = splits.length < 2 ? null : splits[1];
    return Column(
      key: const Key('result_ready'),
      children: [
        Text(
          l10n.yourDirection,
          key: const Key('result_direction_heading'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Colors.white70,
            letterSpacing: trackingFor(context, 2.4),
          ),
        ),
        const SizedBox(height: 14),
        _WinnerHeadline(
          label: winnerLabel,
          percent: winner?.percent,
          accent: accent,
        ),
        if (counterpart != null) ...[
          const SizedBox(height: 14),
          Text(
            '${counterpart.label}  ${counterpart.percent}%',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium
                ?.copyWith(color: Colors.white70),
          ),
        ],
        const SizedBox(height: 18),
        Text(
          l10n.resultBasis,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 6),
        // Kept right under the numbers, never behind an info icon: a symbolic
        // alignment score is not a probability, in any language.
        Text(
          l10n.percentageCaveat,
          key: const Key('result_percentage_caveat'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: Colors.white60),
        ),
      ],
    );
  }
}

/// The winning choice, and its percentage beneath it.
///
/// They are sized together rather than independently. `HACIA DELANTE` and
/// `VỀ PHÍA TRƯỚC` are three times the length of `YES`, and a shrink-to-fit
/// box on its own would quietly reduce the choice until a fixed-size
/// percentage was the biggest thing on the screen — which inverts what the
/// result is saying. Here the choice takes the largest size that fits in at
/// most two lines, and the percentage is always a third of whatever that
/// turned out to be.
class _WinnerHeadline extends StatelessWidget {
  const _WinnerHeadline({
    required this.label,
    required this.percent,
    required this.accent,
  });

  final String label;
  final String? percent;
  final Color accent;

  /// The English treatment, unchanged: `YES` still renders at 114.
  static const _maxSize = 114.0;

  /// Below this the choice stops being the headline and starts being a
  /// caption, so it wraps to a second line instead of shrinking further.
  static const _minSize = 34.0;

  /// What the percentage is worth relative to the choice. 114 × this is 38,
  /// which is the size the English result has always used.
  static const _percentRatio = 1 / 3;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        var size = _maxSize;
        while (size > _minSize &&
            !_fits(label, size, width, scaler, direction)) {
          size -= 2;
        }
        final percentSize = size * _percentRatio;
        return Column(
          children: [
            SizedBox(
              key: const Key('result_winner_box'),
              width: double.infinity,
              child: Text(
                label,
                key: const Key('result_winner_label'),
                textAlign: TextAlign.center,
                maxLines: 2,
                style: _style(size),
              ),
            ),
            if (percent != null) ...[
              const SizedBox(height: 8),
              Text(
                '$percent%',
                key: const Key('result_winner_percent'),
                style: Theme.of(context).textTheme.headlineLarge
                    ?.copyWith(color: accent, fontSize: percentSize),
              ),
            ],
          ],
        );
      },
    );
  }

  TextStyle _style(double size) => TextStyle(
    color: accent,
    fontSize: size,
    height: 1,
    fontWeight: FontWeight.w900,
    // Negative tracking tightens Latin capitals; it would collide glyphs in
    // the scripts that do not use it.
    letterSpacing: size >= 60 ? -2 : 0,
    shadows: [Shadow(color: accent.withValues(alpha: 0.28), blurRadius: 24)],
  );

  /// Whether [label] lays out inside [width] in no more than two lines.
  bool _fits(
    String label,
    double size,
    double width,
    TextScaler scaler,
    TextDirection direction,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: label, style: _style(size)),
      textAlign: TextAlign.center,
      textDirection: direction,
      textScaler: scaler,
      maxLines: 2,
    )..layout(maxWidth: width);
    final fits = !painter.didExceedMaxLines && painter.width <= width;
    painter.dispose();
    return fits;
  }
}

class _Balanced extends StatelessWidget {
  const _Balanced({required this.splits});

  final List<({String label, String percent})> splits;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      key: const Key('result_balanced'),
      children: [
        Text(
          l10n.balancedHeading,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Colors.white70,
            letterSpacing: trackingFor(context, 2.4),
          ),
        ),
        const SizedBox(height: 20),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            l10n.balancedResult,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displayLarge,
          ),
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
          l10n.balancedExplanation,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.percentageCaveat,
          key: const Key('result_percentage_caveat'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: Colors.white60),
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
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Colors.white70,
            letterSpacing: trackingFor(context, 2.4),
          ),
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
    final l10n = AppLocalizations.of(context);
    final colors = brief.colors;
    final colourDescription = colors == null
        // An older saved snapshot kept a single free-text colour. There is no
        // key to translate it by, so it is shown as it was saved.
        ? l10n.colorToKeepNear(titleCaseWords(brief.legacyColorInspiration!))
        : l10n.colorsToKeepNear(
            dailyColorName(l10n, colors.lead),
            dailyColorName(l10n, colors.supporting),
          );
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
                formatWholeNumber(intlLocaleOf(context), brief.luckyNumber),
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
                Expanded(child: Text(l10n.dailyEnergy)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      energyLevelLabel(l10n, brief.energy!.level) ?? '—',
                      key: const Key('result_daily_energy_label'),
                      style: TextStyle(
                        color: CompassColors.teal,
                        fontWeight: FontWeight.w700,
                        letterSpacing: trackingFor(context, 1.2),
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

  /// Reads the wall clock the engine already resolved for the user's zone,
  /// then prints it in the reader's own clock convention. The offset is
  /// intentionally ignored rather than re-applied through the device
  /// timezone, which would shift the window.
  static String _clock(String localeName, String localIso) {
    final match = RegExp(r'T(\d{2}):(\d{2})').firstMatch(localIso);
    if (match == null) return '';
    return formatClock(
      localeName,
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeName = intlLocaleOf(context);
    // One complete heading per period. A translated chip label dropped into
    // an English frame ("in Morning") is ungrammatical in several of these
    // languages, so there is no interpolation here at all.
    final heading = luckyTimesHeading(l10n, period);
    return GlassCard(
      key: const Key('result_lucky_windows'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (heading != null)
            Text(heading, style: Theme.of(context).textTheme.headlineMedium),
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
                            '${_clock(localeName, window.startLocal)} – '
                            '${_clock(localeName, window.endLocal)}',
                          ),
                        ),
                        Text(
                          '${formatWholeNumber(localeName, window.score.round())}%',
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
          // Immediately under the windows, on the same view as the numbers.
          Text(
            l10n.luckyTimesCaveat,
            key: const Key('result_lucky_times_caveat'),
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: CompassColors.muted),
          ),
        ],
      ),
    );
  }
}
