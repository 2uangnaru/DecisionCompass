import 'dart:async';

import 'package:flutter/material.dart';

import '../app_locale.dart';
import '../data/history_entry.dart';
import '../data/models/models.dart' as engine;
import '../data/reading_quota_controller.dart';
import '../localized_presentation.dart';
import '../theme.dart';

/// Snapshot of the reader's daily Free reading turns (3/day, 3h cooldown)
/// paired with the +3 AstraCue Plus instant turns preview.
///
/// Computed from [ReadingQuotaController] and [nowLocal] so `HomePage`,
/// `RitualPage`, and `ResultPage` always render the exact same orb count and
/// cooldown countdown.
class ReadingEnergySnapshot {
  const ReadingEnergySnapshot({
    required this.usedFreeTurns,
    required this.remainingFreeTurns,
    required this.cooldownRemaining,
    required this.timeUntilMidnight,
    this.bonusTurns = 0,
  });

  static const int freeDailyMax = 3;
  static const int plusBonusMax = 3;
  static const int plusDailyMax = 6;
  static const Duration freeCooldown = Duration(hours: 3);

  /// Free turns already consumed on the current local calendar day (`0..3`).
  final int usedFreeTurns;

  /// Free turns still available on the current local calendar day (`0..3`).
  final int remainingFreeTurns;

  /// Remaining wait before the next Free turn is ready, when at least one turn
  /// was used today and at least one Free turn remains. `Duration.zero` when
  /// ready immediately or when all 3 Free turns are spent.
  final Duration cooldownRemaining;

  /// Time remaining until `00:00` local midnight when daily turns reset.
  final Duration timeUntilMidnight;

  /// Extra bonus turns earned via rewarded ads.
  final int bonusTurns;

  /// Whether the reader is currently in the 3-hour cooldown between Free turns.
  bool get isCoolingDown =>
      remainingFreeTurns > 0 && cooldownRemaining > Duration.zero;

  /// Whether all 3 daily Free turns have been used today.
  bool get isDailyFreeExhausted => remainingFreeTurns <= 0;

  /// The 1-indexed turn number the reader is about to use on `RitualPage`
  /// (`1`, `2`, or `3`), or `3` when all Free turns are spent.
  int get activeTurnNumber => (usedFreeTurns + 1).clamp(1, freeDailyMax);

  static const ReadingEnergySnapshot initial = ReadingEnergySnapshot(
    usedFreeTurns: 0,
    remainingFreeTurns: freeDailyMax,
    cooldownRemaining: Duration.zero,
    timeUntilMidnight: Duration(hours: 6),
  );

  /// Resolves the live energy snapshot directly from [ReadingQuotaController],
  /// matching the exact state shown by `RitualPage`'s orb and lock rules.
  static ReadingEnergySnapshot fromQuota({
    required ReadingQuotaController quota,
    required DateTime nowLocal,
    bool? isCooldownOverride,
    bool? isQuotaExhaustedOverride,
  }) {
    final maxFree = quota.maxDailyFreeReadings;
    final exhausted = isQuotaExhaustedOverride ??
        (quota.bonusReadings == 0 &&
            quota.dailyFreeReadingsUsed(nowLocal) >= maxFree);
    var used = exhausted
        ? maxFree
        : quota.dailyFreeReadingsUsed(nowLocal).clamp(0, maxFree);
    final inCooldown =
        isCooldownOverride ?? (!exhausted && quota.isCooldown(nowLocal));
    if (inCooldown && used == 0) {
      used = 1;
    }
    final remaining = (maxFree - used).clamp(0, maxFree);

    final nextMidnight = DateTime(
      nowLocal.year,
      nowLocal.month,
      nowLocal.day + 1,
    );
    final untilMidnight = nextMidnight.difference(nowLocal);

    Duration cooldown = Duration.zero;
    if (!exhausted && inCooldown) {
      cooldown = quota.remainingFreeEnergyCooldown(nowLocal);
      if (cooldown <= Duration.zero) {
        cooldown = quota.remainingCooldown(nowLocal);
      }
    }

    return ReadingEnergySnapshot(
      usedFreeTurns: used,
      remainingFreeTurns: remaining,
      cooldownRemaining: cooldown > Duration.zero ? cooldown : Duration.zero,
      timeUntilMidnight:
          untilMidnight > Duration.zero ? untilMidnight : Duration.zero,
      bonusTurns: quota.bonusReadings,
    );
  }

  static String _isoDate(DateTime local) =>
      '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';

  /// Resolves the current day's turn count and 3-hour cooldown from saved
  /// [entries] and optional just-revealed [currentReading].
  static ReadingEnergySnapshot resolve({
    required List<HistoryEntry> entries,
    required DateTime nowLocal,
    engine.ReadingResponse? currentReading,
  }) {
    final todayIso = _isoDate(nowLocal);
    final seenKeys = <String>{};
    final todayReadings = <engine.ReadingResponse>[];

    void addIfToday(engine.ReadingResponse reading, String fallbackId) {
      if (reading.context.localDate != todayIso) return;
      final key = reading.readingKey ?? fallbackId;
      if (seenKeys.add(key)) {
        todayReadings.add(reading);
      }
    }

    if (currentReading != null) {
      addIfToday(
        currentReading,
        '${currentReading.context.instantUtc}_'
        '${currentReading.mode.toJson()}_'
        '${currentReading.period.toJson()}_'
        '${currentReading.category.toJson()}',
      );
    }

    for (final entry in entries) {
      addIfToday(entry.reading, entry.id);
    }

    todayReadings.sort(
      (a, b) => b.context.instantMs.compareTo(a.context.instantMs),
    );

    final used = todayReadings.length.clamp(0, freeDailyMax);
    final remaining = (freeDailyMax - used).clamp(0, freeDailyMax);

    var cooldown = Duration.zero;
    if (used > 0 && remaining > 0) {
      final latest = todayReadings.first;
      final localMs =
          latest.context.instantMs + latest.context.offsetSeconds * 1000;
      final utcWall = DateTime.fromMillisecondsSinceEpoch(localMs, isUtc: true);
      final latestLocal = DateTime(
        utcWall.year,
        utcWall.month,
        utcWall.day,
        utcWall.hour,
        utcWall.minute,
        utcWall.second,
      );
      var elapsed = nowLocal.difference(latestLocal);
      if (elapsed.isNegative) {
        elapsed = Duration.zero;
      }
      if (elapsed < freeCooldown) {
        cooldown = freeCooldown - elapsed;
      }
    }

    final nextMidnight = DateTime(nowLocal.year, nowLocal.month, nowLocal.day + 1);
    final untilMidnight = nextMidnight.difference(nowLocal);

    return ReadingEnergySnapshot(
      usedFreeTurns: used,
      remainingFreeTurns: remaining,
      cooldownRemaining: cooldown,
      timeUntilMidnight:
          untilMidnight > Duration.zero ? untilMidnight : Duration.zero,
    );
  }

  /// Formats a [Duration] as `HH:MM:SS`.
  static String formatCountdown(Duration duration) {
    final totalSeconds = duration.inSeconds.clamp(0, 86399);
    final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}

/// Visual row of 3 cyan Free orbs + `+` + 3 golden Plus orbs.
class AstralEnergyOrbsRow extends StatelessWidget {
  const AstralEnergyOrbsRow({
    super.key,
    required this.remainingFreeTurns,
    this.orbSize = 9.5,
  });

