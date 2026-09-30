import 'package:flutter/material.dart';

import '../data/history_entry.dart';
import '../data/models/models.dart' as engine;
import '../l10n/app_localizations.dart';
import '../localized_presentation.dart';
import '../reading_dependencies.dart';
import '../reading_mapping.dart';
import '../result_palette.dart';
import '../theme.dart';
import '../widgets/celestial_ui.dart';
import 'result_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key, required this.dependencies});

  final ReadingDependencies dependencies;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  // Loaded once per page visit; a fresh push re-reads storage, so a reading
  // saved just before opening History always shows up.
  late Future<List<HistoryEntry>> _entries;

  @override
  void initState() {
    super.initState();
    _entries = widget.dependencies.historyRepository.list();
  }

  void _retry() => setState(() {
    _entries = widget.dependencies.historyRepository.list();
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CelestialScaffold(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: l10n.backAction,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.yourReadings,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<List<HistoryEntry>>(
                future: _entries,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(
                      key: Key('history_loading'),
                      child: CircularProgressIndicator(
                        color: CompassColors.gold,
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      key: const Key('history_error'),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.historyCouldNotOpen,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: _retry,
                            child: Text(l10n.tryAgain),
                          ),
                        ],
                      ),
                    );
                  }
                  final entries = snapshot.data ?? const [];
                  if (entries.isEmpty) {
                    return const _EmptyHistory();
                  }
                  return _HistoryList(
                    entries: entries,
                    today: _isoDate(widget.dependencies.nowLocal()),
                    dependencies: widget.dependencies,
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                l10n.historySnapshot,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: CompassColors.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _isoDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// Local wall-clock hour/minute, derived the same way the engine resolved
/// them, so it matches what the user actually saw at Reveal regardless of
/// the reading device's current timezone. Printed in the reader's own clock
/// convention.
String _timeOfDay(String localeName, engine.ReadingResponse reading) {
  final localMs =
      reading.context.instantMs + reading.context.offsetSeconds * 1000;
  final local = DateTime.fromMillisecondsSinceEpoch(localMs, isUtc: true);
  return formatClock(localeName, local.hour, local.minute);
}

String _date(String localeName, engine.ReadingResponse reading) {
  final localMs =
      reading.context.instantMs + reading.context.offsetSeconds * 1000;
  final local = DateTime.fromMillisecondsSinceEpoch(localMs, isUtc: true);
  return formatDate(localeName, local);
}

/// The result column's text for every status the contract defines, not just
/// `ready` — a balanced or elapsed reading is still a real saved entry.
///
/// Rebuilt from the mode and the side of the pair the engine named, never
/// from the English word it stored, so an old snapshot reads correctly after
/// a language switch.
String _resultLabel(
  AppLocalizations l10n,
  String localeName,
  engine.ReadingResponse reading,
) {
  switch (reading.status) {
    case engine.ReadingStatus.ready:
      final winner = reading.winner;
      if (winner == null) return '';
      final mode = fromEngineMode(reading.mode);
      final label = localizedChoice(l10n, mode, winner);
      final percent = reading.percentages?[winner];
      return percent == null
          ? label
          : '$label ${formatScore(localeName, percent)}%';
    case engine.ReadingStatus.balanced:
      return l10n.balancedResult;
    case engine.ReadingStatus.insufficientData:
      return l10n.historyNotEnoughData;
    case engine.ReadingStatus.periodElapsed:
      return l10n.historyPeriodPassed;
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      key: const Key('history_empty'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.history_rounded,
              size: 42,
              color: CompassColors.muted,
            ),
            const SizedBox(height: 14),
            Text(
              l10n.noReadings,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: CompassColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Entries grouped by the local calendar day they were resolved for, newest
/// group first, matching the UX spec's `TODAY` / date grouping.
class _HistoryList extends StatelessWidget {
  const _HistoryList({
    required this.entries,
    required this.today,
    required this.dependencies,
  });

  final List<HistoryEntry> entries;
  final String today;
  final ReadingDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeName = intlLocaleOf(context);
    final children = <Widget>[];
    String? openGroup;
    for (final entry in entries) {
      final group = entry.reading.context.localDate;
      if (group != openGroup) {
        if (openGroup != null) children.add(const SizedBox(height: 18));
        openGroup = group;
        children.add(
          Text(
            // The engine's `localDate` is an ISO wire value; the heading is
            // the same day written the way this language writes a date.
            group == today
                ? l10n.historyToday
                : formatDate(localeName, DateTime.parse(group)),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: CompassColors.gold,
              letterSpacing: trackingFor(context, 1.7),
            ),
          ),
        );
        children.add(const SizedBox(height: 12));
      } else {
        children.add(const SizedBox(height: 10));
      }
      children.add(_HistoryRow(entry: entry, dependencies: dependencies));
    }
    return ListView(key: const Key('history_list'), children: children);
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry, required this.dependencies});

  final HistoryEntry entry;
  final ReadingDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeName = intlLocaleOf(context);
    final reading = entry.reading;
    final mode = fromEngineMode(reading.mode);
    final palette = resultPaletteFor(
      mode: mode,
      status: reading.status,
      winner: reading.winner,
    );
    return GlassCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ResultPage(
            reading: reading,
            dependencies: dependencies,
            autoSave: false,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  modeLabel(l10n, mode),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  '${categoryLabel(l10n, reading.category)}  •  '
                  '${_timeOfDay(localeName, reading)}  •  '
                  '${_date(localeName, reading)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _resultLabel(l10n, localeName, reading),
            textAlign: TextAlign.right,
            style: TextStyle(
              color: palette.accent,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded, color: CompassColors.muted),
        ],
      ),
    );
  }
}
