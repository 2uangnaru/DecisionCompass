import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_profile.dart';
import '../data/models/models.dart' as engine;
import '../data/period_availability.dart';
import '../local_engine/time/local_time.dart' show validZone;
import '../l10n/app_localizations.dart';
import '../localized_presentation.dart';
import '../models.dart';
import '../reading_dependencies.dart';
import '../theme.dart';
import '../widgets/celestial_ui.dart';
import '../widgets/responsible_use_sheet.dart';
import 'loading_page.dart';

class RitualPage extends StatefulWidget {
  const RitualPage({
    super.key,
    required this.mode,
    required this.period,
    required this.category,
    required this.profile,
    required this.dependencies,
    this.onSafetyAcknowledged,
  });

  final DecisionMode mode;
  final TimePeriod period;
  final engine.ReadingCategory category;
  final AppProfile profile;
  final ReadingDependencies dependencies;
  final ValueChanged<AppProfile>? onSafetyAcknowledged;

  @override
  State<RitualPage> createState() => _RitualPageState();
}

class _RitualPageState extends State<RitualPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  var _locked = false;
  Timer? _periodRefreshTimer;
  late final AnimationController _pulseController;
  late AppProfile _profile = widget.profile;

  /// The IANA zone a reading taken now would resolve to.
  ///
  /// The reader's IANA zone, once it is known.
  ///
  /// Until it is, no named period can be chosen. How much of Morning is left
  /// is a question about the reader's clock, and an app that has not read that
  /// clock does not know the answer — offering the period anyway would be
  /// claiming it has time left on the strength of never having looked.
  String? _timezone;

  /// Whether the lookup is in flight, done, or failed. Drives the chip suffix
  /// and the retry control.
  _ZoneLookup _zoneLookup = _ZoneLookup.resolving;

  /// Guards against a Reveal tap starting a second lookup on top of the one
  /// the screen started when it opened.
  bool _resolvingZone = false;

  /// When the reading is for. Chosen here, beside the Reveal tap, so the
  /// moment and the period are picked together.
  late TimePeriod _period = widget.period;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addObserver(this);
    _resolveTimezone();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _periodRefreshTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  /// Reads the reader's zone, and re-reads it on demand.
  ///
  /// Returns the zone, or null when it could not be established — either
  /// because the platform refused, or because it named a zone this build's tz
  /// database has never heard of, which is the same thing as far as working
  /// out how much of a local period is left.
  Future<String?> _resolveTimezone() async {
    if (_resolvingZone) return _timezone;
    _resolvingZone = true;
    if (mounted && _timezone == null) {
      setState(() => _zoneLookup = _ZoneLookup.resolving);
    }
    String? zone;
    try {
      zone = await widget.dependencies.contextProvider.currentTimezone();
      if (!validZone(zone)) zone = null;
    } catch (_) {
      zone = null;
    } finally {
      _resolvingZone = false;
    }
    if (!mounted) return zone;
    if (zone == null) {
      // Not "every period is fine": every named period is unanswerable, and
      // the chips say so, with a way to ask again. Any zone read earlier is
      // discarded rather than kept as a best guess — a lookup that fails at
      // the Reveal tap may be failing because the device's zone just changed.
      setState(() {
        _timezone = null;
        _zoneLookup = _ZoneLookup.failed;
      });
      _periodRefreshTimer?.cancel();
      _dropSelectionIfClosed();
      return null;
    }
    setState(() {
      _timezone = zone;
      _zoneLookup = _ZoneLookup.resolved;
    });
    // Every chip is now answerable, and a selection made before the zone
    // arrived may already be closed on the reader's own clock.
    _dropSelectionIfClosed();
    _schedulePeriodRefresh();
    return zone;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back from the background can land well past a cutoff the timer
    // never got to fire for. The repaint is unconditional: a period the reader
    // did *not* pick can close while they are away, and only redrawing when
    // their own choice expired would leave the other chips lying.
    if (state != AppLifecycleState.resumed) return;
    if (!mounted) return;
    setState(() {});
    _dropSelectionIfClosed();
    _schedulePeriodRefresh();
  }

  /// The availability of [period] at this instant, by the reader's own zone.
  ///
  /// [zone] overrides the resolved one, so the Reveal tap can judge the
  /// selection by the zone the reading itself is about to use rather than by
  /// the one this screen happened to read when it opened.
  PeriodAvailability _availability(
    TimePeriod period, {
    DateTime? at,
    String? zone,
  }) {
    // NOW is the instant of the tap. It has no end and needs no clock, so it
    // survives a zone that never resolves.
    if (period.localHours == null) return PeriodAvailability.now;
    final resolved = zone ?? _timezone;
    if (resolved == null) return PeriodAvailability.unknownTimezone;
    return periodAvailability(
      period,
      instantUtc: at ?? widget.dependencies.nowUtc(),
      timezone: resolved,
    );
  }

  /// If the chosen period has closed, fall back to NOW and say why.
  ///
  /// Quietly leaving a closed period selected would let the reader tap Reveal
  /// on something that cannot produce a reading; quietly swapping in a
  /// different named period would answer a question they did not ask.
  void _dropSelectionIfClosed({DateTime? at, String? zone}) {
    if (!mounted || _locked) return;
    final availability = _availability(_period, at: at, zone: zone);
    if (availability.selectable) return;
    final closed = _period;
    setState(() => _period = TimePeriod.now);
    final l10n = AppLocalizations.of(context);
    final label = periodLabel(l10n, closed);
    final messenger = ScaffoldMessenger.of(context)..removeCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        key: const Key('ritual_period_closed_notice'),
        duration: const Duration(seconds: 4),
        content: Text(switch (availability.status) {
          PeriodStatus.passed => l10n.periodHasPassed(label),
          PeriodStatus.unknownTimezone => l10n.timezoneUnavailableNotice,
          _ => l10n.periodNotEnoughTimeLeft(label),
        }),
      ),
    );
  }

  /// Re-render exactly when a period's availability actually changes — when
  /// it drops under its cutoff, when it ends, and when the local date turns
  /// over and re-opens them all — rather than on a poll.
  void _schedulePeriodRefresh() {
    _periodRefreshTimer?.cancel();
    final zone = _timezone;
    if (zone == null) return;
    final now = widget.dependencies.nowUtc();
    final next = nextAvailabilityChange(instantUtc: now, timezone: zone);
    if (next == null) return;
    final wait = next.difference(now.toUtc());
    _periodRefreshTimer = Timer(
      wait > Duration.zero ? wait : const Duration(seconds: 1),
      () {
        if (!mounted) return;
        setState(() {});
        _dropSelectionIfClosed();
        _schedulePeriodRefresh();
      },
    );
  }

  /// Re-checks the selection against the instant of this very tap.
  ///
  /// The chips may have been painted minutes ago. Revalidating here, against
  /// `nowUtc()` rather than the last render, is what stops a stale selection
  /// producing a reading — and it runs before anything is captured, saved or
  /// unlocked.
  bool _rejectClosedPeriod({DateTime? at, String? zone}) {
    final instant = at ?? widget.dependencies.nowUtc();
    if (_availability(_period, at: instant, zone: zone).selectable) {
      return false;
    }
    _dropSelectionIfClosed(at: instant, zone: zone);
    return true;
  }

  Future<void> _reveal() async {
    if (_locked) return;
    // The reading's moment is this tap, taken before any lookup, so a slow
    // one cannot move it — and it is also the instant every check below
    // judges the selection against.
    final instantUtc = widget.dependencies.nowUtc();
    // Cheap rejection first, against what the screen already knows.
    if (_rejectClosedPeriod(at: instantUtc)) return;
    // Then against the zone the reading is actually about to use. The screen
    // may have read its zone minutes ago, and a reader who has crossed a
    // border or whose device changed zone since then would otherwise have
    // their period judged by a clock that is no longer theirs.
    if (_period.localHours != null) {
      final zone = await _resolveTimezone();
      if (!mounted || _locked) return;
      // Unresolvable: `_resolveTimezone` has already dropped the selection
      // and shown why, so the period simply does not travel.
      if (zone == null) return;
      if (_rejectClosedPeriod(at: instantUtc, zone: zone)) return;
    }
    if (!_profile.safetyAcknowledged) {
      final agreed = await showResponsibleUseSheet(
        context,
        isFirstTimeAcknowledgement: true,
      );
      if (!agreed || !mounted) return;
      setState(() => _profile = _profile.copyWith(safetyAcknowledged: true));
      widget.onSafetyAcknowledged?.call(_profile);
    }
    // Checked again: the responsible-use sheet can sit open across a cutoff,
    // and this time against the tap's own instant, not the sheet's.
    if (_rejectClosedPeriod(at: instantUtc)) return;
    setState(() => _locked = true);
    await Future<void>.delayed(const Duration(milliseconds: 360));
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => LoadingPage(
          mode: widget.mode,
          period: _period,
          category: widget.category,
          profile: _profile,
          instantUtc: instantUtc,
          dependencies: widget.dependencies,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return CelestialScaffold(
      // Keep the choice, reveal control and instruction in one top-to-bottom
      // flow. A capped gap after the period chips avoids a tall-screen void;
      // the scroll view still protects small screens and larger text scales.
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 700;
          // Sized from the space actually available rather than from a
          // breakpoint, and capped by width so it never crowds the edges.
          final ringSize = math.min(
            (constraints.maxHeight * 0.28).clamp(150.0, 220.0),
            constraints.maxWidth * 0.62,
          );
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              compact ? 6 : 12,
              20,
              compact ? 18 : 28,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - (compact ? 24 : 40),
              ),
              child: IntrinsicHeight(
                child: _body(compact, ringSize, ringSize * 0.81, reduceMotion),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _body(
    bool compact,
    double ringSize,
    double buttonSize,
    bool reduceMotion,
  ) {
    final l10n = AppLocalizations.of(context);
    final selectedPeriodElapsed = !_availability(_period).selectable;
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: _locked ? null : () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded),
            ),
            Expanded(
              child: Text(
                modeLabel(l10n, widget.mode),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: CompassColors.gold,
                  letterSpacing: trackingFor(context, 1.8),
                ),
              ),
            ),
            IconButton(
              key: const Key('ritual_responsible_use_button'),
              tooltip: l10n.responsibleUse,
              onPressed: _locked
                  ? null
                  : () => showResponsibleUseSheet(context),
              icon: const Icon(Icons.shield_outlined, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _CategoryBadge(
          key: const Key('ritual_category_badge'),
          label: categoryLabel(l10n, widget.category),
          semanticsLabel: l10n.readingAreaSemantics(
            categoryLabel(l10n, widget.category),
          ),
        ),
        SizedBox(height: compact ? 10 : 18),
        _periodSelector(l10n),
        SizedBox(height: compact ? 28 : 48),
        // The hero follows the chips directly. Centring it in all remaining
        // height used to create the large empty band above the circle.
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              button: true,
              enabled: !_locked && !selectedPeriodElapsed,
              // A list of three complete labels, not a sentence with the
              // period dropped into it: "for Morning" is ungrammatical in
              // several of these languages, and a screen reader reads a
              // comma-separated list perfectly well.
              label:
                  '${l10n.reveal}, ${periodLabel(l10n, _period)}, '
                  '${modeLabel(l10n, widget.mode)}',
              child: GestureDetector(
                key: const Key('reveal_button'),
                onTap: _locked || selectedPeriodElapsed ? null : _reveal,
                child: Opacity(
                  opacity: selectedPeriodElapsed ? 0.45 : 1,
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final pulse = reduceMotion || selectedPeriodElapsed
                          ? 0.0
                          : _pulseController.value;
                      // Outer ring breathes noticeably wider than the core button
                      // so the pulse reads clearly without the whole control
                      // feeling like it is jumping in size.
                      final ringScale = _locked ? 0.96 : 1 + pulse * 0.09;
                      final coreScale = _locked ? 0.96 : 1 + pulse * 0.022;
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Transform.scale(
                            scale: ringScale,
                            child: Container(
                              width: ringSize,
                              height: ringSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: CompassColors.blueLight.withValues(
                                    alpha: 0.2 + pulse * 0.28,
                                  ),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: CompassColors.blueLight.withValues(
                                      alpha: 0.08 + pulse * 0.1,
                                    ),
                                    blurRadius: 24 + pulse * 26,
                                    spreadRadius: pulse * 6,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Transform.scale(
                            scale: coreScale,
                            child: Container(
                              width: buttonSize,
                              height: buttonSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const RadialGradient(
                                  colors: [
                                    Color(0xFF286DA5),
                                    Color(0xFF153553),
                                  ],
                                ),
                                border: Border.all(
                                  color: CompassColors.blueLight,
                                  width: 1.4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: CompassColors.blueLight.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: _locked ? 48 : 30 + pulse * 12,
                                    spreadRadius: _locked ? 8 : 2 + pulse * 2,
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ZodiacAvatar(
                                    size: compact ? 54 : 62,
                                    sign: widget.profile.zodiacSign,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    _locked
                                        ? l10n.aligning
                                        : selectedPeriodElapsed
                                        ? l10n.periodPassedShort
                                        : l10n.reveal,
                                    textAlign: TextAlign.center,
                                    // Two lines, because several languages
                                    // need more than one word where English
                                    // needs one; the circle keeps its size.
                                    maxLines: 2,
                                    style: TextStyle(
                                      fontSize: 12,
                                      letterSpacing: trackingFor(context, 2),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            SizedBox(height: compact ? 18 : 24),
            Text(
              _locked
                  ? l10n.ritualLocked
                  : selectedPeriodElapsed
                  ? l10n.periodHasPassed(periodLabel(l10n, _period))
                  : l10n.tapWhenReady,
              key: const Key('ritual_ready_title'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 10),
            Text(
              l10n.keepChoiceInMind,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: compact ? 10 : 14),
            Text(
              l10n.ritualSafety,
              key: const Key('ritual_responsible_use_note'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: CompassColors.secondary,
                fontSize: 11,
                fontStyle: FontStyle.italic,
                height: 1.45,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Compact chips, wrapped and centred so all five fit a 360dp phone without
  /// overflow and without competing with the reveal circle for attention.
  Widget _periodSelector(AppLocalizations l10n) {
    // Availability is read on every build, so a period that closes while the
    // screen is open stops being offered. The engine's own `period_elapsed`
    // answer stays the authority if the clock crosses a boundary after the tap.
    return Column(
      children: [
        Text(
          l10n.periodQuestion,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: CompassColors.secondary,
            letterSpacing: trackingFor(context, 0.7),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          key: const Key('ritual_period_selector'),
          alignment: WrapAlignment.center,
          spacing: 7,
          runSpacing: 2,
          children: TimePeriod.values.map((period) {
            final availability = _availability(period);
            final elapsed = !availability.selectable;
            final selected = period == _period;
            final label = periodLabel(l10n, period);
            // Two complete labels joined by a separator, so no language has to
            // fit "Passed" into an English sentence frame. A period that is
            // still running but under its cutoff says so instead: it has not
            // passed, there is simply not enough of it left.
            final suffix = switch (availability.status) {
              PeriodStatus.available => null,
              PeriodStatus.tooLittleTime => l10n.periodTooLittleTime,
              PeriodStatus.passed => l10n.periodPassed,
              // Not a claim about the period — a claim about this screen. It
              // has no clock to measure the period against yet.
              PeriodStatus.unknownTimezone =>
                _zoneLookup == _ZoneLookup.resolving
                    ? l10n.periodCheckingTimezone
                    : l10n.periodTimezoneUnknown,
            };
            return ChoiceChip(
              key: Key('ritual_period_${period.name}'),
              label: Text(suffix == null ? label : '$label · $suffix'),
              selected: selected,
              showCheckmark: false,
              visualDensity: VisualDensity.compact,
              // A null callback is what disables a chip. Elapsed periods stay
              // on screen, muted, so the whole day is still legible.
              onSelected: elapsed || _locked
                  ? null
                  : (_) {
                      // A cutoff may have passed since the last paint.
                      if (!_availability(period).selectable) {
                        setState(() {});
                        return;
                      }
                      setState(() => _period = period);
                    },
              backgroundColor: Colors.white.withValues(alpha: 0.04),
              disabledColor: Colors.white.withValues(alpha: 0.02),
              selectedColor: const Color(0xFF244C78),
              side: BorderSide(
                color: selected && !elapsed
                    ? CompassColors.blueLight
                    : CompassColors.line,
              ),
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: elapsed
                    ? CompassColors.muted
                    : selected
                    ? Colors.white
                    : CompassColors.secondary,
              ),
            );
          }).toList(),
        ),
        if (_zoneLookup == _ZoneLookup.failed) _zoneRetry(l10n),
      ],
    );
  }

  /// Says why the named periods are unavailable, and offers to look again.
  ///
  /// Without this the chips would simply be dead, which reads as a bug. The
  /// reading itself is not blocked: NOW is still there, and still correct,
  /// because it needs no clock but the tap's own.
  Widget _zoneRetry(AppLocalizations l10n) {
    return Padding(
      key: const Key('ritual_timezone_retry'),
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          Text(
            l10n.timezoneUnavailableNotice,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: CompassColors.muted,
            ),
          ),
          TextButton(
            key: const Key('ritual_timezone_retry_button'),
            onPressed: _locked ? null : _resolveTimezone,
            child: Text(l10n.tryAgain),
          ),
        ],
      ),
    );
  }
}

/// How far the screen has got in reading the reader's own time zone.
enum _ZoneLookup { resolving, resolved, failed }

/// Compact, calm badge naming the area the reading concerns.
class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({
    super.key,
    required this.label,
    required this.semanticsLabel,
  });

  final String label;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: CompassColors.line),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: CompassColors.blueLight,
            letterSpacing: trackingFor(context, 0.9),
          ),
        ),
      ),
    );
  }
}