  final int remainingFreeTurns;
  final double orbSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < ReadingEnergySnapshot.freeDailyMax; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          _FreeOrb(
            active: i < remainingFreeTurns,
            size: orbSize,
          ),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Text(
            '+',
            style: TextStyle(
              color: CompassColors.gold.withValues(alpha: 0.85),
              fontSize: orbSize + 2,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ),
        for (var i = 0; i < ReadingEnergySnapshot.plusBonusMax; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          _PlusGoldOrb(size: orbSize),
        ],
      ],
    );
  }
}

class _FreeOrb extends StatelessWidget {
  const _FreeOrb({required this.active, required this.size});

  final bool active;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active
            ? CompassColors.blueLight
            : CompassColors.deep.withValues(alpha: 0.7),
        border: Border.all(
          color: active
              ? Colors.white.withValues(alpha: 0.75)
              : CompassColors.line,
          width: 1,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: CompassColors.blueLight.withValues(alpha: 0.65),
                  blurRadius: 6,
                  spreadRadius: 0.5,
                ),
              ]
            : null,
      ),
    );
  }
}

class _PlusGoldOrb extends StatelessWidget {
  const _PlusGoldOrb({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF5E2AD),
            CompassColors.gold,
            Color(0xFFA97E2E),
          ],
        ),
        border: Border.all(
          color: const Color(0xFFFFF3D1).withValues(alpha: 0.8),
          width: 0.9,
        ),
        boxShadow: [
          BoxShadow(
            color: CompassColors.gold.withValues(alpha: 0.45),
            blurRadius: 6,
            spreadRadius: 0.3,
          ),
        ],
      ),
    );
  }
}

/// Spot 1 on `HomePage`: Luxury metallic gold `✦ PLUS` emblem button in the header.
class AstraCuePlusHeaderBadge extends StatelessWidget {
  const AstraCuePlusHeaderBadge({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'AstraCue Plus',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const Key('home_plus_button'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF3DFAA),
                  CompassColors.gold,
                  Color(0xFFB88E3B),
                ],
              ),
              border: Border.all(
                color: const Color(0xFFFFF3D1).withValues(alpha: 0.75),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: CompassColors.gold.withValues(alpha: 0.32),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '✦',
                  style: TextStyle(
                    color: CompassColors.deep,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                SizedBox(width: 4),
                Text(
                  'PLUS',
                  style: TextStyle(
                    color: CompassColors.deep,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Spot 2 on `HomePage` (Option B): Golden Energy Tray embedded flush at the
/// bottom of the `_dailySignals` card, separated by a golden hairline divider.
class HomeEmbeddedEnergyTray extends StatelessWidget {
  const HomeEmbeddedEnergyTray({
    super.key,
    required this.snapshot,
    required this.locale,
    required this.onTapPlus,
  });

  final ReadingEnergySnapshot snapshot;
  final AppLocale locale;
  final VoidCallback onTapPlus;

  @override
  Widget build(BuildContext context) {
    final copy = _PlusLocalizedCopy.of(locale);
    final statusText = copy.homeTrayStatus(snapshot);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('home_daily_energy_tray'),
        onTap: onTapPlus,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(21)),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(16, 11, 16, 12),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(21),
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                CompassColors.gold.withValues(alpha: 0.16),
                const Color(0xFF162238),
                CompassColors.violet.withValues(alpha: 0.12),
              ],
            ),
            border: Border(
              top: BorderSide(
                color: CompassColors.gold.withValues(alpha: 0.48),
                width: 1,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AstralEnergyOrbsRow(
                    remainingFreeTurns: snapshot.remainingFreeTurns,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      statusText,
                      key: const Key('home_energy_turns_status'),
                      style: const TextStyle(
                        color: CompassColors.text,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      copy.trayActionLink,
                      key: const Key('home_energy_plus_cta'),
                      style: TextStyle(
                        color: const Color(0xFFF2DC9F),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                        decorationColor: CompassColors.gold.withValues(
                          alpha: 0.7,
                        ),
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Synchronized Golden Energy & Plus card shown on `RitualPage` (below the
/// Reveal circle) and on `ResultPage` (above `Try Another Direction`).
class AnalysisEnergyPlusCard extends StatelessWidget {
  const AnalysisEnergyPlusCard({
    super.key,
    required this.snapshot,
    required this.locale,
    required this.onTapPlus,
    this.isPostReadingResult = false,
  });

  final ReadingEnergySnapshot snapshot;
  final AppLocale locale;
  final VoidCallback onTapPlus;

  /// True on `ResultPage` right after a reading completes; false on `RitualPage`
  /// before the Reveal tap.
  final bool isPostReadingResult;

  @override
  Widget build(BuildContext context) {
    final copy = _PlusLocalizedCopy.of(locale);
    final headline = isPostReadingResult
        ? copy.resultStatusHeadline(snapshot)
        : copy.ritualStatusHeadline(snapshot);
    final subtitle = isPostReadingResult
        ? copy.resultStatusSubtitle(snapshot)
        : copy.ritualStatusSubtitle(snapshot);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTapPlus,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(15, 12, 15, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                CompassColors.gold.withValues(alpha: 0.18),
                const Color(0xFF141F35),
                const Color(0xFF192540),
              ],
            ),
            border: Border.all(
              color: CompassColors.gold.withValues(alpha: 0.52),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: CompassColors.gold.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AstralEnergyOrbsRow(
                    remainingFreeTurns: snapshot.remainingFreeTurns,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      headline,
                      style: const TextStyle(
                        color: Color(0xFFF2DC9F),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(
                  color: CompassColors.secondary,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      copy.trayActionLink,
                      style: TextStyle(
                        color: CompassColors.gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                        decorationColor: CompassColors.gold.withValues(
                          alpha: 0.65,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFF3DFAA),
                          CompassColors.gold,
                        ],
                      ),
                    ),
                    child: const Text(
                      '✦ \$4.99',
                      style: TextStyle(
                        color: CompassColors.deep,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows the luxury AstraCue Plus ($4.99 one-time purchase) modal sheet.
Future<void> showAstraCuePlusSheet(
  BuildContext context, {
  required AppLocale locale,
  required ReadingEnergySnapshot snapshot,
  ReadingEnergySnapshot Function()? snapshotResolver,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => AstraCuePlusSheet(
      locale: locale,
      snapshot: snapshot,
      snapshotResolver: snapshotResolver,
    ),
  );
}

class AstraCuePlusSheet extends StatefulWidget {
  const AstraCuePlusSheet({
    super.key,
    required this.locale,
    required this.snapshot,
    this.snapshotResolver,
  });

  final AppLocale locale;
  final ReadingEnergySnapshot snapshot;
  final ReadingEnergySnapshot Function()? snapshotResolver;

  @override
  State<AstraCuePlusSheet> createState() => _AstraCuePlusSheetState();
}

class _AstraCuePlusSheetState extends State<AstraCuePlusSheet> {
  late ReadingEnergySnapshot _snapshot = widget.snapshot;
  Timer? _tickTimer;

  @override
  void initState() {
    super.initState();
    _scheduleTick();
  }

  void _scheduleTick() {
    _tickTimer?.cancel();
    if (!_snapshot.isCoolingDown && !_snapshot.isDailyFreeExhausted) return;
    _tickTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        if (widget.snapshotResolver != null) {
          _snapshot = widget.snapshotResolver!();
        } else {
          final nextCooldown =
              _snapshot.cooldownRemaining - const Duration(seconds: 1);
          final nextMidnight =
              _snapshot.timeUntilMidnight - const Duration(seconds: 1);
          _snapshot = ReadingEnergySnapshot(
            usedFreeTurns: _snapshot.usedFreeTurns,
            remainingFreeTurns: _snapshot.remainingFreeTurns,
            cooldownRemaining:
                nextCooldown > Duration.zero ? nextCooldown : Duration.zero,
            timeUntilMidnight:
                nextMidnight > Duration.zero ? nextMidnight : Duration.zero,
          );
        }
      });
      _scheduleTick();
    });
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    final copy = _PlusLocalizedCopy.of(widget.locale);
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.88;

    return Container(
      key: const Key('astracue_plus_sheet'),
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: CompassColors.raised,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: CompassColors.gold.withValues(alpha: 0.55),
          width: 1.2,
        ),
        boxShadow: [
          const BoxShadow(
            color: Colors.black87,
            blurRadius: 36,
            spreadRadius: 4,
          ),
          BoxShadow(
            color: CompassColors.gold.withValues(alpha: 0.14),
            blurRadius: 28,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: CompassColors.gold.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Luxury Emblem
                  Center(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            CompassColors.gold.withValues(alpha: 0.25),
                            CompassColors.deep.withValues(alpha: 0.8),
                          ],
                        ),
                        border: Border.all(
                          color: CompassColors.gold.withValues(alpha: 0.75),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: CompassColors.gold.withValues(alpha: 0.28),
                            blurRadius: 20,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: CompassColors.gold,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: CompassColors.gold.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: CompassColors.gold.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Text(
                        copy.sheetEyebrow,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: const Color(0xFFF2DC9F),
                          letterSpacing: trackingFor(context, 1.4),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    copy.sheetTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: CompassColors.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    copy.sheetSubtitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: CompassColors.secondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Live comparison of today's energy orbs (3 Free + 3 Plus = 6 instant)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          CompassColors.gold.withValues(alpha: 0.16),
                          CompassColors.deep.withValues(alpha: 0.85),
                        ],
                      ),
                      border: Border.all(
                        color: CompassColors.gold.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            AstralEnergyOrbsRow(
                              remainingFreeTurns: snapshot.remainingFreeTurns,
                              orbSize: 11,
                            ),
                            Text(
                              '\$4.99',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    color: CompassColors.gold,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          copy.sheetLiveStatus(snapshot),
                          style: const TextStyle(
                            color: CompassColors.text,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  _PlusBenefitTile(
                    icon: Icons.bolt_rounded,
                    accent: CompassColors.gold,
                    title: copy.benefitTurnsTitle,
                    detail: copy.benefitTurnsDetail,
                  ),
                  _PlusBenefitTile(
                    icon: Icons.lock_open_rounded,
                    accent: CompassColors.blueLight,
                    title: copy.benefitUnlockTitle,
                    detail: copy.benefitUnlockDetail,
                  ),
                  _PlusBenefitTile(
                    icon: Icons.visibility_off_outlined,
                    accent: CompassColors.teal,
                    title: copy.benefitNoAdsTitle,
                    detail: copy.benefitNoAdsDetail,
                  ),
                  _PlusBenefitTile(
                    icon: Icons.balance_rounded,
                    accent: CompassColors.violet,
                    title: copy.benefitFormulaTitle,
                    detail: copy.benefitFormulaDetail,
                  ),

                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 1),
                          child: Icon(
                            Icons.nights_stay_outlined,
                            size: 16,
                            color: CompassColors.gold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            copy.sheetHonestFootnote,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: CompassColors.secondary,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Pinned bottom purchase bar
          Container(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 14),
            decoration: const BoxDecoration(
              color: CompassColors.raised,
              border: Border(top: BorderSide(color: Colors.white12)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: const Key('astracue_plus_purchase_button'),
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(18),
                      child: Ink(
                        height: 54,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFF4E0AC),
                              CompassColors.gold,
                              Color(0xFFBA8F3B),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: CompassColors.gold.withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              copy.purchaseButtonLabel,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: CompassColors.deep,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    key: const Key('close_astracue_plus_sheet'),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      copy.maybeLaterLabel,
                      style: const TextStyle(
                        color: CompassColors.muted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlusBenefitTile extends StatelessWidget {
  const _PlusBenefitTile({
    required this.icon,
    required this.accent,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.045),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: CompassColors.line.withValues(alpha: 0.75)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: accent.withValues(alpha: 0.35)),
              ),
              child: Icon(icon, size: 18, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: CompassColors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    detail,
                    style: const TextStyle(
                      color: CompassColors.secondary,
                      fontSize: 12,
                      height: 1.38,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Localized copy for AstraCue Plus UI & energy turn states across all 7 languages.
class _PlusLocalizedCopy {
  const _PlusLocalizedCopy({
    required this.trayActionLink,
    required this.sheetEyebrow,
    required this.sheetTitle,
    required this.sheetSubtitle,
    required this.benefitTurnsTitle,
    required this.benefitTurnsDetail,
    required this.benefitUnlockTitle,
    required this.benefitUnlockDetail,
    required this.benefitNoAdsTitle,
    required this.benefitNoAdsDetail,
    required this.benefitFormulaTitle,
    required this.benefitFormulaDetail,
    required this.sheetHonestFootnote,
    required this.purchaseButtonLabel,
    required this.maybeLaterLabel,
    required this.homeTrayStatus,
    required this.ritualStatusHeadline,
    required this.ritualStatusSubtitle,
    required this.resultStatusHeadline,
    required this.resultStatusSubtitle,
    required this.sheetLiveStatus,
  });

  final String trayActionLink;
  final String sheetEyebrow;
  final String sheetTitle;
  final String sheetSubtitle;
  final String benefitTurnsTitle;
  final String benefitTurnsDetail;
  final String benefitUnlockTitle;
  final String benefitUnlockDetail;
  final String benefitNoAdsTitle;
  final String benefitNoAdsDetail;
  final String benefitFormulaTitle;
  final String benefitFormulaDetail;
  final String sheetHonestFootnote;
  final String purchaseButtonLabel;
  final String maybeLaterLabel;
  final String Function(ReadingEnergySnapshot) homeTrayStatus;
  final String Function(ReadingEnergySnapshot) ritualStatusHeadline;
  final String Function(ReadingEnergySnapshot) ritualStatusSubtitle;
  final String Function(ReadingEnergySnapshot) resultStatusHeadline;
  final String Function(ReadingEnergySnapshot) resultStatusSubtitle;
  final String Function(ReadingEnergySnapshot) sheetLiveStatus;

  static _PlusLocalizedCopy of(AppLocale locale) {
    return switch (locale) {
      AppLocale.vietnamese => _vi,
      AppLocale.english => _en,
      AppLocale.spanish => _es,
      AppLocale.japanese => _ja,
      AppLocale.thai => _th,
      AppLocale.hindi => _hi,
      AppLocale.simplifiedChinese => _zh,
      AppLocale.korean => _ko,
    };
  }

  static final _vi = _PlusLocalizedCopy(
    trayActionLink: 'Mở 6 lượt tức thì & Tắt Ads (\$4.99) →',
    sheetEyebrow: '✦ ASTRACUE PLUS • MUA 1 LẦN DUY NHẤT',
    sheetTitle: 'Trải nghiệm định hướng liền mạch & tĩnh lặng',
    sheetSubtitle:
        'Mở khóa trọn vẹn năng lượng trong ngày với một lần nâng cấp duy nhất — không gia hạn định kỳ.',
    benefitTurnsTitle: '6 lượt phân tích tức thì mỗi ngày (Không chờ 3 giờ)',
    benefitTurnsDetail:
        'Tăng từ 3 lượt (cách nhau 3 giờ) lên 6 lượt tức thì mỗi ngày. Tra cứu liên tiếp bất cứ lúc nào bạn cần.',
    benefitUnlockTitle: 'Mở sẵn toàn bộ Chế độ, Lĩnh vực & Buổi phân tích',
    benefitUnlockDetail:
        'Tự do chọn mọi khung giờ (Sáng, Trưa, Chiều, Tối), mọi lĩnh vực và cặp định hướng mà không cần xem video mở khóa.',
    benefitNoAdsTitle: 'Tắt hoàn toàn Banner & Quảng cáo chuyển trang',
    benefitNoAdsDetail:
        'Loại bỏ hẳn quảng cáo tự động để giữ không gian chiêm nghiệm tĩnh lặng, không đứt mạch cảm xúc.',
    benefitFormulaTitle: 'Giữ nguyên 100% công thức & chất lượng gốc',
    benefitFormulaDetail:
        'Thuật toán và độ chuẩn xác giống hệt bản miễn phí — bạn chỉ trả tiền cho sự tiện lợi và liền mạch.',
    sheetHonestFootnote:
        'Minh bạch: Gói Plus cung cấp tối đa 6 lượt phân tích tức thì mỗi ngày (tự động làm mới vào 00:00). Khi dùng hết 6 lượt, ứng dụng sẽ thông báo rõ và tuyệt đối không bắt bạn xem quảng cáo.',
    purchaseButtonLabel: '✦ Mở khóa AstraCue Plus — \$4.99 (Mua 1 lần)',
    maybeLaterLabel: 'Để sau',
    homeTrayStatus: (s) {
      if (s.isDailyFreeExhausted) {
        return '0/3 lượt • Làm mới sau ${ReadingEnergySnapshot.formatCountdown(s.timeUntilMidnight)}';
      }
      if (s.isCoolingDown) {
        return '${s.remainingFreeTurns}/3 lượt • Hồi sau ${ReadingEnergySnapshot.formatCountdown(s.cooldownRemaining)}';
      }
      return '${s.remainingFreeTurns}/3 lượt hôm nay • Cách nhau 3h';
    },
    ritualStatusHeadline: (s) {
      if (s.isDailyFreeExhausted) {
        return '🌙 Đã dùng hết 3/3 lượt Free hôm nay • Làm mới sau ${ReadingEnergySnapshot.formatCountdown(s.timeUntilMidnight)}';
      }
      if (s.isCoolingDown) {
        return '⏳ Còn ${s.remainingFreeTurns}/3 lượt hôm nay • Hồi lượt kế tiếp sau ${ReadingEnergySnapshot.formatCountdown(s.cooldownRemaining)}';
      }
      return '⚡ Đang dùng lượt ${s.activeTurnNumber}/3 hôm nay • Lượt kế tiếp cách 3 giờ';
    },
    ritualStatusSubtitle: (s) =>
        'Nâng cấp AstraCue Plus: Mở sẵn mọi Buổi, Lĩnh vực & 6 lượt tức thì/ngày không chờ hồi năng lượng.',
    resultStatusHeadline: (s) {
      if (s.isDailyFreeExhausted) {
        return '🌙 Đã dùng trọn 3/3 lượt Free hôm nay • Làm mới sau ${ReadingEnergySnapshot.formatCountdown(s.timeUntilMidnight)}';
      }
      if (s.isCoolingDown) {
        return '⏳ Còn ${s.remainingFreeTurns}/3 lượt • Hồi lượt tiếp theo sau ${ReadingEnergySnapshot.formatCountdown(s.cooldownRemaining)}';
      }
      return '⚡ Còn ${s.remainingFreeTurns}/3 lượt Free hôm nay';
    },
    resultStatusSubtitle: (s) =>
        'Muốn phân tích tiếp cho Lĩnh vực hoặc Buổi khác ngay lúc này mà không chờ 3 giờ?',
    sheetLiveStatus: (s) {
      if (s.isDailyFreeExhausted) {
        return 'Hôm nay bạn đã dùng hết 3/3 lượt Free. Nâng cấp Plus để mở thêm 3 hạt vàng (tổng 6 lượt tức thì/ngày).';
      }
      if (s.isCoolingDown) {
        return 'Hiện còn ${s.remainingFreeTurns}/3 lượt Free (đang chờ hồi ${ReadingEnergySnapshot.formatCountdown(s.cooldownRemaining)}). Lên Plus để xóa chờ 3h & nhận 6 lượt tức thì/ngày.';
      }
      return 'Hiện có ${s.remainingFreeTurns}/3 hạt xanh (Free) + 3 hạt vàng (Plus) = 6 lượt tức thì/ngày không cần chờ hồi.';
    },
  );

  static final _en = _PlusLocalizedCopy(
    trayActionLink: 'Unlock 6 instant turns & No Ads (\$4.99) →',
    sheetEyebrow: '✦ ASTRACUE PLUS • ONE-TIME PURCHASE',
    sheetTitle: 'Uninterrupted, serene daily direction',
    sheetSubtitle:
        'Unlock the full daily rhythm with a single \$4.99 upgrade — no recurring subscription.',
    benefitTurnsTitle: '6 instant readings per day (No 3-hour wait)',
    benefitTurnsDetail:
        'Double your daily allowance from 3 turns (spaced 3 hours apart) to 6 back-to-back readings whenever you need.',
    benefitUnlockTitle: 'All Modes, Life Areas & Time Periods unlocked',
    benefitUnlockDetail:
        'Freely select any time window (Morning, Midday, Afternoon, Evening) and any category without watching unlock ads.',
    benefitNoAdsTitle: 'Banner & Interstitial ads completely removed',
    benefitNoAdsDetail:
        'Enjoy a calm, distraction-free celestial space with zero automatic ad interruptions.',
    benefitFormulaTitle: 'Identical core formula & reading quality',
    benefitFormulaDetail:
        'Every calculation uses the exact same authentic engine as the free edition — you only pay for convenience and flow.',
    sheetHonestFootnote:
        'Transparency note: Plus includes up to 6 instant readings per day (resetting at 00:00). Once all 6 turns are used, the app notifies you clearly and never asks you to watch rewarded ads.',
    purchaseButtonLabel: '✦ Unlock AstraCue Plus — \$4.99 (One-time)',
    maybeLaterLabel: 'Maybe later',
    homeTrayStatus: (s) {
      if (s.isDailyFreeExhausted) {
        return '0/3 turns • Resets in ${ReadingEnergySnapshot.formatCountdown(s.timeUntilMidnight)}';
      }
      if (s.isCoolingDown) {
        return '${s.remainingFreeTurns}/3 turns • Ready in ${ReadingEnergySnapshot.formatCountdown(s.cooldownRemaining)}';
      }
      return '${s.remainingFreeTurns}/3 turns today • 3h cooldown';
    },
    ritualStatusHeadline: (s) {
      if (s.isDailyFreeExhausted) {
        return '🌙 0/3 Free turns left today • Resets in ${ReadingEnergySnapshot.formatCountdown(s.timeUntilMidnight)}';
      }
      if (s.isCoolingDown) {
        return '⏳ ${s.remainingFreeTurns}/3 turns left • Next turn in ${ReadingEnergySnapshot.formatCountdown(s.cooldownRemaining)}';
      }
      return '⚡ Using turn ${s.activeTurnNumber}/3 today • 3h cooldown between turns';
    },
    ritualStatusSubtitle: (s) =>
        'AstraCue Plus unlocks all Time Periods, Life Areas & 6 instant daily turns with no waiting.',
    resultStatusHeadline: (s) {
      if (s.isDailyFreeExhausted) {
        return '🌙 All 3/3 Free turns used today • Resets in ${ReadingEnergySnapshot.formatCountdown(s.timeUntilMidnight)}';
      }
      if (s.isCoolingDown) {
        return '⏳ ${s.remainingFreeTurns}/3 turns left • Next turn in ${ReadingEnergySnapshot.formatCountdown(s.cooldownRemaining)}';
      }
      return '⚡ ${s.remainingFreeTurns}/3 Free turns remaining today';
    },
    resultStatusSubtitle: (s) =>
        'Want to explore another Life Area or Time Period right now without waiting 3 hours?',
    sheetLiveStatus: (s) {
      if (s.isDailyFreeExhausted) {
        return 'You have used all 3/3 Free turns today. Upgrade to Plus for +3 golden turns (6 instant turns/day).';
      }
      if (s.isCoolingDown) {
        return '${s.remainingFreeTurns}/3 Free turns left (cooling down ${ReadingEnergySnapshot.formatCountdown(s.cooldownRemaining)}). Upgrade to skip the 3h wait.';
      }
      return '${s.remainingFreeTurns}/3 cyan orbs (Free) + 3 gold orbs (Plus) = 6 instant daily turns with zero cooldown.';
    },
  );

  static final _es = _PlusLocalizedCopy(
    trayActionLink: '6 lecturas al instante y Sin Anuncios (\$4.99) →',
    sheetEyebrow: '✦ ASTRACUE PLUS • PAGO ÚNICO',
    sheetTitle: 'Orientación diaria fluida y sin interrupciones',
    sheetSubtitle:
        'Desbloquea todo el potencial diario con un único pago de \$4.99 — sin suscripciones.',
    benefitTurnsTitle: '6 análisis instantáneos al día (Sin espera de 3h)',
    benefitTurnsDetail:
        'Pasa de 3 turnos diarios (con 3 horas de espera) a 6 lecturas inmediatas cuando lo necesites.',
    benefitUnlockTitle: 'Todos los Modos, Áreas y Momentos abiertos',
    benefitUnlockDetail:
        'Elige libremente cualquier período del día y área sin ver videos publicitarios.',
    benefitNoAdsTitle: 'Sin banners ni anuncios intersticiales',
    benefitNoAdsDetail:
        'Un espacio sereno y libre de interrupciones automáticas.',
    benefitFormulaTitle: 'La misma fórmula y calidad de resultado',
    benefitFormulaDetail:
        'El motor simbólico es idéntico al gratuito — solo pagas por la comodidad y fluidez.',
    sheetHonestFootnote:
        'Transparencia: Plus incluye hasta 6 análisis instantáneos al día (se renuevan a las 00:00). Al agotarse, se te informará claramente sin pedirte ver anuncios.',
    purchaseButtonLabel: '✦ Desbloquear AstraCue Plus — \$4.99',
    maybeLaterLabel: 'Más tarde',
    homeTrayStatus: (s) {
      if (s.isDailyFreeExhausted) {
        return '0/3 turnos • Reinicia en ${ReadingEnergySnapshot.formatCountdown(s.timeUntilMidnight)}';
      }
      if (s.isCoolingDown) {
        return '${s.remainingFreeTurns}/3 turnos • Listo en ${ReadingEnergySnapshot.formatCountdown(s.cooldownRemaining)}';
      }
      return '${s.remainingFreeTurns}/3 turnos hoy • Espera de 3h';
    },
    ritualStatusHeadline: (s) {
      if (s.isDailyFreeExhausted) {
        return '🌙 0/3 turnos gratis hoy • Reinicia en ${ReadingEnergySnapshot.formatCountdown(s.timeUntilMidnight)}';
      }
      if (s.isCoolingDown) {
        return '⏳ Quedan ${s.remainingFreeTurns}/3 turnos • Siguiente en ${ReadingEnergySnapshot.formatCountdown(s.cooldownRemaining)}';
      }
      return '⚡ Turno ${s.activeTurnNumber}/3 de hoy • 3h de espera entre turnos';
    },
    ritualStatusSubtitle: (s) =>
        'AstraCue Plus abre todos los períodos, áreas y 6 turnos instantáneos al día sin esperas.',
    resultStatusHeadline: (s) {
      if (s.isDailyFreeExhausted) {
        return '🌙 3/3 turnos gratis usados • Reinicia en ${ReadingEnergySnapshot.formatCountdown(s.timeUntilMidnight)}';
      }
      if (s.isCoolingDown) {
        return '⏳ Quedan ${s.remainingFreeTurns}/3 turnos • Siguiente en ${ReadingEnergySnapshot.formatCountdown(s.cooldownRemaining)}';
      }
      return '⚡ Quedan ${s.remainingFreeTurns}/3 turnos gratis hoy';
    },
    resultStatusSubtitle: (s) =>
        '¿Quieres consultar otra área o período ahora mismo sin esperar 3 horas?',
    sheetLiveStatus: (s) {
      if (s.isDailyFreeExhausted) {
        return 'Has usado los 3/3 turnos gratis de hoy. Sube a Plus para +3 esferas doradas (6 lecturas instantáneas/día).';
      }
      if (s.isCoolingDown) {
        return 'Quedan ${s.remainingFreeTurns}/3 turnos gratis (en espera ${ReadingEnergySnapshot.formatCountdown(s.cooldownRemaining)}). Sube a Plus para omitir las 3h de espera.';
      }
      return '${s.remainingFreeTurns}/3 esferas azules (Gratis) + 3 doradas (Plus) = 6 lecturas instantáneas al día sin esperas.';
    },
  );

  static final _ja = _PlusLocalizedCopy(
    trayActionLink: '即時6回＆広告オフを解放 (\$4.99) →',
    sheetEyebrow: '✦ ASTRACUE PLUS • 買い切りプラン',
    sheetTitle: '待ち時間のない、静謐な導きの体験',
    sheetSubtitle: '\$4.99の1回払いで全機能を解放。定期購読ではありません。',
    benefitTurnsTitle: '1日6回の即時リーディング（3時間の待機なし）',
    benefitTurnsDetail: '1日3回（3時間間隔）から、待ち時間なしの1日6回へ倍増します。',
    benefitUnlockTitle: 'すべてのモード・分野・時間帯を常時解放',
    benefitUnlockDetail: '動画広告を見ることなく、すべての時間帯と分野を自由に選択できます。',
    benefitNoAdsTitle: 'バナー広告・全画面広告を完全に非表示',
    benefitNoAdsDetail: '自動表示される広告をなくし、集中できる静かな空間を保ちます。',
    benefitFormulaTitle: 'アルゴリズムと結果の品質は無料版と同一',
    benefitFormulaDetail: '計算式や精度は無料版と100%同じです。快適さと連続性のためのアップグレードです。',
    sheetHonestFootnote:
        'ご案内：Plusは1日最大6回の即時分析を提供します（毎日00:00にリセット）。6回使い切った際は明確にお知らせし、動画広告の視聴を求めることはありません。',
    purchaseButtonLabel: '✦ AstraCue Plus を解放 — \$4.99',
    maybeLaterLabel: 'あとで',
    homeTrayStatus: (s) {
      if (s.isDailyFreeExhausted) {
        return '残り0/3回 • リセットまで ${ReadingEnergySnapshot.formatCountdown(s.timeUntilMidnight)}';
      }
      if (s.isCoolingDown) {
        return '残り${s.remainingFreeTurns}/3回 • 回復まで ${ReadingEnergySnapshot.formatCountdown(s.cooldownRemaining)}';
      }
      return '本日 ${s.remainingFreeTurns}/3回 • 3時間間隔';
    },
    ritualStatusHeadline: (s) {
      if (s.isDailyFreeExhausted) {
        return '🌙 本日の無料分(3/3回)終了 • リセットまで ${ReadingEnergySnapshot.formatCountdown(s.timeUntilMidnight)}';
      }
      if (s.isCoolingDown) {
        return '⏳ 残り${s.remainingFreeTurns}/3回 • 次回まで ${ReadingEnergySnapshot.formatCountdown(s.cooldownRemaining)}';
      }
      return '⚡ 本日 ${s.activeTurnNumber}/3回目の分析 • 次回まで3時間待機';
    },
    ritualStatusSubtitle: (s) =>
        'AstraCue Plusなら全時間帯・全分野を常時解放し、待機なしで1日6回分析できます。',
    resultStatusHeadline: (s) {
      if (s.isDailyFreeExhausted) {
        return '🌙 本日の無料分(3/3回)終了 • リセットまで ${ReadingEnergySnapshot.formatCountdown(s.timeUntilMidnight)}';
      }
      if (s.isCoolingDown) {
        return '⏳ 残り${s.remainingFreeTurns}/3回 • 次回まで ${ReadingEnergySnapshot.formatCountdown(s.cooldownRemaining)}';
      }
      return '⚡ 本日の無料分 残り${s.remainingFreeTurns}/3回';
    },
    resultStatusSubtitle: (s) => '3時間待たずに、今すぐ別の分野や時間帯を占いますか？',
    sheetLiveStatus: (s) {
      if (s.isDailyFreeExhausted) {
        return '本日の無料分(3/3回)を使い切りました。Plusへアップグレードすると金オーブ3個が加わり、1日6回即時分析できます。';
      }
      if (s.isCoolingDown) {
        return '無料分 残り${s.remainingFreeTurns}/3回（回復まで ${ReadingEnergySnapshot.formatCountdown(s.cooldownRemaining)}）。Plusなら3時間の待機なしで即座に分析できます。';
      }
      return '青オーブ ${s.remainingFreeTurns}/3個 (無料) + 金オーブ 3個 (Plus) = 待機なしで1日6回分析可能。';
    },
  );

  static final _th = _PlusLocalizedCopy(
    trayActionLink: 'ปลดล็อก 6 ครั้งทันที & ปิดโฆษณา (\$4.99) →',
    sheetEyebrow: '✦ ASTRACUE PLUS • ซื้อครั้งเดียว',
    sheetTitle: 'สัมผัสการนำทางที่ต่อเนื่องและสงบนิ่ง',
    sheetSubtitle: 'อัปเกรดเพียงครั้งเดียว \$4.99 — ไม่มีการต่ออายุรายเดือน',
    benefitTurnsTitle: 'วิเคราะห์ได้ทันที 6 ครั้ง/วัน (ไม่ต้องรอ 3 ชม.)',
    benefitTurnsDetail:
        'เพิ่มจาก 3 ครั้ง/วัน (รอคูลดาวน์ 3 ชม.) เป็น 6 ครั้งทันทีโดยไม่ต้องรอฟื้นพลังงาน',
    benefitUnlockTitle: 'ปลดล็อกทุกโหมด ทุกด้าน และทุกช่วงเวลา',
    benefitUnlockDetail: 'เลือกช่วงเวลาและหมวดหมู่ได้ทั้งหมดโดยไม่ต้องดูวิดีโอโฆษณา',
    benefitNoAdsTitle: 'ปิดแบนเนอร์และโฆษณาคั่นหน้าจอทั้งหมด',
    benefitNoAdsDetail: 'ไร้โฆษณารบกวนสมาธิระหว่างการใช้งาน',
    benefitFormulaTitle: 'สูตรคำนวณและคุณภาพผลลัพธ์เหมือนเดิม 100%',
    benefitFormulaDetail:
        'ความแม่นยำเหมือนรุ่นฟรีทุกประการ คุณจ่ายเพื่อความสะดวกและต่อเนื่องเท่านั้น',
    sheetHonestFootnote:
        'ความโปร่งใส: แพ็กเกจ Plus ให้สิทธิ์วิเคราะห์ทันที 6 ครั้ง/วัน (รีเซ็ตเวลา 00:00 น.) เมื่อใช้ครบจะแจ้งเตือนอย่างชัดเจนและไม่บังคับดูโฆษณา',
    purchaseButtonLabel: '✦ ปลดล็อก AstraCue Plus — \$4.99',
    maybeLaterLabel: 'ไว้ทีหลัง',
    homeTrayStatus: (s) {
      if (s.isDailyFreeExhausted) {
        return '0/3 ครั้ง • รีเซ็ตใน ${ReadingEnergySnapshot.formatCountdown(s.timeUntilMidnight)}';
      }
      if (s.isCoolingDown) {
        return 'เหลือ ${s.remainingFreeTurns}/3 ครั้ง • พร้อมใน ${ReadingEnergySnapshot.formatCountdown(s.cooldownRemaining)}';
      }
      return 'วันนี้ ${s.remainingFreeTurns}/3 ครั้ง • ห่างกัน 3 ชม.';
    },
    ritualStatusHeadline: (s) {
      if (s.isDailyFreeExhausted) {
        return '🌙 ใช้ครบ 3/3 ครั้งวันนี้ • รีเซ็ตใน ${ReadingEnergySnapshot.formatCountdown(s.timeUntilMidnight)}';
      }
      if (s.isCoolingDown) {
        return '⏳ เหลือ ${s.remainingFreeTurns}/3 ครั้ง • ครั้งถัดไปใน ${ReadingEnergySnapshot.formatCountdown(s.cooldownRemaining)}';
      }
      return '⚡ กำลังใช้ครั้งที่ ${s.activeTurnNumber}/3 วันนี้ • ครั้งถัดไปรอ 3 ชม.';
    },
    ritualStatusSubtitle: (s) =>
        'AstraCue Plus ปลดล็อกทุกช่วงเวลา ทุกหมวดหมู่ และวิเคราะห์ได้ 6 ครั้งทันทีต่อวัน',
    resultStatusHeadline: (s) {
      if (s.isDailyFreeExhausted) {
        return '🌙 ใช้ครบ 3/3 ครั้งวันนี้ • รีเซ็ตใน ${ReadingEnergySnapshot.formatCountdown(s.timeUntilMidnight)}';
      }
      if (s.isCoolingDown) {
        return '⏳ เหลือ ${s.remainingFreeTurns}/3 ครั้ง • ครั้งถัดไปใน ${ReadingEnergySnapshot.formatCountdown(s.cooldownRemaining)}';
      }
      return '⚡ เหลือสิทธิ์ฟรี ${s.remainingFreeTurns}/3 ครั้งวันนี้';
    },
    resultStatusSubtitle: (s) =>
        'ต้องการวิเคราะห์หมวดอื่นหรือช่วงเวลาอื่นต่อทันทีโดยไม่ต้องรอ 3 ชั่วโมงหรือไม่?',
    sheetLiveStatus: (s) {
      if (s.isDailyFreeExhausted) {
        return 'วันนี้คุณใช้สิทธิ์ฟรีครบ 3/3 ครั้งแล้ว อัปเกรดเป็น Plus เพื่อรับเพิ่ม 3 ลูกแก้วสีทอง (รวม 6 ครั้งทันที/วัน)';
      }
      if (s.isCoolingDown) {
        return 'เหลือสิทธิ์ฟรี ${s.remainingFreeTurns}/3 ครั้ง (รอคูลดาวน์ ${ReadingEnergySnapshot.formatCountdown(s.cooldownRemaining)}) อัปเกรดเป็น Plus เพื่อไม่ต้องรอ 3 ชม.';
      }
      return 'ลูกแก้วสีฟ้า ${s.remainingFreeTurns}/3 (ฟรี) + สีทอง 3 (Plus) = วิเคราะห์ได้ทันที 6 ครั้ง/วัน';
    },
  );

  static final _hi = _PlusLocalizedCopy(
    trayActionLink: '6 तुरंत विश्लेषण और विज्ञापन-मुक्त (\$4.99) →',
    sheetEyebrow: '✦ ASTRACUE PLUS • एक बार की खरीदारी',
    sheetTitle: 'निर्बाध और शांत दैनिक मार्गदर्शन',
    sheetSubtitle:
        'केवल \$4.99 के एक बार के अपग्रेड के साथ पूरा अनुभव अनलॉक करें — कोई आवर्ती शुल्क नहीं।',
    benefitTurnsTitle: 'प्रतिदिन 6 तुरंत विश्लेषण (3 घंटे की प्रतीक्षा नहीं)',
    benefitTurnsDetail:
        '3 विश्लेषण/दिन (3 घंटे के अंतराल) से बढ़ाकर बिना किसी प्रतीक्षा के 6 तुरंत विश्लेषण प्राप्त करें।',
    benefitUnlockTitle: 'सभी मोड, क्षेत्र और समय-अवधि अनलॉक',
    benefitUnlockDetail:
        'बिना कोई विज्ञापन वीडियो देखे किसी भी समय-अवधि और क्षेत्र का स्वतंत्र रूप से चयन करें।',
    benefitNoAdsTitle: 'बैनर और इंटरस्टिशियल विज्ञापन पूरी तरह बंद',
    benefitNoAdsDetail: 'बिना किसी विज्ञापन रुकावट के शांत अनुभव का आनंद लें।',
    benefitFormulaTitle: 'समान सूत्र और परिणाम की गुणवत्ता',
    benefitFormulaDetail:
        'गणना और सटीकता निःशुल्क संस्करण के समान ही रहती है — आप केवल सुविधा के लिए भुगतान करते हैं।',
    sheetHonestFootnote:
        'पारदर्शिता: Plus प्रतिदिन 6 तुरंत विश्लेषण प्रदान करता है (00:00 बजे रीसेट)। 6 बार उपयोग होने पर स्पष्ट सूचना दी जाएगी और कोई विज्ञापन देखने को नहीं कहा जाएगा।',
    purchaseButtonLabel: '✦ AstraCue Plus अनलॉक करें — \$4.99',
    maybeLaterLabel: 'बाद में',
    homeTrayStatus: (s) {
      if (s.isDailyFreeExhausted) {
        return '0/3 शेष • ${ReadingEnergySnapshot.formatCountdown(s.timeUntilMidnight)} में रीसेट';
      }
      if (s.isCoolingDown) {
        return '${s.remainingFreeTurns}/3 शेष • ${ReadingEnergySnapshot.formatCountdown(s.cooldownRemaining)} में तैयार';
      }
      return 'आज ${s.remainingFreeTurns}/3 बार • 3 घंटे का अंतराल';
    },
    ritualStatusHeadline: (s) {
      if (s.isDailyFreeExhausted) {
        return '🌙 आज के 3/3 निःशुल्क विश्लेषण समाप्त • ${ReadingEnergySnapshot.formatCountdown(s.timeUntilMidnight)} में रीसेट';
      }
      if (s.isCoolingDown) {
        return '⏳ ${s.remainingFreeTurns}/3 शेष • अगला ${ReadingEnergySnapshot.formatCountdown(s.cooldownRemaining)} में';
      }
      return '⚡ आज का विश्लेषण ${s.activeTurnNumber}/3 • अगले के लिए 3 घंटे प्रतीक्षा';
    },
    ritualStatusSubtitle: (s) =>
        'AstraCue Plus सभी समय-अवधि, क्षेत्र और बिना प्रतीक्षा के 6 दैनिक विश्लेषण अनलॉक करता है।',
    resultStatusHeadline: (s) {
      if (s.isDailyFreeExhausted) {
        return '🌙 आज के 3/3 निःशुल्क विश्लेषण पूरे • ${ReadingEnergySnapshot.formatCountdown(s.timeUntilMidnight)} में रीसेट';
      }
      if (s.isCoolingDown) {
        return '⏳ ${s.remainingFreeTurns}/3 शेष • अगला ${ReadingEnergySnapshot.formatCountdown(s.cooldownRemaining)} में';
      }
      return '⚡ आज ${s.remainingFreeTurns}/3 निःशुल्क विश्लेषण शेष';
    },
    resultStatusSubtitle: (s) =>
        'क्या आप 3 घंटे प्रतीक्षा किए बिना अभी किसी अन्य क्षेत्र या समय के लिए विश्लेषण करना चाहते हैं?',
    sheetLiveStatus: (s) {
      if (s.isDailyFreeExhausted) {
        return 'आपने आज के सभी 3/3 निःशुल्क विश्लेषण उपयोग कर लिए हैं। +3 सुनहरे विश्लेषण (6 तुरंत विश्लेषण/दिन) के लिए Plus लें।';
      }
      if (s.isCoolingDown) {
        return '${s.remainingFreeTurns}/3 निःशुल्क शेष (${ReadingEnergySnapshot.formatCountdown(s.cooldownRemaining)} प्रतीक्षा)। 3 घंटे की प्रतीक्षा हटाने के लिए Plus में अपग्रेड करें।';
      }
      return '${s.remainingFreeTurns}/3 नीले (निःशुल्क) + 3 सुनहरे (Plus) = प्रतिदिन 6 तुरंत विश्लेषण।';
    },
  );

  static final _zh = _PlusLocalizedCopy(
    trayActionLink: '解锁每日6次即时分析 & 去广告 (\$4.99) →',
    sheetEyebrow: '✦ ASTRACUE PLUS • 一次性买断',
    sheetTitle: '静谧连贯的每日方向指引',
    sheetSubtitle: '仅需 \$4.99 一次性升级，无自动续费订阅。',
    benefitTurnsTitle: '每日 6 次即时分析（免去 3 小时冷却等待）',
    benefitTurnsDetail: '由每日 3 次（每次间隔 3 小时）提升至每日 6 次即时连续分析，无需等待能量恢复。',
    benefitUnlockTitle: '全部模式、领域与时段永久解锁',
    benefitUnlockDetail: '自由选择早、中、下午、晚间等任意时段与领域，无需观看激励视频。',
    benefitNoAdsTitle: '彻底关闭横幅与插屏广告',
    benefitNoAdsDetail: '移除所有自动打断的广告，保留纯粹静谧的思考空间。',
    benefitFormulaTitle: '核心算法与结果品质 100% 一致',
    benefitFormulaDetail: '推算公式与免费版完全相同——您仅为流畅与便捷体验付费。',
    sheetHonestFootnote:
        '透明承诺：Plus 每日提供最多 6 次即时分析（每日 00:00 自动重置）。用完 6 次后会明确提示，绝不诱导或要求您观看广告。',
    purchaseButtonLabel: '✦ 解锁 AstraCue Plus — \$4.99（买断）',
    maybeLaterLabel: '稍后再说',
    homeTrayStatus: (s) {
      if (s.isDailyFreeExhausted) {
        return '0/3 次 • ${ReadingEnergySnapshot.formatCountdown(s.timeUntilMidnight)} 后重置';
      }
      if (s.isCoolingDown) {
        return '剩余 ${s.remainingFreeTurns}/3 次 • ${ReadingEnergySnapshot.formatCountdown(s.cooldownRemaining)} 后恢复';
      }
      return '今日 ${s.remainingFreeTurns}/3 次 • 间隔 3 小时';
    },
    ritualStatusHeadline: (s) {
      if (s.isDailyFreeExhausted) {
        return '🌙 今日 3/3 次免费分析已用完 • ${ReadingEnergySnapshot.formatCountdown(s.timeUntilMidnight)} 后重置';
      }
      if (s.isCoolingDown) {
        return '⏳ 剩余 ${s.remainingFreeTurns}/3 次 • 下次恢复还需 ${ReadingEnergySnapshot.formatCountdown(s.cooldownRemaining)}';
      }
      return '⚡ 正在进行今日第 ${s.activeTurnNumber}/3 次分析 • 下次需等待 3 小时';
    },
    ritualStatusSubtitle: (s) =>
        '升级 AstraCue Plus：免广告解锁全部时段与领域，享每日 6 次即时分析。',
    resultStatusHeadline: (s) {
      if (s.isDailyFreeExhausted) {
        return '🌙 今日 3/3 次免费分析已用完 • ${ReadingEnergySnapshot.formatCountdown(s.timeUntilMidnight)} 后重置';
      }
      if (s.isCoolingDown) {
        return '⏳ 剩余 ${s.remainingFreeTurns}/3 次 • 下次恢复还需 ${ReadingEnergySnapshot.formatCountdown(s.cooldownRemaining)}';
      }
      return '⚡ 今日还剩 ${s.remainingFreeTurns}/3 次免费分析';
    },
    resultStatusSubtitle: (s) => '想要无需等待 3 小时，立即继续探索其他领域或时段吗？',
    sheetLiveStatus: (s) {
      if (s.isDailyFreeExhausted) {
        return '今日 3/3 次免费分析已用完。升级 Plus 即可解锁 +3 颗金星（每日 6 次即时分析）。';
      }
      if (s.isCoolingDown) {
        return '剩余 ${s.remainingFreeTurns}/3 次免费分析（冷却中 ${ReadingEnergySnapshot.formatCountdown(s.cooldownRemaining)}）。升级 Plus 免去 3 小时等待。';
      }
      return '当前 ${s.remainingFreeTurns}/3 颗蓝星（免费）+ 3 颗金星（Plus）= 每日 6 次无冷却即时分析。';
    },
  );

  static final _ko = _PlusLocalizedCopy(
    trayActionLink: '즉시 6회 분석 & 광고 제거 (\$4.99) →',
    sheetEyebrow: '✦ ASTRACUE PLUS • 1회성 평생 소장',
    sheetTitle: '기다림 없는 고요하고 매끄러운 방향 안내',
    sheetSubtitle: '\$4.99 단 한 번의 업그레이드로 모든 일일 에너지를 잠금 해제하세요 — 정기 결제 없음.',
    benefitTurnsTitle: '매일 6회 즉시 분석 (3시간 대기 없음)',
    benefitTurnsDetail:
        '하루 3회(3시간 간격)에서 대기 시간 없는 하루 6회 연속 분석으로 두 배 확대됩니다.',
    benefitUnlockTitle: '모든 모드, 영역 및 시간대 상시 오픈',
    benefitUnlockDetail:
        '보상형 광고를 시청할 필요 없이 오전, 정오, 오후, 저녁 등 모든 시간대와 영역을 자유롭게 선택하세요.',
    benefitNoAdsTitle: '배너 및 전면 광고 완전 제거',
    benefitNoAdsDetail: '흐름을 방해하는 자동 광고 없이 고요하고 집중된 성찰의 공간을 유지합니다.',
    benefitFormulaTitle: '핵심 알고리즘 및 결과 품질 100% 동일',
    benefitFormulaDetail:
        '계산 공식과 정확도는 무료 버전과 완전히 동일합니다 — 오직 편리함과 몰입을 위한 업그레이드입니다.',
    sheetHonestFootnote:
        '투명성 안내: Plus는 하루 최대 6회의 즉시 분석을 제공합니다(매일 00:00 초기화). 6회를 모두 사용하면 명확히 안내하며 절대 광고 시청을 요구하지 않습니다.',
    purchaseButtonLabel: '✦ AstraCue Plus 잠금 해제 — \$4.99 (1회 결제)',
    maybeLaterLabel: '나중에',
    homeTrayStatus: (s) {
      if (s.isDailyFreeExhausted) {
        return '0/3회 남음 • ${ReadingEnergySnapshot.formatCountdown(s.timeUntilMidnight)} 후 초기화';
      }
      if (s.isCoolingDown) {
        return '${s.remainingFreeTurns}/3회 남음 • ${ReadingEnergySnapshot.formatCountdown(s.cooldownRemaining)} 후 충전';
      }
      return '오늘 ${s.remainingFreeTurns}/3회 • 3시간 간격';
    },
    ritualStatusHeadline: (s) {
      if (s.isDailyFreeExhausted) {
        return '🌙 오늘 무료 분석(3/3회) 소진 • ${ReadingEnergySnapshot.formatCountdown(s.timeUntilMidnight)} 후 초기화';
      }
      if (s.isCoolingDown) {
        return '⏳ ${s.remainingFreeTurns}/3회 남음 • 다음 충전까지 ${ReadingEnergySnapshot.formatCountdown(s.cooldownRemaining)}';
      }
      return '⚡ 오늘 ${s.activeTurnNumber}/3번째 분석 사용 중 • 다음 분석까지 3시간 대기';
    },
    ritualStatusSubtitle: (s) =>
        'AstraCue Plus는 모든 시간대와 영역을 상시 개방하고 대기 없이 하루 6회 즉시 분석을 제공합니다.',
    resultStatusHeadline: (s) {
      if (s.isDailyFreeExhausted) {
        return '🌙 오늘 무료 분석(3/3회) 모두 사용 • ${ReadingEnergySnapshot.formatCountdown(s.timeUntilMidnight)} 후 초기화';
      }
      if (s.isCoolingDown) {
        return '⏳ ${s.remainingFreeTurns}/3회 남음 • 다음 충전까지 ${ReadingEnergySnapshot.formatCountdown(s.cooldownRemaining)}';
      }
      return '⚡ 오늘 무료 분석 ${s.remainingFreeTurns}/3회 남음';
    },
    resultStatusSubtitle: (s) =>
        '3시간을 기다리지 않고 지금 바로 다른 영역이나 시간대를 분석해 보시겠어요?',
    sheetLiveStatus: (s) {
      if (s.isDailyFreeExhausted) {
        return '오늘 무료 분석(3/3회)을 모두 사용했습니다. Plus로 업그레이드하여 황금 오브 +3개(하루 6회 즉시 분석)를 잠금 해제하세요.';
      }
      if (s.isCoolingDown) {
        return '무료 분석 ${s.remainingFreeTurns}/3회 남음(쿨다운 ${ReadingEnergySnapshot.formatCountdown(s.cooldownRemaining)}). Plus로 3시간 대기를 건너뛰세요.';
      }
      return '푸른 오브 ${s.remainingFreeTurns}/3개(무료) + 황금 오브 3개(Plus) = 대기 없는 하루 6회 즉시 분석.';
    },
  );
}
